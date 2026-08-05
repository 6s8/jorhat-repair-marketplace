import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/retailer_order_model.dart';
import '../models/appliance_order_model.dart';
import '../repositories/retailer_orders_repository.dart';
import '../repositories/appliance_orders_repository.dart';

// --- Spare Part Orders ---
final retailerOrdersProvider = StreamProvider<List<RetailerOrder>>((ref) {
  final repo = ref.watch(retailerOrdersRepositoryProvider);
  return repo.watchOrders();
});

class RetailerOrderActionNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  Future<void> updateStatus(String orderId, String newStatus) async {
    final oldState = state;
    state = {...state, orderId: newStatus};
    try {
      final repo = ref.read(retailerOrdersRepositoryProvider);
      await repo.updateOrderStatus(orderId, newStatus);
    } catch (e) {
      state = oldState;
      rethrow;
    }
  }
}

final retailerOrderActionProvider =
    NotifierProvider<RetailerOrderActionNotifier, Map<String, String>>(
  () => RetailerOrderActionNotifier(),
);

// --- Appliance Orders ---
final applianceOrdersProvider = StreamProvider<List<ApplianceOrder>>((ref) {
  final repo = ref.watch(applianceOrdersRepositoryProvider);
  return repo.watchOrders();
});

class ApplianceOrderActionNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  Future<void> updateStatus(String orderId, String newStatus) async {
    final oldState = state;
    state = {...state, orderId: newStatus};
    try {
      final repo = ref.read(applianceOrdersRepositoryProvider);
      await repo.updateOrderStatus(orderId, newStatus);
    } catch (e) {
      state = oldState;
      rethrow;
    }
  }
}

final applianceOrderActionProvider =
    NotifierProvider<ApplianceOrderActionNotifier, Map<String, String>>(
  () => ApplianceOrderActionNotifier(),
);
