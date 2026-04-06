import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/datasources/location_datasource.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/location/get_current_location_usecase.dart';

/// Provides the GeolocatorPlatform instance for location services.
final geolocatorProvider = Provider<GeolocatorPlatform>((ref) {
  return GeolocatorPlatform.instance;
});

/// Provides the location datasource implementation.
final locationDatasourceProvider = Provider<ILocationDatasource>((ref) {
  final geolocator = ref.watch(geolocatorProvider);
  return LocationDatasource(geolocatorPlatform: geolocator);
});

/// Provides the location repository implementation.
final locationRepositoryProvider = Provider<ILocationRepository>((ref) {
  final datasource = ref.watch(locationDatasourceProvider);
  return LocationRepository(locationDatasource: datasource);
});

/// Provides the get current location usecase.
final getCurrentLocationUsecaseProvider = Provider<GetCurrentLocationUsecase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return GetCurrentLocationUsecase(locationRepository: repository);
});

/// Provides location permission request result.
///
/// Returns true if permission was granted, false otherwise.
/// Use this to prompt user for location permission.
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return await repository.requestPermission();
});

/// Provides real-time location stream.
///
/// Emits [LocationEntity] whenever device location changes.
/// Returns error state if permission denied or service disabled.
/// Build this with `.when()` to handle loading, data, and error states.
final currentLocationProvider = StreamProvider<LocationEntity>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.watchLocation();
});

/// Provides current location as a one-time Future.
///
/// Use this to get current location once, not continuously.
/// Returns error state if permission denied or service disabled.
final singleLocationProvider = FutureProvider<LocationEntity>((ref) async {
  final usecase = ref.watch(getCurrentLocationUsecaseProvider);
  return await usecase();
});
