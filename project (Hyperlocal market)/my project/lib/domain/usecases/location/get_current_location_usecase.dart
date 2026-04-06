import '../../entities/location_entity.dart';
import '../../repositories/location_repository.dart';

/// Use case for getting the current device location.
///
/// Retrieves the device's current GPS coordinates and accuracy information.
/// Call this usecase by invoking an instance: `await getLocationUsecase()`
class GetCurrentLocationUsecase {
  /// Creates a new [GetCurrentLocationUsecase].
  const GetCurrentLocationUsecase({
    required ILocationRepository locationRepository,
  }) : _locationRepository = locationRepository;

  final ILocationRepository _locationRepository;

  /// Get the current device location.
  ///
  /// Returns [LocationEntity] with GPS coordinates and accuracy.
  /// Throws [LocationFailure] if permission denied or service disabled.
  Future<LocationEntity> call() async {
    return await _locationRepository.getCurrentLocation();
  }
}
