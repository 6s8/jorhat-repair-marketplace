import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controller/booking_controller.dart';
import '../widgets/price_card.dart';

/// Step 2: Issue Description Page.
class CustomerIssuePage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CustomerIssuePage({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<CustomerIssuePage> createState() => _CustomerIssuePageState();
}

class _CustomerIssuePageState extends ConsumerState<CustomerIssuePage> {
  late final TextEditingController _issueController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(bookingControllerProvider);
    _issueController = TextEditingController(text: state.issueDescription);
  }

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);
    final charLength = state.issueDescription.trim().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Category Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Describe Issue',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Chip(
                avatar: const Icon(Icons.build_rounded, size: 16),
                label: Text(
                  state.selectedCategory ?? 'Repair',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Provide details so the technician brings the correct tools',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 20),

          // Price Summary Card
          if (state.selectedCategory != null && state.estimatedPrice != null) ...[
            PriceCard(
              category: state.selectedCategory!,
              estimatedPrice: state.estimatedPrice!,
            ),
            const SizedBox(height: 20),
          ],

          // Issue Input TextField
          TextField(
            controller: _issueController,
            maxLines: 5,
            maxLength: 500,
            onChanged: (val) => controller.updateIssue(val),
            decoration: InputDecoration(
              hintText: 'e.g. My ${state.selectedCategory ?? "appliance"} is not cooling properly and making a strange noise.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          // Character Counter & Validation Guidance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                charLength < 15
                    ? 'Enter at least ${15 - charLength} more characters'
                    : 'Good description!',
                style: TextStyle(
                  fontSize: 12,
                  color: charLength < 15 ? Colors.orange[800] : Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$charLength/500',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action Buttons (Back & Continue)
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    controller.previousStep();
                    widget.onBack();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: state.isIssueValid
                      ? () {
                          controller.nextStep();
                          widget.onNext();
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
