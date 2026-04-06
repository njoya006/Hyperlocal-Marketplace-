# GitHub Copilot Instructions — HyperLocal Market (Lead Developer)

You are an expert Flutter/Dart developer assisting the **Lead Developer** of the
HyperLocal Market app. Read and follow every rule in this file before making
any suggestion, completion, or edit.

---

## 🧠 PROJECT OVERVIEW

**App Name:** HyperLocal Market
**Purpose:** Connects nearby customers with local shops for ultra-fast delivery.
**Platforms:** Android (Customer + Shop Owner) · Web (Admin panel only)
**Backend:** Firebase (Firestore + Auth + FCM + Storage)
**Maps:** Mapbox (free tier)
**Real-time:** Firestore streams
**Notifications:** Firebase Cloud Messaging (FCM)
**Payment:** Cash on delivery only (Phase 1)

---

## 👥 USER ROLES

| Role | Platform | Responsibilities |
|---|---|---|
| `customer` | Android | Browse shops, place orders, track deliveries |
| `shop_owner` | Android | Manage products, receive & update orders |
| `admin` | Web only | Approve shops, monitor users, generate reports |

Every Firestore document that belongs to a user MUST include a `role` field.
Always check `role` before granting access to any screen or data operation.

---

## 🏗️ ARCHITECTURE — STRICT LAYERED ARCHITECTURE

This project follows a **strict 3-layer architecture**. Never mix layers.

```
Presentation Layer  →  providers/ + screens/ + widgets/
Domain Layer        →  entities/ + usecases/
Data Layer          →  models/ + repositories/ + datasources/
```

### Rules:
- `screens/` MUST only call **providers** — never repositories directly
- `providers/` MUST only call **usecases** — never datasources directly
- `usecases/` MUST only call **repositories** — never Firestore directly
- `repositories/` MUST only call **datasources** — never Firebase SDK directly
- `datasources/` is the ONLY layer allowed to import Firebase packages
- `models/` handle JSON serialization — entities do NOT
- `entities/` are pure Dart classes with NO external dependencies

---

## 📁 FOLDER STRUCTURE

```
lib/
├── core/
│   ├── constants/        → app_colors.dart, app_strings.dart, app_sizes.dart
│   ├── errors/           → exceptions.dart, failures.dart
│   ├── network/          → network_info.dart
│   └── utils/            → location_utils.dart, validators.dart
├── data/
│   ├── models/           → *_model.dart (JSON serializable)
│   ├── repositories/     → *_repository.dart (implements domain interfaces)
│   └── datasources/      → *_datasource.dart (Firebase SDK calls only here)
├── domain/
│   ├── entities/         → *_entity.dart (pure Dart, no external deps)
│   └── usecases/         → *_usecase.dart (single responsibility)
├── presentation/
│   ├── providers/        → *_provider.dart (Riverpod)
│   ├── screens/          → organised by role: auth/ customer/ shop_owner/ admin/
│   ├── widgets/          → common/ shop/ map/
│   └── router/           → app_router.dart (go_router)
└── config/
    └── app_config.dart
```

---

## 🎯 CODING STANDARDS — STRICTLY ENFORCED

### Dart Style
- Always use `final` over `var` wherever possible
- Always use `const` constructors wherever possible
- Never use `dynamic` — always declare explicit types
- Always use named parameters for functions with 2+ parameters
- Always add trailing commas to multi-line parameter lists
- Maximum line length: **100 characters**
- Always use `///` doc comments on every public class and method
- Never use `print()` — use `debugPrint()` in debug mode only

### Naming Conventions
```dart
// Classes → PascalCase
class AuthRepository {}
class UserModel {}
class LoginScreen {}

// Variables & methods → camelCase
final String userId;
Future<void> placeOrder() async {}

// Constants → camelCase with const
const String appName = 'HyperLocal Market';

// Files → snake_case
auth_repository.dart
user_model.dart
login_screen.dart

// Riverpod providers → camelCase + Provider suffix
final authStateProvider = StreamProvider<User?>(...);
final nearbyShopsProvider = FutureProvider<List<ShopEntity>>(...);
```

### Widget Rules
- Every screen is a `ConsumerWidget` or `ConsumerStatefulWidget` — NEVER a plain `StatelessWidget`
- Extract any widget more than 3 levels deep into its own file in `widgets/`
- Never put business logic inside a widget's `build()` method
- Always use `key` parameter on list item widgets

### Async Rules
- Always use `async/await` — never `.then()` chains
- Always wrap Firebase calls in `try/catch`
- Always handle loading, error, and data states in every provider

---

## 🔥 FIREBASE RULES

### Firestore Collections
```
/users/{userId}
/shops/{shopId}
/shops/{shopId}/products/{productId}
/orders/{orderId}
/notifications/{notificationId}
```

### Firestore Coding Rules
- Always use `withConverter()` when reading/writing Firestore documents
- Always check `snapshot.exists` before accessing document data
- Always use Firestore streams (`.snapshots()`) for real-time data — never `.get()` for live data
- Never store sensitive user data (passwords, payment info) in Firestore
- Always include `createdAt` and `updatedAt` timestamps on every document write
- Use `FieldValue.serverTimestamp()` — NEVER `DateTime.now()` for timestamps

### Auth Rules
- Always check `FirebaseAuth.instance.currentUser` before any Firestore write
- Always save FCM token to Firestore on every successful login
- Always clear local state on logout

---

## 🗺️ MAPBOX RULES

- Never hardcode the Mapbox token in Dart files — read from config only
- Always dispose map controllers in `dispose()`
- Use `GeoJsonSource` for displaying multiple shop markers
- Camera animation duration: 500ms for user-initiated moves, 1000ms for auto-moves

---

## 📦 RIVERPOD RULES

- Use `@riverpod` annotation (riverpod_generator) for all new providers
- Use `AsyncNotifier` for providers that perform async operations with state
- Use `StreamProvider` for Firestore real-time streams
- Use `FutureProvider` for one-time async reads
- Always use `ref.watch()` in build methods — never `ref.read()` in build
- Use `ref.read()` ONLY inside callbacks and event handlers
- Always handle `.when(data:, loading:, error:)` on every async provider

---

## 🧪 TESTING AWARENESS

The testing developer writes unit tests for every repository and usecase you create.
To make their job easier, you MUST:

- Always inject dependencies via constructor — NEVER use singletons inside classes
- Always program to interfaces (abstract classes) — not concrete implementations
- Every repository class MUST have a corresponding abstract class it implements
- Never call `FirebaseFirestore.instance` directly inside a repository — inject it

### Example of correct injectable pattern:
```dart
// ✅ CORRECT — injectable, testable
abstract class IAuthRepository {
  Future<UserEntity> login({required String email, required String password});
}

class AuthRepository implements IAuthRepository {
  const AuthRepository({required FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  final FirebaseAuth _firebaseAuth;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return UserEntity.fromCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    }
  }
}

// ❌ WRONG — impossible to unit test
class AuthRepository {
  Future<void> login(String email, String password) async {
    await FirebaseFirestore.instance.collection('users').get(); // BAD
  }
}
```

---

## 🚦 ORDER STATUS FLOW

Always use this exact enum — never raw strings for order status:
```dart
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}
```

Valid transitions only:
```
pending → confirmed → preparing → outForDelivery → delivered
pending → cancelled
confirmed → cancelled
```

---

## 🚫 THINGS COPILOT MUST NEVER SUGGEST

- `var` when the type is known
- `dynamic` anywhere
- `FirebaseFirestore.instance` outside of datasource files
- `FirebaseAuth.instance` outside of datasource files
- `print()` statements
- Hardcoded strings — use `AppStrings` constants
- Hardcoded colors — use `AppColors` constants
- Hardcoded numbers — use `AppSizes` constants
- `.then()` callbacks — use `async/await`
- Pushing directly to `main` branch
- Committing `google-services.json` or `firebase_options.dart`

---

## ✅ BEFORE EVERY COMMIT CHECKLIST

Run these commands — zero errors allowed before pushing:
```bash
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

---

## 📝 COMMIT MESSAGE FORMAT

```
feat:     New feature
fix:      Bug fix
refactor: Code restructure (no behavior change)
chore:    Config/setup changes
docs:     Documentation only
style:    Formatting only
```

Example: `feat: add Mapbox nearby shops map with GPS clustering`
