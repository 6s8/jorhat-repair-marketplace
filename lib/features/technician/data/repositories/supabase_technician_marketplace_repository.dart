import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../retailer/models/spare_part_model.dart';
import '../../domain/repositories/technician_marketplace_repository.dart';

class SupabaseTechnicianMarketplaceRepository
    implements TechnicianMarketplaceRepository {
  final SupabaseClient _client;

  SupabaseTechnicianMarketplaceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  List<SparePart> _getFallbackCatalog() {
    final now = DateTime.now();
    return [
      SparePart(
        id: 'ret-sp-001',
        retailerId: 'guest_retailer_001',
        partName: 'Samsung 1.5 Ton Inverter AC Rotary Compressor R32',
        category: 'AC',
        brand: 'Samsung',
        customerPrice: 4850.0,
        technicianPrice: 4100.0,
        inStock: true,
        stockStatus: 'In Stock',
        retailerPhone: '+919876543210',
        createdAt: now.subtract(const Duration(days: 2)),
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
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      SparePart(
        id: 'ret-sp-003',
        retailerId: 'guest_retailer_001',
        partName: 'Whirlpool Washing Machine Inlet Valve & Drain Motor',
        category: 'Washing Machine',
        brand: 'Whirlpool',
        customerPrice: 890.0,
        technicianPrice: 720.0,
        inStock: true,
        stockStatus: 'In Stock',
        retailerPhone: '+919876543210',
        createdAt: now,
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
        createdAt: now,
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
        createdAt: now,
      ),
      SparePart(
        id: 'ret-sp-006',
        retailerId: 'guest_retailer_001',
        partName: 'Sony 43" Smart LED TV Power Supply Board',
        category: 'Television',
        brand: 'Sony',
        customerPrice: 1450.0,
        technicianPrice: 1150.0,
        inStock: true,
        stockStatus: 'In Stock',
        retailerPhone: '+919876543210',
        createdAt: now,
      ),
      SparePart(
        id: 'ret-sp-007',
        retailerId: 'guest_retailer_001',
        partName: 'Godrej Inverter Refrigerator Main Control PCB',
        category: 'Refrigerator',
        brand: 'Godrej',
        customerPrice: 2200.0,
        technicianPrice: 1800.0,
        inStock: true,
        stockStatus: 'In Stock',
        retailerPhone: '+919876543210',
        createdAt: now,
      ),
    ];
  }

  @override
  Future<List<SparePart>> getSpareParts({String? category, String? search}) async {
    final map = <String, SparePart>{};

    // 1. Fetch live retailer-listed parts from jobs table
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

    // 3. Fallback catalog if DB returns empty
    if (map.isEmpty) {
      for (final p in _getFallbackCatalog()) {
        map[p.id] = p;
      }
    }

    var parts = map.values.toList();

    if (category != null && category.isNotEmpty && category != 'All') {
      final normalizedCat = category.replaceAll(' Parts', '').trim().toLowerCase();
      parts = parts.where((p) {
        final pCat = p.category.toLowerCase();
        return pCat.contains(normalizedCat) || normalizedCat.contains(pCat);
      }).toList();
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      parts = parts.where((p) {
        final nameMatch = p.partName.toLowerCase().contains(q);
        final catMatch = p.category.toLowerCase().contains(q);
        final brandMatch = p.brand.toLowerCase().contains(q);
        return nameMatch || catMatch || brandMatch;
      }).toList();
    }

    return parts;
  }

  @override
  Stream<List<SparePart>> watchSpareParts({String? category, String? search}) {
    final controller = StreamController<List<SparePart>>();

    getSpareParts(category: category, search: search).then((parts) {
      if (!controller.isClosed) controller.add(parts);
    }).catchError((_) {
      if (!controller.isClosed) controller.add(_getFallbackCatalog());
    });

    try {
      final sub = _client
          .from('jobs')
          .stream(primaryKey: ['id'])
          .listen((data) async {
        if (!controller.isClosed) {
          final parts = await getSpareParts(category: category, search: search);
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
}
