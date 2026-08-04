import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_progress_indicator.dart';
import '../../controller/booking_controller.dart';

/// Step 5: Booking Confirmation Success Page for Fixly.
class BookingSuccessPage extends ConsumerWidget {
  final VoidCallback onBackHome;

  const BookingSuccessPage({
    super.key,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingControllerProvider);
    final job = state.createdJob;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Morphing Checkmark Indicator
            const AppProgressIndicator(
              isCompleted: true,
              size: 54,
            ),
            const SizedBox(height: 24),

            Text(
              'Booking Confirmed!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your repair request has been sent to nearby technicians in Jorhat.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 28),

            // Booking Details Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Booking ID', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        Text(
                          job != null ? job.id.substring(0, 8).toUpperCase() : 'PENDING',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Appliance Category', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        Text(
                          state.selectedCategory ?? 'Repair',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Price', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        Text(
                          '₹${state.estimatedPrice?.toStringAsFixed(0) ?? "399"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Customer Name', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        Text(
                          state.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    const Text('Service Address', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      state.formattedAddress.isNotEmpty
                          ? state.formattedAddress
                          : '${state.house}, ${state.area}, Jorhat',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Live Tracking Button
            if (job != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/track-job', extra: {
                      'jobId': job.id,
                      'category': state.selectedCategory,
                      'customerName': state.customerName,
                    });
                  },
                  icon: const Icon(Icons.track_changes_rounded),
                  label: const Text(
                    'View Live Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Book Another Repair
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(bookingControllerProvider.notifier).reset();
                  onBackHome();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Book Another Repair',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
