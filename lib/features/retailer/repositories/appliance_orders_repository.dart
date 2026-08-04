import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appliance_order_model.dart';
import '../../../core/supabase/supabase_client.dart';

final applianceOrdersRepositoryProvider =
    Provider<ApplianceOrdersRepository>((ref) {
  return SupabaseApplianceOrdersRepository();
});

abstract class ApplianceOrdersRepository {
  Stream<List<ApplianceOrder>> watchOrders();
  Future<void> updateOrderStatus(String orderId, String status);
}

class SupabaseApplianceOrdersRepository implements ApplianceOrdersRepository {
  final SupabaseClient _client = supabase;

  @override
  Stream<List<ApplianceOrder>> watchOrders() {
    try {
      return _client
          .from('appliance_orders')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((rows) => rows.map((r) => ApplianceOrder.fromJson(r)).toList())
          .handleError((_) => <ApplianceOrder>[]);
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _client
          .from('appliance_orders')
          .update({'status': status}).eq('id', orderId);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') return; // table not yet created
      rethrow;
    }
  }
}
