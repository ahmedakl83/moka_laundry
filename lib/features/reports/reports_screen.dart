import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../orders/orders_provider.dart';
import '../expenses/expenses_provider.dart';
import '../customers/customers_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final expenses = ref.watch(expensesProvider);
    final customers = ref.watch(customersProvider);

    double totalIncome = orders.fold(0, (sum, item) => sum + item.paidAmount);
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
              title: 'إجمالي الإيرادات',
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
            const SizedBox(height: 16),
            _buildSummaryCard(
              title: 'الديون المستحقة',
              amount: totalDebt,
              icon: Icons.money_off,
              color: Colors.orange,
            ),
            const SizedBox(height: 32),
            const Text(
              'تفاصيل الطلبات الأخيرة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // قائمة مبسطة للطلبات الأخيرة
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length > 5 ? 5 : orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text('طلب رقم: ${order.serialNumber}'),
                  subtitle: Text(order.customerName),
                  trailing: Text('${order.totalPrice} ريال'),
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
                  Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Text('$amount ريال', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
