import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) => OrdersNotifier());

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  OrdersNotifier() : super([]) {
    _loadOrders();
  }

  void _loadOrders() {
    _db.collection('orders').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        // تحويل الـ Timestamp من Firestore إلى DateTime لـ OrderModel
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        return OrderModel.fromMap(data);
      }).toList();
    });
  }

  Future<void> addOrder(OrderModel order) async {
    final docRef = _db.collection('orders').doc(order.id);
    await docRef.set({
      ...order.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await _db.collection('orders').doc(orderId).update({
      'status': newStatus.name,
    });
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
