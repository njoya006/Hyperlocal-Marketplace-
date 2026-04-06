import 'dart:typed_data';
import 'dart:ui' as ui;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Geolocator, LocationPermission;

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/location_entity.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../providers/location_provider.dart';
import '../../providers/shop_provider.dart';
import '../shop/shop_list_cards.dart';

class MapboxWidget extends ConsumerStatefulWidget {
  const MapboxWidget({super.key});

  @override
  ConsumerState<MapboxWidget> createState() => _MapboxWidgetState();
}

class _MapboxWidgetState extends ConsumerState<MapboxWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  bool _mapStyleLoaded = false;
  LocationEntity? _lastLocation;
  List<ShopEntity>? _lastShops;
  Uint8List? _customerMarkerImage;
  Uint8List? _shopMarkerImage;

  Future<Uint8List> _buildMarkerImage(Color color) async {
    const size = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 18), 26, shadowPaint);

    final outerPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(Icons.location_on.codePoint),
        style: TextStyle(
          fontFamily: Icons.location_on.fontFamily,
          package: Icons.location_on.fontPackage,
          fontSize: 118,
          color: Colors.white,
        ),
      ),
    )..layout();
    outerPainter.paint(canvas, const Offset(4, 0));

    final innerPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(Icons.location_on.codePoint),
        style: TextStyle(
          fontFamily: Icons.location_on.fontFamily,
          package: Icons.location_on.fontPackage,
          fontSize: 106,
          color: color,
        ),
      ),
    )..layout();
    innerPainter.paint(canvas, const Offset(10, 5));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _ensureMarkerImages() async {
    _customerMarkerImage ??= await _buildMarkerImage(Colors.blue);
    _shopMarkerImage ??= await _buildMarkerImage(Colors.green);
  }

  Future<void> _fitCameraToMarkers() async {
    if (_mapboxMap == null || _lastLocation == null) {
      return;
    }

    final coordinates = <Point>[
      Point(
        coordinates: Position(
          _lastLocation!.longitude,
          _lastLocation!.latitude,
        ),
      ),
      ...?_lastShops?.map(
        (shop) => Point(
          coordinates: Position(shop.longitude, shop.latitude),
        ),
      ),
    ];

    if (coordinates.length < 2) {
      return;
    }

    try {
      final camera = await _mapboxMap!.cameraForCoordinatesPadding(
        coordinates,
        CameraOptions(zoom: 13.5),
        MbxEdgeInsets(top: 90, left: 60, bottom: 260, right: 60),
        16.0,
        null,
      );
      await _mapboxMap!.easeTo(
        camera,
        MapAnimationOptions(duration: 450),
      );
      debugPrint('[MAPBOX] Fitted camera to ${coordinates.length} points');
    } catch (e) {
      debugPrint('[MAPBOX] Error fitting camera: $e');
    }
  }

  /// Re-apply customer and shop markers when the map style and data are ready.
  Future<void> _refreshMarkers() async {
    if (!_mapStyleLoaded ||
        _pointAnnotationManager == null ||
        _lastLocation == null) {
      return;
    }

    await _pointAnnotationManager!.deleteAll();

    await _ensureMarkerImages();
    await _addCustomerMarker(_lastLocation!);

    final shops = _lastShops;
    if (shops != null && shops.isNotEmpty) {
      await _addShopMarkers(shops);
    }
  }

  /// Add a visible customer marker at the current location.
  Future<void> _addCustomerMarker(LocationEntity location) async {
    if (_pointAnnotationManager == null || _customerMarkerImage == null) {
      return;
    }

    try {
      await _pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(location.longitude, location.latitude),
          ),
          image: _customerMarkerImage,
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: 0.55,
        ),
      );
      debugPrint('[MAPBOX] Added customer marker');
    } catch (e) {
      debugPrint('[MAPBOX] Error adding customer marker: $e');
    }
  }

  /// Add shop markers to the map with green pin icons and labels
  Future<void> _addShopMarkers(List<ShopEntity> shops) async {
    if (_pointAnnotationManager == null ||
        _shopMarkerImage == null ||
        shops.isEmpty) {
      return;
    }

    try {
      final pointOptions = <PointAnnotationOptions>[];

      for (final shop in shops) {
        pointOptions.add(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(shop.longitude, shop.latitude),
            ),
            image: _shopMarkerImage,
            iconAnchor: IconAnchor.BOTTOM,
            iconSize: 0.7,
            symbolSortKey: 1,
            textField: shop.name,
            textSize: 11.0,
            textColor: Colors.black.toARGB32(),
            textHaloColor: Colors.white.toARGB32(),
            textHaloWidth: 1.5,
            textAnchor: TextAnchor.TOP,
            textOffset: const [0.0, 1.3],
          ),
        );
      }

      if (pointOptions.isNotEmpty) {
        await _pointAnnotationManager!.createMulti(pointOptions);
      }

      debugPrint('[MAPBOX] Added ${shops.length} shop markers');
    } catch (e) {
      debugPrint('[MAPBOX] Error adding markers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(singleLocationProvider);
    final shopsAsync = ref.watch(nearbyShopsProvider);

    return locationAsync.when(
      data: (location) {
        return shopsAsync.when(
          data: (shops) {
            _lastLocation = location;
            // Store shops reference for marker addition
            _lastShops = shops;
            debugPrint('[MAPBOX] Visible shops loaded: ${shops.length}');

            if (_mapStyleLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _refreshMarkers();
                _fitCameraToMarkers();
              });
            }

            return SizedBox.expand(
              child: Column(
                children: [
                  // Map section (60%)
                  Expanded(
                    flex: 6,
                    child: MapWidget(
                      key: const ValueKey('mapbox_map'),
                      onMapCreated: (MapboxMap mapboxMap) async {
                        _mapboxMap = mapboxMap;
                        _mapboxMap?.setCamera(
                          CameraOptions(
                            center: Point(
                              coordinates: Position(
                                location.longitude,
                                location.latitude,
                              ),
                            ),
                            zoom: 14.0,
                          ),
                        );
                      },
                      onStyleLoadedListener: (styleLoadedEventData) async {
                        if (_mapStyleLoaded) return;
                        try {
                          _pointAnnotationManager = await _mapboxMap
                              ?.annotations
                              .createPointAnnotationManager();
                          await _pointAnnotationManager!.setIconAllowOverlap(
                            true,
                          );
                          await _pointAnnotationManager!.setIconIgnorePlacement(
                            true,
                          );
                          await _pointAnnotationManager!.setTextAllowOverlap(
                            true,
                          );
                          await _pointAnnotationManager!.setTextIgnorePlacement(
                            true,
                          );
                          await _pointAnnotationManager!.setTextOptional(true);
                          _mapStyleLoaded = true;
                          await _refreshMarkers();
                          await _fitCameraToMarkers();
                        } catch (e) {
                          debugPrint('[MAPBOX] Error initializing: $e');
                        }
                      },
                    ),
                  ),
                  // Shop cards section (40%)
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              AppStrings.labelNearbyShops,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ShopListCards(
                              shops: shops,
                              userLatitude: location.latitude,
                              userLongitude: location.longitude,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Center(
            child: Text('Error loading shops: $e'),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Could not access location',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final granted = await ref.read(locationPermissionProvider.future);
                  if (!granted) {
                    final permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.deniedForever) {
                      await Geolocator.openAppSettings();
                    }
                  }

                  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    await Geolocator.openLocationSettings();
                  }

                  ref.invalidate(singleLocationProvider);
                  ref.invalidate(nearbyShopsProvider);
                },
                child: const Text('Grant Permission & Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapboxMap = null;
    _pointAnnotationManager = null;
    _mapStyleLoaded = false;
    _lastLocation = null;
    _lastShops = null;
    super.dispose();
  }
}
