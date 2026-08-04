import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/refurbished_store_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_progress_indicator.dart';
import '../../../retailer/models/spare_part_model.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_store_provider.dart';
import '../widgets/refurbished_appliance_card.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class CustomerStoreScreen extends ConsumerStatefulWidget {
  const CustomerStoreScreen({super.key});

  @override
  ConsumerState<CustomerStoreScreen> createState() => _CustomerStoreScreenState();
}

class _CustomerStoreScreenState extends ConsumerState<CustomerStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0: New Spare Parts, 1: Refurbished Appliances

  final List<String> _categoryChips = const [
    'All',
    'AC Parts',
    'Fridge Parts',
    'Washing Machine Parts',
    'Auto AC',
    'TV Parts',
    'Water Purifier',
    'Microwave',
    'Others',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('ac')) return Icons.ac_unit_rounded;
    if (cat.contains('fridge') || cat.contains('refrigerator')) return Icons.kitchen_rounded;
    if (cat.contains('wash')) return Icons.local_laundry_service_rounded;
    if (cat.contains('tv')) return Icons.tv_rounded;
    if (cat.contains('water') || cat.contains('ro')) return Icons.water_drop_rounded;
    if (cat.contains('micro')) return Icons.microwave_rounded;
    return Icons.build_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(customerStoreProvider);
    final activeCategory = ref.watch(storeCategoryFilterProvider);
    final itemCount = ref.watch(cartTotalItemCountProvider);
    final refurbishedItems = ref.watch(refurbishedStoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).cardColor;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Marketplace & Store',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Shopping Cart',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Segment Toggle
          Container(
            color: cardColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'New Spare Parts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _selectedTab == 0 ? Colors.white : mutedTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 16,
                              color: _selectedTab == 1 ? AppColors.accent : AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Refurbished Appliances',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedTab == 1 ? Colors.white : mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedTab == 0) ...[
            Container(
              color: cardColor,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (text) {
                      ref
                          .read(customerStoreProvider.notifier)
                          .setSearchQueryDebounced(text);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search parts by name, category, or brand...',
                      prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(storeSearchQueryProvider.notifier)
                                    .state = '';
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categoryChips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final chip = _categoryChips[index];
                        final isSelected = activeCategory == chip;
                        return ChoiceChip(
                          label: Text(chip),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(storeCategoryFilterProvider.notifier)
                                  .state = chip;
                            }
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : mutedTextColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                          elevation: isSelected ? 2 : 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () async {
                  await ref.read(customerStoreProvider.notifier).refresh();
                },
                child: storeState.when(
                  loading: () => const Center(
                    child: AppProgressIndicator(label: 'Loading products...'),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading products: $err', style: const TextStyle(color: AppColors.error)),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: mutedTextColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No Listed Parts Available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(context, products[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: refurbishedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_outlined,
                              size: 64, color: mutedTextColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No Refurbished Appliances Listed Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: mutedTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Retailers will add certified pre-owned appliances here.',
                            style: TextStyle(color: mutedTextColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: refurbishedItems.length,
                      itemBuilder: (context, index) {
                        return RefurbishedApplianceCard(
                          appliance: refurbishedItems[index],
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, SparePart part) {
    final categoryIcon = _getCategoryIcon(part.category);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(part: part),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Icon(categoryIcon, size: 36, color: primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              part.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: mutedTextColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: part.inStock
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              part.displayStockStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: part.inStock
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        part.partName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Retailer: Assam Authorized Parts',
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${part.customerPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: part.inStock ? () {
                                  ref.read(cartProvider.notifier).addToCart(part);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added "${part.partName}" to Cart'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } : null,
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(color: part.inStock ? primaryColor : Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  part.inStock ? '+ Cart' : 'Out of Stock',
                                  style: TextStyle(
                                    color: part.inStock ? primaryColor : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: part.inStock ? () {
                                  ref.read(cartProvider.notifier).addToCart(part);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CartScreen(),
                                    ),
                                  );
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: part.inStock ? AppColors.accent : Colors.grey,
                                  foregroundColor: part.inStock ? AppColors.text : Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(part.inStock ? 'Buy Now' : 'Out of Stock'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
