import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../controller/booking_controller.dart';
import '../widgets/price_card.dart';

/// Step 3: Complaint Details Screen for Fixly.
class ComplaintDetailsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ComplaintDetailsScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends ConsumerState<ComplaintDetailsScreen> {
  late final TextEditingController _customIssueController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(bookingControllerProvider);
    _customIssueController = TextEditingController(text: state.customComplaint);
  }

  @override
  void dispose() {
    _customIssueController.dispose();
    super.dispose();
  }

  List<String> _getChipsForCategory(String category) {
    switch (category) {
      case 'AC':
        return ['Not Cooling', 'Leaking Water', 'Gas Refill', 'Bad Smell', 'Compressor Problem', 'Remote Issue', 'Power Issue', 'Water Dripping', 'Making Noise', 'Fan Not Working', 'Other'];
      case 'Refrigerator':
        return ['Not Cooling', 'Ice Build-up', 'Compressor Issue', 'Door Problem', 'Water Leakage', 'Power Issue', 'Making Noise', 'Other'];
      case 'Washing Machine':
        return ['Not Spinning', 'Water Leakage', 'Drain Problem', 'Power Issue', 'Not Starting', 'Excessive Vibration', 'Making Noise', 'Other'];
      case 'Television':
        return ['No Display', 'Power Issue', 'Sound Problem', 'Screen Flickering', 'Remote Issue', 'HDMI Issue', 'Other'];
      case 'Car AC':
        return ['Not Cooling', 'Gas Leak', 'Compressor Issue', 'Bad Smell', 'Fan Issue', 'Other'];
      default:
        return ['Not Working', 'Power Issue', 'Physical Damage', 'Other'];
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'AC':
        return Icons.ac_unit_rounded;
      case 'Refrigerator':
        return Icons.kitchen_rounded;
      case 'Washing Machine':
        return Icons.local_laundry_service_rounded;
      case 'Television':
        return Icons.tv_rounded;
      case 'Car AC':
        return Icons.directions_car_rounded;
      case 'Microwave':
        return Icons.microwave_rounded;
      default:
        return Icons.home_repair_service_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);

    final category = state.selectedCategory ?? 'Appliance';
    final availableChips = _getChipsForCategory(category);
    final selectedChips = state.selectedIssueChips;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20.0,
        20.0,
        20.0,
        MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom + 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 3 of 5 — Issues',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select Issues & Symptoms',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              Chip(
                avatar: Icon(_getIconForCategory(category), size: 16, color: AppColors.primary),
                label: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Issue Section
          Text(
            'Select Common Issues',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: availableChips.map((chipText) {
              final isSelected = selectedChips.contains(chipText);
              return FilterChip(
                label: Text(chipText),
                selected: isSelected,
                onSelected: (bool selected) {
                  controller.toggleIssueChip(chipText);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Custom Complaint Form
          Text(
            'Describe issue in detail (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customIssueController,
            maxLines: 4,
            maxLength: 500,
            onChanged: (val) {
              controller.setComplaint(val);
            },
            decoration: const InputDecoration(
              hintText: 'Example: "My AC cools for five minutes and then stops making cold air."',
            ),
          ),
          const SizedBox(height: 24),

          // Price Card
          if (state.estimatedPrice != null)
            PriceCard(category: category, estimatedPrice: state.estimatedPrice!),
          
          if (state.estimatedPrice != null)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  'Note: Actual repair cost may vary after technician inspection.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                child: const Text('Back'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isIssueValid ? widget.onNext : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.text, // Charcoal on Marigold for contrast
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to Address & Map', 
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
