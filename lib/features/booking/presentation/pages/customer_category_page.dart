import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controller/booking_controller.dart';
import '../../pricing/repair_pricing.dart';
import '../widgets/category_card.dart';

/// Step 1: Appliance Category Selection Page.
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
    final categories = RepairPricing.basePrice.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Appliance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the appliance that needs repair in Jorhat',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 20),

          // Appliance Grid
          Expanded(
            child: GridView.builder(
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = state.selectedCategory == category;

                return CategoryCard(
                  categoryName: category,
                  isSelected: isSelected,
                  onTap: () => controller.selectCategory(category),
                );
              },
            ),
          ),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: state.isCategoryValid
                  ? () {
                      controller.nextStep();
                      onNext();
                    }
                  : null,
              style: FilledButton.styleFrom(
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
    );
  }
}
