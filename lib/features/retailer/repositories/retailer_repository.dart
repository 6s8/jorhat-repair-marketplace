import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/spare_part_model.dart';
import '../../../core/supabase/supabase_client.dart';

final retailerRepositoryProvider = Provider<RetailerRepository>((ref) {
  return SupabaseRetailerRepository();
});

abstract class RetailerRepository {
  Stream<List<SparePart>> watchParts();
  Future<List<SparePart>> getParts();
  Future<void> addPart(SparePart part);
  Future<void> updatePart(SparePart part);
  Future<void> deletePart(String partId);
}

class SupabaseRetailerRepository implements RetailerRepository {
  final SupabaseClient _client = supabase;

  @override
  Stream<List<SparePart>> watchParts() {
    final controller = StreamController<List<SparePart>>();

    getParts().then((parts) {
      if (!controller.isClosed) controller.add(parts);
    }).catchError((_) {
      if (!controller.isClosed) controller.add([]);
    });

    try {
      final sub = _client
          .from('jobs')
          .stream(primaryKey: ['id'])
          .listen((data) async {
        if (!controller.isClosed) {
          final parts = await getParts();
          controller.add(parts);
        }
      }, onError: (_) {});

      controller.onCancel = () {
        sub.cancel();
        controller.close();
      };
    } catch (_) {}

    return controller.stream;
  }

  @override
  Future<List<SparePart>> getParts() async {
    final map = <String, SparePart>{};

    // 1. Fetch from jobs table (status = marketplace_item)
    try {
      final List<dynamic> jobRows = await _client
          .from('jobs')
          .select()
          .eq('status', 'marketplace_item')
          .order('created_at', ascending: false);

      for (final row in jobRows) {
        final issueStr = row['issue']?.toString() ?? '';
        if (issueStr.startsWith('MARKETPLACE_PART:')) {
          try {
            final jsonRaw = jsonDecode(issueStr.replaceFirst('MARKETPLACE_PART:', ''));
            final part = SparePart.fromJson(Map<String, dynamic>.from(jsonRaw as Map));
            map[part.id] = part;
          } catch (_) {}
        }
      }
    } catch (_) {}

    // 2. Fetch from spare_parts table
    try {
      final List<dynamic> dbRows = await _client
          .from('spare_parts')
          .select()
          .order('created_at', ascending: false);

      for (final row in dbRows) {
        final part = SparePart.fromJson(row as Map<String, dynamic>);
        if (!map.containsKey(part.id)) {
          map[part.id] = part;
        }
      }
    } catch (_) {}

    return map.values.toList();
  }

  String _ensureValidUuid(String id) {
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(id)) {
      return id;
    }
    return const Uuid().v4();
  }

  @override
  Future<void> addPart(SparePart part) async {
    final validId = _ensureValidUuid(part.id);
    final validPart = part.copyWith(id: validId);

    final payload = {
      'id': validId,
      'customer_id': validId,
      'appliance_category': validPart.category,
      'issue': 'MARKETPLACE_PART:${jsonEncode(validPart.toJson())}',
      'price': validPart.customerPrice,
      'status': 'marketplace_item',
    };

    try {
      await _client.from('jobs').upsert(payload);
    } catch (_) {}

    // Also attempt spare_parts insert
    try {
      await _client.from('spare_parts').upsert({
        'id': validId,
        'retailer_id': validPart.retailerId,
        'part_name': validPart.partName,
        'category': validPart.category,
        'customer_price': validPart.customerPrice,
        'technician_price': validPart.technicianPrice,
        'in_stock': validPart.inStock,
      });
    } catch (_) {}
  }

  @override
  Future<void> updatePart(SparePart part) async {
    await addPart(part);
  }

  @override
  Future<void> deletePart(String partId) async {
    try {
      await _client.from('jobs').delete().eq('id', partId);
    } catch (_) {}
    try {
      await _client.from('spare_parts').delete().eq('id', partId);
    } catch (_) {}
  }
}
