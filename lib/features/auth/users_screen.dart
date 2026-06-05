import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/constants.dart';
import 'employees_provider.dart';
import 'auth_provider.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين والرواتب'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'الموظفين'),
            Tab(text: 'التحضير'),
            Tab(text: 'الرواتب'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildEmployeesTab(),
            _buildAttendanceTab(),
            _buildPayrollTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeesTab() {
    final employees = ref.watch(employeesProvider).employees;

    return Scaffold(
      body: ListView.builder(
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(employee.name),
            subtitle: Text('اليومية: ${employee.dailyRate} ج.م'),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    final state = ref.watch(employeesProvider);
    final today = DateTime.now();
    final dateStr = intl.DateFormat('yyyy/MM/dd').format(today);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('تحضير اليوم: $dateStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.employees.length,
            itemBuilder: (context, index) {
              final employee = state.employees[index];
              final isPresent = state.attendance.any((a) =>
                a.employeeId == employee.id &&
                intl.DateFormat('yyyyMMdd').format(a.date) == intl.DateFormat('yyyyMMdd').format(today)
              );

              return CheckboxListTile(
                title: Text(employee.name),
                value: isPresent,
                onChanged: (val) {
                  ref.read(employeesProvider.notifier).markAttendance(employee.id, today, val ?? false);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPayrollTab() {
    final state = ref.watch(employeesProvider);
    final days = ['الأثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

    return Column(
      children: [
        ListTile(
          title: const Text('يوم بداية الأسبوع'),
          subtitle: Text('حالياً: ${days[state.weekStartDay - 1]}'),
          trailing: const Icon(Icons.settings),
          onTap: _showWeekStartDialog,
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('مستحقات الأسبوع الحالي:', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.employees.length,
            itemBuilder: (context, index) {
              final employee = state.employees[index];
              final salary = ref.read(employeesProvider.notifier).calculateWeeklySalary(employee.id);
              return ListTile(
                title: Text(employee.name),
                trailing: Text('$salary ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة موظف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الموظف')),
            TextField(controller: rateController, decoration: const InputDecoration(labelText: 'قيمة اليومية (ج.م)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(employeesProvider.notifier).addEmployee(
                  nameController.text,
                  double.tryParse(rateController.text) ?? 0.0
                );
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showWeekStartDialog() {
    final days = ['الأثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر يوم بداية الأسبوع'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 7,
            itemBuilder: (context, index) => ListTile(
              title: Text(days[index]),
              onTap: () {
                ref.read(employeesProvider.notifier).setWeekStartDay(index + 1);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }
}
