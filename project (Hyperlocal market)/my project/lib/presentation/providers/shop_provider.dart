import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../config/app_config.dart';
import '../../data/datasources/firebase_storage_datasource.dart';
import '../../data/datasources/firestore_shop_datasource.dart';
import '../../data/repositories/shop_repository_impl.dart';
import '../../data/repositories/storage_repository_impl.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/shop/create_shop_usecase.dart';
import '../../domain/repositories/shop_repository.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/usecases/shop/get_shops_by_owner_usecase.dart';
import '../../domain/usecases/shop/get_nearby_shops_usecase.dart';
import '../../domain/usecases/shop/upload_shop_image_usecase.dart';
import '../../domain/usecases/shop/watch_shop_usecase.dart';
import 'location_provider.dart';

// ============== DEPENDENCY INJECTION ==============

/// Provides the Firestore instance for shop data access.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provides the shop datasource implementation.
final shopDatasourceProvider = Provider<IShopDatasource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreShopDatasource(firestore: firestore);
});

/// Provides Firebase Storage instance.
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Provides the storage datasource implementation.
final storageDatasourceProvider = Provider<IStorageDatasource>((ref) {
  final firebaseStorage = ref.watch(firebaseStorageProvider);
  return FirebaseStorageDatasource(firebaseStorage: firebaseStorage);
});

/// Provides the storage repository implementation.
final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  final datasource = ref.watch(storageDatasourceProvider);
  return StorageRepository(storageDatasource: datasource);
});

/// Provides the shop repository implementation.
final shopRepositoryProvider = Provider<IShopRepository>((ref) {
  final datasource = ref.watch(shopDatasourceProvider);
  return ShopRepository(shopDatasource: datasource);
});

/// Provides the get nearby shops usecase.
final getNearbyShopsUsecaseProvider = Provider<GetNearbyShopsUsecase>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  return GetNearbyShopsUsecase(shopRepository: repository);
});

/// Provides the watch shop usecase.
final watchShopUsecaseProvider = Provider<WatchShopUsecase>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  return WatchShopUsecase(shopRepository: repository);
});

/// Provides the get shops by owner usecase.
final getShopsByOwnerUsecaseProvider = Provider<GetShopsByOwnerUsecase>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  return GetShopsByOwnerUsecase(shopRepository: repository);
});

/// Provides the create shop usecase.
final createShopUsecaseProvider = Provider<CreateShopUsecase>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  return CreateShopUsecase(shopRepository: repository);
});

/// Provides shop image upload usecase.
final uploadShopImageUsecaseProvider = Provider<UploadShopImageUsecase>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  return UploadShopImageUsecase(storageRepository: repository);
});

// ============== STATE & CONFIGURATION ==============

/// Manages the search radius for nearby shops.
///
/// Users can adjust the search radius independently from the default.
/// Defaults to [AppConfig.defaultRadiusKm] (5 km).
/// Valid range: [AppConfig.minRadiusKm] to [AppConfig.maxRadiusKm] (1-20 km).
final shopRadiusProvider = StateProvider<double>((ref) {
  return AppConfig.defaultRadiusKm;
});

// ============== DATA PROVIDERS ==============

/// Provides nearby shops based on current user location.
///
/// Uses the device's current GPS coordinates and the current search radius.
/// Automatically updates when:
/// - User's location changes
/// - Search radius is adjusted
/// - Manual refresh is triggered
///
/// Build with `.when()` to handle:
/// - `loading`: Fetching shops...
/// - `data`: List of nearby shops sorted by distance
/// - `error`: Location permission denied, network error, etc.
///
/// Example:
/// ```dart
/// nearbyShopsProvider.when(
///   loading: () => LoadingWidget(),
///   data: (shops) => ShopList(shops: shops),
///   error: (err, stk) => ErrorWidget(error: err),
/// )
/// ```
final nearbyShopsProvider = FutureProvider<List<ShopEntity>>((ref) async {
  // Use a one-time location snapshot to avoid continuous auto-refresh while
  // users are interacting with the map.
  final location = await ref.watch(singleLocationProvider.future);
  
  // Watch for radius changes
  final radius = ref.watch(shopRadiusProvider);

  // Fetch shops with the available location
  final usecase = ref.watch(getNearbyShopsUsecaseProvider);
  return await usecase(
    lat: location.latitude,
    lng: location.longitude,
    radiusKm: radius,
  );
});

/// Creates a provider for watching a specific shop in real-time.
///
/// Pass the shop ID to get a stream of real-time shop updates.
/// Useful for displaying shop details, checking approval status, or live status.
///
/// Example:
/// ```dart
/// final shopProvider = watchShopProvider('shop_123');
/// 
/// ref.watch(shopProvider).when(
///   loading: () => LoadingWidget(),
///   data: (shop) => ShopHeader(shop: shop),
///   error: (err, stk) => ErrorWidget(error: err),
/// )
/// ```
///
/// [shopId] is the unique identifier of the shop to watch
/// Returns a [StreamProvider<ShopEntity>] that emits shop updates
final watchShopProvider = StreamProvider.family<ShopEntity, String>((ref, shopId) {
  final usecase = ref.watch(watchShopUsecaseProvider);
  return usecase(shopId);
});

/// Loads all shops owned by a specific user.
final ownerShopsProvider = FutureProvider.family<List<ShopEntity>, String>(
  (ref, ownerId) async {
    final usecase = ref.watch(getShopsByOwnerUsecaseProvider);
    return await usecase(ownerId: ownerId);
  },
);

/// Picks the first available shop for the current owner.
final ownerShopProvider = FutureProvider.family<ShopEntity?, String>(
  (ref, ownerId) async {
    final shops = await ref.watch(ownerShopsProvider(ownerId).future);
    if (shops.isEmpty) {
      return null;
    }
    final approved = shops.where((shop) => shop.isApproved).toList();
    return approved.isNotEmpty ? approved.first : shops.first;
  },
);

/// Provides a refresh mechanism for nearby shops.
///
/// Use ref.refresh(refreshNearbyShopsProvider) to manually refresh shops.
/// Or use ref.refresh(nearbyShopsProvider) directly.
/// This is a convenience provider for refresh callbacks.
final refreshNearbyShopsProvider = Provider<Function()>((ref) {
  return () => ref.refresh(nearbyShopsProvider);
});

/// Notifier for creating a shop.
class CreateShopNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Creates a new shop and updates async state.
  Future<void> createShop({required ShopEntity shop}) async {
    state = const AsyncLoading();
    final createShopUsecase = ref.read(createShopUsecaseProvider);
    state = await AsyncValue.guard(() => createShopUsecase(shop: shop));
  }
}

/// Async notifier provider for shop creation.
final createShopProvider =
    AsyncNotifierProvider<CreateShopNotifier, void>(CreateShopNotifier.new);
