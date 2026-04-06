/// Application configuration constants and settings.
/// 
/// Centralized configuration for app behavior, feature flags, API endpoints,
/// and other configurable parameters.
abstract final class AppConfig {
  // ============== APP INFO ==============
  /// Application name
  static const String appName = 'HyperLocal Market';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Application build number
  static const int buildNumber = 1;

  /// App package name (must match android/app/build.gradle & iOS bundle id)
  static const String packageName = 'com.hyperlocal.hyperlocal_market';

  // ============== FIREBASE ==============
  /// Firebase project ID for Firestore database
  static const String firebaseProjectId = 'hyperlocal-market-ba481';

  // ============== MAPBOX ==============
  /// Mapbox access token.
  /// 
  /// On Android: Stored in android/local.properties and injected via build.gradle.kts
  /// On iOS: Stored in Podfile or configured via native code
  /// On Web: Loaded from environment variables during build
  /// This is a placeholder - actual token is injected by build system.
  static const String mapboxToken = '';  // Injected by Android build process

  /// Placeholder method for future Mapbox token dynamic loading.
  /// Currently, the token is injected via Android build configuration.
  static Future<String> getMapboxToken() async {
    // Token is set via android/local.properties and build.gradle.kts
    return mapboxToken;
  }

  // ============== LOCATION SETTINGS ==============
  /// Default search radius in kilometers for nearby shops.
  static const double defaultRadiusKm = 5.0;

  /// Minimum search radius in kilometers.
  static const double minRadiusKm = 1.0;

  /// Maximum search radius in kilometers.
  static const double maxRadiusKm = 20.0;

  /// Location update interval in seconds.
  /// Used for real-time location tracking during delivery.
  static const int locationUpdateIntervalSeconds = 10;

  /// Location accuracy threshold in meters.
  /// Minimum accuracy required to consider location valid.
  static const double locationAccuracyThresholdM = 50.0;

  // ============== ORDER SETTINGS ==============
  /// Maximum order placement timeout in seconds.
  static const int orderPlacementTimeoutSeconds = 30;

  /// Order status update polling interval in seconds (when not using real-time streams).
  static const int orderStatusPollingIntervalSeconds = 5;

  /// Default payment method (currently only supports cash on delivery).
  static const String defaultPaymentMethod = 'cash_on_delivery';

  /// Maximum items allowed in a single order.
  static const int maxItemsPerOrder = 100;

  /// Minimum order value in local currency (in cents to avoid float precision issues).
  /// For example: 50000 = 500 XAF (Cameroon Franc) = ~$0.80 USD
  static const int minOrderValueCents = 50000;

  // ============== PRODUCT SETTINGS ==============
  /// Maximum product title length in characters.
  static const int maxProductTitleLength = 100;

  /// Maximum product description length in characters.
  static const int maxProductDescriptionLength = 500;

  /// Maximum price value (to prevent accidental data entry errors).
  /// In cents: 10000000 = 100,000 local currency units
  static const int maxProductPriceCents = 10000000;

  // ============== CACHE SETTINGS ==============
  /// Cache duration for shop list in minutes.
  static const Duration shopCacheDuration = Duration(minutes: 15);

  /// Cache duration for product list in minutes.
  static const Duration productCacheDuration = Duration(minutes: 10);

  /// Cache duration for user profile in minutes.
  static const Duration userCacheDuration = Duration(minutes: 30);

  /// Cache duration for orders in minutes.
  static const Duration orderCacheDuration = Duration(minutes: 5);

  /// Maximum cache size in bytes (100 MB).
  static const int maxCacheSizeBytes = 100 * 1024 * 1024;

  // ============== PAGINATION ==============
  /// Default page size for list queries (shops, products, orders).
  static const int defaultPageSize = 20;

  /// Minimum page size for queries.
  static const int minPageSize = 5;

  /// Maximum page size for queries (prevent abusing the API).
  static const int maxPageSize = 100;

  // ============== API TIMEOUT ==============
  /// Default API request timeout in seconds.
  static const int apiTimeoutSeconds = 30;

  /// Image upload timeout in seconds (longer than regular requests).
  static const int imageUploadTimeoutSeconds = 60;

  /// Chat/real-time operations timeout in seconds.
  static const int realtimeTimeoutSeconds = 60;

  // ============== IMAGE SETTINGS ==============
  /// Maximum image upload size in bytes (10 MB).
  static const int maxImageSizeBytes = 10 * 1024 * 1024;

  /// Allowed image MIME types for uploads.
  static const List<String> allowedImageMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  /// Image compression quality (0.0 to 1.0).
  /// 0.8 provides good quality while reducing file size.
  static const double imageCompressionQuality = 0.8;

  // ============== NOTIFICATION SETTINGS ==============
  /// Maximum notification fetch batch size.
  static const int notificationBatchSize = 20;

  /// Notification cache duration in hours.
  static const Duration notificationCacheDuration = Duration(hours: 24);

  // ============== ADMIN SETTINGS ==============
  /// Number of days to keep audit logs.
  static const int auditLogRetentionDays = 90;

  /// Number of failed login attempts before account lockout.
  static const int maxFailedLoginAttempts = 5;

  /// Account lockout duration in minutes.
  static const int accountLockoutDurationMinutes = 15;

  // ============== FEATURE FLAGS ==============
  /// Enable/disable shop rating system.
  static const bool enableRatings = true;

  /// Enable/disable customer reviews.
  static const bool enableReviews = true;

  /// Enable/disable order tracking in real-time.
  static const bool enableRealtimeTracking = true;

  /// Enable/disable push notifications.
  static const bool enablePushNotifications = true;

  /// Enable/disable shop owner promotions.
  static const bool enablePromotions = true;

  /// Enable/disable order cancellation by customer (only from pending state).
  static const bool enableOrderCancellation = true;

  // ============== DEVELOPMENT FLAGS ==============
  /// Enable debug logging throughout the app.
  static const bool enableDebugLogging = true;

  /// Show network request/response logs.
  static const bool enableNetworkLogging = true;

  /// Enable Firestore emulator (for local development).
  static const bool useFirestoreEmulator = false;

  /// Enable Firebase Auth emulator (for local development).
  static const bool useAuthEmulator = false;

  // ============== ENVIRONMENT ==============
  /// Current environment ('development', 'staging', 'production').
  /// Set via --dart-define at compile time: flutter run --dart-define=ENVIRONMENT=production
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Check if app is running in debug mode.
  static const bool isDebugMode = bool.fromEnvironment(
    'DEBUG',
    defaultValue: false,
  );

  /// Helper to check current environment.
  static bool isProduction() => environment == 'production';
  static bool isStaging() => environment == 'staging';
  static bool isDevelopment() => environment == 'development';
}
