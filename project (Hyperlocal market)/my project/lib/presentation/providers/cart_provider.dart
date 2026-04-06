import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/product_entity.dart';

/// Result of a cart update request.
enum CartActionResult {
  added,
  differentShop,
  unavailable,
  outOfStock,
}

/// Immutable shopping cart state.
class CartState extends Equatable {
  /// Creates a [CartState].
  const CartState({
    required this.items,
    required this.total,
    required this.shopId,
  });

  /// Empty cart state.
  factory CartState.empty() => const CartState(
        items: <CartItemEntity>[],
        total: 0,
        shopId: null,
      );

  /// Cart items.
  final List<CartItemEntity> items;

  /// Total cart amount.
  final double total;

  /// Active shop ID. Cart can only contain products from one shop.
  final String? shopId;

  /// Whether the cart has no items.
  bool get isEmpty => items.isEmpty;

  /// Returns the quantity for a specific product.
  int quantityFor(String productId) {
    for (final item in items) {
      if (item.product.id == productId) {
        return item.quantity;
      }
    }
    return 0;
  }

  /// Creates a copy of this state.
  CartState copyWith({
    List<CartItemEntity>? items,
    double? total,
    String? shopId,
    bool clearShopId = false,
  }) {
    return CartState(
      items: items ?? this.items,
      total: total ?? this.total,
      shopId: clearShopId ? null : shopId ?? this.shopId,
    );
  }

  @override
  List<Object?> get props => [items, total, shopId];
}

/// Shopping cart notifier.
class CartNotifier extends StateNotifier<CartState> {
  /// Creates a [CartNotifier].
  CartNotifier() : super(CartState.empty()) {
    _restoreCart();
  }

  static const String _storageKey = 'customer_cart_v1';

  /// Adds a product to the cart.
  CartActionResult addItem(ProductEntity product, {int quantity = 1}) {
    if (!product.isAvailable || product.stockQuantity <= 0) {
      return CartActionResult.unavailable;
    }

    if (state.shopId != null && state.shopId != product.shopId) {
      return CartActionResult.differentShop;
    }

    final items = [...state.items];
    final index = items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      final currentItem = items[index];
      final nextQuantity = currentItem.quantity + quantity;
      if (nextQuantity > product.stockQuantity) {
        return CartActionResult.outOfStock;
      }
      items[index] = currentItem.copyWith(quantity: nextQuantity);
    } else {
      if (quantity > product.stockQuantity) {
        return CartActionResult.outOfStock;
      }
      items.add(CartItemEntity(product: product, quantity: quantity));
    }

    _setState(_buildState(items, product.shopId));
    return CartActionResult.added;
  }

  /// Re-adds all items from a previous order into the cart.
  CartActionResult addOrderItems(OrderEntity order) {
    if (order.items.isEmpty) {
      return CartActionResult.unavailable;
    }

    if (state.shopId != null && state.shopId != order.shopId) {
      return CartActionResult.differentShop;
    }

    CartActionResult result = CartActionResult.added;
    for (final item in order.items) {
      final product = ProductEntity(
        id: item.productId,
        shopId: order.shopId,
        name: item.productName,
        description: 'Reordered item',
        price: item.unitPrice,
        stockQuantity: 9999,
        isAvailable: true,
        imageUrl: item.productImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final addResult = addItem(product, quantity: item.quantity);
      if (addResult != CartActionResult.added) {
        result = addResult;
      }
    }

    return result;
  }

  /// Increments a product quantity by one.
  void incrementItem(String productId) {
    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index < 0) {
      return;
    }

    final items = [...state.items];
    final item = items[index];
    if (item.quantity >= item.product.stockQuantity) {
      return;
    }

    items[index] = item.copyWith(quantity: item.quantity + 1);
    _setState(_buildState(items, state.shopId));
  }

  /// Decrements a product quantity by one, removing it at zero.
  void decrementItem(String productId) {
    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index < 0) {
      return;
    }

    final items = [...state.items];
    final item = items[index];
    if (item.quantity <= 1) {
      items.removeAt(index);
    } else {
      items[index] = item.copyWith(quantity: item.quantity - 1);
    }

    _setState(_buildState(items, items.isEmpty ? null : state.shopId));
  }

  /// Removes a product from the cart.
  void removeItem(String productId) {
    final items = [...state.items]..removeWhere((item) => item.product.id == productId);
    _setState(_buildState(items, items.isEmpty ? null : state.shopId));
  }

  /// Clears the cart.
  void clearCart() {
    _setState(CartState.empty());
  }

  void _setState(CartState nextState) {
    state = nextState;
    _persistCart();
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'shopId': state.shopId,
      'items': state.items.map(_cartItemToMap).toList(growable: false),
    };
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<void> _restoreCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final rawItems = decoded['items'];
      if (rawItems is! List) {
        return;
      }

      final items = rawItems
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .map(_cartItemFromMap)
          .toList(growable: false);

      _setState(_buildState(
        items,
        decoded['shopId'] as String?,
      ));
    } catch (_) {
      // If data is malformed, clear it to prevent repeated parse failures.
      await prefs.remove(_storageKey);
    }
  }

  Map<String, dynamic> _cartItemToMap(CartItemEntity item) {
    return <String, dynamic>{
      'product': {
        'id': item.product.id,
        'shopId': item.product.shopId,
        'name': item.product.name,
        'description': item.product.description,
        'price': item.product.price,
        'stockQuantity': item.product.stockQuantity,
        'isAvailable': item.product.isAvailable,
        'imageUrl': item.product.imageUrl,
        'createdAt': item.product.createdAt.toIso8601String(),
        'updatedAt': item.product.updatedAt.toIso8601String(),
      },
      'quantity': item.quantity,
    };
  }

  CartItemEntity _cartItemFromMap(Map<String, dynamic> map) {
    final productMap = Map<String, dynamic>.from(map['product'] as Map);
    final product = ProductEntity(
      id: (productMap['id'] ?? '') as String,
      shopId: (productMap['shopId'] ?? '') as String,
      name: (productMap['name'] ?? '') as String,
      description: (productMap['description'] ?? '') as String,
      price: (productMap['price'] as num?)?.toDouble() ?? 0,
      stockQuantity: (productMap['stockQuantity'] as num?)?.toInt() ?? 0,
      isAvailable: productMap['isAvailable'] as bool? ?? true,
      imageUrl: productMap['imageUrl'] as String?,
      createdAt: DateTime.tryParse((productMap['createdAt'] ?? '') as String) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((productMap['updatedAt'] ?? '') as String) ??
          DateTime.now(),
    );

    return CartItemEntity(
      product: product,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  CartState _buildState(List<CartItemEntity> items, String? shopId) {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    return CartState(
      items: List.unmodifiable(items),
      total: total,
      shopId: items.isEmpty ? null : shopId,
    );
  }
}

/// Provides the shopping cart state.
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});