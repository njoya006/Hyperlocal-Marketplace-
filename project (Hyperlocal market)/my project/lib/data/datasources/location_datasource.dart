import 'package:geolocator/geolocator.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/location_entity.dart';

/// Abstract interface for location data access.
abstract class ILocationDatasource {
  /// Get the current device location.
  ///
  /// Throws [LocationException] if permission is denied or location services disabled.
  Future<LocationEntity> getCurrentPosition();

  /// Request location permission from the user.
  Future<bool> requestPermission();

  /// Watch location changes as a stream.
  ///
  /// Emits [LocationEntity] whenever device location changes.
  /// Throws [LocationException] if permission is denied or location services disabled.
  Stream<LocationEntity> watchPosition();
}

/// Concrete implementation of [ILocationDatasource] using geolocator package.
class LocationDatasource implements ILocationDatasource {
  /// Creates a new [LocationDatasource].
  const LocationDatasource({
    required GeolocatorPlatform geolocatorPlatform,
  }) : _geolocator = geolocatorPlatform;

  final GeolocatorPlatform _geolocator;

  @override
  Future<LocationEntity> getCurrentPosition() async {
    try {
      final permission = await _ensurePermission();
      if (!permission) {
        throw const LocationException(
          code: 'PERMISSION_DENIED',
          message: 'Location permission denied',
        );
      }

      final isServiceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        throw const LocationException(
          code: 'LOCATION_DISABLED',
          message: 'Location services are disabled',
        );
      }

      final position = await _geolocator.getCurrentPosition();

      return LocationEntity(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          position.timestamp.millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      if (e is LocationException) rethrow;
      throw LocationException(code: 'UNKNOWN', message: e.toString());
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final permission = await _geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      throw LocationException(code: 'UNKNOWN', message: e.toString());
    }
  }

  @override
  Stream<LocationEntity> watchPosition() async* {
    try {
      final permission = await _ensurePermission();
      if (!permission) {
        throw const LocationException(
          code: 'PERMISSION_DENIED',
          message: 'Location permission denied',
        );
      }

      final isServiceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        throw const LocationException(
          code: 'LOCATION_DISABLED',
          message: 'Location services are disabled',
        );
      }

      yield* _geolocator.getPositionStream().map(
        (position) => LocationEntity(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            position.timestamp.millisecondsSinceEpoch,
          ),
        ),
      );
    } catch (e) {
      if (e is LocationException) rethrow;
      throw LocationException(code: 'UNKNOWN', message: e.toString());
    }
  }

  /// Ensure permission is granted by checking then requesting when needed.
  Future<bool> _ensurePermission() async {
    final currentPermission = await _geolocator.checkPermission();
    if (currentPermission == LocationPermission.whileInUse ||
        currentPermission == LocationPermission.always) {
      return true;
    }

    if (currentPermission == LocationPermission.deniedForever) {
      throw const LocationException(
        code: 'PERMISSION_DENIED_FOREVER',
        message: 'Location permission denied forever. Open app settings.',
      );
    }

    final requestedPermission = await _geolocator.requestPermission();
    return requestedPermission == LocationPermission.whileInUse ||
        requestedPermission == LocationPermission.always;
  }
}
