import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../retailer/models/spare_part_model.dart';
import '../../../../models/job_model.dart';
import '../providers/marketplace_providers.dart';

class FulfillmentBottomSheet extends ConsumerStatefulWidget {
  final SparePart part;
  final Job? linkedJob;
  final VoidCallback onOrderConfirmed;

  const FulfillmentBottomSheet({
    super.key,
    required this.part,
    this.linkedJob,
    required this.onOrderConfirmed,
  });

  @override
  ConsumerState<FulfillmentBottomSheet> createState() =>
      _FulfillmentBottomSheetState();
}

class _FulfillmentBottomSheetState
    extends ConsumerState<FulfillmentBottomSheet> {
  FulfillmentMode _mode = FulfillmentMode.express;

  Future<void> _callRetailer(String? phone) async {
    final uriString = 'tel:${phone ?? "+919876543210"}';
    final uri = Uri.parse(uriString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.linkedJob;

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
                'Choose Delivery Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Express Delivery Card
          InkWell(
            onTap: () => setState(() => _mode = FulfillmentMode.express),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _mode == FulfillmentMode.express
                    ? Colors.deepOrange.withValues(alpha: 0.06)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _mode == FulfillmentMode.express
                      ? Colors.deepOrange
                      : Colors.grey.shade300,
                  width: _mode == FulfillmentMode.express ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<FulfillmentMode>(
                    value: FulfillmentMode.express,
                    groupValue: _mode,
                    activeColor: Colors.deepOrange,
                    onChanged: (val) {
                      if (val != null) setState(() => _mode = val);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.local_shipping_rounded,
                                color: Colors.deepOrange, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Express Delivery',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job != null
                              ? 'Deliver directly to ${job.customerName ?? "Customer"}\'s address: ${job.displayAddress}'
                              : 'Deliver directly to the customer\'s site.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Store Pickup Card
          InkWell(
            onTap: () => setState(() => _mode = FulfillmentMode.pickup),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _mode == FulfillmentMode.pickup
                    ? Colors.deepOrange.withValues(alpha: 0.06)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _mode == FulfillmentMode.pickup
                      ? Colors.deepOrange
                      : Colors.grey.shade300,
                  width: _mode == FulfillmentMode.pickup ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<FulfillmentMode>(
                    value: FulfillmentMode.pickup,
                    groupValue: _mode,
                    activeColor: Colors.deepOrange,
                    onChanged: (val) {
                      if (val != null) setState(() => _mode = val);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.store_rounded,
                                color: Colors.deepOrange, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Store Pickup',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reserve part for counter pickup at retailer shop in Jorhat.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_mode == FulfillmentMode.pickup) ...[
            OutlinedButton.icon(
              onPressed: () => _callRetailer(widget.part.retailerPhone),
              icon: const Icon(Icons.call_rounded, color: Colors.green),
              label: const Text('Call Retailer Store'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade800,
                side: BorderSide(color: Colors.green.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(fulfillmentModeProvider.notifier).state = _mode;
                Navigator.of(context).pop();
                widget.onOrderConfirmed();
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
                'Continue Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
