import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../core/constants.dart';
import '../../models/order_model.dart';
import 'orders_provider.dart';
import '../customers/customers_provider.dart';

class OperationsScreen extends ConsumerWidget {
  const OperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    // تصفية الطلبات النشطة فقط (غير المكتملة أو الملغاة)
    final activeOrders = orders.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة العمليات'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: activeOrders.isEmpty
            ? const Center(child: Text('لا توجد عمليات نشطة حالياً'))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: activeOrders.length,
                itemBuilder: (context, index) {
                  final order = activeOrders[index];
                  return _buildOrderCard(context, ref, order);
                },
              ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, OrderModel order) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text('${order.customerName} - ${order.carNumber ?? "بدون رقم"}'),
        subtitle: Text('الحالة: ${_getStatusText(order.status)}'),
        leading: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                        child: Icon(Icons.edit, color: Colors.white, size: 30),
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _showEditPlateDialog(context, ref, order),
                    icon: const Icon(Icons.edit),
                    label: const Text('إدخال رقم اللوحة'),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(context, ref, order, OrderStatus.washing, 'غسيل', Colors.blue),
                    _buildActionButton(context, ref, order, OrderStatus.ready, 'جاهزة', Colors.orange),
                    _buildActionButton(context, ref, order, OrderStatus.completed, 'تسليم', Colors.green),
                  ],
                ),
                const Divider(),
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
        // تحديث حالة الطلب
        // سنضيف هذه الميزة في OrdersProvider
        ref.read(ordersProvider.notifier).updateOrderStatus(order.id, targetStatus);
      },
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      child: Text(label),
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
      default: return Icons.done_all;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.grey;
      case OrderStatus.washing: return Colors.blue;
      case OrderStatus.ready: return Colors.orange;
      default: return Colors.green;
    }
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
                    const Text('يمكنك تكبير الصورة باللمس لرؤية الرقم بوضوح', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      height: 300, // زيادة الارتفاع
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

  void _notifyCustomer(BuildContext context, WidgetRef ref, OrderModel order) async {
    final customers = ref.read(customersProvider);
    final customer = customers.firstWhere((c) => c.id == order.customerId, orElse: () => throw "العميل غير موجود");

    // تحويل رقم الهاتف لصيغة دولية إذا كان مصرياً يبدأ بـ 01
    String phone = customer.phone.trim();
    if (phone.startsWith('01')) {
      phone = '2$phone';
    } else if (phone.startsWith('1')) {
      phone = '20$phone';
    }

    final message = "مرحباً ${customer.name}، سيارتك رقم (${order.carNumber ?? ''}) أصبحت جاهزة للتسليم في مغسلة Moka. شكراً لتعاملكم معنا.";

    // محاولة فتح واتساب مباشرة أولاً
    final whatsappUrl = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
    final webUrl = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        // إذا فشل كلاهما، نحاول الفتح القسري للرابط الإلكتروني
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب، يرجى التأكد من تثبيت التطبيق')));
      }
    }
  }
}
