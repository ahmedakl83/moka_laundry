import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../../models/user_model.dart';
import '../customers/customers_screen.dart';
import '../services/services_screen.dart';
import '../orders/new_order_screen.dart';
import '../expenses/expenses_screen.dart';
import '../reports/reports_screen.dart';
import '../auth/users_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلاً بك يا ${user?.name ?? 'مستخدم'}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin ? 'لوحة تحكم المدير' : 'لوحة إدخال البيانات اليومية',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    title: 'تسجيل طلب',
                    icon: Icons.add_shopping_cart,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NewOrderScreen()));
                    },
                  ),
                  _buildMenuCard(
                    context,
                    title: 'العملاء',
                    icon: Icons.people,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()));
                    },
                  ),
                  if (isAdmin) ...[
                    _buildMenuCard(
                      context,
                      title: 'الخدمات',
                      icon: Icons.local_car_wash,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesScreen()));
                      },
                    ),
                    _buildMenuCard(
                      context,
                      title: 'المصروفات',
                      icon: Icons.money_off,
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
                      },
                    ),
                    _buildMenuCard(
                      context,
                      title: 'التقارير',
                      icon: Icons.bar_chart,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                      },
                    ),
                    _buildMenuCard(
                      context,
                      title: 'الموظفين',
                      icon: Icons.badge,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
