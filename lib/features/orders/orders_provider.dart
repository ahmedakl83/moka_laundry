import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_model.dart';
import '../../models/service_model.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) {
  return OrdersNotifier();
});

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  OrdersNotifier() : super([]);

  void addOrder(OrderModel order) {
    state = [order, ...state];
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          OrderModel(
            id: order.id,
            serialNumber: order.serialNumber,
            customerId: order.customerId,
            customerName: order.customerName,
            carNumber: order.carNumber,
            carPlateImagePath: order.carPlateImagePath,
            services: order.services,
            totalPrice: order.totalPrice,
            status: newStatus,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            userId: order.userId,
            createdAt: order.createdAt,
          )
        else
          order
    ];
  }

  String generateSerialNumber() {
    final now = DateTime.now();
    return "${now.year}${now.month}${now.day}${state.length + 1}";
  }
}
