# TASKS.md — HyperLocal Market Build Order

> This file tells GitHub Copilot and the Lead Developer exactly WHAT to build,
> in what ORDER, and what DONE means for each task.
> Always complete tasks in sequence — later tasks depend on earlier ones.

---

## 🚦 BUILD PHASES OVERVIEW

```
Phase 1 → Project foundation + Auth
Phase 2 → Shop discovery + Maps
Phase 3 → Products + Cart + Orders
Phase 4 → Real-time tracking + Notifications
Phase 5 → Admin web panel
Phase 6 → Polish + Performance
```

---

## PHASE 1 — FOUNDATION & AUTHENTICATION
**Estimated: Week 1**

### Task 1.1 — Core Setup
- [ ] Create all folders from the folder structure in AGENTS.md
- [ ] Configure `pubspec.yaml` with all dependencies
- [ ] Run `flutter pub get` successfully
- [ ] Configure Firebase (run `flutterfire configure`)
- [ ] Set up `main.dart` with ProviderScope + Firebase init
- [ ] Create `AppColors`, `AppStrings`, `AppSizes` constants
- [ ] Create `Exceptions` and `Failures` base classes
- [ ] Set up `app_router.dart` with go_router (all routes stubbed)

**Done when:** `flutter run` launches a blank app without errors on Android

---

### Task 1.2 — User Model & Entity
- [ ] Create `UserEntity` in `domain/entities/user_entity.dart`
- [ ] Create `UserModel` in `data/models/user_model.dart`
- [ ] `UserModel.fromFirestore()` factory constructor
- [ ] `UserModel.toFirestore()` method
- [ ] `UserModel.fromEntity()` factory constructor
- [ ] `UserEntity` uses `Equatable` for value comparison

**Done when:** Tester can write and pass serialization tests for UserModel

---

### Task 1.3 — Authentication Datasource
- [ ] Create abstract `IAuthDatasource` interface
- [ ] Implement `FirebaseAuthDatasource`
- [ ] `signInWithEmail(email, password)` → returns `UserCredential`
- [ ] `registerWithEmail(email, password)` → returns `UserCredential`
- [ ] `signOut()` → void
- [ ] `authStateChanges()` → `Stream<User?>`
- [ ] `currentUser` getter → `User?`
- [ ] Save user document to Firestore on registration

**Done when:** Tester can mock `IAuthDatasource` and test all methods

---

### Task 1.4 — Authentication Repository
- [ ] Create abstract `IAuthRepository` interface
- [ ] Implement `AuthRepository` using `IAuthDatasource`
- [ ] `login(email, password)` → `Future<UserEntity>`
- [ ] `register(email, password, name, role)` → `Future<UserEntity>`
- [ ] `logout()` → `Future<void>`
- [ ] `watchAuthState()` → `Stream<UserEntity?>`
- [ ] Handle `FirebaseAuthException` → throw typed `AuthException`

**Done when:** Tester passes all AuthRepository unit tests

---

### Task 1.5 — Authentication Usecases
- [ ] `LoginUseCase` — calls `IAuthRepository.login()`
- [ ] `RegisterUseCase` — calls `IAuthRepository.register()`
- [ ] `LogoutUseCase` — calls `IAuthRepository.logout()`
- [ ] Each usecase is a callable class with `call()` method

**Done when:** Tester passes all auth usecase tests

---

### Task 1.6 — Auth Provider & Screens
- [ ] `authStateProvider` → `StreamProvider<UserEntity?>`
- [ ] `loginProvider` → `AsyncNotifierProvider`
- [ ] `registerProvider` → `AsyncNotifierProvider`
- [ ] `LoginScreen` with email + password fields + validation
- [ ] `RegisterScreen` with name, email, password, role selector
- [ ] Role selector: Customer or Shop Owner (admin created manually)
- [ ] Route guard: redirect to `/login` if not authenticated
- [ ] Route guard: redirect based on role after login
- [ ] `SplashScreen` checks auth state → routes correctly

**Done when:** User can register, login, and be routed to correct screen

---

## PHASE 2 — SHOP DISCOVERY & MAPS
**Estimated: Week 2**

### Task 2.1 — Location Service
- [ ] Create `LocationDatasource` using `geolocator` package
- [ ] `getCurrentPosition()` → `Future<Position>`
- [ ] `requestPermission()` → `Future<LocationPermission>`
- [ ] `watchPosition()` → `Stream<Position>`
- [ ] Handle permission denied → throw `LocationPermissionException`
- [ ] Handle location services disabled → throw `LocationDisabledException`
- [ ] `LocationRepository` wraps datasource
- [ ] `GetCurrentLocationUseCase`
- [ ] `locationProvider` → `StreamProvider<Position>`

**Done when:** App shows current GPS coordinates in debug overlay

---

### Task 2.2 — Shop Model & Entity
- [ ] `ShopEntity` in `domain/entities/shop_entity.dart`
- [ ] `ShopModel` in `data/models/shop_model.dart`
- [ ] `ShopModel.fromFirestore()` factory
- [ ] `ShopModel.toFirestore()` method
- [ ] `distanceTo(double lat, double lng)` utility on `ShopEntity`

**Done when:** Tester passes ShopModel serialization tests

---

### Task 2.3 — Shop Datasource & Repository
- [ ] Abstract `IShopDatasource` interface
- [ ] `FirestoreShopDatasource` implementation
- [ ] `getNearbyShops(lat, lng, radiusKm)` → `Future<List<ShopModel>>`
  - Query Firestore using geohash or bounding box technique
- [ ] `watchShop(shopId)` → `Stream<ShopModel>`
- [ ] `createShop(ShopModel)` → `Future<void>` (for shop_owner)
- [ ] `updateShop(shopId, Map data)` → `Future<void>`
- [ ] `IShopRepository` interface + `ShopRepository` implementation
- [ ] `GetNearbyShopsUseCase`
- [ ] `WatchShopUseCase`

**Done when:** Tester passes all ShopRepository unit tests

---

### Task 2.4 — Mapbox Map Screen
- [ ] `MapboxWidget` in `widgets/map/mapbox_widget.dart`
- [ ] Initialise map at user's GPS location
- [ ] Add `GeoJsonSource` for shop markers
- [ ] `nearbyShopsProvider` → `FutureProvider<List<ShopEntity>>`
- [ ] Populate markers from provider data
- [ ] Tap marker → show `ShopPreviewBottomSheet`
- [ ] `ShopPreviewBottomSheet` shows name, category, rating, distance
- [ ] "View Shop" button → navigates to `/customer/shop/:shopId`
- [ ] Radius selector (5km, 10km, 20km)
- [ ] Refresh button to reload shops

**Done when:** Map shows real shops from Firestore with working tap behaviour

---

### Task 2.5 — Shop Owner Registration Flow
- [ ] After `shop_owner` registers → prompt to create shop
- [ ] `CreateShopScreen` with name, category, description, phone, address
- [ ] GPS auto-fills coordinates on screen open
- [ ] Image upload to Firebase Storage → saves `imageUrl`
- [ ] On submit → create shop document with `isApproved: false`
- [ ] Show "Awaiting admin approval" screen after submission

**Done when:** Shop owner can register and create a shop pending approval

---

## PHASE 3 — PRODUCTS, CART & ORDERS
**Estimated: Week 3**

### Task 3.1 — Product Model & Repository
- [ ] `ProductEntity` + `ProductModel`
- [ ] `IProductDatasource` + `FirestoreProductDatasource`
- [ ] `getShopProducts(shopId)` → `Future<List<ProductModel>>`
- [ ] `addProduct(shopId, ProductModel)` → `Future<void>`
- [ ] `updateProduct(shopId, productId, data)` → `Future<void>`
- [ ] `deleteProduct(shopId, productId)` → `Future<void>`
- [ ] `IProductRepository` + `ProductRepository`
- [ ] `GetShopProductsUseCase`

**Done when:** Tester passes all ProductRepository tests

---

### Task 3.2 — Shop Detail & Products Screen
- [ ] `ShopDetailScreen` at route `/customer/shop/:shopId`
- [ ] Shows shop header (image, name, rating, open/closed badge)
- [ ] Lists products in a grid with image, name, price
- [ ] `ProductCard` widget in `widgets/shop/product_card.dart`
- [ ] "Add to Cart" button on each product

**Done when:** Customer can view shop and browse products

---

### Task 3.3 — Cart Feature
- [ ] `CartNotifier` → `StateNotifier` managing cart state
- [ ] `cartProvider` → `StateNotifierProvider<CartNotifier, CartState>`
- [ ] `CartState` contains: `List<CartItem>`, `double total`, `String? shopId`
- [ ] Only products from ONE shop at a time (show warning if mixing shops)
- [ ] `addItem(product)`, `removeItem(productId)`, `clearCart()` methods
- [ ] `CartScreen` showing items, quantities, total
- [ ] Increment/decrement quantity controls
- [ ] "Place Order" button → navigates to `CheckoutScreen`

**Done when:** Customer can add products and manage cart without errors

---

### Task 3.4 — Order Model & Repository
- [ ] `OrderEntity` + `OrderModel`
- [ ] `OrderStatus` enum (pending, confirmed, preparing, outForDelivery, delivered, cancelled)
- [ ] `IOrderDatasource` + `FirestoreOrderDatasource`
- [ ] `placeOrder(OrderModel)` → `Future<String>` (returns orderId)
- [ ] `watchOrder(orderId)` → `Stream<OrderModel>` ← CRITICAL for tracking
- [ ] `getCustomerOrders(customerId)` → `Future<List<OrderModel>>`
- [ ] `getShopOrders(shopId)` → `Stream<List<OrderModel>>`
- [ ] `updateOrderStatus(orderId, OrderStatus)` → `Future<void>`
- [ ] `IOrderRepository` + `OrderRepository`
- [ ] `PlaceOrderUseCase`, `TrackOrderUseCase`, `UpdateOrderStatusUseCase`

**Done when:** Tester passes all OrderRepository tests including stream tests

---

### Task 3.5 — Checkout & Order History
- [ ] `CheckoutScreen` — shows delivery address, order summary, total
- [ ] Uses customer's current GPS as delivery location
- [ ] "Confirm Order" button → calls `PlaceOrderUseCase`
- [ ] On success → navigate to `OrderTrackingScreen`
- [ ] `OrderHistoryScreen` — lists all customer orders
- [ ] `OrderCard` widget showing status badge, shop name, total, date

**Done when:** Customer can place an order end-to-end

---

## PHASE 4 — REAL-TIME TRACKING & NOTIFICATIONS
**Estimated: Week 4**

### Task 4.1 — Order Tracking Screen
- [ ] `OrderTrackingScreen` at `/customer/track/:orderId`
- [ ] `trackingProvider(orderId)` → `StreamProvider<OrderEntity>`
- [ ] Progress stepper showing all status stages
- [ ] Current status highlighted
- [ ] Estimated delivery info
- [ ] Auto-updates when shop owner changes status

**Done when:** Status changes in Firestore appear on screen within 2 seconds

---

### Task 4.2 — Shop Owner Order Management
- [ ] `OwnerOrdersScreen` — live list of incoming orders
- [ ] `ownerOrdersProvider(shopId)` → `StreamProvider<List<OrderEntity>>`
- [ ] New order appears automatically (no refresh needed)
- [ ] Each order card shows customer name, items, total, status
- [ ] Status update buttons: Confirm → Preparing → Out for Delivery → Delivered
- [ ] Cancel button (only on pending/confirmed)
- [ ] Prevent invalid status transitions

**Done when:** Shop owner can manage orders in real-time

---

### Task 4.3 — FCM Push Notifications
- [ ] `NotificationDatasource` — handles FCM token + foreground messages
- [ ] Save FCM token to `users/{uid}.fcmToken` on every login
- [ ] Handle foreground notification → show `SnackBar`
- [ ] Handle background notification → navigate to relevant screen on tap
- [ ] Notification types: `order_update`, `new_order`, `shop_approved`
- [ ] `NotificationRepository` + provider

**Done when:** Customer receives push notification when order status changes

---

## PHASE 5 — ADMIN WEB PANEL
**Estimated: Week 5**

### Task 5.1 — Admin Dashboard
- [ ] `AdminDashboardScreen` — stats cards (total users, shops, orders today)
- [ ] Recent activity feed
- [ ] Responsive layout (works on desktop browser)

### Task 5.2 — Shop Approval
- [ ] `ManageShopsScreen` — lists shops with `isApproved: false`
- [ ] Approve button → sets `isApproved: true` in Firestore
- [ ] Reject button → deletes shop document or sets `isRejected: true`
- [ ] Approved shops list (with deactivate option)

### Task 5.3 — User Management
- [ ] `ManageUsersScreen` — searchable list of all users
- [ ] Deactivate/reactivate user (sets `isActive: false`)

### Task 5.4 — Reports
- [ ] Simple summary: total orders per day (last 7 days)
- [ ] Top shops by order count
- [ ] Display as simple data table (charts in Phase 6)

**Done when:** Admin can approve shops and the shop appears on the customer map

---

## PHASE 6 — POLISH & PERFORMANCE
**Estimated: Week 6**

- [ ] Loading skeleton screens (`shimmer` package) for shop list + products
- [ ] Offline detection banner using `connectivity_plus`
- [ ] Pull-to-refresh on all list screens
- [ ] Error screens with retry buttons
- [ ] Empty state illustrations
- [ ] App icon + splash screen
- [ ] Camera integration — product image upload from gallery/camera
- [ ] Profile picture upload
- [ ] Store ratings + reviews
- [ ] `flutter analyze` — zero warnings
- [ ] Final test coverage check — all minimums met
- [ ] Build release APK: `flutter build apk --release`

---

## 📋 TASK STATUS LEGEND

```
- [ ] Not started
- [~] In progress
- [x] Complete — tests passing
- [!] Blocked — needs discussion
```

---

## ⚠️ DEPENDENCY MAP — DO NOT SKIP STEPS

```
1.1 → 1.2 → 1.3 → 1.4 → 1.5 → 1.6   (auth must be fully done first)
                                  ↓
                              2.1 → 2.2 → 2.3 → 2.4 → 2.5
                                                        ↓
                                              3.1 → 3.2 → 3.3 → 3.4 → 3.5
                                                                        ↓
                                                              4.1 → 4.2 → 4.3
                                                                            ↓
                                                                    5.1 → 5.2 → 5.3 → 5.4
                                                                                          ↓
                                                                                         6.*
```
