import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';

/// Concrete implementation of [INotificationRepository].
class NotificationRepository implements INotificationRepository {
  /// Creates a [NotificationRepository].
  const NotificationRepository({
    required INotificationDatasource notificationDatasource,
  }) : _notificationDatasource = notificationDatasource;

  final INotificationDatasource _notificationDatasource;

  @override
  Future<bool> initialize() async {
    try {
      return await _notificationDatasource.requestPermission();
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> saveToken(String uid) async {
    try {
      final token = await _notificationDatasource.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      await _notificationDatasource.saveToken(uid: uid, token: token);
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> clearToken(String uid) async {
    try {
      await _notificationDatasource.clearToken(uid: uid);
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Stream<RemoteMessage> onMessage() => _notificationDatasource.onMessage();

  @override
  Stream<RemoteMessage> onMessageOpenedApp() =>
      _notificationDatasource.onMessageOpenedApp();

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await _notificationDatasource.getInitialMessage();
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }
}