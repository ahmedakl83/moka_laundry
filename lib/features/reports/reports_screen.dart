import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/constants.dart';
import '../orders/orders_provider.dart';
import '../expenses/expenses_provider.dart';
import '../../models/order_model.dart';
import '../../models/expense_model.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersProvider.notifier).getOrdersByDateRange(_startDate, _endDate);
    final allExpenses = ref.watch(expensesProvider.notifier).getExpensesByDateRange(_startDate, _endDate);

    double totalIncome = allOrders.fold(0, (sum, item) => sum + item.totalPrice);
    double totalExpenses = allExpenses.fold(0, (sum, item) => sum + item.amount);
    double netProfit = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير التفصيلية'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeIndicator(),
            const SizedBox(height: 20),
            _buildSummaryRow(totalIncome, totalExpenses, netProfit),
            const SizedBox(height: 32),
            const Text('إحصائيات طرق الدفع:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPaymentStats(allOrders),
            const SizedBox(height: 32),
            const Text('أكثر الخدمات طلباً:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildServiceStats(allOrders),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeIndicator() {
    final df = intl.DateFormat('yyyy/MM/dd');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.lightBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month, size: 20, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Text('من: ${df.format(_startDate)}  إلى: ${df.format(_endDate)}'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(double income, double expenses, double profit) {
    return Column(
      children: [
        _buildStatCard('إجمالي الإيرادات', income, Colors.green),
        const SizedBox(height: 12),
        _buildStatCard('إجمالي المصروفات', expenses, Colors.red),
        const SizedBox(height: 12),
        _buildStatCard('صافي الربح', profit, AppColors.primaryBlue),
      ],
    );
  }

  Widget _buildStatCard(String title, double amount, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text('${amount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStats(List<OrderModel> orders) {
    double cash = orders.where((o) => o.paymentMethod == PaymentMethod.cash).fold(0, (sum, i) => sum + i.totalPrice);
    double wallet = orders.where((o) => o.paymentMethod == PaymentMethod.wallet).fold(0, (sum, i) => sum + i.totalPrice);

    return Row(
      children: [
        Expanded(child: _buildMiniStat('نقدي', cash, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildMiniStat('محفظة', wallet, Colors.orange)),
      ],
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${amount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildServiceStats(List<OrderModel> orders) {
    Map<String, int> counts = {};
    for (var o in orders) {
      for (var s in o.services) {
        counts[s.name] = (counts[s.name] ?? 0) + 1;
      }
    }

    var sortedEntries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((e) => ListTile(
        title: Text(e.key),
        trailing: CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.primaryBlue,
          child: Text(e.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      )).toList(),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}
