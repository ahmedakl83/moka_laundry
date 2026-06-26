import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../core/constants.dart';
import '../../models/order_model.dart';
import 'orders_provider.dart';
import '../customers/customers_provider.dart';
import '../services/services_provider.dart';
import '../../models/service_model.dart';
import '../../core/plate_formatter.dart';

class OperationsScreen extends ConsumerWidget {
  const OperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final services = ref.watch(servicesProvider);

    // تصفية العمليات وترتيبها زمنياً (الأقدم أولاً)
    final pendingOrders = orders
        .where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.washing)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final readyOrders = orders
        .where((o) => o.status == OrderStatus.ready)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final completedOrders = orders
        .where((o) => o.status == OrderStatus.completed)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة العمليات'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSectionHeader('العمليات قيد الانتظار / الغسيل', Colors.grey.shade700, pendingOrders.length),
              ...pendingOrders.map((order) => _buildOrderCard(context, ref, order, services, Colors.blue.shade50)),

              _buildSectionHeader('جاهزة للتسليم', Colors.orange.shade800, readyOrders.length),
              ...readyOrders.map((order) => _buildOrderCard(context, ref, order, services, Colors.orange.shade50)),

              _buildSectionHeader('تم التسليم', Colors.green.shade800, completedOrders.length),
              ...completedOrders.map((order) => _buildOrderCard(context, ref, order, services, Colors.green.shade50)),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, OrderModel order, List<ServiceModel> allServices, Color bgColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: bgColor,
      child: ExpansionTile(
        title: Text(
          '${order.customerName} - ${order.carNumber ?? "بدون رقم"}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('الحالة: ${_getStatusText(order.status)} | الإجمالي: ${order.totalPrice} ج.م'),
        leading: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.carPlateImagePath != null)
                  GestureDetector(
                    onTap: () => _showEditPlateDialog(context, ref, order),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(order.carPlateImagePath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.zoom_in, color: Colors.white, size: 30),
                      ),
                    ),
                  )
                else if (order.status != OrderStatus.completed)
                  TextButton.icon(
                    onPressed: () => _showEditPlateDialog(context, ref, order),
                    icon: const Icon(Icons.edit),
                    label: const Text('إدخال رقم اللوحة'),
                  ),

                const Text('الخدمات:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  children: order.services.map((s) => Chip(
                    label: Text('${s.name} (${s.totalPrice} ج.م)', style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                  )).toList(),
                ),

                if (order.status != OrderStatus.completed)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _showAddServiceDialog(context, ref, order, allServices),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('إضافة خدمة إضافية'),
                    ),
                  ),

                const Divider(),
                if (order.status != OrderStatus.completed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(context, ref, order, OrderStatus.washing, 'غسيل', Colors.blue),
                      _buildActionButton(context, ref, order, OrderStatus.ready, 'جاهزة', Colors.orange),
                      _buildDeliveryButton(context, ref, order),
                    ],
                  ),
                if (order.status != OrderStatus.completed)
                  const Divider(),
                if (order.status != OrderStatus.completed)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _notifyCustomer(context, ref, order),
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('تنبيه العميل (واتساب)'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, OrderModel order, OrderStatus targetStatus, String label, Color color) {
    bool isCurrent = order.status == targetStatus;
    return ElevatedButton(
      onPressed: isCurrent ? null : () {
        ref.read(ordersProvider.notifier).updateOrderStatus(order.id, targetStatus);
      },
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      child: Text(label),
    );
  }

  Widget _buildDeliveryButton(BuildContext context, WidgetRef ref, OrderModel order) {
    return ElevatedButton(
      onPressed: () => _showDeliveryDialog(context, ref, order),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
      child: const Text('تسليم'),
    );
  }

  void _showDeliveryDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    PaymentMethod selectedMethod = PaymentMethod.cash;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إتمام التسليم والدفع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إجمالي الحساب النهائي: ${order.totalPrice} ج.م', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('اختر طريقة الدفع:'),
              RadioListTile<PaymentMethod>(
                title: const Text('نقدي'),
                value: PaymentMethod.cash,
                groupValue: selectedMethod,
                onChanged: (val) => setState(() => selectedMethod = val!),
              ),
              RadioListTile<PaymentMethod>(
                title: const Text('تحويل محفظة'),
                value: PaymentMethod.wallet,
                groupValue: selectedMethod,
                onChanged: (val) => setState(() => selectedMethod = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                ref.read(ordersProvider.notifier).updateOrderStatus(order.id, OrderStatus.completed, paymentMethod: selectedMethod);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إتمام الطلب بنجاح')));
              },
              child: const Text('تأكيد التسليم'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context, WidgetRef ref, OrderModel order, List<ServiceModel> allServices) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة خدمة للطلب'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allServices.length,
            itemBuilder: (context, index) {
              final service = allServices[index];
              return ListTile(
                title: Text(service.name),
                subtitle: Text('${service.totalPrice} ج.م'),
                onTap: () {
                  ref.read(ordersProvider.notifier).addServiceToOrder(order.id, service);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditPlateDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    final controller = TextEditingController(text: order.carNumber);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل رقم اللوحة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (order.carPlateImagePath != null)
                Column(
                  children: [
                    const Text('يمكنك تكبير الصورة باللمس لرؤية الرقم بوضوح', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      height: 300,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: InteractiveViewer(
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(20),
                          minScale: 0.5,
                          maxScale: 4,
                          child: Image.file(
                            File(order.carPlateImagePath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              TextField(
                controller: controller,
                inputFormatters: [PlateNumberFormatter()],
                style: const TextStyle(fontFamily: 'Calibri', fontWeight: FontWeight.bold, fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'رقم السيارة',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              ref.read(ordersProvider.notifier).updateCarNumber(order.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'قيد الانتظار';
      case OrderStatus.washing: return 'جاري الغسيل';
      case OrderStatus.ready: return 'جاهزة للتسليم';
      case OrderStatus.completed: return 'تم التسليم';
      default: return 'ملغي';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.timer;
      case OrderStatus.washing: return Icons.local_car_wash;
      case OrderStatus.ready: return Icons.check_circle_outline;
      case OrderStatus.completed: return Icons.done_all;
      default: return Icons.cancel;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.grey;
      case OrderStatus.washing: return Colors.blue;
      case OrderStatus.ready: return Colors.orange;
      case OrderStatus.completed: return Colors.green;
      default: return Colors.red;
    }
  }

  void _notifyCustomer(BuildContext context, WidgetRef ref, OrderModel order) async {
    final customers = ref.read(customersProvider);
    final customerList = customers.where((c) => c.id == order.customerId);
    if (customerList.isEmpty) return;

    final customer = customerList.first;

    String phone = customer.phone.trim();
    if (phone.startsWith('01')) {
      phone = '2$phone';
    } else if (phone.startsWith('1')) {
      phone = '20$phone';
    }

    // بناء سرد الخدمات
    String servicesList = "";
    for (var s in order.services) {
      servicesList += "\n- ${s.name}: ${s.totalPrice} ج.م";
    }

    String carInfo = order.carNumber != null && order.carNumber!.isNotEmpty
        ? "سيارتك رقم (${order.carNumber})"
        : "سيارتك";

    final message = "مرحبا ${customer.name}، $carInfo أصبحت جاهزة للتسليم في مغسلة Moka.\n\nالخدمات التي تمت:$servicesList\n\nإجمالي الحساب: ${order.totalPrice} ج.م\nشكراً لتعاملكم معنا.";

    final whatsappUrl = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
    final webUrl = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب')));
      }
    }
  }
}
