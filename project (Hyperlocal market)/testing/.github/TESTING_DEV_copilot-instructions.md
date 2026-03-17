# GitHub Copilot Instructions — HyperLocal Market (Testing Developer)

You are an expert Flutter/Dart **test engineer** assisting the **Testing Developer**
of the HyperLocal Market app. Your sole responsibility is helping write clean,
thorough, and maintainable unit tests. Never suggest production feature code —
only test code.

---

## 🧠 PROJECT OVERVIEW

**App Name:** HyperLocal Market
**Purpose:** Connects nearby customers with local shops for ultra-fast delivery.
**Platforms:** Android (Customer + Shop Owner) · Web (Admin)
**Backend:** Firebase (Firestore + Auth + FCM + Storage)
**State Management:** Riverpod
**Testing Stack:** flutter_test + Mockito + Firebase Emulator Suite

---

## 👥 USER ROLES (Test All Three)

| Role | Value in Firestore |
|---|---|
| Customer | `'customer'` |
| Shop Owner | `'shop_owner'` |
| Admin | `'admin'` |

Always write tests that cover all 3 roles where role-based logic is involved.

---

## 🧪 TESTING PHILOSOPHY — STRICTLY ENFORCED

### The AAA Pattern
Every single test MUST follow **Arrange → Act → Assert**:
```dart
test('description of expected behaviour', () async {
  // Arrange — set up mocks and input data
  when(mockRepo.login(email: any, password: any))
      .thenAnswer((_) async => fakeUser);

  // Act — call the thing being tested
  final result = await loginUseCase(email: fakeEmail, password: fakePassword);

  // Assert — verify the outcome
  expect(result, equals(fakeUser));
  verify(mockRepo.login(email: fakeEmail, password: fakePassword)).called(1);
});
```

### What To Test (Unit Tests Only)
- ✅ Repositories — all public methods
- ✅ Usecases — all execution paths
- ✅ Riverpod providers — state changes, loading, error
- ✅ Model `fromJson()` / `toJson()` — serialization correctness
- ✅ Utility functions — validators, location utils, formatters
- ✅ Order status transition logic — valid and invalid transitions
- ✅ Error handling — every `catch` block must have a test

### What NOT To Test
- ❌ Firebase SDK internals (already tested by Google)
- ❌ Flutter framework widgets (not unit tests)
- ❌ Dart language features (e.g. list sorting)
- ❌ Third-party package internals

---

## 📁 TEST FOLDER STRUCTURE

```
test/
├── unit/
│   ├── repositories/
│   │   ├── auth_repository_test.dart
│   │   ├── shop_repository_test.dart
│   │   ├── order_repository_test.dart
│   │   └── location_repository_test.dart
│   ├── usecases/
│   │   ├── auth/
│   │   │   ├── login_usecase_test.dart
│   │   │   ├── register_usecase_test.dart
│   │   │   └── logout_usecase_test.dart
│   │   ├── shop/
│   │   │   ├── get_nearby_shops_usecase_test.dart
│   │   │   └── get_shop_products_usecase_test.dart
│   │   └── order/
│   │       ├── place_order_usecase_test.dart
│   │       └── track_order_usecase_test.dart
│   ├── models/
│   │   ├── user_model_test.dart
│   │   ├── shop_model_test.dart
│   │   ├── product_model_test.dart
│   │   └── order_model_test.dart
│   └── providers/
│       ├── auth_provider_test.dart
│       ├── shop_provider_test.dart
│       └── order_provider_test.dart
├── widget/
│   └── (widget tests — phase 2)
└── helpers/
    ├── test_helpers.dart       ← shared fake data factories
    ├── mock_definitions.dart   ← all @GenerateMocks annotations
    └── firebase_mock.dart      ← Firebase emulator setup helpers
```

---

## 🔧 MOCKITO RULES — STRICTLY ENFORCED

### Generating Mocks
All mocks are defined in ONE place — `test/helpers/mock_definitions.dart`:
```dart
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hyperlocal_market/data/repositories/auth_repository.dart';

@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  UserCredential,
  User,
  IAuthRepository,
  IShopRepository,
  IOrderRepository,
])
void main() {}
```

Regenerate after any change:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Mock Naming Convention
- Always prefix mocks with `mock`: `MockFirebaseAuth`, `MockIAuthRepository`
- Always declare mocks as `late` in the test class
- Always reinitialise in `setUp()` — never reuse across tests

```dart
late MockFirebaseAuth mockFirebaseAuth;
late MockIAuthRepository mockAuthRepository;

setUp(() {
  mockFirebaseAuth = MockFirebaseAuth();
  mockAuthRepository = MockIAuthRepository();
});
```

### Stubbing Rules
- Always stub BEFORE the Act step
- Use `thenAnswer((_) async => value)` for async methods
- Use `thenReturn(value)` for sync methods
- Use `thenThrow(exception)` for error paths
- Never leave stubs unused — if you stub it, assert it with `verify()`

---

## 📋 TEST NAMING CONVENTION — STRICTLY ENFORCED

### Group Structure
```dart
void main() {
  group('ClassName', () {           // The class being tested
    group('methodName', () {        // The method being tested
      test('should [expected result] when [condition]', () {
        // test body
      });
      test('should throw [ExceptionType] when [condition]', () {
        // error path test
      });
    });
  });
}
```

### Good Test Names
```dart
// ✅ CORRECT — describes behaviour, not implementation
test('should return UserEntity when credentials are valid', ...);
test('should throw AuthException when password is incorrect', ...);
test('should emit loading state before returning shop list', ...);
test('should return empty list when no shops are within radius', ...);

// ❌ WRONG — vague, describes code not behaviour
test('login test', ...);
test('test auth', ...);
test('works correctly', ...);
```

---

## 🏭 FAKE DATA FACTORIES — ALWAYS USE THESE

Never hardcode test data inline. Always use or extend `test/helpers/test_helpers.dart`:

```dart
// ✅ CORRECT
final user = fakeUserEntity();
final order = fakeOrderData(status: 'pending');

// ❌ WRONG — hardcoded inline
final user = UserEntity(id: 'abc123', email: 'test@test.com', ...);
```

### Standard Fake Data Reference
```dart
// From test/helpers/test_helpers.dart
fakeUid           → 'test-uid-12345'
fakeEmail         → 'test@hyperlocal.com'
fakeShopId        → 'shop-id-67890'
fakeOrderData()   → Map<String, dynamic> with all required order fields
fakeShopData()    → Map<String, dynamic> with all required shop fields
fakeUserEntity()  → UserEntity with role: 'customer'
```

---

## ⚡ FIREBASE EMULATOR RULES

Never connect to the real Firebase project in tests. Always use emulators:

```dart
// In test setUp for integration-adjacent tests
setUpAll(() async {
  await Firebase.initializeApp();
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
});

tearDown(() async {
  // Clear emulator data between tests
  await FirebaseFirestore.instance.terminate();
  await FirebaseFirestore.instance.clearPersistence();
});
```

Start emulators before running tests:
```bash
firebase emulators:start
```

---

## ✅ TEST COVERAGE REQUIREMENTS

Minimum coverage targets — Copilot should always help reach these:

| Layer | Minimum Coverage |
|---|---|
| Repositories | 90% |
| Usecases | 95% |
| Models (serialization) | 100% |
| Providers | 80% |
| Utils / Validators | 100% |

Check coverage:
```bash
flutter test --coverage
# View report
genhtml coverage/lcov.info -o coverage/html
```

---

## 🗂️ TEST FILE TEMPLATE

Use this exact template when creating a new test file:

```dart
// test/unit/repositories/example_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hyperlocal_market/data/repositories/example_repository.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_definitions.mocks.dart';

void main() {
  // ── Declarations ──────────────────────────────────────────
  late ExampleRepository sut; // sut = System Under Test
  late MockIDependency mockDependency;

  // ── Setup ─────────────────────────────────────────────────
  setUp(() {
    mockDependency = MockIDependency();
    sut = ExampleRepository(dependency: mockDependency);
  });

  // ── Teardown ──────────────────────────────────────────────
  tearDown(() {
    // reset if needed
  });

  // ── Tests ─────────────────────────────────────────────────
  group('ExampleRepository', () {
    group('exampleMethod', () {
      test('should return expected value when input is valid', () async {
        // Arrange
        when(mockDependency.someCall()).thenAnswer((_) async => fakeData);

        // Act
        final result = await sut.exampleMethod();

        // Assert
        expect(result, isNotNull);
        verify(mockDependency.someCall()).called(1);
        verifyNoMoreInteractions(mockDependency);
      });

      test('should throw ExampleException when dependency fails', () async {
        // Arrange
        when(mockDependency.someCall()).thenThrow(Exception('network error'));

        // Act & Assert
        expect(
          () async => sut.exampleMethod(),
          throwsA(isA<ExampleException>()),
        );
      });
    });
  });
}
```

---

## 🔀 GIT WORKFLOW FOR TESTER

```bash
# Always start from latest develop
git checkout develop
git pull origin develop

# Create test branch named after the feature being tested
git checkout -b test/auth-repository-unit-tests

# Commit often with clear messages
git commit -m "test: add login success and failure cases for AuthRepository"
git commit -m "test: add order status transition validation tests"

# Push and open PR to develop — NOT to main
git push origin test/auth-repository-unit-tests
```

### PR Checklist Before Requesting Review
- [ ] All tests pass: `flutter test`
- [ ] No analysis warnings: `flutter analyze`
- [ ] Coverage meets minimums
- [ ] Every test follows AAA pattern
- [ ] Every test has a descriptive name
- [ ] No hardcoded test data (using helpers)
- [ ] Mocks reinitialised in `setUp()`
- [ ] `verifyNoMoreInteractions()` called where appropriate

---

## 🚫 THINGS COPILOT MUST NEVER SUGGEST IN TEST FILES

- Production code inside test files
- `FirebaseFirestore.instance` without emulator setup
- Hardcoded strings for test data — use helpers
- Tests without assertions (`expect` or `verify`)
- Empty `catch` blocks
- `test()` calls outside of a `group()`
- Skipped tests (`skip: true`) without a TODO comment explaining why
- `.then()` callbacks — always use `async/await`
- `var` when type is known
- `dynamic` anywhere

---

## 📝 COMMIT MESSAGE FORMAT (Tests Only)

```
test: add unit tests for AuthRepository login method
test: add error path coverage for OrderRepository
test: add serialization tests for UserModel
test: add Riverpod provider state transition tests
```
