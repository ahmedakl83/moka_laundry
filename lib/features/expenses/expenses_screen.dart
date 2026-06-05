import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../models/expense_model.dart';
import '../../models/expense_category_model.dart';
import '../auth/auth_provider.dart';
import 'expenses_provider.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات اليومية'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('لا توجد مصروفات مسجلة'))
          : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEBEE),
                      child: Icon(Icons.money_off, color: Colors.red),
                    ),
                    title: Text(expense.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(expense.description),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${expense.amount} ج.م', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        Text(DateFormat('yyyy/MM/dd').format(expense.date), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context, ref),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final categories = ref.read(expenseCategoriesProvider);
    ExpenseCategoryModel? selectedCategory = categories.isNotEmpty ? categories.first : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تسجيل مصروف جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ExpenseCategoryModel>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
                decoration: const InputDecoration(labelText: 'الفئة'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'المبلغ'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'التفاصيل / الملاحظات'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isNotEmpty && selectedCategory != null) {
                  final user = ref.read(authProvider).user;
                  final expense = ExpenseModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    categoryId: selectedCategory!.id,
                    categoryName: selectedCategory!.name,
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    description: descController.text,
                    userId: user?.id ?? '',
                    date: DateTime.now(),
                  );
                  ref.read(expensesProvider.notifier).addExpense(expense);
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
