import '../../entities/order_entity.dart';
import '../../repositories/order_repository.dart';

/// Retrieves all orders for a customer.
class GetCustomerOrdersUsecase {
  /// Creates a [GetCustomerOrdersUsecase].
  const GetCustomerOrdersUsecase({required IOrderRepository orderRepository})
      : _orderRepository = orderRepository;

  final IOrderRepository _orderRepository;

  /// Returns the customer's orders.
  Future<List<OrderEntity>> call({required String customerId}) async {
    return await _orderRepository.getCustomerOrders(customerId);
  }
}