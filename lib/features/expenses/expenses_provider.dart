import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/expense_model.dart';
import '../../models/expense_category_model.dart';

final expenseCategoriesProvider = StateNotifierProvider<ExpenseCategoriesNotifier, List<ExpenseCategoryModel>>((ref) => ExpenseCategoriesNotifier());

class ExpenseCategoriesNotifier extends StateNotifier<List<ExpenseCategoryModel>> {
  ExpenseCategoriesNotifier() : super([]) {
    _loadCategories();
  }

  void _loadCategories() {
    state = [
      ExpenseCategoryModel(id: '1', name: 'إيجار'),
      ExpenseCategoryModel(id: '2', name: 'كهرباء ومياه'),
      ExpenseCategoryModel(id: '3', name: 'مواد تنظيف'),
      ExpenseCategoryModel(id: '4', name: 'رواتب'),
      ExpenseCategoryModel(id: '5', name: 'أخرى'),
    ];
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<ExpenseModel>>((ref) => ExpensesNotifier());

class ExpensesNotifier extends StateNotifier<List<ExpenseModel>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ExpensesNotifier() : super([]) {
    _loadExpenses();
  }

  void _loadExpenses() {
    _db.collection('expenses').orderBy('date', descending: true).snapshots().listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
        }
        return ExpenseModel.fromMap(data);
      }).toList();
    });
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final docRef = _db.collection('expenses').doc();
    await docRef.set({
      ...expense.toMap(),
      'id': docRef.id,
      'date': FieldValue.serverTimestamp(),
    });
  }

  List<ExpenseModel> getExpensesByDateRange(DateTime start, DateTime end) {
    return state.where((e) =>
      e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
      e.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }
}
