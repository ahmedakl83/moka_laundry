import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer_model.dart';

// ملاحظة: هذا الـ Provider سيتم ربطه بـ Firestore لاحقاً
final customersProvider = StateNotifierProvider<CustomersNotifier, List<CustomerModel>>((ref) {
  return CustomersNotifier();
});

class CustomersNotifier extends StateNotifier<List<CustomerModel>> {
  CustomersNotifier() : super([]) {
    _loadCustomers();
  }

  void _loadCustomers() {
    // محاكاة تحميل البيانات
    state = [
      CustomerModel(id: '1', name: 'عميل نقدي', phone: '0000000000', balance: 0),
    ];
  }

  void addCustomer(String name, String phone) {
    final newCustomer = CustomerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phone,
    );
    state = [...state, newCustomer];
  }

  void updateCustomer(CustomerModel updatedCustomer) {
    state = [
      for (final customer in state)
        if (customer.id == updatedCustomer.id) updatedCustomer else customer
    ];
  }

  void deleteCustomer(String id) {
    state = state.where((customer) => customer.id != id).toList();
  }
}
