import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstract interface for network connectivity checks.
///
/// This interface provides a method to determine if the device is currently
/// connected to a network. By using an abstract interface, we enable easy
/// mocking for unit tests and allow switching network implementations.
abstract class INetworkInfo {
  /// Checks if the device has an active network connection.
  ///
  /// Returns true if the device is currently connected to WiFi, mobile data,
  /// or any other network interface. Returns false if offline.
  ///
  /// This getter provides a synchronous check for the current network state.
  Future<bool> get isConnected;
}

/// Concrete implementation of [INetworkInfo] using the connectivity_plus package.
///
/// This class wraps the [Connectivity] plugin to provide a consistent interface
/// for checking network connectivity across the app. It handles different
/// connectivity types (WiFi, mobile data, Ethernet, VPN, etc.) and returns
/// a simple boolean indicating whether the device has any internet connection.
///
/// Used by repositories to determine if network-dependent operations should
/// proceed, allowing graceful fallback to cached data when offline.
class NetworkInfo implements INetworkInfo {
  /// Connectivity plugin instance.
  /// Injected via constructor to allow mocking in tests.
  final Connectivity _connectivity;

  /// Creates a new [NetworkInfo].
  ///
  /// Requires a [Connectivity] instance to be injected, enabling this
  /// class to be easily tested with a mock implementation.
  const NetworkInfo({required Connectivity connectivity})
      : _connectivity = connectivity;

  @override
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      // Connected if results list is not empty and doesn't contain only 'none'
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (e) {
      // If checking connectivity fails, assume not connected to be safe
      return false;
    }
  }
}
