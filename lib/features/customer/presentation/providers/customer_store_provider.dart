import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_marketplace_store.dart';
import '../../../retailer/models/spare_part_model.dart';
import '../../data/repositories/supabase_customer_store_repository.dart';
import '../../domain/repositories/customer_store_repository.dart';

final customerStoreRepositoryProvider = Provider<CustomerStoreRepository>((ref) {
  return SupabaseCustomerStoreRepository();
});

final storeCategoryFilterProvider = StateProvider<String>((ref) => 'All');
final storeSearchQueryProvider = StateProvider<String>((ref) => '');

class CustomerStoreNotifier extends AsyncNotifier<List<SparePart>> {
  late CustomerStoreRepository _repository;
  Timer? _debounceTimer;

  @override
  Future<List<SparePart>> build() async {
    _repository = ref.watch(customerStoreRepositoryProvider);
    final category = ref.watch(storeCategoryFilterProvider);
    final search = ref.watch(storeSearchQueryProvider);
    final sharedParts = ref.watch(sharedMarketplaceStoreProvider);

    final remoteParts = await _repository.getAvailableSpareParts(
      category: category,
      searchQuery: search,
    );

    // Merge remote parts and shared in-memory retailer parts seamlessly
    final map = <String, SparePart>{};
    for (final p in remoteParts) {
      map[p.id] = p;
    }
    for (final p in sharedParts) {
      if (p.inStock) map[p.id] = p;
    }

    var list = map.values.toList();

    if (category != 'All' && category.isNotEmpty) {
      final normalizedCat = category.replaceAll(' Parts', '').trim().toLowerCase();
      list = list.where((p) {
        final pCat = p.category.toLowerCase();
        return pCat.contains(normalizedCat) || normalizedCat.contains(pCat);
      }).toList();
    }

    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((p) {
        final nameMatch = p.partName.toLowerCase().contains(q);
        final catMatch = p.category.toLowerCase().contains(q);
        final brandMatch = p.brand.toLowerCase().contains(q);
        return nameMatch || catMatch || brandMatch;
      }).toList();
    }

    return list;
  }

  void setSearchQueryDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(storeSearchQueryProvider.notifier).state = query;
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final customerStoreProvider =
    AsyncNotifierProvider<CustomerStoreNotifier, List<SparePart>>(() {
  return CustomerStoreNotifier();
});
