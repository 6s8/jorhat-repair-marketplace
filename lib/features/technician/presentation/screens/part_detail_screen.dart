import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../retailer/models/spare_part_model.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/profit_badge.dart';
import '../widgets/active_job_selector.dart';
import '../widgets/fulfillment_bottom_sheet.dart';

class PartDetailScreen extends ConsumerWidget {
  final SparePart part;

  const PartDetailScreen({super.key, required this.part});

  Future<void> _callRetailer(BuildContext context, String? phone) async {
    final uriString = 'tel:${phone ?? "+919876543210"}';
    final uri = Uri.parse(uriString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }

  void _showActiveJobSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActiveJobSelectorSheet(
        onJobSelected: (job) async {
          final success = await ref.read(attachPartProvider.notifier).attach(
                jobId: job.id,
                partId: part.id,
                quantity: 1,
                technicianPrice: part.technicianPrice,
                customerPrice: part.customerPrice,
              );

          if (context.mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Successfully attached ${part.partName} to Job #${job.id.length > 8 ? job.id.substring(0, 8) : job.id}!'),
                  backgroundColor: Colors.green.shade800,
                ),
              );
            } else {
              final err = ref.read(attachPartProvider).errorMessage;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to attach part: $err'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showFulfillmentSheet(BuildContext context, WidgetRef ref) {
    final linkedJob = ref.watch(selectedJobProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FulfillmentBottomSheet(
        part: part,
        linkedJob: linkedJob,
        onOrderConfirmed: () {
          // Add to cart or direct place order
          ref.read(cartProvider.notifier).addItem(
                CartItem(
                  partId: part.id,
                  partName: part.partName,
                  technicianPrice: part.technicianPrice,
                  customerPrice: part.customerPrice,
                ),
              );

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedJob = ref.watch(selectedJobProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          part.partName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Placeholder / Icon
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepOrange.shade100),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 64,
                    color: Colors.deepOrange.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    part.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Header: Category & Stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(part.category),
                  backgroundColor: Colors.deepOrange.shade50,
                  side: BorderSide(color: Colors.deepOrange.shade200),
                  labelStyle: const TextStyle(color: Colors.deepOrange),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: part.inStock ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: part.inStock ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    part.displayStockStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: part.inStock ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              part.partName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),
            ProfitBadge(
              technicianPrice: part.technicianPrice,
              customerPrice: part.customerPrice,
            ),

            const SizedBox(height: 20),

            // Pricing Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Wholesale Technician Price:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '₹${part.technicianPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Customer Selling Price:',
                        style: TextStyle(color: Colors.black54),
                      ),
                      Text(
                        '₹${part.customerPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Technician Net Profit:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '₹${(part.customerPrice - part.technicianPrice).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Linked Active Job Card (if selected)
            if (selectedJob != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Linked Active Job',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          Text(
                            '${selectedJob.displayTitle} (${selectedJob.customerName ?? "Customer"})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(selectedJobProvider.notifier).state = null;
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showActiveJobSelector(context, ref),
                    icon: const Icon(Icons.build_circle_outlined, size: 18),
                    label: const Text('Attach To Job'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: BorderSide(color: Colors.deepOrange.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: part.inStock
                        ? () => _showFulfillmentSheet(context, ref)
                        : null,
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: const Text('Order Part'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Call Retailer
            Center(
              child: TextButton.icon(
                onPressed: () => _callRetailer(context, part.retailerPhone),
                icon: const Icon(Icons.call_rounded, size: 18, color: Colors.green),
                label: const Text(
                  'Call Wholesale Retailer',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
