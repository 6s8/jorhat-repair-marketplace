import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_progress_indicator.dart';
import '../../../../models/job_model.dart';
import '../providers/technician_earnings_provider.dart';

class EarningsTab extends ConsumerWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedState = ref.watch(technicianCompletedJobsProvider);
    final summaryState = ref.watch(technicianEarningsSummaryProvider);
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(technicianCompletedJobsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Summary Cards Header
            SliverToBoxAdapter(
              child: summaryState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: AppProgressIndicator(label: 'Calculating earnings...'),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error computing earnings: $err', style: const TextStyle(color: AppColors.error)),
                ),
                data: (summary) => _buildSummaryCards(context, summary),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'COMPLETED JOBS BREAKDOWN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: mutedTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            completedState.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: AppProgressIndicator(label: 'Loading completed jobs...'),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error loading completed jobs: $err', style: const TextStyle(color: AppColors.error))),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: mutedTextColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Completed Jobs Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: mutedTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Completed repair jobs will appear here with your payout summary.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: mutedTextColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final job = jobs[index];
                        return _buildCompletedJobCard(context, job);
                      },
                      childCount: jobs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, TechnicianEarningsSummary summary) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: "Today's Earnings",
                  value: '₹${summary.todayEarnings.toStringAsFixed(0)}',
                  icon: Icons.today,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Weekly Total',
                  value: '₹${summary.weeklyEarnings.toStringAsFixed(0)}',
                  icon: Icons.date_range,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Monthly Total',
                  value: '₹${summary.monthlyEarnings.toStringAsFixed(0)}',
                  icon: Icons.calendar_month,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Completed Jobs',
                  value: '${summary.completedJobsCount}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Platform Commission (10%)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '-₹${summary.totalCommission.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.white24,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL NET PAYOUT (90%)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${summary.totalNetPayout.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildCompletedJobCard(BuildContext context, Job job) {
    final gross = job.finalAmount ?? job.price;
    final commission = gross * 0.1;
    final netPayout = gross * 0.9;
    final date = job.completedAt ?? job.updatedAt ?? job.createdAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job.applianceCategory ?? job.issue,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              job.customerName ?? 'Fixly Customer',
              style: TextStyle(fontSize: 13, color: mutedTextColor),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Customer Bill:', style: TextStyle(color: mutedTextColor, fontSize: 13)),
                Text(
                  '₹${gross.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('(-) Platform Commission (10%):', style: TextStyle(color: AppColors.error, fontSize: 13)),
                Text(
                  '-₹${commission.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '(=) NET TECHNICIAN PAYOUT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '₹${netPayout.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                      fontSize: 18,
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
