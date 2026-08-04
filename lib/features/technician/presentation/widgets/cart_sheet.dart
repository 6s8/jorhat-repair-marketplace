import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/marketplace_providers.dart';

class CartBottomSheet extends ConsumerWidget {
  const CartBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wholesale Order Cart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (cartItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Your order cart is empty.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cartItems.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.partName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Wholesale ₹${item.technicianPrice.toStringAsFixed(0)} × ${item.quantity}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 20),
                            onPressed: () => cartNotifier.updateQuantity(
                                item.partId, item.quantity - 1),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () => cartNotifier.updateQuantity(
                                item.partId, item.quantity + 1),
                          ),
                        ],
                      ),
                      Text(
                        '₹${item.lineTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Wholesale Cost:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${cartNotifier.subtotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Profit Margin:',
                  style: TextStyle(color: Colors.green, fontSize: 13),
                ),
                Text(
                  '₹${cartNotifier.totalProfit.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  cartNotifier.clear();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Wholesale Order placed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Wholesale Order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
