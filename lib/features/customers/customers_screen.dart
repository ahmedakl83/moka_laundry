import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../models/customer_model.dart';
import 'customers_provider.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العملاء'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: customers.isEmpty
            ? const Center(child: Text('لا يوجد عملاء مسجلين'))
            : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('رقم الهاتف: ${customer.phone}'),
                      trailing: Text(
                        'الدين: ${customer.balance} ج.م',
                        style: TextStyle(
                          color: customer.balance > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _showCustomerDialog(context, ref, customer: customer),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerDialog(context, ref),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, WidgetRef ref, {CustomerModel? customer}) {
    final nameController = TextEditingController(text: customer?.name);
    final phoneController = TextEditingController(text: customer?.phone);
    final isEditing = customer != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل بيانات العميل' : 'إضافة عميل جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم العميل'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              keyboardType: TextInputType.phone,
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
              if (nameController.text.isNotEmpty) {
                if (isEditing) {
                  ref.read(customersProvider.notifier).updateCustomer(
                        CustomerModel(
                          id: customer.id,
                          name: nameController.text,
                          phone: phoneController.text,
                          balance: customer.balance,
                        ),
                      );
                } else {
                  ref.read(customersProvider.notifier).addCustomer(
                        nameController.text,
                        phoneController.text,
                      );
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
