import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import 'auth_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // في الوضع الحالي بدون Firebase، سنعرض فقط المدير
    // لاحقاً سنضيف قائمة الموظفين من Firestore
    final admin = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (admin != null)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
                title: Text(admin.name),
                subtitle: Text('مدير النظام - @${admin.username}'),
                trailing: const Badge(label: Text('مسؤول')),
              ),
            ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'ميزة إضافة موظفين جدد ستفعل عند ربط Firebase',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى ربط Firebase لإضافة موظفين إضافيين')),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
