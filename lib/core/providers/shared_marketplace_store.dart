import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Conditionally import html for web persistence without breaking non-web platforms
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../../features/retailer/models/spare_part_model.dart';

class SharedMarketplaceStoreNotifier extends Notifier<List<SparePart>> {
  static const String _storageKey = 'assamparts_retailer_listed_items_v2';

  @override
  List<SparePart> build() {
    return _loadInitialParts();
  }

  List<SparePart> _loadInitialParts() {
    try {
      if (kIsWeb) {
        final raw = html.window.localStorage[_storageKey];
        if (raw != null && raw.isNotEmpty) {
          final List decoded = jsonDecode(raw) as List;
          final parts = decoded
              .map((e) => SparePart.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (parts.isNotEmpty) return parts;
        }
      }
    } catch (_) {}

    // Default seeded retailer-listed items
    final seeded = [
      SparePart(
        id: 'ret-sp-001',
        retailerId: 'guest_retailer_001',
        partName: 'Samsung 1.5 Ton Inverter AC Fan Motor',
        category: 'AC',
        brand: 'Samsung',
        customerPrice: 3400.0,
        technicianPrice: 2850.0,
        inStock: true,
        stockStatus: 'In Stock',
        retailerPhone: '+919876543210',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SparePart(
        id: 'ret-sp-002',
        retailerId: 'guest_retailer_001',
        partName: 'LG Double Door Refrigerator Thermostat & Sensor',
        category: 'Refrigerator',
        brand: 'LG',
        customerPrice: 750.0,
        technicianPrice: 580.0,
        inStock: true,
        stockStatus: 'In Stock',
        retailerPhone: '+919876543210',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SparePart(
        id: 'ret-sp-003',
        retailerId: 'guest_retailer_001',
        partName: 'Whirlpool Front Load Washing Machine Inlet Valve',
        category: 'Washing Machine',
        brand: 'Whirlpool',
        customerPrice: 520.0,
        technicianPrice: 390.0,
        inStock: true,
        stockStatus: 'In Stock',
        retailerPhone: '+919876543210',
        createdAt: DateTime.now(),
      ),
      SparePart(
        id: 'ret-sp-004',
        retailerId: 'guest_retailer_001',
        partName: 'Voltas R32 Refrigerant Gas Canister (3kg)',
        category: 'AC',
        brand: 'Voltas',
        customerPrice: 2400.0,
        technicianPrice: 1950.0,
        inStock: true,
        stockStatus: 'In Stock',
        retailerPhone: '+919876543210',
        createdAt: DateTime.now(),
      ),
      SparePart(
        id: 'ret-sp-005',
        retailerId: 'guest_retailer_001',
        partName: 'Kent RO Water Purifier Booster Pump 75 GPD',
        category: 'Water Purifier',
        brand: 'Kent',
        customerPrice: 1650.0,
        technicianPrice: 1320.0,
        inStock: true,
        stockStatus: 'In Stock',
        retailerPhone: '+919876543210',
        createdAt: DateTime.now(),
      ),
    ];

    _persistToWeb(seeded);
    return seeded;
  }

  void _persistToWeb(List<SparePart> parts) {
    try {
      if (kIsWeb) {
        final encoded = jsonEncode(parts.map((p) => p.toJson()..['id'] = p.id).toList());
        html.window.localStorage[_storageKey] = encoded;
      }
    } catch (_) {}
  }

  void setParts(List<SparePart> parts) {
    if (parts.isNotEmpty) {
      state = parts;
      _persistToWeb(parts);
    }
  }

  void addOrUpdatePart(SparePart part) {
    final idx = state.indexWhere((p) => p.id == part.id);
    List<SparePart> updated;
    if (idx >= 0) {
      updated = [
        for (int i = 0; i < state.length; i++)
          if (i == idx) part else state[i]
      ];
    } else {
      updated = [part, ...state];
    }
    state = updated;
    _persistToWeb(updated);
  }

  void removePart(String partId) {
    final updated = state.where((p) => p.id != partId).toList();
    state = updated;
    _persistToWeb(updated);
  }
}

final sharedMarketplaceStoreProvider =
    NotifierProvider<SharedMarketplaceStoreNotifier, List<SparePart>>(
  () => SharedMarketplaceStoreNotifier(),
);
