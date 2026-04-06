import '../entities/location_entity.dart';

/// Abstract interface for location repository.
///
/// Defines the contract for location operations in the domain layer.
abstract class ILocationRepository {
  /// Get the current device location.
  ///
  /// Returns a [LocationEntity] with current GPS coordinates.
  /// May throw exceptions if permission denied or service disabled.
  Future<LocationEntity> getCurrentLocation();

  /// Watch location changes in real-time.
  ///
  /// Returns a stream that emits [LocationEntity] whenever device location changes.
  Stream<LocationEntity> watchLocation();

  /// Request location permission from the user.
  ///
  /// Returns true if permission was granted, false otherwise.
  Future<bool> requestPermission();
}
