import 'package:flutter_test/flutter_test.dart';

import 'package:hyperlocal_market/data/models/order_model.dart';
import 'package:hyperlocal_market/domain/entities/order_entity.dart';
import 'package:hyperlocal_market/domain/entities/order_item_entity.dart';

void main() {
  test('fromEntity and toEntity preserve order data', () {
    final entity = OrderEntity(
      id: 'order-1',
      customerId: 'customer-1',
      customerName: 'Test Customer',
      shopId: 'shop-1',
      items: const [
        OrderItemEntity(
          productId: 'product-1',
          productName: 'Rice',
          unitPrice: 3.5,
          quantity: 2,
        ),
      ],
      subtotal: 7.0,
      deliveryFee: 1.0,
      tax: 0.5,
      total: 8.5,
      status: OrderStatus.pending,
      deliveryAddress: 'Test address',
      deliveryLatitude: 3.9552,
      deliveryLongitude: 11.5883,
      customerNotes: 'Call on arrival',
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    final model = OrderModel.fromEntity(entity);
    final mapped = model.toEntity();

    expect(mapped.id, entity.id);
    expect(mapped.customerId, entity.customerId);
    expect(mapped.shopId, entity.shopId);
    expect(mapped.items, entity.items);
    expect(mapped.total, entity.total);
    expect(mapped.status, entity.status);
    expect(mapped.deliveryAddress, entity.deliveryAddress);
  });

  test('toFirestore outputs expected order fields', () {
    final model = OrderModel(
      id: 'order-2',
      customerId: 'customer-2',
      customerName: 'Test Customer',
      shopId: 'shop-2',
      items: [
        OrderItemEntity(
          productId: 'product-2',
          productName: 'Milk',
          unitPrice: 2.0,
          quantity: 3,
        ),
      ],
      subtotal: 6.0,
      deliveryFee: 1.0,
      tax: 0.0,
      total: 7.0,
      status: OrderStatus.confirmed,
      deliveryAddress: 'Another address',
      deliveryLatitude: 4.0,
      deliveryLongitude: 11.0,
      customerNotes: null,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    final map = model.toFirestore();

    expect(map['customerId'], 'customer-2');
    expect(map['customerName'], 'Test Customer');
    expect(map['shopId'], 'shop-2');
    expect(map['status'], 'confirmed');
    expect(map['total'], 7.0);
    expect((map['items'] as List).length, 1);
  });
}
