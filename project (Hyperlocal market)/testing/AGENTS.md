# AGENTS.md — HyperLocal Market Architecture Bible

> This file is the single source of truth for AI agents, GitHub Copilot,
> and all developers. Every architectural decision is documented here.
> Read this file completely before writing any code.

---

## 🎯 WHAT THIS APP DOES

HyperLocal Market connects customers with local shops in their GPS radius
for ultra-fast cash-on-delivery orders. Think of it as a hyper-local
version of a delivery app — but built for small businesses.

**Core user journey:**
1. Customer opens app → GPS detects location
2. Nearby shops appear on a Mapbox map within defined radius
3. Customer browses products from a selected shop
4. Customer adds to cart → places order (cash on delivery)
5. Shop owner receives notification → confirms → prepares order
6. Order status updates in real-time via Firestore streams
7. Customer tracks order status live
8. Admin monitors everything via web dashboard

---

## 🏗️ ARCHITECTURE DECISION — WHY LAYERED ARCHITECTURE

We use a strict **3-layer clean architecture** because:
- The testing developer needs to unit test each layer in isolation
- Firebase can be swapped out in future without touching UI code
- Riverpod providers stay thin and focused
- Every class has one reason to change (Single Responsibility)

```
┌─────────────────────────────────────────────────┐
│           PRESENTATION LAYER                    │
│   screens/ + widgets/ + providers/ + router/    │
│   → Riverpod ConsumerWidgets only               │
│   → No Firebase imports allowed here            │
└──────────────────┬──────────────────────────────┘
                   │ calls
┌──────────────────▼──────────────────────────────┐
│              DOMAIN LAYER                       │
│         entities/ + usecases/                   │
│   → Pure Dart — zero external dependencies      │
│   → Defines abstract repository interfaces      │
└──────────────────┬──────────────────────────────┘
                   │ implements
┌──────────────────▼──────────────────────────────┐
│               DATA LAYER                        │
│      models/ + repositories/ + datasources/     │
│   → Firebase SDK lives ONLY in datasources/     │
│   → models/ handle JSON ↔ Dart conversion       │
└─────────────────────────────────────────────────┘
```

---

## 🔥 FIREBASE SERVICES IN USE

| Service | Purpose | Used In |
|---|---|---|
| Firebase Auth | User login, register, session | `auth_datasource.dart` |
| Firestore | All app data, real-time streams | `firestore_datasource.dart` |
| Firebase Storage | Product images, profile pics | `storage_datasource.dart` |
| FCM | Push notifications | `notification_datasource.dart` |

---

## 📊 FIRESTORE SCHEMA — EXACT STRUCTURE

### `/users/{userId}`
```
uid:         String   — Firebase Auth UID (document ID = uid)
email:       String
name:        String
role:        String   — 'customer' | 'shop_owner' | 'admin'
phone:       String
fcmToken:    String   — updated every login
photoUrl:    String?  — nullable
isActive:    Boolean  — admin can deactivate users
createdAt:   Timestamp
updatedAt:   Timestamp
```

### `/shops/{shopId}`
```
id:          String   — Firestore auto-generated ID
ownerId:     String   — ref to /users/{userId}
name:        String
description: String
category:    String   — 'grocery' | 'pharmacy' | 'electronics' | 'food' | 'other'
latitude:    Number   — GPS coordinate
longitude:   Number   — GPS coordinate
address:     String
phone:       String
isOpen:      Boolean  — shop owner toggles this
isApproved:  Boolean  — admin must approve before shop is visible
rating:      Number   — 0.0 to 5.0
totalReviews:Number
imageUrl:    String
createdAt:   Timestamp
updatedAt:   Timestamp
```

### `/shops/{shopId}/products/{productId}`
```
id:          String
shopId:      String
name:        String
description: String
price:       Number   — in local currency (XAF for Cameroon)
imageUrl:    String
category:    String
inStock:     Boolean
stockCount:  Number
createdAt:   Timestamp
updatedAt:   Timestamp
```

### `/orders/{orderId}`
```
id:             String
customerId:     String   — ref to /users
shopId:         String   — ref to /shops
shopOwnerId:    String   — denormalised for easy querying
customerName:   String   — denormalised
shopName:       String   — denormalised
items:          Array
  - productId:  String
  - name:       String
  - price:      Number
  - quantity:   Number
  - imageUrl:   String
totalAmount:    Number
status:         String   — see OrderStatus enum below
paymentMethod:  String   — 'cash_on_delivery' (only value in Phase 1)
customerLat:    Number
customerLng:    Number
deliveryAddress:String
notes:          String?  — optional customer notes
createdAt:      Timestamp
updatedAt:      Timestamp
```

### `/notifications/{notificationId}`
```
id:          String
userId:      String   — recipient
title:       String
body:        String
type:        String   — 'order_update' | 'new_order' | 'shop_approved' | 'promotion'
orderId:     String?  — nullable, only for order-related notifications
isRead:      Boolean
createdAt:   Timestamp
```

---

## ⚡ ORDER STATUS FLOW

```
pending ──► confirmed ──► preparing ──► outForDelivery ──► delivered
   │              │
   └──────────────┴──────────────────────────────────────► cancelled
```

Who changes each status:
```
pending        → set by customer when placing order
confirmed      → set by shop_owner
preparing      → set by shop_owner
outForDelivery → set by shop_owner
delivered      → set by shop_owner
cancelled      → set by customer (only from pending) OR shop_owner (from pending/confirmed)
```

---

## 🗺️ MAPBOX IMPLEMENTATION NOTES

- Package: `mapbox_maps_flutter: ^2.3.0`
- Token: loaded from `AppConfig.mapboxToken` — never hardcoded
- Initial camera: set to user's GPS location on app open
- Shop markers: use `GeoJsonSource` with `SymbolLayer` for clustering
- Marker tap: shows bottom sheet with shop summary + "View Shop" button
- Search radius: default 5km, configurable up to 20km

---

## 📡 REAL-TIME TRACKING IMPLEMENTATION

Order tracking uses **Firestore streams**:

```dart
// In order_datasource.dart
Stream<OrderModel> watchOrder(String orderId) {
  return _firestore
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snap) => OrderModel.fromFirestore(snap));
}
```

The stream is exposed through:
```
firestore_datasource → order_repository → track_order_usecase → order_provider → tracking_screen
```

---

## 🔔 FCM NOTIFICATION FLOW

```
1. Shop owner receives new order
   → Cloud Function triggers (future phase)
   → OR: shop_owner app listens to Firestore stream for new orders

2. Customer receives order status update
   → When shop owner changes order status in Firestore
   → FCM notification sent to customer's fcmToken

3. Shop owner receives approval notification from admin
   → Admin approves shop in web dashboard
   → Firestore updates shop.isApproved = true
   → FCM sent to shop owner's fcmToken
```

---

## 🌐 WEB ADMIN PANEL NOTES

The admin panel is Flutter Web targeting these routes:
```
/admin/dashboard     → overview stats (users, shops, orders)
/admin/shops         → approve/reject shop registrations
/admin/users         → view, deactivate users
/admin/orders        → monitor all orders
/admin/reports       → simple activity reports
```

Admin login uses the same Firebase Auth — role check redirects to admin panel.
Non-admin users attempting `/admin/*` routes are redirected to `/`.

---

## 📱 NAVIGATION STRUCTURE (go_router)

```
/ (root)
├── /splash                    → SplashScreen (checks auth state)
├── /login                     → LoginScreen
├── /register                  → RegisterScreen (with role selection)
├── /customer
│   ├── /home                  → CustomerHomeScreen (map + shops)
│   ├── /shop/:shopId          → ShopDetailScreen
│   ├── /cart                  → CartScreen
│   ├── /checkout              → CheckoutScreen
│   ├── /orders                → OrderHistoryScreen
│   ├── /track/:orderId        → OrderTrackingScreen
│   └── /profile               → CustomerProfileScreen
├── /owner
│   ├── /dashboard             → OwnerDashboardScreen
│   ├── /products              → ManageProductsScreen
│   ├── /orders                → OwnerOrdersScreen
│   └── /profile               → OwnerProfileScreen
└── /admin (web only)
    ├── /dashboard             → AdminDashboardScreen
    ├── /shops                 → ManageShopsScreen
    ├── /users                 → ManageUsersScreen
    └── /reports               → ReportsScreen
```

Route guards: every `/customer/*`, `/owner/*`, `/admin/*` route checks
`FirebaseAuth.currentUser` and user role before allowing access.

---

## 🔒 SECURITY MODEL

| Action | Customer | Shop Owner | Admin |
|---|---|---|---|
| Read own profile | ✅ | ✅ | ✅ |
| Read any shop | ✅ | ✅ | ✅ |
| Write shop data | ❌ | Own shop only | ✅ |
| Place order | ✅ | ❌ | ❌ |
| Update order status | ❌ | Own orders only | ✅ |
| Approve shop | ❌ | ❌ | ✅ |
| Deactivate user | ❌ | ❌ | ✅ |
| View all orders | ❌ | ❌ | ✅ |

---

## 🧱 KEY DEPENDENCIES & THEIR PURPOSE

```yaml
firebase_core:         Firebase initialisation
firebase_auth:         User authentication
cloud_firestore:       Database + real-time streams
firebase_messaging:    Push notifications (FCM)
firebase_storage:      Image uploads
flutter_riverpod:      State management
riverpod_annotation:   Code generation for providers
mapbox_maps_flutter:   Maps + GPS visualisation
geolocator:            Get device GPS coordinates
geocoding:             Convert coordinates to addresses
go_router:             Navigation + deep links + web routes
dio:                   HTTP client (for any REST calls)
equatable:             Value equality for entities
freezed_annotation:    Immutable data classes
json_annotation:       JSON serialisation
uuid:                  Generate unique IDs client-side
intl:                  Date/number formatting
shared_preferences:    Local key-value storage
cached_network_image:  Efficient image loading + caching
shimmer:               Loading skeleton animations
connectivity_plus:     Check internet connection
mockito:               (dev) Mock generation for tests
build_runner:          (dev) Code generation runner
```
