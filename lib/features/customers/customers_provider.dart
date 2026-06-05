import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/customer_model.dart';

final customersProvider = StateNotifierProvider<CustomersNotifier, List<CustomerModel>>((ref) {
  return CustomersNotifier();
});

class CustomersNotifier extends StateNotifier<List<CustomerModel>> {
  CustomersNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final customersJson = prefs.getString('customers_list');

    if (customersJson != null) {
      final List decoded = json.decode(customersJson);
      state = decoded.map((c) => CustomerModel.fromMap(c)).toList();
    } else {
      // الحالة الافتراضية عند أول تشغيل
      state = [
        CustomerModel(id: '1', name: 'عميل نقدي', phone: '0000000000', balance: 0),
      ];
      _saveCustomers();
    }
  }

  Future<void> _saveCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(state.map((c) => c.toMap()).toList());
    await prefs.setString('customers_list', encoded);
  }

  CustomerModel addCustomer(String name, String phone) {
    final newCustomer = CustomerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phone,
    );
    state = [...state, newCustomer];
    _saveCustomers();
    return newCustomer;
  }

  void updateCustomer(CustomerModel updatedCustomer) {
    state = [
      for (final customer in state)
        if (customer.id == updatedCustomer.id) updatedCustomer else customer
    ];
    _saveCustomers();
  }

  void deleteCustomer(String id) {
    state = state.where((customer) => customer.id != id).toList();
    _saveCustomers();
  }
}
