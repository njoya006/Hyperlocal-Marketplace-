import '../../entities/order_entity.dart';
import '../../repositories/order_repository.dart';

/// Places an order and returns the generated order id.
class PlaceOrderUsecase {
  /// Creates a [PlaceOrderUsecase].
  const PlaceOrderUsecase({required IOrderRepository orderRepository})
      : _orderRepository = orderRepository;

  final IOrderRepository _orderRepository;

  /// Places the supplied order.
  Future<String> call({required OrderEntity order}) async {
    return await _orderRepository.placeOrder(order: order);
  }
}