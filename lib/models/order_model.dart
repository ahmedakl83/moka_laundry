import 'service_model.dart';

enum OrderStatus { pending, washing, ready, completed, cancelled }
enum PaymentMethod { cash, wallet, pending }

class OrderModel {
  final String id;
  final String serialNumber;
  final String? customerId;
  final String customerName;
  final String? carNumber;
  final String? carPlateImagePath;
  final List<ServiceModel> services;
  final double totalPrice;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String notes;
  final String userId;
  final DateTime createdAt;
  final DateTime? completedAt;

  OrderModel({
    required this.id,
    required this.serialNumber,
    this.customerId,
    required this.customerName,
    this.carNumber,
    this.carPlateImagePath,
    required this.services,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.notes,
    required this.userId,
    required this.createdAt,
    this.completedAt,
  });

  OrderModel copyWith({
    String? carNumber,
    List<ServiceModel>? services,
    double? totalPrice,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? completedAt,
  }) {
    return OrderModel(
      id: id,
      serialNumber: serialNumber,
      customerId: customerId,
      customerName: customerName,
      carNumber: carNumber ?? this.carNumber,
      carPlateImagePath: carPlateImagePath,
      services: services ?? this.services,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      userId: userId,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'customerId': customerId,
      'customerName': customerName,
      'carNumber': carNumber,
      'carPlateImagePath': carPlateImagePath,
      'services': services.map((s) => s.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'notes': notes,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      customerId: map['customerId'],
      customerName: map['customerName'] ?? 'عميل نقدي',
      carNumber: map['carNumber'],
      carPlateImagePath: map['carPlateImagePath'],
      services: (map['services'] as List? ?? [])
          .map((s) => ServiceModel.fromMap(s))
          .toList(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.pending,
      ),
      notes: map['notes'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }
}
