import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/accept_job_controller.dart';
import '../../../../providers/realtime_job_list_provider.dart';
import '../widgets/empty_jobs_widget.dart';
import '../widgets/job_card.dart';

/// Main Realtime Technician Dispatch Feed Screen.
class JobFeedScreen extends ConsumerWidget {
  final String currentTechnicianId;

  const JobFeedScreen({
    super.key,
    this.currentTechnicianId = '00000000-0000-4000-8000-000000000001',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJobs = ref.watch(realtimeJobListProvider);

    // Listen to acceptState changes to navigate or display error snackbars
    ref.listen<AcceptJobState>(acceptJobControllerProvider, (previous, next) {
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(acceptJobControllerProvider.notifier).clearError();
      }

      if (next.acceptedJob != null && previous?.acceptedJob != next.acceptedJob) {
        context.push(
          '/job-detail',
          extra: next.acceptedJob,
        );
      }
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(realtimeJobListProvider.notifier).refresh(),
      child: asyncJobs.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading jobs feed: ${error.toString()}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(realtimeJobListProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (jobs) {
            if (jobs.isEmpty) {
              return EmptyJobsWidget(
                onRefresh: () =>
                    ref.read(realtimeJobListProvider.notifier).refresh(),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];

                return JobCard(
                  key: ValueKey(job.id),
                  job: job,
                  currentTechnicianId: currentTechnicianId,
                  onAcceptSuccess: () {
                    context.push('/job-detail', extra: job);
                  },
                )
                    .animate()
                    .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    );
              },
            );
          },
        ),
      );
  }
}
