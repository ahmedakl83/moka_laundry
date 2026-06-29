import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  ExpensesNotifier() : super([]) {
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getString('expenses_history');
    if (expensesJson != null) {
      final List decoded = json.decode(expensesJson);
      state = decoded.map((e) => ExpenseModel.fromMap(e)).toList();
    }
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(state.map((e) => e.toMap()).toList());
    await prefs.setString('expenses_history', encoded);
  }

  void addExpense(ExpenseModel expense) {
    state = [expense, ...state];
    _saveExpenses();
  }

  List<ExpenseModel> getExpensesByDateRange(DateTime start, DateTime end) {
    return state.where((e) =>
      e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
      e.date.isBefore(end)
    ).toList();
  }
}
