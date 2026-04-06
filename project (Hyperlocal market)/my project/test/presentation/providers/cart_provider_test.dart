import 'package:flutter_test/flutter_test.dart';

import 'package:hyperlocal_market/domain/entities/product_entity.dart';
import 'package:hyperlocal_market/presentation/providers/cart_provider.dart';

void main() {
  ProductEntity buildProduct({
    required String id,
    required String shopId,
    required double price,
    int stock = 10,
    bool isAvailable = true,
  }) {
    return ProductEntity(
      id: id,
      shopId: shopId,
      name: 'Product $id',
      description: 'Description',
      price: price,
      stockQuantity: stock,
      isAvailable: isAvailable,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  group('CartNotifier', () {
    test('adds items and calculates total', () {
      final notifier = CartNotifier();
      final product = buildProduct(id: 'p1', shopId: 's1', price: 12.5);

      final result = notifier.addItem(product, quantity: 2);

      expect(result, CartActionResult.added);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.quantity, 2);
      expect(notifier.state.shopId, 's1');
      expect(notifier.state.total, 25.0);
    });

    test('rejects products from another shop while cart has items', () {
      final notifier = CartNotifier();
      final firstProduct = buildProduct(id: 'p1', shopId: 's1', price: 10);
      final secondProduct = buildProduct(id: 'p2', shopId: 's2', price: 15);

      notifier.addItem(firstProduct);
      final result = notifier.addItem(secondProduct);

      expect(result, CartActionResult.differentShop);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.shopId, 's1');
    });

    test('enforces stock limits', () {
      final notifier = CartNotifier();
      final product = buildProduct(id: 'p1', shopId: 's1', price: 5, stock: 2);

      final firstResult = notifier.addItem(product, quantity: 2);
      final secondResult = notifier.addItem(product, quantity: 1);

      expect(firstResult, CartActionResult.added);
      expect(secondResult, CartActionResult.outOfStock);
      expect(notifier.state.items.first.quantity, 2);
    });

    test('decrement removes item and resets shop when cart becomes empty', () {
      final notifier = CartNotifier();
      final product = buildProduct(id: 'p1', shopId: 's1', price: 8);

      notifier.addItem(product);
      notifier.decrementItem(product.id);

      expect(notifier.state.items, isEmpty);
      expect(notifier.state.shopId, isNull);
      expect(notifier.state.total, 0);
    });
  });
}
