import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/order_model.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) => OrdersNotifier());

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  OrdersNotifier() : super([]) {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString('orders_history');
    if (ordersJson != null) {
      final List decoded = json.decode(ordersJson);
      state = decoded.map((o) => OrderModel.fromMap(o)).toList();
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(state.map((o) => o.toMap()).toList());
    await prefs.setString('orders_history', encoded);
  }

  void addOrder(OrderModel order) {
    state = [order, ...state];
    _saveOrders();
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
    _saveOrders();
  }

  void updateCarNumber(String orderId, String newCarNumber) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          OrderModel(
            id: order.id,
            serialNumber: order.serialNumber,
            customerId: order.customerId,
            customerName: order.customerName,
            carNumber: newCarNumber,
            carPlateImagePath: order.carPlateImagePath,
            services: order.services,
            totalPrice: order.totalPrice,
            status: order.status,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            userId: order.userId,
            createdAt: order.createdAt,
          )
        else
          order
    ];
    _saveOrders();
  }

  List<OrderModel> getOrdersByDateRange(DateTime start, DateTime end) {
    return state.where((o) =>
      o.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
      o.createdAt.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  String generateSerialNumber() {
    final now = DateTime.now();
    final datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    return "$datePart${state.length + 1}";
  }
}
