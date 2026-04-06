import 'dart:math';

import 'package:equatable/equatable.dart';

/// Represents a geographic location with GPS coordinates and accuracy.
class LocationEntity extends Equatable {
  const LocationEntity({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  /// Latitude coordinate (decimal degrees)
  final double latitude;

  /// Longitude coordinate (decimal degrees)
  final double longitude;

  /// Horizontal accuracy in meters
  final double accuracy;

  /// Timestamp when location was captured
  final DateTime timestamp;

  /// Returns distance in kilometres from the given coordinates using Haversine formula.
  double distanceTo(double lat, double lng) {
    const double earthRadiusKm = 6371;
    final dLat = _toRadians(lat - latitude);
    final dLng = _toRadians(lng - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Converts degrees to radians.
  double _toRadians(double degree) => degree * pi / 180;

  @override
  List<Object?> get props => [latitude, longitude, accuracy, timestamp];
}
