import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyperlocal_market/domain/entities/order_entity.dart';
import 'package:hyperlocal_market/domain/entities/shop_entity.dart';
import 'package:hyperlocal_market/domain/repositories/order_repository.dart';
import 'package:hyperlocal_market/domain/repositories/shop_repository.dart';
import 'package:hyperlocal_market/domain/usecases/order/update_order_status_usecase.dart';
import 'package:hyperlocal_market/domain/usecases/shop/create_shop_usecase.dart';
import 'package:hyperlocal_market/domain/usecases/shop/get_shops_by_owner_usecase.dart';
import 'package:hyperlocal_market/presentation/providers/shop_provider.dart';

void main() {
  group('Owner flow coverage', () {
    test('create shop notifier submits an unapproved owner shop', () async {
      final repository = _FakeShopRepository();
      final container = ProviderContainer(
        overrides: [
          createShopUsecaseProvider.overrideWithValue(
            CreateShopUsecase(shopRepository: repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      final shop = _buildShop(
        id: 'shop-1',
        ownerId: 'owner-1',
        isApproved: false,
        isOpen: true,
      );

      await container.read(createShopProvider.notifier).createShop(shop: shop);

      expect(repository.createdShops, hasLength(1));
      expect(repository.createdShops.single.id, shop.id);
      expect(repository.createdShops.single.ownerId, 'owner-1');
      expect(repository.createdShops.single.isApproved, isFalse);
      expect(repository.createdShops.single.isOpen, isTrue);
    });

    test('owner shop provider prefers approved shops when present', () async {
      final approvedShop = _buildShop(
        id: 'approved-shop',
        ownerId: 'owner-1',
        isApproved: true,
        isOpen: true,
      );
      final pendingShop = _buildShop(
        id: 'pending-shop',
        ownerId: 'owner-1',
        isApproved: false,
        isOpen: true,
      );
      final repository = _FakeShopRepository(ownerShops: [pendingShop, approvedShop]);
      final container = ProviderContainer(
        overrides: [
          getShopsByOwnerUsecaseProvider.overrideWithValue(
            GetShopsByOwnerUsecase(shopRepository: repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      final shop = await container.read(ownerShopProvider('owner-1').future);

      expect(shop, isNotNull);
      expect(shop!.id, approvedShop.id);
      expect(shop.isApproved, isTrue);
    });

    test('update order status usecase delegates to the repository', () async {
      final repository = _FakeOrderRepository();
      final usecase = UpdateOrderStatusUsecase(orderRepository: repository);

      await usecase(orderId: 'order-1', status: OrderStatus.confirmed);

      expect(repository.updatedOrderId, 'order-1');
      expect(repository.updatedStatus, OrderStatus.confirmed);
    });
  });
}

ShopEntity _buildShop({
  required String id,
  required String ownerId,
  required bool isApproved,
  required bool isOpen,
}) {
  return ShopEntity(
    id: id,
    ownerId: ownerId,
    name: 'Shop $id',
    description: 'Test shop',
    category: ShopCategory.grocery,
    latitude: 3.95,
    longitude: 11.59,
    address: 'Test address',
    phone: '555-0100',
    isOpen: isOpen,
    isApproved: isApproved,
    rating: 4.5,
    totalReviews: 12,
    createdAt: DateTime(2026, 4, 1),
  );
}

class _FakeShopRepository implements IShopRepository {
  _FakeShopRepository({List<ShopEntity>? ownerShops}) : _ownerShops = ownerShops ?? <ShopEntity>[];

  final List<ShopEntity> _ownerShops;
  final List<ShopEntity> createdShops = <ShopEntity>[];

  @override
  Future<void> createShop(ShopEntity shop) async {
    createdShops.add(shop);
  }

  @override
  Future<List<ShopEntity>> getNearbyShops({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    return <ShopEntity>[];
  }

  @override
  Future<List<ShopEntity>> getShopsByOwner(String ownerId) async {
    return _ownerShops.where((shop) => shop.ownerId == ownerId).toList();
  }

  @override
  Future<void> updateShop(String shopId, Map<String, dynamic> data) async {}

  @override
  Stream<ShopEntity> watchShop(String shopId) async* {}
}

class _FakeOrderRepository implements IOrderRepository {
  String? updatedOrderId;
  OrderStatus? updatedStatus;

  @override
  Future<String> placeOrder({required OrderEntity order}) async {
    return order.id;
  }

  @override
  Future<List<OrderEntity>> getCustomerOrders(String customerId) async {
    return <OrderEntity>[];
  }

  @override
  Stream<List<OrderEntity>> getShopOrders(String shopId) async* {}

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    updatedOrderId = orderId;
    updatedStatus = status;
  }

  @override
  Stream<OrderEntity> watchOrder(String orderId) async* {}
}