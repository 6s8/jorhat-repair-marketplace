import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../../features/retailer/models/refurbished_appliance_model.dart';
import '../supabase/supabase_client.dart';

class RefurbishedStoreNotifier extends Notifier<List<RefurbishedAppliance>> {
  static const String _storageKey = 'assamparts_refurbished_appliances_v3';
  StreamSubscription? _realtimeSub;

  @override
  List<RefurbishedAppliance> build() {
    final initial = _loadInitialAppliances();
    _initSupabaseSync();
    return initial;
  }

  List<RefurbishedAppliance> _getFallbackCatalog() {
    final now = DateTime.now();
    return [
      RefurbishedAppliance(
        id: 'ref-001',
        retailerId: 'guest_retailer_001',
        title: 'LG 260L Double Door Refrigerator (Smart Inverter)',
        category: 'Refrigerator',
        brand: 'LG',
        condition: 'Like New (Certified Refurbished)',
        warrantyPeriod: '6 Months Shop Warranty',
        customerPrice: 13500.0,
        originalPrice: 28900.0,
        imageUrl: 'assets/appliances/refrigerator.png',
        description:
            'Fully serviced LG Double Door Refrigerator. New compressor relay, gas recharged, excellent cooling performance with low power draw.',
        inStock: true,
        retailerPhone: '+919876543210',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      RefurbishedAppliance(
        id: 'ref-002',
        retailerId: 'guest_retailer_001',
        title: 'Samsung 1.5 Ton 3 Star Inverter Split AC',
        category: 'AC',
        brand: 'Samsung',
        condition: 'Good Condition (Refurbished)',
        warrantyPeriod: '6 Months Shop Warranty',
        customerPrice: 18900.0,
        originalPrice: 37500.0,
        imageUrl: 'assets/appliances/ac.png',
        description:
            'Complete AC indoor + outdoor unit set. Copper coil leak pressure tested, gas refilled R32, includes original remote control.',
        inStock: true,
        retailerPhone: '+919876543210',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      RefurbishedAppliance(
        id: 'ref-003',
        retailerId: 'guest_retailer_001',
        title: 'IFB 6.5kg Fully Automatic Front Load Washing Machine',
        category: 'Washing Machine',
        brand: 'IFB',
        condition: 'Like New (Certified Refurbished)',
        warrantyPeriod: '1 Year Shop Warranty',
        customerPrice: 11200.0,
        originalPrice: 26000.0,
        imageUrl: 'assets/appliances/washing_machine.png',
        description:
            'Pre-owned IFB Front Load washer. New inlet valve & shock absorbers fitted. Super clean stainless steel drum condition.',
        inStock: true,
        retailerPhone: '+919876543210',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      RefurbishedAppliance(
        id: 'ref-004',
        retailerId: 'guest_retailer_001',
        title: 'Sony Bravia 43 inch Full HD Smart LED TV',
        category: 'Television',
        brand: 'Sony',
        condition: 'Certified Refurbished',
        warrantyPeriod: '3 Months Shop Warranty',
        customerPrice: 14800.0,
        originalPrice: 42900.0,
        imageUrl: 'assets/appliances/television.png',
        description:
            'Crisp Full HD display with original wall mount bracket & remote control. Power board tested and refurbished.',
        inStock: true,
        retailerPhone: '+919876543210',
        createdAt: now,
      ),
    ];
  }

  List<RefurbishedAppliance> _loadInitialAppliances() {
    try {
      if (kIsWeb) {
        final raw = html.window.localStorage[_storageKey];
        if (raw != null && raw.isNotEmpty) {
          final List decoded = jsonDecode(raw) as List;
          final items = decoded
              .map((e) =>
                  RefurbishedAppliance.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (items.isNotEmpty) return items;
        }
      }
    } catch (_) {}

    final seeded = _getFallbackCatalog();
    _persistToWeb(seeded);
    return seeded;
  }

  void _initSupabaseSync() async {
    _fetchFromSupabase();

    try {
      _realtimeSub = supabase
          .from('jobs')
          .stream(primaryKey: ['id'])
          .listen((_) => _fetchFromSupabase(), onError: (_) {});
    } catch (_) {}
  }

  Future<void> _fetchFromSupabase() async {
    try {
      final List<dynamic> rows = await supabase
          .from('jobs')
          .select()
          .eq('status', 'refurbished_appliance')
          .order('created_at', ascending: false);

      final map = <String, RefurbishedAppliance>{};
      for (final item in _getFallbackCatalog()) {
        map[item.id] = item;
      }

      for (final row in rows) {
        final issueStr = row['issue']?.toString() ?? '';
        if (issueStr.startsWith('REFURBISHED_APPLIANCE:')) {
          try {
            final jsonRaw =
                jsonDecode(issueStr.replaceFirst('REFURBISHED_APPLIANCE:', ''));
            final item =
                RefurbishedAppliance.fromJson(Map<String, dynamic>.from(jsonRaw as Map));
            map[item.id] = item;
          } catch (_) {}
        }
      }

      final merged = map.values.toList();
      state = merged;
      _persistToWeb(merged);
    } catch (_) {}
  }

  void _persistToWeb(List<RefurbishedAppliance> items) {
    try {
      if (kIsWeb) {
        final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
        html.window.localStorage[_storageKey] = encoded;
      }
    } catch (_) {}
  }

  String _ensureValidUuid(String id) {
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(id)) {
      return id;
    }
    return const Uuid().v4();
  }

  Future<void> addOrUpdateAppliance(RefurbishedAppliance item) async {
    final validId = _ensureValidUuid(item.id);
    final validItem = item.copyWith(id: validId);

    final idx = state.indexWhere((i) => i.id == validItem.id);
    List<RefurbishedAppliance> updated;
    if (idx >= 0) {
      updated = [
        for (int i = 0; i < state.length; i++)
          if (i == idx) validItem else state[i]
      ];
    } else {
      updated = [validItem, ...state];
    }
    state = updated;
    _persistToWeb(updated);

    // Save to Supabase jobs table
    try {
      final payload = {
        'id': validId,
        'customer_id': validId,
        'appliance_category': validItem.category,
        'customer_name': 'Assam Authorized Retailer',
        'customer_phone': validItem.retailerPhone,
        'address_text': 'Jorhat Market',
        'issue': 'REFURBISHED_APPLIANCE:${jsonEncode(validItem.toJson())}',
        'price': validItem.customerPrice,
        'status': 'refurbished_appliance',
      };
      await supabase.from('jobs').upsert(payload);
    } catch (_) {}
  }

  Future<void> removeAppliance(String id) async {
    final updated = state.where((i) => i.id != id).toList();
    state = updated;
    _persistToWeb(updated);

    try {
      await supabase.from('jobs').delete().eq('id', id);
    } catch (_) {}
  }
}

final refurbishedStoreProvider =
    NotifierProvider<RefurbishedStoreNotifier, List<RefurbishedAppliance>>(
  () => RefurbishedStoreNotifier(),
);
