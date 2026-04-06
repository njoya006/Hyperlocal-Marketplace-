import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_datasource.dart';

/// Concrete implementation of [ILocationRepository] using [ILocationDatasource].
///
/// Handles all location-related data operations and maps exceptions to failures.
class LocationRepository implements ILocationRepository {
  /// Creates a new [LocationRepository].
  const LocationRepository({
    required ILocationDatasource locationDatasource,
  }) : _locationDatasource = locationDatasource;

  final ILocationDatasource _locationDatasource;

  @override
  Future<LocationEntity> getCurrentLocation() async {
    try {
      return await _locationDatasource.getCurrentPosition();
    } on LocationException catch (e) {
      throw LocationFailure(code: e.code, message: e.message);
    } catch (e) {
      throw LocationFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Stream<LocationEntity> watchLocation() {
    try {
      return _locationDatasource.watchPosition().handleError((error) {
        if (error is LocationException) {
          throw LocationFailure(code: error.code, message: error.message);
        }
        throw LocationFailure(code: 'unknown', message: error.toString());
      });
    } catch (e) {
      if (e is LocationFailure) rethrow;
      throw LocationFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _locationDatasource.requestPermission();
    } catch (e) {
      throw LocationFailure(code: 'unknown', message: e.toString());
    }
  }
}
