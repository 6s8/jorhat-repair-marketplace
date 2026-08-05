import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_spare_part_order_repository.dart';
import '../../domain/repositories/spare_part_order_repository.dart';
import '../providers/cart_provider.dart';

final sparePartOrderRepositoryProvider =
    Provider<SparePartOrderRepository>((ref) {
  return SupabaseSparePartOrderRepository();
});

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController =
      TextEditingController(text: 'Customer');
  final TextEditingController _phoneController =
      TextEditingController(text: '9876543210');
  final TextEditingController _addressController =
      TextEditingController(text: 'AT Road, Club Road Area, Jorhat, Assam - 785001');

  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      final subtotal = ref.read(cartSubtotalPriceProvider);
      final total = subtotal + 50.0;
      final repo = ref.read(sparePartOrderRepositoryProvider);

      bool allSuccess = true;
      for (final item in cart) {
        final request = SparePartOrderRequest(
          customerId: 'cust-assam-001',
          retailerId: item.part.retailerId,
          partId: item.part.id,
          partName: item.part.partName,
          quantity: item.quantity,
          deliveryAddress: _addressController.text.trim(),
          totalAmount: total,
        );
        final ok = await repo.placeOrder(request);
        if (!ok) allSuccess = false;
      }

      if (!mounted) return;

      if (allSuccess) {
        ref.read(cartProvider.notifier).clearCart();
        final outerContext = context;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            icon: const Icon(Icons.check_circle_rounded,
                size: 64, color: Colors.teal),
            title: const Text('Order Placed Successfully!'),
            content: const Text(
              'Your spare part order has been sent to the authorized retailer. They will contact you shortly for delivery.',
              textAlign: TextAlign.center,
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx);
                  if (Navigator.canPop(outerContext)) Navigator.pop(outerContext);
                  if (Navigator.canPop(outerContext)) Navigator.pop(outerContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Store'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place order. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalPriceProvider);
    const deliveryFee = 50.0;
    final total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Checkout Order',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORDER SUMMARY',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal)),
                    const SizedBox(height: 12),
                    ...cart.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}x ${item.part.partName}',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('₹${item.totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items Subtotal:'),
                        Text('₹${subtotal.toStringAsFixed(0)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Fee:'),
                        Text('₹50'),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Payable:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Delivery Address Form
              Text(
                'Delivery Address Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Recipient Name',
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Contact Phone',
                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.teal),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) =>
                    val == null || val.trim().length < 10 || !RegExp(r'^[0-9]+$').hasMatch(val.trim()) ? 'Enter valid 10-digit phone' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.teal),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  icon: _isPlacingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: Text(_isPlacingOrder
                      ? 'Placing Order...'
                      : 'PLACE ORDER NOW (₹${total.toStringAsFixed(0)})'),
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
      ),
    );
  }
}
