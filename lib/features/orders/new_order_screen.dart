import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _paidAmountController = TextEditingController();

  CustomerModel? _selectedCustomer;
  List<ServiceModel> _selectedServices = [];
  OrderStatus _selectedStatus = OrderStatus.paid;

  double get _totalPrice => _selectedServices.fold(0, (sum, item) => sum + item.price);

  @override
  void initState() {
    super.initState();
    // العميل الافتراضي هو أول واحد (غالباً عميل نقدي)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customers = ref.read(customersProvider);
      if (customers.isNotEmpty) {
        setState(() => _selectedCustomer = customers.first);
      }
    });
  }

  void _submitOrder() {
    if (_carNumberController.text.isEmpty || _selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم اللوحة واختيار خدمة واحدة على الأقل')),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serialNumber: ref.read(ordersProvider.notifier).generateSerialNumber(),
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name ?? 'عميل نقدي',
      carNumber: _carNumberController.text,
      services: _selectedServices,
      totalPrice: _totalPrice,
      paidAmount: double.tryParse(_paidAmountController.text) ?? _totalPrice,
      status: _selectedStatus,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم العميل
            const Text('العميل:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<CustomerModel>(
              value: _selectedCustomer,
              items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) => setState(() => _selectedCustomer = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // قسم رقم اللوحة مع OCR
            const Text('رقم اللوحة:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _carNumberController,
                    decoration: const InputDecoration(
                      hintText: 'أدخل رقم السيارة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const PlateScannerScreen()),
                    );
                    if (result != null) {
                      setState(() => _carNumberController.text = result);
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('تصوير'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // قسم الخدمات
            const Text('الخدمات المطلوبة:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: services.map((s) {
                final isSelected = _selectedServices.contains(s);
                return FilterChip(
                  label: Text('${s.name} (${s.price} ريال)'),
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

            // الحساب الإجمالي
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي المستحق:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$_totalPrice ريال', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // حالة الدفع
            const Text('حالة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
            SegmentedButton<OrderStatus>(
              segments: const [
                ButtonSegment(value: OrderStatus.paid, label: Text('مدفوع')),
                ButtonSegment(value: OrderStatus.partiallyPaid, label: Text('جزئي')),
                ButtonSegment(value: OrderStatus.debt, label: Text('دين')),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (set) => setState(() => _selectedStatus = set.first),
            ),
            const SizedBox(height: 32),

            // زر الحفظ
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
                child: const Text('تأكيد وحفظ الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
