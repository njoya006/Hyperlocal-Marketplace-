# DATA_MODELS.md — HyperLocal Market Dart Model Definitions

> This file contains the EXACT Dart class structure for every model and entity.
> GitHub Copilot must use these definitions as the source of truth.
> Do NOT deviate from these structures — the testing developer writes tests
> against these exact fields and method signatures.

---

## 📌 IMPORTANT RULES

- **Entities** live in `lib/domain/entities/` — pure Dart, no Firebase imports
- **Models** live in `lib/data/models/` — handle Firestore serialization
- Every model has `fromFirestore()`, `toFirestore()`, and `fromEntity()`
- Every entity uses `Equatable` for value equality
- All fields use `final` — models are immutable
- Nullable fields are explicitly marked with `?`

---

## 1. USER

### `lib/domain/entities/user_entity.dart`
```dart
import 'package:equatable/equatable.dart';

enum UserRole { customer, shopOwner, admin }

class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.phone,
    this.photoUrl,
    this.fcmToken,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final String? phone;
  final String? photoUrl;
  final String? fcmToken;

  bool get isCustomer => role == UserRole.customer;
  bool get isShopOwner => role == UserRole.shopOwner;
  bool get isAdmin => role == UserRole.admin;

  UserEntity copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? fcmToken,
    bool? isActive,
  }) {
    return UserEntity(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  List<Object?> get props => [uid, email, name, role, isActive, createdAt];
}
```

### `lib/data/models/user_model.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.phone,
    this.photoUrl,
    this.fcmToken,
  });

  final String uid;
  final String email;
  final String name;
  final String role;        // stored as string in Firestore
  final bool isActive;
  final DateTime createdAt;
  final String? phone;
  final String? photoUrl;
  final String? fcmToken;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String,
      name: data['name'] as String,
      role: data['role'] as String,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      name: entity.name,
      role: _roleToString(entity.role),
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      phone: entity.phone,
      photoUrl: entity.photoUrl,
      fcmToken: entity.fcmToken,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      name: name,
      role: _roleFromString(role),
      isActive: isActive,
      createdAt: createdAt,
      phone: phone,
      photoUrl: photoUrl,
      fcmToken: fcmToken,
    );
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.customer:   return 'customer';
      case UserRole.shopOwner:  return 'shop_owner';
      case UserRole.admin:      return 'admin';
    }
  }

  static UserRole _roleFromString(String role) {
    switch (role) {
      case 'shop_owner': return UserRole.shopOwner;
      case 'admin':      return UserRole.admin;
      default:           return UserRole.customer;
    }
  }
}
```

---

## 2. SHOP

### `lib/domain/entities/shop_entity.dart`
```dart
import 'dart:math';
import 'package:equatable/equatable.dart';

enum ShopCategory { grocery, pharmacy, electronics, food, other }

class ShopEntity extends Equatable {
  const ShopEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.isOpen,
    required this.isApproved,
    required this.rating,
    required this.totalReviews,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final ShopCategory category;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final bool isOpen;
  final bool isApproved;
  final double rating;
  final int totalReviews;
  final DateTime createdAt;
  final String? imageUrl;

  /// Returns distance in kilometres from the given coordinates
  double distanceTo(double lat, double lng) {
    const double earthRadiusKm = 6371;
    final dLat = _toRadians(lat - latitude);
    final dLng = _toRadians(lng - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  @override
  List<Object?> get props => [id, ownerId, name, isOpen, isApproved, rating];
}
```

### `lib/data/models/shop_model.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/shop_entity.dart';

class ShopModel {
  const ShopModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.isOpen,
    required this.isApproved,
    required this.rating,
    required this.totalReviews,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final bool isOpen;
  final bool isApproved;
  final double rating;
  final int totalReviews;
  final DateTime createdAt;
  final String? imageUrl;

  factory ShopModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ShopModel(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      address: data['address'] as String,
      phone: data['phone'] as String,
      isOpen: data['isOpen'] as bool? ?? false,
      isApproved: data['isApproved'] as bool? ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phone': phone,
      'isOpen': isOpen,
      'isApproved': isApproved,
      'rating': rating,
      'totalReviews': totalReviews,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  ShopEntity toEntity() {
    return ShopEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      category: _categoryFromString(category),
      latitude: latitude,
      longitude: longitude,
      address: address,
      phone: phone,
      isOpen: isOpen,
      isApproved: isApproved,
      rating: rating,
      totalReviews: totalReviews,
      createdAt: createdAt,
      imageUrl: imageUrl,
    );
  }

  static ShopCategory _categoryFromString(String cat) {
    switch (cat) {
      case 'grocery':     return ShopCategory.grocery;
      case 'pharmacy':    return ShopCategory.pharmacy;
      case 'electronics': return ShopCategory.electronics;
      case 'food':        return ShopCategory.food;
      default:            return ShopCategory.other;
    }
  }
}
```

---

## 3. PRODUCT

### `lib/domain/entities/product_entity.dart`
```dart
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.inStock,
    required this.stockCount,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String shopId;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool inStock;
  final int stockCount;
  final DateTime createdAt;
  final String? imageUrl;

  bool get isAvailable => inStock && stockCount > 0;

  @override
  List<Object?> get props => [id, shopId, name, price, inStock];
}
```

### `lib/data/models/product_model.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.inStock,
    required this.stockCount,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String shopId;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool inStock;
  final int stockCount;
  final DateTime createdAt;
  final String? imageUrl;

  factory ProductModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ProductModel(
      id: doc.id,
      shopId: data['shopId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      category: data['category'] as String,
      inStock: data['inStock'] as bool? ?? true,
      stockCount: data['stockCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopId': shopId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'inStock': inStock,
      'stockCount': stockCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      shopId: shopId,
      name: name,
      description: description,
      price: price,
      category: category,
      inStock: inStock,
      stockCount: stockCount,
      createdAt: createdAt,
      imageUrl: imageUrl,
    );
  }
}
```

---

## 4. ORDER

### `lib/domain/entities/order_entity.dart`
```dart
import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  double get subtotal => price * quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.customerId,
    required this.shopId,
    required this.shopOwnerId,
    required this.customerName,
    required this.shopName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.customerLat,
    required this.customerLng,
    required this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final String id;
  final String customerId;
  final String shopId;
  final String shopOwnerId;
  final String customerName;
  final String shopName;
  final List<CartItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String paymentMethod;
  final double customerLat;
  final double customerLng;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  bool get isActive =>
      status != OrderStatus.delivered && status != OrderStatus.cancelled;

  @override
  List<Object?> get props => [id, customerId, shopId, status, totalAmount];
}
```

### `lib/data/models/order_model.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_entity.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.customerId,
    required this.shopId,
    required this.shopOwnerId,
    required this.customerName,
    required this.shopName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.customerLat,
    required this.customerLng,
    required this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final String id;
  final String customerId;
  final String shopId;
  final String shopOwnerId;
  final String customerName;
  final String shopName;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final double customerLat;
  final double customerLng;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] as String,
      shopId: data['shopId'] as String,
      shopOwnerId: data['shopOwnerId'] as String,
      customerName: data['customerName'] as String,
      shopName: data['shopName'] as String,
      items: List<Map<String, dynamic>>.from(data['items'] as List),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      status: data['status'] as String,
      paymentMethod: data['paymentMethod'] as String,
      customerLat: (data['customerLat'] as num).toDouble(),
      customerLng: (data['customerLng'] as num).toDouble(),
      deliveryAddress: data['deliveryAddress'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'shopId': shopId,
      'shopOwnerId': shopOwnerId,
      'customerName': customerName,
      'shopName': shopName,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'deliveryAddress': deliveryAddress,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (notes != null) 'notes': notes,
    };
  }

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      customerId: customerId,
      shopId: shopId,
      shopOwnerId: shopOwnerId,
      customerName: customerName,
      shopName: shopName,
      items: items.map((item) => CartItem(
        productId: item['productId'] as String,
        name: item['name'] as String,
        price: (item['price'] as num).toDouble(),
        quantity: item['quantity'] as int,
        imageUrl: item['imageUrl'] as String?,
      )).toList(),
      totalAmount: totalAmount,
      status: _statusFromString(status),
      paymentMethod: paymentMethod,
      customerLat: customerLat,
      customerLng: customerLng,
      deliveryAddress: deliveryAddress,
      createdAt: createdAt,
      updatedAt: updatedAt,
      notes: notes,
    );
  }

  static OrderStatus _statusFromString(String status) {
    switch (status) {
      case 'confirmed':       return OrderStatus.confirmed;
      case 'preparing':       return OrderStatus.preparing;
      case 'outForDelivery':  return OrderStatus.outForDelivery;
      case 'delivered':       return OrderStatus.delivered;
      case 'cancelled':       return OrderStatus.cancelled;
      default:                return OrderStatus.pending;
    }
  }

  static String statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:        return 'pending';
      case OrderStatus.confirmed:      return 'confirmed';
      case OrderStatus.preparing:      return 'preparing';
      case OrderStatus.outForDelivery: return 'outForDelivery';
      case OrderStatus.delivered:      return 'delivered';
      case OrderStatus.cancelled:      return 'cancelled';
    }
  }
}
```

---

## 5. CART STATE (Riverpod — not stored in Firestore)

### `lib/presentation/providers/cart_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/product_entity.dart';

class CartState {
  const CartState({
    this.items = const [],
    this.shopId,
    this.shopName,
  });

  final List<CartItem> items;
  final String? shopId;     // Only one shop per cart
  final String? shopName;

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    String? shopId,
    String? shopName,
  }) {
    return CartState(
      items: items ?? this.items,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Adds a product. Returns false if product is from a different shop.
  bool addItem({
    required ProductEntity product,
    required String shopId,
    required String shopName,
  }) {
    // Block mixing shops
    if (state.shopId != null && state.shopId != shopId) {
      return false;
    }

    final existingIndex =
        state.items.indexWhere((i) => i.productId == product.id);

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = List.from(state.items);
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = CartItem(
        productId: existing.productId,
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity + 1,
        imageUrl: existing.imageUrl,
      );
    } else {
      updatedItems = [
        ...state.items,
        CartItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
          imageUrl: product.imageUrl,
        ),
      ];
    }

    state = state.copyWith(
      items: updatedItems,
      shopId: shopId,
      shopName: shopName,
    );
    return true;
  }

  void removeItem(String productId) {
    final updatedItems =
        state.items.where((i) => i.productId != productId).toList();
    state = updatedItems.isEmpty
        ? const CartState()
        : state.copyWith(items: updatedItems);
  }

  void decrementItem(String productId) {
    final index = state.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;
    if (state.items[index].quantity == 1) {
      removeItem(productId);
      return;
    }
    final updatedItems = List<CartItem>.from(state.items);
    final item = updatedItems[index];
    updatedItems[index] = CartItem(
      productId: item.productId,
      name: item.name,
      price: item.price,
      quantity: item.quantity - 1,
      imageUrl: item.imageUrl,
    );
    state = state.copyWith(items: updatedItems);
  }

  void clearCart() => state = const CartState();
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);
```
