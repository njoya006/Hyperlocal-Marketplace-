import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/notification_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../router/app_router.dart';
import 'auth_provider.dart';

/// Provides Firebase Messaging instance.
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// Provides notification datasource implementation.
final notificationDatasourceProvider = Provider<INotificationDatasource>((ref) {
  final messaging = ref.watch(firebaseMessagingProvider);
  final firestore = ref.watch(firestoreProvider);
  return FirebaseNotificationDatasource(
    firebaseMessaging: messaging,
    firestore: firestore,
  );
});

/// Provides notification repository implementation.
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  final datasource = ref.watch(notificationDatasourceProvider);
  return NotificationRepository(notificationDatasource: datasource);
});

/// Global controller that wires auth changes to notification handling.
final notificationControllerProvider = Provider<NotificationController>((ref) {
  final controller = NotificationController();
  final repository = ref.watch(notificationRepositoryProvider);

  ref.listen(authStateProvider, (previous, next) async {
    final previousUser = previous?.maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );
    final nextUser = next.maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );

    if (previousUser?.uid == nextUser?.uid) {
      return;
    }

    if (previousUser != null) {
      await repository.clearToken(previousUser.uid);
    }

    if (nextUser != null) {
      await repository.saveToken(nextUser.uid);
    }
  });

  controller.initialize(repository);
  ref.onDispose(controller.dispose);
  return controller;
});

/// Small controller that owns notification listeners.
class NotificationController {
  /// Creates a [NotificationController].
  NotificationController();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  bool _initialized = false;

  /// Starts listening to auth and messaging streams.
  Future<void> initialize(INotificationRepository repository) async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await repository.initialize();
    _foregroundSubscription = repository.onMessage().listen(_handleMessage);
    _openedSubscription = repository.onMessageOpenedApp().listen(_handleMessageTap);

    final initialMessage = await repository.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
  }

  void _handleMessage(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    final snackBar = SnackBar(
      content: Text(body.isEmpty ? title : '$title • $body'),
      action: SnackBarAction(
        label: 'Open',
        onPressed: () => _navigateForMessage(message),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _handleMessageTap(RemoteMessage message) {
    _navigateForMessage(message);
  }

  void _navigateForMessage(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final type = message.data['type']?.toString() ?? '';
    final id = message.data['orderId']?.toString() ?? message.data['id']?.toString() ?? '';

    switch (type) {
      case 'new_order':
        GoRouter.of(context).go(Routes.ownerOrders);
        return;
      case 'order_update':
        if (id.isNotEmpty) {
          GoRouter.of(context).go('${Routes.customer}/track/$id');
        }
        return;
      case 'shop_approved':
        GoRouter.of(context).go(Routes.ownerDashboard);
        return;
      default:
        if (id.isNotEmpty) {
          GoRouter.of(context).go('${Routes.customer}/track/$id');
        }
    }
  }
}