import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/accept_job_controller.dart';
import 'countdown_timer.dart';
import 'distance_badge.dart';
import 'price_tag.dart';

/// Material 3 Job Card component for Technician Dispatch System.
class JobCard extends ConsumerWidget {
  final Job job;
  final String currentTechnicianId;
  final VoidCallback? onAcceptSuccess;

  const JobCard({
    super.key,
    required this.job,
    required this.currentTechnicianId,
    this.onAcceptSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acceptState = ref.watch(acceptJobControllerProvider);
    final isLoadingThisJob = acceptState.isLoading && acceptState.loadingJobId == job.id;
    final isAnyJobLoading = acceptState.isLoading;

    final isAccepted = job.status == 'accepted';
    final isExpired = job.isExpired;
    final isDisabled = isAccepted || isExpired || isAnyJobLoading;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Distance Badge (Left) & Price Tag (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DistanceBadge(distanceKm: job.distanceKm),
                PriceTag(price: job.price),
              ],
            ),
            const SizedBox(height: 14),

            // Issue Title (Max 2 lines, 18 bold)
            Text(
              job.issue,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 14),

            // Countdown Timer Section
            if (job.expiresAt != null) ...[
              CountdownTimerWidget(expiresAt: job.expiresAt),
              const SizedBox(height: 16),
            ],

            // Bottom Full-Width Accept Button (Height 48)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isDisabled
                    ? null
                    : () async {
                        final result = await ref
                            .read(acceptJobControllerProvider.notifier)
                            .acceptJob(
                              jobId: job.id,
                              technicianId: currentTechnicianId,
                            );

                        if (!context.mounted) return;

                        result.when(
                          success: (acceptedJob) {
                            onAcceptSuccess?.call();
                          },
                          jobAlreadyTaken: (msg) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red[700],
                              ),
                            );
                          },
                          networkError: (msg) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.orange[800],
                              ),
                            );
                          },
                          timeout: (msg) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.orange[800],
                              ),
                            );
                          },
                          unknownError: (msg) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red[700],
                              ),
                            );
                          },
                        );
                      },
                child: isLoadingThisJob
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isAccepted
                            ? 'Accepted'
                            : isExpired
                                ? 'Expired'
                                : 'Accept Job',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
