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
    // هنا سيتم الحفظ في Firestore
  }

  String generateSerialNumber() {
    final now = DateTime.now();
    return "${now.year}${now.month}${now.day}${state.length + 1}";
  }
}
