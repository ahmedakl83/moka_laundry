import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../orders/orders_provider.dart';
import '../expenses/expenses_provider.dart';
import '../customers/customers_provider.dart';
import '../../models/order_model.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final expenses = ref.watch(expensesProvider);
    final customers = ref.watch(customersProvider);

    // كل الطلبات الآن مدفوعة بالكامل حسب التعديل الجديد
    double totalIncome = orders.fold(0, (sum, item) => sum + item.totalPrice);
    double totalExpenses = expenses.fold(0, (sum, item) => sum + item.amount);
    double netProfit = totalIncome - totalExpenses;
    double totalDebt = customers.fold(0, (sum, item) => sum + item.balance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryCard(
              title: 'إجمالي الإيرادات (مدفوع)',
              amount: totalIncome,
              icon: Icons.trending_up,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              title: 'إجمالي المصروفات',
              amount: totalExpenses,
              icon: Icons.trending_down,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              title: 'صافي الربح',
              amount: netProfit,
              icon: Icons.account_balance_wallet,
              color: AppColors.primaryBlue,
            ),
            if (totalDebt > 0) ...[
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'ديون سابقة مستحقة',
                amount: totalDebt,
                icon: Icons.money_off,
                color: Colors.orange,
              ),
            ],
            const SizedBox(height: 32),
            const Row(
              children: [
                Icon(Icons.history, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'آخر العمليات المنفذة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length > 10 ? 10 : orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      order.paymentMethod == PaymentMethod.cash ? Icons.money : Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                    title: Text('${order.customerName} - ${order.totalPrice} ج.م'),
                    subtitle: Text('رقم: ${order.serialNumber} | ${order.paymentMethod == PaymentMethod.cash ? "نقدي" : "محفظة"}'),
                    trailing: Icon(
                      order.status == OrderStatus.completed ? Icons.check_circle : Icons.pending_actions,
                      color: order.status == OrderStatus.completed ? Colors.green : Colors.orange,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required double amount, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text('${amount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
