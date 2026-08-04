import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalPriceProvider);
    const deliveryFee = 50.0;
    final total = cart.isEmpty ? 0.0 : subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Shopping Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Cart',
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Your Cart is Empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse spare parts in the store and add items to your cart.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Go to Store'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(Icons.build_circle_rounded,
                                    color: Colors.teal, size: 28),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.part.partName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.part.customerPrice.toStringAsFixed(0)} each',
                                    style: TextStyle(
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Selector
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20, color: Colors.grey),
                                  onPressed: () {
                                    if (item.quantity <= 1) {
                                      ref.read(cartProvider.notifier).removeFromCart(item.part.id);
                                    } else {
                                      ref.read(cartProvider.notifier).updateQuantity(
                                          item.part.id, item.quantity - 1);
                                    }
                                  },
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 20, color: Colors.teal),
                                  onPressed: () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                            item.part.id, item.quantity + 1);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Order Summary Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text('₹${subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Local Delivery Fee:'),
                          const Text('₹50', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('₹${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Proceed to Checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
