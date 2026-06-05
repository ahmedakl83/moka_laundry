import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/expense_model.dart';
import '../../models/expense_category_model.dart';

final expenseCategoriesProvider = StateNotifierProvider<ExpenseCategoriesNotifier, List<ExpenseCategoryModel>>((ref) {
  return ExpenseCategoriesNotifier();
});

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

  void addCategory(String name) {
    state = [...state, ExpenseCategoryModel(id: DateTime.now().toString(), name: name)];
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<ExpenseModel>>((ref) {
  return ExpensesNotifier();
});

class ExpensesNotifier extends StateNotifier<List<ExpenseModel>> {
  ExpensesNotifier() : super([]);

  void addExpense(ExpenseModel expense) {
    state = [expense, ...state];
  }

  double getTotalExpenses() {
    return state.fold(0, (sum, item) => sum + item.amount);
  }
}
