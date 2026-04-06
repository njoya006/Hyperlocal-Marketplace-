// Custom exceptions for HyperLocal Market application.
// Typed exceptions for different error scenarios.

/// Base exception class for authentication-related errors.
/// 
/// Thrown by [FirebaseAuthDatasource] when authentication operations fail.
/// The [code] identifies the specific error type for handling.
class AuthException implements Exception {
  /// Creates an [AuthException].
  /// 
  /// [code] is a string identifier for the specific auth error.
  /// [message] is a user-friendly description of the error.
  const AuthException({
    required this.code,
    required this.message,
  });

  /// Error code identifying the specific authentication failure.
  /// 
  /// Common codes:
  /// - 'invalid-email': Email format is invalid
  /// - 'user-not-found': No user exists with this email
  /// - 'wrong-password': Password is incorrect
  /// - 'user-disabled': User account has been disabled
  /// - 'email-already-in-use': Email already registered
  /// - 'weak-password': Password does not meet strength requirements
  /// - 'operation-not-allowed': This operation is not enabled
  /// - 'invalid-credential': Credential is invalid or expired
  /// - 'network-error': Network error during authentication
  /// - 'unknown': Unknown authentication error
  final String code;

  /// Human-readable error message suitable for UI display.
  /// 
  /// Localized in production.
  final String message;

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

/// Exception thrown when network operations fail.
/// 
/// Thrown by datasources when network requests encounter issues such as
/// no connectivity, timeouts, or invalid responses.
class NetworkException implements Exception {
  /// Creates a [NetworkException].
  /// 
  /// [code] describes the type of network failure.
  /// [message] explains what went wrong.
  const NetworkException({
    required this.code,
    required this.message,
  });

  /// Error code identifying the type of network failure.
  /// 
  /// Common codes:
  /// - 'no-connection': Device has no internet connection
  /// - 'timeout': Request timed out waiting for response
  /// - 'connection-refused': Server refused the connection
  /// - 'bad-response': Server returned invalid data
  /// - 'ssl-error': SSL/TLS certificate verification failed
  /// - 'host-lookup-failed': Could not resolve domain name
  /// - 'unknown': Unknown network error
  final String code;

  /// Human-readable error message suitable for UI display.
  final String message;

  @override
  String toString() => 'NetworkException(code: $code, message: $message)';
}

/// Exception thrown when location operations fail.
/// 
/// Thrown by [LocationDatasource] when GPS access or location retrieval fails.
class LocationException implements Exception {
  /// Creates a [LocationException].
  /// 
  /// [code] identifies the location-related failure.
  /// [message] explains what went wrong.
  const LocationException({
    required this.code,
    required this.message,
  });

  /// Error code identifying the type of location failure.
  /// 
  /// Common codes:
  /// - 'permission-denied': User denied location permission
  /// - 'permission-denied-forever': User permanently denied permission
  /// - 'service-disabled': Location services are disabled on device
  /// - 'location-not-available': Current location could not be determined
  /// - 'timeout': Location request timed out
  /// - 'gps-disabled': GPS is disabled on the device
  /// - 'accuracy-insufficient': Location accuracy is too low
  /// - 'unknown': Unknown location error
  final String code;

  /// Human-readable error message suitable for UI display.
  final String message;

  @override
  String toString() => 'LocationException(code: $code, message: $message)';
}

/// Exception thrown when server operations fail.
/// 
/// Thrown by datasources when Firestore or other backend services return errors.
class ServerException implements Exception {
  /// Creates a [ServerException].
  /// 
  /// [code] identifies the server error.
  /// [message] explains what went wrong.
  /// [statusCode] is optional HTTP status code if available.
  const ServerException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  /// Error code identifying the type of server failure.
  /// 
  /// Common codes (Firebase Firestore):
  /// - 'not-found': Document or resource not found
  /// - 'already-exists': Document already exists
  /// - 'permission-denied': Permission denied by Firestore rules
  /// - 'invalid-argument': Invalid argument provided to Firestore
  /// - 'unauthenticated': Request is not authenticated
  /// - 'internal': Internal server error
  /// - 'service-unavailable': Service temporarily unavailable
  /// - 'unknown': Unknown server error
  final String code;

  /// Human-readable error message suitable for UI display.
  final String message;

  /// Optional HTTP status code (e.g., 400, 404, 500).
  final int? statusCode;

  @override
  String toString() =>
      'ServerException(code: $code, statusCode: $statusCode, message: $message)';
}

/// Exception thrown when storage operations fail.
/// 
/// Thrown by [FirebaseStorageDatasource] when file upload/download fails.
class StorageException implements Exception {
  /// Creates a [StorageException].
  /// 
  /// [code] identifies the storage error.
  /// [message] explains what went wrong.
  const StorageException({
    required this.code,
    required this.message,
  });

  /// Error code identifying the type of storage failure.
  /// 
  /// Common codes:
  /// - 'object-not-found': File does not exist in storage
  /// - 'bucket-not-found': Storage bucket does not exist
  /// - 'project-not-found': Firebase project not configured
  /// - 'quota-exceeded': Storage quota exceeded
  /// - 'unauthenticated': User is not authenticated
  /// - 'unauthorized': User lacks permission to access file
  /// - 'retry-limit-exceeded': Upload/download retry limit exceeded
  /// - 'invalid-url': Storage URL is invalid
  /// - 'invalid-argument': Invalid argument provided
  /// - 'network-error': Network error during upload/download
  final String code;

  /// Human-readable error message suitable for UI display.
  final String message;

  @override
  String toString() => 'StorageException($code): $message';
}

/// Exception thrown when validation fails.
/// 
/// Thrown when user input or data validation fails.
class ValidationException implements Exception {
  /// Creates a [ValidationException].
  /// 
  /// [code] identifies what was invalid.
  /// [message] explains the validation failure.
  const ValidationException({
    required this.code,
    required this.message,
  });

  /// Error code identifying the validation failure.
  /// 
  /// Common codes:
  /// - 'empty-field': Required field is empty
  /// - 'invalid-email': Email format is invalid
  /// - 'invalid-phone': Phone number format is invalid
  /// - 'password-too-short': Password is too short
  /// - 'password-mismatch': Passwords do not match
  /// - 'invalid-number': Field should be a valid number
  /// - 'value-out-of-range': Value is outside acceptable range
  final String code;

  /// Human-readable error message suitable for UI display.
  final String message;

  @override
  String toString() => 'ValidationException($code): $message';
}
