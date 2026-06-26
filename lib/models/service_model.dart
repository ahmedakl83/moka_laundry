class ServiceModel {
  final String id;
  final String name;
  final double basePrice;
  final double tip;

  ServiceModel({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.tip,
  });

  double get totalPrice => basePrice + tip;

  // Compatibility getter for existing code that uses .price
  double get price => totalPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'basePrice': basePrice,
      'tip': tip,
      // Keeping price for older saved data compatibility
      'price': totalPrice,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      basePrice: (map['basePrice'] ?? map['price'] ?? 0.0).toDouble(),
      tip: (map['tip'] ?? 0.0).toDouble(),
    );
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    double? basePrice,
    double? tip,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      tip: tip ?? this.tip,
    );
  }
}
