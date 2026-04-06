import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/errors/exceptions.dart';

/// Abstract interface for notification-related Firebase operations.
abstract class INotificationDatasource {
  /// Requests notification permissions from the user.
  Future<bool> requestPermission();

  /// Returns the current FCM token.
  Future<String?> getToken();

  /// Persists the FCM token to the user document.
  Future<void> saveToken({required String uid, required String token});

  /// Deletes the stored FCM token from the user document.
  Future<void> clearToken({required String uid});

  /// Listens for foreground messages.
  Stream<RemoteMessage> onMessage();

  /// Listens for taps on notifications while app is in background.
  Stream<RemoteMessage> onMessageOpenedApp();

  /// Returns the notification that launched the app, if any.
  Future<RemoteMessage?> getInitialMessage();
}

/// Firebase implementation of [INotificationDatasource].
class FirebaseNotificationDatasource implements INotificationDatasource {
  /// Creates a [FirebaseNotificationDatasource].
  const FirebaseNotificationDatasource({
    required FirebaseMessaging firebaseMessaging,
    required FirebaseFirestore firestore,
  })  : _firebaseMessaging = firebaseMessaging,
        _firestore = firestore;

  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      throw ServerException(code: 'notification_permission', message: e.toString());
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      throw ServerException(code: 'notification_token', message: e.toString());
    }
  }

  @override
  Future<void> saveToken({required String uid, required String token}) async {
    try {
      await _usersCollection.doc(uid).set(
        {
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw ServerException(code: e.code, message: e.message ?? 'Failed to save FCM token');
    } catch (e) {
      throw ServerException(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> clearToken({required String uid}) async {
    try {
      await _usersCollection.doc(uid).set(
        {
          'fcmToken': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw ServerException(code: e.code, message: e.message ?? 'Failed to clear FCM token');
    } catch (e) {
      throw ServerException(code: 'unknown', message: e.toString());
    }
  }

  @override
  Stream<RemoteMessage> onMessage() => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> onMessageOpenedApp() => FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await _firebaseMessaging.getInitialMessage();
    } catch (e) {
      throw ServerException(code: 'notification_initial_message', message: e.toString());
    }
  }
}