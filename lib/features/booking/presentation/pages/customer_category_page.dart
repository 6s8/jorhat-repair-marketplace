import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controller/booking_controller.dart';
import '../widgets/appliance_selection_grid.dart';

/// Step 1: Appliance Category Selection Page with modern grid catalog.
class CustomerCategoryPage extends ConsumerWidget {
  final VoidCallback onNext;

  const CustomerCategoryPage({
    super.key,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding set to 100px for floating navbar clearance
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Appliance',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose repair category to book an expert in Jorhat',
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Step 1 of 5',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Appliance Grid Catalog
          Expanded(
            child: ApplianceSelectionGrid(
              selectedCategoryTitle: state.selectedCategory,
              onSelectAppliance: (category) {
                controller.selectCategory(
                  category.title,
                  inspectionFee: category.baseInspectionFee,
                );
                onNext();
              },
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Action CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.isCategoryValid ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.text,
                elevation: 2,
                shadowColor: AppColors.accent.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue to Brand & Model',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
