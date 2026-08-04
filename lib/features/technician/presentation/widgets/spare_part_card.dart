import 'package:flutter/material.dart';
import '../../../retailer/models/spare_part_model.dart';
import 'profit_badge.dart';

/// Compact Wholesale product card for technician marketplace grid.
class SparePartCard extends StatelessWidget {
  final SparePart part;
  final VoidCallback onTap;
  final VoidCallback onOrderTap;

  const SparePartCard({
    super.key,
    required this.part,
    required this.onTap,
    required this.onOrderTap,
  });

  IconData _getCategoryIcon(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('ac') || lower.contains('cooler')) return Icons.ac_unit_rounded;
    if (lower.contains('refrigerator') || lower.contains('fridge')) return Icons.kitchen_rounded;
    if (lower.contains('washing')) return Icons.local_laundry_service_rounded;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv_rounded;
    if (lower.contains('purifier') || lower.contains('ro')) return Icons.water_drop_rounded;
    if (lower.contains('microwave') || lower.contains('oven')) return Icons.microwave_rounded;
    if (lower.contains('geyser') || lower.contains('heater')) return Icons.opacity_rounded;
    return Icons.build_circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section: Badges & Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Category Badge + Stock Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(part.category),
                                size: 12,
                                color: Colors.deepOrange,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  part.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Stock status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: part.inStock ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: part.inStock ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          part.displayStockStatus,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: part.inStock ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Part Name
                  Text(
                    part.partName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Profit Badge
                  ProfitBadge(
                    technicianPrice: part.technicianPrice,
                    customerPrice: part.customerPrice,
                  ),
                ],
              ),

              // Bottom Section: Pricing & Order Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),

                  // Compact Pricing Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wholesale',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${part.technicianPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Selling',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '₹${part.customerPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Compact Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: part.inStock ? onOrderTap : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 14),
                      label: const Text(
                        'Order / Attach',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
