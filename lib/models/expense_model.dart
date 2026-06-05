class ExpenseModel {
  final String id;
  final String categoryId;
  final String categoryName;
  final double amount;
  final String description;
  final String userId;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.description,
    required this.userId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'description': description,
      'userId': userId,
      'date': date.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }
}
