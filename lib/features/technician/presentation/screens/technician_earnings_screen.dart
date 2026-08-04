import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';

final completedJobsProvider = FutureProvider.family<List<Job>, String>((ref, technicianId) async {
  final repo = ref.watch(jobRepositoryProvider);
  return await repo.fetchCompletedJobsForTechnician(technicianId);
});

class TechnicianEarningsScreen extends ConsumerWidget {
  final String technicianId;

  const TechnicianEarningsScreen({
    super.key,
    this.technicianId = '00000000-0000-4000-8000-000000000001',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJobs = ref.watch(completedJobsProvider(technicianId));

    return asyncJobs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('Failed to load earnings', style: TextStyle(color: Colors.red)),
            TextButton(
              onPressed: () => ref.invalidate(completedJobsProvider(technicianId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (jobs) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final daysSinceMonday = now.weekday - 1;
        final weekStart = todayStart.subtract(Duration(days: daysSinceMonday));

        double todayEarnings = 0;
        double weeklyEarnings = 0;
        double totalPlatformCommission = 0;
        int completedCount = jobs.length;

        for (final job in jobs) {
          final updated = job.updatedAt ?? job.createdAt;
          final totalBill = job.price;
          final platformFee = totalBill * 0.10;
          final netPayout = totalBill - platformFee;

          totalPlatformCommission += platformFee;

          if (updated.isAfter(todayStart) || updated.isAtSameMomentAs(todayStart)) {
            todayEarnings += netPayout;
          }
          if (updated.isAfter(weekStart) || updated.isAtSameMomentAs(weekStart)) {
            weeklyEarnings += netPayout;
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(completedJobsProvider(technicianId));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryHeader(
                context,
                todayEarnings: todayEarnings,
                weeklyEarnings: weeklyEarnings,
                completedCount: completedCount,
                platformCommission: totalPlatformCommission,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payout Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (jobs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No completed jobs yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                )
              else
                ...jobs.map((job) => _buildEarningsCard(context, job)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context, {
    required double todayEarnings,
    required double weeklyEarnings,
    required int completedCount,
    required double platformCommission,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings Dashboard',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  'Today\'s Earnings',
                  '₹${todayEarnings.toStringAsFixed(0)}',
                  Colors.green.shade700,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: _buildSummaryMetric(
                  'Weekly Total',
                  '₹${weeklyEarnings.toStringAsFixed(0)}',
                  Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  'Completed Jobs',
                  '$completedCount',
                  Colors.black87,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: _buildSummaryMetric(
                  'Platform Commission',
                  '₹${platformCommission.toStringAsFixed(0)}',
                  Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(BuildContext context, Job job) {
    final totalBill = job.price;
    final platformFee = totalBill * 0.10;
    final netPayout = totalBill - platformFee;
    
    final updatedDate = job.updatedAt ?? job.createdAt;
    final formattedDate = DateFormat('MMM d, y • h:mm a').format(updatedDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${job.customerName ?? 'Customer'} - ${job.applianceCategory ?? 'Repair'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Customer Bill'),
                Text('₹${totalBill.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Platform Commission (10%)', style: TextStyle(color: Colors.orange.shade800)),
                Text('- ₹${platformFee.toStringAsFixed(2)}', style: TextStyle(color: Colors.orange.shade800)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Technician Payout',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  Text(
                    '₹${netPayout.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
