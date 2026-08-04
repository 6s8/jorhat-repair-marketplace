import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/retailer_order_model.dart';
import '../../../core/supabase/supabase_client.dart';

final retailerOrdersRepositoryProvider =
    Provider<RetailerOrdersRepository>((ref) {
  return SupabaseRetailerOrdersRepository();
});

abstract class RetailerOrdersRepository {
  Stream<List<RetailerOrder>> watchOrders();
  Future<void> updateOrderStatus(String orderId, String status);
}

class SupabaseRetailerOrdersRepository implements RetailerOrdersRepository {
  final SupabaseClient _client = supabase;

  @override
  Stream<List<RetailerOrder>> watchOrders() {
    return _client
        .from('spare_part_orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => RetailerOrder.fromJson(row)).toList());
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client
        .from('spare_part_orders')
        .update({'status': status})
        .eq('id', orderId);
  }
}
