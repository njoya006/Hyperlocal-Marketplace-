import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'firebase_options.dart';
import 'presentation/router/app_router.dart';
import 'presentation/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mapbox token BEFORE Firebase - required on Android
  // Token is injected via android/local.properties and build.gradle.kts
  _initializeMapbox();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: HyperLocalApp(),
    ),
  );
}

/// Initialize Mapbox with access token
void _initializeMapbox() {
  const String mapboxToken =
      String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');
  if (mapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxToken);
    debugPrint('[MAPBOX] Access token initialized for Android');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[NOTIFICATION] Background message: ${message.messageId}');
}

class HyperLocalApp extends ConsumerWidget {
  const HyperLocalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationControllerProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'HyperLocal Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
