import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/retailer_order_model.dart';
import '../repositories/retailer_orders_repository.dart';

final retailerOrdersProvider = StreamProvider<List<RetailerOrder>>((ref) {
  final repo = ref.watch(retailerOrdersRepositoryProvider);
  return repo.watchOrders();
});

class RetailerOrderActionNotifier extends Notifier<bool> {
  @override
  bool build() => false; // isUpdating

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
