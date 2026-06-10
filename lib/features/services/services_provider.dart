import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/service_model.dart';

final servicesProvider = StateNotifierProvider<ServicesNotifier, List<ServiceModel>>((ref) => ServicesNotifier());

class ServicesNotifier extends StateNotifier<List<ServiceModel>> {
  ServicesNotifier() : super([]) {
    _loadServices();
  }

  Future<void> _loadServices() async {
    final prefs = await SharedPreferences.getInstance();
    final json_ = prefs.getString('services_list');
    if (json_ != null) {
      state = (json.decode(json_) as List).map((s) => ServiceModel.fromMap(s)).toList();
    } else {
      state = [
        ServiceModel(id: '1', name: 'غسيل خارجي', price: 20),
        ServiceModel(id: '2', name: 'غسيل كامل', price: 50),
        ServiceModel(id: '3', name: 'تلميع ساطع', price: 150),
      ];
      _saveServices();
    }
  }

  Future<void> _saveServices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('services_list', json.encode(state.map((s) => s.toMap()).toList()));
  }

  void addService(String name, double price) {
    state = [...state, ServiceModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, price: price)];
    _saveServices();
  }

  void updateService(ServiceModel updated) {
    state = [for (final s in state) if (s.id == updated.id) updated else s];
    _saveServices();
  }

  void deleteService(String id) {
    state = state.where((s) => s.id != id).toList();
    _saveServices();
  }
}
