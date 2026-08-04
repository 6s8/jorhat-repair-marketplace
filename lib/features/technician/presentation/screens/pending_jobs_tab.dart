import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_progress_indicator.dart';
import '../../../../models/job_model.dart';
import '../providers/technician_default_view_provider.dart';
import '../providers/technician_pending_jobs_provider.dart';
import '../providers/technician_profile_provider.dart';
import '../widgets/complaint_image_viewer.dart';
import '../widgets/radar_job_alert_dialog.dart';
import 'job_feed_map_view.dart';

class PendingJobsTab extends ConsumerStatefulWidget {
  const PendingJobsTab({super.key});

  @override
  ConsumerState<PendingJobsTab> createState() => _PendingJobsTabState();
}

class _PendingJobsTabState extends ConsumerState<PendingJobsTab> {
  final Set<String> _acceptingIds = {};
  ProviderSubscription? _alertSubscription;

  @override
  void initState() {
    super.initState();
    _alertSubscription = ref.listenManual(latestAlertJobProvider, (previous, next) {
      if (next != null && mounted) {
        RadarJobAlertDialog.show(context, next);
      }
    });
  }

  @override
  void dispose() {
    _alertSubscription?.close();
    super.dispose();
  }

  Future<void> _handleAccept(String jobId) async {
    if (_acceptingIds.contains(jobId)) return;
    setState(() => _acceptingIds.add(jobId));

    final result = await ref.read(technicianPendingJobsProvider.notifier).acceptJob(jobId);

    if (!mounted) return;
    setState(() => _acceptingIds.remove(jobId));

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job accepted successfully! Check Active Jobs tab.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Could not accept job. It may have been accepted by another technician.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(technicianPendingJobsProvider);
    final profileState = ref.watch(technicianProfileProvider);
    final showMapView = ref.watch(technicianDefaultViewProvider);

    final profile = profileState.value;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isOffline = profile == null || !profile.isOnline;
    final technicianId = profile?.id ?? '00000000-0000-4000-8000-000000000001';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Dispatch Feed',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Center(
            child: _ViewToggleSegment(
              isMap: showMapView,
              onChanged: (isMap) {
                ref.read(technicianDefaultViewProvider.notifier).setDefaultView(isMap);
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Radar Settings',
            onPressed: () {
              context.push('/radar-settings');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: showMapView
          ? JobFeedMapView(technicianId: technicianId)
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async {
                await ref.read(technicianPendingJobsProvider.notifier).refresh();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (isOffline)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You are Offline. Toggle Online status in your Profile to start receiving repair requests within ${profile?.workRadiusKm.toStringAsFixed(0) ?? 20} km.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  pendingState.when(
                    loading: () => const SliverFillRemaining(
                      child: Center(
                        child: AppProgressIndicator(label: 'Scanning live job feed...'),
                      ),
                    ),
                    error: (err, _) => SliverFillRemaining(
                      child: Center(
                        child: Text('Error loading pending jobs: $err', style: const TextStyle(color: AppColors.error)),
                      ),
                    ),
                    data: (jobs) {
                      if (jobs.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.radar,
                                    size: 64, color: mutedTextColor.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  'No Pending Jobs Nearby',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: mutedTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scanning within ${profile?.workRadiusKm.toStringAsFixed(0) ?? 20} km radius of Jorhat...\nNew requests will appear here automatically.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: mutedTextColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final job = jobs[index];
                              return _buildJobCard(context, job);
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

  Widget _buildJobCard(BuildContext context, Job job) {
    final isAccepting = _acceptingIds.contains(job.id);
    final netPayout = job.price * 0.9;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.home_repair_service_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          job.applianceCategory ?? job.issue,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.near_me, size: 14, color: isDark ? AppColors.accent : AppColors.text),
                      const SizedBox(width: 4),
                      Text(
                        '${job.distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.accent : AppColors.text,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.person, size: 18, color: mutedTextColor),
                const SizedBox(width: 6),
                Text(
                  job.customerName ?? 'Fixly Customer',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            if (job.addressText != null && job.addressText!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: mutedTextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.addressText!,
                      style: TextStyle(color: mutedTextColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                job.issueDescription ?? job.issue,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (job.imageUrls != null && job.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Complaint Photos:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mutedTextColor),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: job.imageUrls!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final url = job.imageUrls![index];
                    return GestureDetector(
                      onTap: () => ComplaintImageViewer.show(
                        context,
                        job.imageUrls!,
                        initialIndex: index,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 54,
                            height: 54,
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 18),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Payout (90%)',
                      style: TextStyle(fontSize: 11, color: mutedTextColor),
                    ),
                    Text(
                      '₹${netPayout.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: isAccepting ? null : () => _handleAccept(job.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.text,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppColors.text,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    isAccepting ? 'Accepting...' : 'ACCEPT JOB',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom sleek pill-shaped view toggle (List vs Map) for Live Dispatch Feed header.
class _ViewToggleSegment extends StatelessWidget {
  final bool isMap;
  final ValueChanged<bool> onChanged;

  const _ViewToggleSegment({
    required this.isMap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            context,
            title: 'List',
            icon: Icons.format_list_bulleted_rounded,
            isSelected: !isMap,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 2),
          _buildItem(
            context,
            title: 'Map',
            icon: Icons.map_rounded,
            isSelected: isMap,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.text : Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.text : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
