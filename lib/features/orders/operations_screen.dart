import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
