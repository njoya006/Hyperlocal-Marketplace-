import 'package:firebase_messaging/firebase_messaging.dart';

/// Abstract notification repository contract.
abstract class INotificationRepository {
  /// Starts notification handling and returns true if permission is granted.
  Future<bool> initialize();

  /// Saves the current token for a specific user.
  Future<void> saveToken(String uid);

  /// Clears the current token for a specific user.
  Future<void> clearToken(String uid);

  /// Stream of foreground messages.
  Stream<RemoteMessage> onMessage();

  /// Stream of tap events from background notifications.
  Stream<RemoteMessage> onMessageOpenedApp();

  /// Returns the launch notification, if any.
  Future<RemoteMessage?> getInitialMessage();
}