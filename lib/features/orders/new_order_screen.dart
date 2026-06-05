import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../core/constants.dart';
import '../../models/customer_model.dart';
import '../../models/order_model.dart';
import '../../models/service_model.dart';
import '../customers/customers_provider.dart';
import '../services/services_provider.dart';
import '../auth/auth_provider.dart';
import '../ocr/plate_scanner_screen.dart';
import 'orders_provider.dart';

class NewOrderScreen extends ConsumerStatefulWidget {
  const NewOrderScreen({super.key});

  @override
  ConsumerState<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends ConsumerState<NewOrderScreen> {
  final _carNumberController = TextEditingController();
  final _notesController = TextEditingController();
  String? _capturedImagePath;

  CustomerModel? _selectedCustomer;
  List<ServiceModel> _selectedServices = [];
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  double get _totalPrice => _selectedServices.fold(0, (sum, item) => sum + item.price);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customers = ref.read(customersProvider);
      if (customers.isNotEmpty) {
        setState(() => _selectedCustomer = customers.first);
      }
    });
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عميل جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العميل')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
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
                setState(() => _selectedCustomer = newCustomer);
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _submitOrder() {
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
      paymentMethod: _paymentMethod,
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
                      DropdownButtonFormField<CustomerModel>(
                        value: customers.contains(_selectedCustomer) ? _selectedCustomer : (customers.isNotEmpty ? customers.first : null),
                        isExpanded: true,
                        items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                        onChanged: (val) => setState(() => _selectedCustomer = val),
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
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
                  const Text('إجمالي الحساب:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$_totalPrice ج.م', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // طريقة الدفع
            const Text('طريقة الدفع (بالكامل):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('نقدي')),
                    selected: _paymentMethod == PaymentMethod.cash,
                    onSelected: (val) => setState(() => _paymentMethod = PaymentMethod.cash),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('تحويل محفظة')),
                    selected: _paymentMethod == PaymentMethod.wallet,
                    onSelected: (val) => setState(() => _paymentMethod = PaymentMethod.wallet),
                  ),
                ),
              ],
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
            const SizedBox(height: 50), // مساحة إضافية كبيرة لضمان عدم التداخل
          ],
        ),
      ),
    );
  }
}
