import 'service_model.dart';

enum OrderStatus { paid, partiallyPaid, pending, debt }

class OrderModel {
  final String id;
  final String serialNumber;
  final String? customerId;
  final String customerName; // لتسهيل العرض السريع
  final String carNumber;
  final List<ServiceModel> services;
  final double totalPrice;
  final double paidAmount;
  final OrderStatus status;
  final String notes;
  final String userId; // الموظف الذي سجل الطلب
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.serialNumber,
    this.customerId,
    required this.customerName,
    required this.carNumber,
    required this.services,
    required this.totalPrice,
    required this.paidAmount,
    required this.status,
    required this.notes,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'customerId': customerId,
      'customerName': customerName,
      'carNumber': carNumber,
      'services': services.map((s) => s.toMap()).toList(),
      'totalPrice': totalPrice,
      'paidAmount': paidAmount,
      'status': status.name,
      'notes': notes,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      customerId: map['customerId'],
      customerName: map['customerName'] ?? 'عميل نقدي',
      carNumber: map['carNumber'] ?? '',
      services: (map['services'] as List? ?? [])
          .map((s) => ServiceModel.fromMap(s))
          .toList(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      notes: map['notes'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
