class ExpenseCategoryModel {
  final String id;
  final String name;

  ExpenseCategoryModel({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map) {
    return ExpenseCategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
