import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../retailer/models/spare_part_model.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  final SparePart part;

  const ProductDetailScreen({super.key, required this.part});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryIcon = _getCategoryIcon(part.category);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          part.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Hero Image Card
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(categoryIcon, size: 80, color: Colors.teal),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: part.inStock ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        part.displayStockStatus,
                        style: TextStyle(
                          color: part.inStock ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category & Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  part.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '₹${part.customerPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Part Name
            Text(
              part.partName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 16),

            // Compatible Brands & Info
            _buildInfoTile(
              context,
              icon: Icons.branding_watermark_outlined,
              title: 'Compatible Brands',
              subtitle: 'Samsung, LG, Whirlpool, Godrej, Voltas, Haier & Universal Fit',
            ),
            const SizedBox(height: 12),
            _buildInfoTile(
              context,
              icon: Icons.storefront_outlined,
              title: 'Authorized Retailer',
              subtitle: 'Assam Repair Parts Hub (Jorhat Central)',
            ),
            const SizedBox(height: 12),
            _buildInfoTile(
              context,
              icon: Icons.verified_user_outlined,
              title: 'Quality Guarantee',
              subtitle: '100% Original Manufacturer Warranty & Inspection Certified',
            ),
            const SizedBox(height: 24),

            // Description Box
            Text(
              'Product Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'High-durability replacement spare part for ${part.category} appliances. Fully tested for Assam electrical standards and humidity endurance.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: part.inStock ? () {
                  ref.read(cartProvider.notifier).addToCart(part);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${part.partName}" to Cart'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } : null,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text(part.inStock ? 'Add To Cart' : 'Out of Stock'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: part.inStock ? Colors.teal : Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: part.inStock ? () {
                  ref.read(cartProvider.notifier).addToCart(part);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                } : null,
                icon: const Icon(Icons.flash_on_rounded),
                label: Text(part.inStock ? 'Buy Now' : 'Out of Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: part.inStock ? Colors.teal : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: part.inStock ? 2 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context,
      {required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
