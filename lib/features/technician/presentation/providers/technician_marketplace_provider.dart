import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_marketplace_store.dart';
import '../../../retailer/models/spare_part_model.dart';
import '../../data/repositories/supabase_technician_marketplace_repository.dart';
import '../../domain/repositories/technician_marketplace_repository.dart';

final technicianMarketplaceRepositoryProvider =
    Provider<TechnicianMarketplaceRepository>((ref) {
  return SupabaseTechnicianMarketplaceRepository();
});

class CategoryFilterNotifier extends StateNotifier<String> {
  CategoryFilterNotifier() : super('All');
  void setCategory(String category) => state = category;
}

final marketplaceCategoryFilterProvider =
    StateNotifierProvider<CategoryFilterNotifier, String>((ref) {
  return CategoryFilterNotifier();
});

class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');
  void setSearch(String query) => state = query;
}

final marketplaceSearchQueryProvider =
    StateNotifierProvider<SearchQueryNotifier, String>((ref) {
  return SearchQueryNotifier();
});

class TechnicianMarketplaceNotifier extends AsyncNotifier<List<SparePart>> {
  @override
  Future<List<SparePart>> build() async {
    final repository = ref.watch(technicianMarketplaceRepositoryProvider);
    final category = ref.watch(marketplaceCategoryFilterProvider);
    final search = ref.watch(marketplaceSearchQueryProvider);
    final sharedParts = ref.watch(sharedMarketplaceStoreProvider);

    final remoteParts = await repository.getSpareParts(
        category: category == 'All' ? '' : category, search: search);

    final map = <String, SparePart>{};
    for (final p in remoteParts) {
      map[p.id] = p;
    }
    for (final p in sharedParts) {
      map[p.id] = p;
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

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final technicianMarketplaceProvider =
    AsyncNotifierProvider<TechnicianMarketplaceNotifier, List<SparePart>>(
  () => TechnicianMarketplaceNotifier(),
);
