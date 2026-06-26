import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../models/customer_model.dart';
import 'customers_provider.dart';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  Future<void> _pickFromContacts(BuildContext context, TextEditingController nameCtrl, TextEditingController phoneCtrl) async {
    if (await Permission.contacts.request().isGranted) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        final fullContact = await FlutterContacts.getContact(contact.id);
        if (fullContact != null) {
          nameCtrl.text = fullContact.displayName;
          if (fullContact.phones.isNotEmpty) {
            if (fullContact.phones.length == 1) {
              phoneCtrl.text = fullContact.phones.first.number;
            } else {
              final selectedPhone = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('اختر رقم الهاتف'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: fullContact.phones.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(fullContact.phones[index].number),
                        subtitle: Text(fullContact.phones[index].label.name),
                        onTap: () => Navigator.pop(context, fullContact.phones[index].number),
                      ),
                    ),
                  ),
                ),
              );
              if (selectedPhone != null) {
                phoneCtrl.text = selectedPhone;
              }
            }
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب منح صلاحية الوصول لجهات الاتصال')));
    }
  }

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
                padding: const EdgeInsets.only(bottom: 80),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEditing ? 'تعديل بيانات العميل' : 'إضافة عميل جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _pickFromContacts(context, nameController, phoneController);
                      setStateDialog(() {});
                    },
                    icon: const Icon(Icons.contact_phone),
                    label: const Text('اختيار من جهات الاتصال'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ),
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
      ),
    );
  }
}
