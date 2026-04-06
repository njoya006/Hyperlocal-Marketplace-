import '../../entities/order_entity.dart';
import '../../repositories/order_repository.dart';

/// Watches an order for real-time updates.
class TrackOrderUsecase {
  /// Creates a [TrackOrderUsecase].
  const TrackOrderUsecase({required IOrderRepository orderRepository})
      : _orderRepository = orderRepository;

  final IOrderRepository _orderRepository;

  /// Returns a stream of order updates.
  Stream<OrderEntity> call(String orderId) {
    return _orderRepository.watchOrder(orderId);
  }
}