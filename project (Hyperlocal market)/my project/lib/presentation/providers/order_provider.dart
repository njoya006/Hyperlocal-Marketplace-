import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firestore_order_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/order/get_customer_orders_usecase.dart';
import '../../domain/usecases/order/place_order_usecase.dart';
import '../../domain/usecases/order/track_order_usecase.dart';
import '../../domain/usecases/order/update_order_status_usecase.dart';
import 'auth_provider.dart';

/// Provides Firestore instance for order operations.
final orderFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return ref.watch(firestoreProvider);
});

/// Provides order datasource implementation.
final orderDatasourceProvider = Provider<IOrderDatasource>((ref) {
  final firestore = ref.watch(orderFirestoreProvider);
  return FirestoreOrderDatasource(firestore: firestore);
});

/// Provides order repository implementation.
final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  final datasource = ref.watch(orderDatasourceProvider);
  return OrderRepository(orderDatasource: datasource);
});

/// Provides place order usecase.
final placeOrderUsecaseProvider = Provider<PlaceOrderUsecase>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return PlaceOrderUsecase(orderRepository: repository);
});

/// Provides get customer orders usecase.
final getCustomerOrdersUsecaseProvider =
    Provider<GetCustomerOrdersUsecase>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return GetCustomerOrdersUsecase(orderRepository: repository);
});

/// Provides track order usecase.
final trackOrderUsecaseProvider = Provider<TrackOrderUsecase>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return TrackOrderUsecase(orderRepository: repository);
});

/// Provides update order status usecase.
final updateOrderStatusUsecaseProvider =
    Provider<UpdateOrderStatusUsecase>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return UpdateOrderStatusUsecase(orderRepository: repository);
});

/// Loads a customer's orders.
final customerOrdersProvider =
    FutureProvider.family<List<OrderEntity>, String>((ref, customerId) async {
  final usecase = ref.watch(getCustomerOrdersUsecaseProvider);
  return await usecase(customerId: customerId);
});

/// Tracks a single order in real time.
final trackingProvider =
    StreamProvider.family<OrderEntity, String>((ref, orderId) {
  final usecase = ref.watch(trackOrderUsecaseProvider);
  return usecase(orderId);
});

/// Loads all live orders for a shop owner.
final ownerOrdersProvider =
    StreamProvider.family<List<OrderEntity>, String>((ref, shopId) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getShopOrders(shopId);
});