import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../models/service_model.dart';
import 'services_provider.dart';

import '../auth/auth_provider.dart';
import '../../models/user_model.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الخدمات'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: services.isEmpty
            ? const Center(child: Text('لا توجد خدمات مسجلة'))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.lightBlue,
                        child: Icon(Icons.local_car_wash, color: AppColors.primaryBlue),
                      ),
                      title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: isAdmin
                        ? Text('القيمة: ${service.basePrice} + إكرامية: ${service.tip} = إجمالي: ${service.totalPrice} ج.م')
                        : Text('السعر الإجمالي: ${service.totalPrice} ج.م'),
                      trailing: isAdmin ? IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                        onPressed: () => _showServiceDialog(context, ref, service: service),
                      ) : null,
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceDialog(context, ref),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add_business, color: Colors.white),
      ),
    );
  }

  void _showServiceDialog(BuildContext context, WidgetRef ref, {ServiceModel? service}) {
    final nameController = TextEditingController(text: service?.name);
    final basePriceController = TextEditingController(text: service?.basePrice.toString());
    final tipController = TextEditingController(text: service?.tip.toString() ?? "0");
    final isEditing = service != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل الخدمة' : 'إضافة خدمة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الخدمة'),
            ),
            TextField(
              controller: basePriceController,
              decoration: const InputDecoration(labelText: 'قيمة الخدمة (ج.م)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: tipController,
              decoration: const InputDecoration(labelText: 'الإكرامية (ج.م)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          if (isEditing)
            TextButton(
              onPressed: () {
                ref.read(servicesProvider.notifier).deleteService(service.id);
                Navigator.pop(context);
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              final basePrice = double.tryParse(basePriceController.text) ?? 0.0;
              final tip = double.tryParse(tipController.text) ?? 0.0;
              if (name.isNotEmpty) {
                if (isEditing) {
                  ref.read(servicesProvider.notifier).updateService(
                        ServiceModel(id: service.id, name: name, basePrice: basePrice, tip: tip),
                      );
                } else {
                  ref.read(servicesProvider.notifier).addService(name, basePrice, tip);
                }
                Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'تحديث' : 'إضافة'),
          ),
        ],
      ),
    );
  }
}
