import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/job_model.dart';
import '../providers/marketplace_providers.dart';

/// Modal bottom sheet or dropdown widget to select an active technician job.
class ActiveJobSelectorSheet extends ConsumerWidget {
  final ValueChanged<Job> onJobSelected;

  const ActiveJobSelectorSheet({
    super.key,
    required this.onJobSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeJobsState = ref.watch(activeJobsProvider);

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
                'Select Active Job',
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
          const SizedBox(height: 8),
          Text(
            'Choose the repair job to link this spare part bill.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          activeJobsState.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error fetching active jobs: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            data: (jobs) {
              if (jobs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.orange.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No active jobs found. You must accept a job before attaching spare parts.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  final shortId = job.id.length > 8
                      ? job.id.substring(0, 8).toUpperCase()
                      : job.id.toUpperCase();

                  return InkWell(
                    onTap: () {
                      ref.read(selectedJobProvider.notifier).state = job;
                      onJobSelected(job);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.build_circle_rounded,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Job #$shortId • ${job.displayTitle}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${job.customerName ?? "Customer"} • ${job.displayAddress}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
