import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/customer_model.dart';

final customersProvider = StateNotifierProvider<CustomersNotifier, List<CustomerModel>>((ref) {
  return CustomersNotifier();
});

class CustomersNotifier extends StateNotifier<List<CustomerModel>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CustomersNotifier() : super([]) {
    _init();
  }

  void _init() {
    _db.collection('customers').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        // إضافة عميل نقدي افتراضي إذا كانت القائمة فارغة
        addCustomer('عميل نقدي', '0000000000');
      } else {
        state = snapshot.docs.map((doc) => CustomerModel.fromMap(doc.data())).toList();
      }
    });
  }

  CustomerModel addCustomer(String name, String phone) {
    final docRef = _db.collection('customers').doc();
    final newCustomer = CustomerModel(
      id: docRef.id,
      name: name,
      phone: phone,
      balance: 0.0,
    );
    docRef.set(newCustomer.toMap());
    return newCustomer;
  }

  Future<void> updateCustomer(CustomerModel updated) async {
    await _db.collection('customers').doc(updated.id).update(updated.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    await _db.collection('customers').doc(id).delete();
  }
}
