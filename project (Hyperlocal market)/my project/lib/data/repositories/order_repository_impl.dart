import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/firestore_order_datasource.dart';
import '../models/order_model.dart';

/// Concrete implementation of [IOrderRepository].
class OrderRepository implements IOrderRepository {
  /// Creates a new [OrderRepository].
  const OrderRepository({required IOrderDatasource orderDatasource})
      : _orderDatasource = orderDatasource;

  final IOrderDatasource _orderDatasource;

  @override
  Future<String> placeOrder({required OrderEntity order}) async {
    try {
      final model = OrderModel.fromEntity(order);
      return await _orderDatasource.placeOrder(order: model);
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Stream<OrderEntity> watchOrder(String orderId) {
    try {
      return _orderDatasource
          .watchOrder(orderId)
          .map((model) => model.toEntity())
          .handleError((error) {
        if (error is ServerException) {
          throw ServerFailure(code: error.code, message: error.message);
        }
        throw ServerFailure(code: 'unknown', message: error.toString());
      });
    } catch (e) {
      if (e is ServerFailure) {
        return Stream.error(e);
      }
      return Stream.error(ServerFailure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<List<OrderEntity>> getCustomerOrders(String customerId) async {
    try {
      final models = await _orderDatasource.getCustomerOrders(customerId);
      return models.map((model) => model.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Stream<List<OrderEntity>> getShopOrders(String shopId) {
    try {
      return _orderDatasource.getShopOrders(shopId).map(
            (models) => models.map((model) => model.toEntity()).toList(),
          ).handleError((error) {
        if (error is ServerException) {
          throw ServerFailure(code: error.code, message: error.message);
        }
        throw ServerFailure(code: 'unknown', message: error.toString());
      });
    } catch (e) {
      return Stream.error(ServerFailure(code: 'unknown', message: e.toString()));
    }
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    try {
      await _orderDatasource.updateOrderStatus(orderId: orderId, status: status);
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }
}