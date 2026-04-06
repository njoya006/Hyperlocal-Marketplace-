import 'package:equatable/equatable.dart';

// Failures for HyperLocal Market application.
// Abstract and concrete failure classes for error reporting and handling.

/// Abstract base failure class for all application failures.
/// 
/// Failures are returned from repositories to the domain layer when operations fail.
/// Each failure corresponds to a specific exception type thrown by datasources.
/// Failures use [Equatable] for value-based equality comparison.
abstract class Failure extends Equatable {
  /// A unique failure code for identifying the type of failure.
  final String code;

  /// A user-friendly message describing the failure.
  final String message;

  /// Creates a [Failure].
  const Failure({
    required this.code,
    required this.message,
  });

  @override
  List<Object?> get props => [code, message];
}

/// Failure representing authentication-related errors.
/// 
/// Thrown when login, registration, password reset, or other auth operations fail.
/// Repositories catch [AuthException] and convert to [AuthFailure].
class AuthFailure extends Failure {
  /// Creates an [AuthFailure].
  /// 
  /// [code] should match one from [AuthException]:
  /// 'invalid-email', 'user-not-found', 'wrong-password', 'user-disabled',
  /// 'email-already-in-use', 'weak-password', 'network-error', 'unknown'
  const AuthFailure({
    required super.code,
    required super.message,
  });

  @override
  String toString() => 'AuthFailure(code: $code, message: $message)';
}

/// Failure representing network-related errors.
/// 
/// Thrown when HTTP requests fail due to connectivity issues, timeouts, or bad responses.
/// Repositories catch [NetworkException] and convert to [NetworkFailure].
class NetworkFailure extends Failure {
  /// Creates a [NetworkFailure].
  /// 
  /// [code] should match one from [NetworkException]:
  /// 'no-connection', 'timeout', 'connection-refused', 'bad-response',
  /// 'ssl-error', 'host-lookup-failed', 'unknown'
  const NetworkFailure({
    required super.code,
    required super.message,
  });

  @override
  String toString() => 'NetworkFailure(code: $code, message: $message)';
}

/// Failure representing location-related errors.
/// 
/// Thrown when GPS access is denied, location services are disabled, or retrieval fails.
/// Repositories catch [LocationException] and convert to [LocationFailure].
class LocationFailure extends Failure {
  /// Creates a [LocationFailure].
  /// 
  /// [code] should match one from [LocationException]:
  /// 'permission-denied', 'permission-denied-forever', 'service-disabled',
  /// 'location-not-available', 'timeout', 'gps-disabled', 'unknown'
  const LocationFailure({
    required super.code,
    required super.message,
  });

  @override
  String toString() => 'LocationFailure(code: $code, message: $message)';
}

/// Failure representing server-related errors.
/// 
/// Thrown when Firestore, Cloud Functions, or other backend services return errors.
/// Repositories catch [ServerException] and convert to [ServerFailure].
class ServerFailure extends Failure {
  /// Optional HTTP status code from the server (e.g., 400, 404, 500).
  final int? statusCode;

  /// Creates a [ServerFailure].
  /// 
  /// [code] should match one from [ServerException]:
  /// 'not-found', 'already-exists', 'permission-denied', 'invalid-argument',
  /// 'unauthenticated', 'internal', 'service-unavailable', 'unknown'
  /// [statusCode] is optional and should be the HTTP status code if available.
  const ServerFailure({
    required super.code,
    required super.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [code, message, statusCode];

  @override
  String toString() =>
      'ServerFailure(code: $code, statusCode: $statusCode, message: $message)';
}
