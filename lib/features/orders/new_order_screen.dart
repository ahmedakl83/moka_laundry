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
  final _carNumbersController = TextEditingController();
  final _carLettersController = TextEditingController();
  final _notesController = TextEditingController();
  final _paidAmountController = TextEditingController();

  CustomerModel? _selectedCustomer;
  List<ServiceModel> _selectedServices = [];
  OrderStatus _selectedStatus = OrderStatus.paid;

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

  void _submitOrder() {
    String carPlate = "${_carLettersController.text} ${_carNumbersController.text}".trim();
    if (carPlate.isEmpty || _selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال بيانات اللوحة واختيار خدمة واحدة على الأقل')),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serialNumber: ref.read(ordersProvider.notifier).generateSerialNumber(),
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name ?? 'عميل نقدي',
      carNumber: carPlate,
      services: _selectedServices,
      totalPrice: _totalPrice,
      paidAmount: _selectedStatus == OrderStatus.debt
          ? 0
          : (_selectedStatus == OrderStatus.paid ? _totalPrice : (double.tryParse(_paidAmountController.text) ?? 0)),
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
            const Text('العميل:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<CustomerModel>(
              value: _selectedCustomer,
              items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) => setState(() => _selectedCustomer = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            const Text('رقم اللوحة (مصر):', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _carLettersController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'حروف (أ ب ج)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _carNumbersController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'أرقام (1234)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const PlateScannerScreen()),
                    );
                    if (result != null) {
                      // محاولة تقسيم النتيجة لـ حروف وأرقام إذا أمكن
                      setState(() {
                        _carLettersController.text = result.replaceAll(RegExp(r'[0-9]'), '').trim();
                        _carNumbersController.text = result.replaceAll(RegExp(r'[^0-9]'), '').trim();
                      });
                    }
                  },
                  icon: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                  style: IconButton.styleFrom(backgroundColor: AppColors.lightBlue.withOpacity(0.2)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('الخدمات المطلوبة:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('$_totalPrice ج.م', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 24),

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

            if (_selectedStatus == OrderStatus.partiallyPaid) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع حالياً',
                  hintText: 'أدخل المبلغ',
                  border: OutlineInputBorder(),
                  suffixText: 'ج.م',
                ),
              ),
            ],
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
                child: const Text('تأكيد وحفظ الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
