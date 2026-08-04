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

class RetailerOrderActionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> updateStatus(String orderId, String newStatus) async {
    state = true;
    try {
      final repo = ref.read(retailerOrdersRepositoryProvider);
      await repo.updateOrderStatus(orderId, newStatus);
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }
}

final retailerOrderActionProvider =
    NotifierProvider<RetailerOrderActionNotifier, bool>(
  () => RetailerOrderActionNotifier(),
);

// --- Appliance Orders ---
final applianceOrdersProvider = StreamProvider<List<ApplianceOrder>>((ref) {
  final repo = ref.watch(applianceOrdersRepositoryProvider);
  return repo.watchOrders();
});

class ApplianceOrderActionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> updateStatus(String orderId, String newStatus) async {
    state = true;
    try {
      final repo = ref.read(applianceOrdersRepositoryProvider);
      await repo.updateOrderStatus(orderId, newStatus);
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }
}

final applianceOrderActionProvider =
    NotifierProvider<ApplianceOrderActionNotifier, bool>(
  () => ApplianceOrderActionNotifier(),
);
