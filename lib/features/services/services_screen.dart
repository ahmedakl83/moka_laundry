import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../models/service_model.dart';
import 'services_provider.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);

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
                      subtitle: Text('السعر: ${service.price} ج.م'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                        onPressed: () => _showServiceDialog(context, ref, service: service),
                      ),
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
    final priceController = TextEditingController(text: service?.price.toString());
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
              controller: priceController,
              decoration: const InputDecoration(labelText: 'السعر (ج.م)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              final price = double.tryParse(priceController.text) ?? 0.0;
              if (name.isNotEmpty) {
                if (isEditing) {
                  ref.read(servicesProvider.notifier).updateService(
                        ServiceModel(id: service.id, name: name, price: price),
                      );
                } else {
                  ref.read(servicesProvider.notifier).addService(name, price);
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
