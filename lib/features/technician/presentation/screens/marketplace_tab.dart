import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../retailer/models/spare_part_model.dart';
import '../providers/technician_marketplace_provider.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/spare_part_card.dart';
import '../widgets/fulfillment_bottom_sheet.dart';
import '../widgets/cart_sheet.dart';
import 'part_detail_screen.dart';

/// Upgraded Production-Grade Wholesale Marketplace Tab for Technicians.
class MarketplaceTab extends ConsumerStatefulWidget {
  const MarketplaceTab({super.key});

  @override
  ConsumerState<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends ConsumerState<MarketplaceTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  final List<String> _categories = const [
    'All',
    'AC Parts',
    'Refrigerator',
    'Washing Machine',
    'Car AC',
    'Microwave',
    'Water Purifier',
    'TV',
    'Others',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(marketplaceSearchQueryProvider.notifier).setSearch(query);
    });
  }

  void _openPartDetail(SparePart part) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PartDetailScreen(part: part),
      ),
    );
  }

  void _openFulfillmentSheet(SparePart part) {
    final linkedJob = ref.watch(selectedJobProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FulfillmentBottomSheet(
        part: part,
        linkedJob: linkedJob,
        onOrderConfirmed: () {
          ref.read(cartProvider.notifier).addItem(
                CartItem(
                  partId: part.id,
                  partName: part.partName,
                  technicianPrice: part.technicianPrice,
                  customerPrice: part.customerPrice,
                ),
              );

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${part.partName} added to order cart!'),
              backgroundColor: Colors.deepOrange,
            ),
          );
        },
      ),
    );
  }

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceState = ref.watch(technicianMarketplaceProvider);
    final currentCat = ref.watch(marketplaceCategoryFilterProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top Search & Category Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                // Debounced Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search parts, brands, categories...',
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: Colors.deepOrange),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(marketplaceSearchQueryProvider.notifier)
                                  .setSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = _categories[idx];
                      final isSelected = cat == currentCat;

                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: Colors.deepOrange,
                        backgroundColor: Colors.grey.shade100,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.deepOrange
                              : Colors.grey.shade300,
                        ),
                        onSelected: (_) {
                          ref
                              .read(marketplaceCategoryFilterProvider.notifier)
                              .setCategory(cat);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Wholesale Spare Parts Grid / List
          Expanded(
            child: RefreshIndicator(
              color: Colors.deepOrange,
              onRefresh: () async {
                ref.invalidate(technicianMarketplaceProvider);
              },
              child: marketplaceState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text('Error loading marketplace: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(technicianMarketplaceProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (parts) {
                  if (parts.isEmpty) {
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No Spare Parts Found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search query or category filter.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 700
                          ? 3
                          : (constraints.maxWidth > 480 ? 2 : 2);
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: parts.length,
                        itemBuilder: (context, index) {
                          final part = parts[index];
                          return SparePartCard(
                            part: part,
                            onTap: () => _openPartDetail(part),
                            onOrderTap: () => _openFulfillmentSheet(part),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Floating Cart Button (if items in cart)
      floatingActionButton: cartItemCount > 0
          ? FloatingActionButton.extended(
              onPressed: _openCartSheet,
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart_rounded),
              label: Text(
                'Cart ($cartItemCount)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
