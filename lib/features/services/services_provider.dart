import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_model.dart';

final servicesProvider = StateNotifierProvider<ServicesNotifier, List<ServiceModel>>((ref) => ServicesNotifier());

class ServicesNotifier extends StateNotifier<List<ServiceModel>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ServicesNotifier() : super([]) {
    _loadServices();
  }

  void _loadServices() {
    _db.collection('services').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        _addDefaultServices();
      } else {
        state = snapshot.docs.map((doc) => ServiceModel.fromMap(doc.data())).toList();
      }
    });
  }

  Future<void> _addDefaultServices() async {
    final defaults = [
      ServiceModel(id: '1', name: 'غسيل خارجي', price: 20),
      ServiceModel(id: '2', name: 'غسيل كامل', price: 50),
      ServiceModel(id: '3', name: 'تلميع ساطع', price: 150),
    ];
    for (var s in defaults) {
      await _db.collection('services').doc(s.id).set(s.toMap());
    }
  }

  Future<void> addService(String name, double price) async {
    final docRef = _db.collection('services').doc();
    final newService = ServiceModel(id: docRef.id, name: name, price: price);
    await docRef.set(newService.toMap());
  }

  Future<void> updateService(ServiceModel updated) async {
    await _db.collection('services').doc(updated.id).update(updated.toMap());
  }

  Future<void> deleteService(String id) async {
    await _db.collection('services').doc(id).delete();
  }
}
