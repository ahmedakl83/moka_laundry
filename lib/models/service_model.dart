class ServiceModel {
  final String id;
  final String name;
  final double price;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }
}
