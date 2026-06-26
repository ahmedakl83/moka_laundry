import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants.dart';
import '../../models/customer_model.dart';
import '../../models/order_model.dart';
import '../../models/service_model.dart';
import '../customers/customers_provider.dart';
import '../services/services_provider.dart';
import '../auth/auth_provider.dart';
import '../ocr/plate_scanner_screen.dart';
import 'orders_provider.dart';
import '../../core/plate_formatter.dart';

class NewOrderScreen extends ConsumerStatefulWidget {
  const NewOrderScreen({super.key});

  @override
  ConsumerState<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends ConsumerState<NewOrderScreen> {
  final _carNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _customerSearchController = TextEditingController();
  String? _capturedImagePath;

  CustomerModel? _selectedCustomer;
  List<ServiceModel> _selectedServices = [];
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  double get _totalPrice => _selectedServices.fold(0, (sum, item) => sum + item.totalPrice);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customers = ref.read(customersProvider);
      if (customers.isNotEmpty) {
        setState(() {
          _selectedCustomer = customers.first;
          _customerSearchController.text = _selectedCustomer!.name;
        });
      }
    });
  }

  Future<void> _pickFromContacts(TextEditingController nameCtrl, TextEditingController phoneCtrl) async {
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
              if (mounted) {
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
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب منح صلاحية الوصول لجهات الاتصال')));
      }
    }
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('إضافة عميل جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _pickFromContacts(nameController, phoneController);
                  setStateDialog(() {});
                },
                icon: const Icon(Icons.contact_phone),
                label: const Text('اختيار من جهات الاتصال'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العميل')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', suffixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newCustomer = ref.read(customersProvider.notifier).addCustomer(
                    nameController.text,
                    phoneController.text,
                  );
                  setState(() {
                    _selectedCustomer = newCustomer;
                    _customerSearchController.text = newCustomer.name;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitOrder() {
    // التحقق من حالة العميل إذا كان هناك نص مكتوب ولم يتم الاختيار
    if (_selectedCustomer == null && _customerSearchController.text.isNotEmpty) {
      final customers = ref.read(customersProvider);
      final match = customers.where((c) => c.name.trim() == _customerSearchController.text.trim()).toList();

      if (match.length == 1) {
        _selectedCustomer = match.first;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار العميل من القائمة الظاهرة أو الضغط على زر إضافة عميل جديد'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_capturedImagePath == null && _carNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تصوير اللوحة أو إدخال رقم السيارة')),
      );
      return;
    }
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار خدمة واحدة على الأقل')));
      return;
    }

    final user = ref.read(authProvider).user;
    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serialNumber: ref.read(ordersProvider.notifier).generateSerialNumber(),
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name ?? 'عميل نقدي',
      carNumber: _carNumberController.text.isEmpty ? null : _carNumberController.text,
      carPlateImagePath: _capturedImagePath,
      services: _selectedServices,
      totalPrice: _totalPrice,
      status: OrderStatus.pending,
      paymentMethod: PaymentMethod.pending,
      notes: _notesController.text,
      userId: user?.id ?? '',
      createdAt: DateTime.now(),
    );

    ref.read(ordersProvider.notifier).addOrder(order);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الطلب بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final services = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل طلب جديد'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم العميل
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('العميل:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Autocomplete<CustomerModel>(
                          displayStringForOption: (CustomerModel c) => c.name,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return customers;
                            }
                            return customers.where((CustomerModel c) {
                              return c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                     c.phone.contains(textEditingValue.text);
                            });
                          },
                          onSelected: (CustomerModel c) {
                            setState(() => _selectedCustomer = c);
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            // ربط المتحكم الخارجي بالمتحكم الخاص بالـ Autocomplete
                            if (_customerSearchController.text.isNotEmpty && controller.text.isEmpty) {
                               controller.text = _customerSearchController.text;
                            }
                            controller.addListener(() {
                              _customerSearchController.text = controller.text;
                            });

                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                hintText: 'ابحث باسم العميل أو رقمه...',
                                prefixIcon: Icon(Icons.search),
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topRight,
                              child: Material(
                                elevation: 4.0,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width * 0.7),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final CustomerModel option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.name),
                                        subtitle: Text(option.phone),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: IconButton.filled(
                      onPressed: _showAddCustomerDialog,
                      icon: const Icon(Icons.person_add),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // قسم صورة اللوحة
              const Text('صورة لوحة السيارة:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const PlateScannerScreen()),
                  );
                  if (result != null) {
                    setState(() => _capturedImagePath = result);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                  ),
                  child: _capturedImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_capturedImagePath!), fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_enhance, size: 50, color: AppColors.primaryBlue),
                            SizedBox(height: 8),
                            Text('اضغط لتصوير اللوحة'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _carNumberController,
                inputFormatters: [PlateNumberFormatter()],
                style: const TextStyle(fontFamily: 'Calibri', fontWeight: FontWeight.bold, fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'رقم السيارة (اختياري حالياً)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
              ),
              const SizedBox(height: 24),

              // قسم الخدمات
              const Text('الخدمات المطلوب تنفيذها:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: services.map((s) {
                  final isSelected = _selectedServices.contains(s);
                  return FilterChip(
                    label: Text('${s.name} (${s.price} ج.م)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServices.add(s);
                        } else {
                          _selectedServices.remove(s);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // الإجمالي
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي الحساب المبدئي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('$_totalPrice ج.م', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('بدء العملية وحفظ الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
