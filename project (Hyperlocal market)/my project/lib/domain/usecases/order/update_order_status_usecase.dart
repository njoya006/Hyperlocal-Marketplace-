import '../../entities/order_entity.dart';
import '../../repositories/order_repository.dart';

/// Updates the status of an existing order.
class UpdateOrderStatusUsecase {
  /// Creates an [UpdateOrderStatusUsecase].
  const UpdateOrderStatusUsecase({required IOrderRepository orderRepository})
      : _orderRepository = orderRepository;

  final IOrderRepository _orderRepository;

  /// Updates the order status.
  Future<void> call({
    required String orderId,
    required OrderStatus status,
  }) async {
    await _orderRepository.updateOrderStatus(orderId: orderId, status: status);
  }
}