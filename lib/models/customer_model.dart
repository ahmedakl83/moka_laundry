class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final double balance; // الديون المستحقة

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'balance': balance,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
    );
  }
}
