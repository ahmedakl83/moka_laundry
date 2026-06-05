import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/service_model.dart';

final servicesProvider = StateNotifierProvider<ServicesNotifier, List<ServiceModel>>((ref) {
  return ServicesNotifier();
});

class ServicesNotifier extends StateNotifier<List<ServiceModel>> {
  ServicesNotifier() : super([]) {
    _loadServices();
  }

  void _loadServices() {
    // خدمات افتراضية
    state = [
      ServiceModel(id: '1', name: 'غسيل خارجي', price: 20),
      ServiceModel(id: '2', name: 'غسيل كامل', price: 50),
      ServiceModel(id: '3', name: 'تلميع ساطع', price: 150),
    ];
  }

  void addService(String name, double price) {
    final newService = ServiceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      price: price,
    );
    state = [...state, newService];
  }

  void updateService(ServiceModel updatedService) {
    state = [
      for (final service in state)
        if (service.id == updatedService.id) updatedService else service
    ];
  }

  void deleteService(String id) {
    state = state.where((service) => service.id != id).toList();
  }
}
