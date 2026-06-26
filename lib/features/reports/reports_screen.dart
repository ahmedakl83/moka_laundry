import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/constants.dart';
import '../orders/orders_provider.dart';
import '../expenses/expenses_provider.dart';
import '../../models/order_model.dart';
import '../../models/expense_model.dart';

enum ReportFilter { today, week, month, total, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportFilter _selectedFilter = ReportFilter.month;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  void _updateDateRange(ReportFilter filter) {
    final now = DateTime.now();
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case ReportFilter.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case ReportFilter.week:
          int daysToSubtract = (now.weekday + 1) % 7;
          _startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
          _endDate = now;
          break;
        case ReportFilter.month:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case ReportFilter.total:
          _startDate = DateTime(2024, 1, 1);
          _endDate = now;
          break;
        case ReportFilter.custom:
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateDateRange(ReportFilter.month);
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersProvider.notifier).getOrdersByDateRange(_startDate, _endDate);
    final allExpenses = ref.watch(expensesProvider.notifier).getExpensesByDateRange(_startDate, _endDate);

    double totalTips = 0;
    double totalBaseIncome = 0;

    for (var order in allOrders) {
      for (var service in order.services) {
        totalTips += service.tip;
        totalBaseIncome += service.basePrice;
      }
    }

    double totalExpenses = allExpenses.fold(0, (sum, item) => sum + item.amount);
    double netProfit = totalBaseIncome - totalExpenses;

    // تصفية عمليات اليوم فقط للقسم السفلي
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayOrders = allOrders.where((o) => o.createdAt.isAfter(todayStart)).toList();

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterChips(),
              const SizedBox(height: 16),
              _buildDateRangeIndicator(),
              const SizedBox(height: 20),

              // ملحوظة الإكراميات
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملحوظة: الإكراميات تُوزع على العمال ولا تُحسب ضمن دخل المغسلة الصافي.',
                        style: TextStyle(fontSize: 12, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),

              _buildSummaryRow(totalBaseIncome, totalTips, totalExpenses, netProfit),
              const SizedBox(height: 32),
              const Text('إحصائيات طرق الدفع:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildPaymentStats(allOrders),
              const SizedBox(height: 32),
              const Text('أكثر الخدمات طلباً:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildServiceStats(allOrders),
              const SizedBox(height: 32),
              const Divider(thickness: 2),
              const SizedBox(height: 16),
              const Text('عمليات اليوم وتفاصيل الحساب:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              const SizedBox(height: 12),
              _buildTodayOrdersList(todayOrders),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('لا توجد عمليات مسجلة لهذا اليوم حتى الآن'),
      ));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        double orderTips = order.services.fold(0, (sum, s) => sum + s.tip);
        double orderBase = order.services.fold(0, (sum, s) => sum + s.basePrice);

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${order.customerName} (${order.carNumber ?? "بدون رقم"})'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(intl.DateFormat('hh:mm a').format(order.createdAt)),
                Text('خدمة: $orderBase | إكرامية: $orderTips', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: Text('${order.totalPrice} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('اليوم', ReportFilter.today),
          _filterChip('هذا الأسبوع', ReportFilter.week),
          _filterChip('هذا الشهر', ReportFilter.month),
          _filterChip('الكل', ReportFilter.total),
          _filterChip('مخصص', ReportFilter.custom),
        ],
      ),
    );
  }

  Widget _filterChip(String label, ReportFilter filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (filter == ReportFilter.custom) {
            _selectDateRange(context);
          } else {
            _updateDateRange(filter);
          }
        },
        selectedColor: AppColors.primaryBlue.withOpacity(0.2),
        checkmarkColor: AppColors.primaryBlue,
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

  Widget _buildSummaryRow(double baseIncome, double tips, double expenses, double profit) {
    return Column(
      children: [
        _buildStatCard('إيرادات الخدمات (المغسلة)', baseIncome, Colors.green),
        const SizedBox(height: 12),
        _buildStatCard('إجمالي الإكراميات (للعمال)', tips, Colors.orange),
        const SizedBox(height: 12),
        _buildStatCard('إجمالي المصروفات', expenses, Colors.red),
        const SizedBox(height: 12),
        _buildStatCard('صافي ربح المغسلة', profit, AppColors.primaryBlue),
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
        _selectedFilter = ReportFilter.custom;
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}
