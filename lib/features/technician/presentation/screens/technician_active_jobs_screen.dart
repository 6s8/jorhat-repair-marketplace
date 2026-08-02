import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';

// ─── Provider: fetch active (accepted) jobs for this technician ───────────────
final activeJobsProvider = FutureProvider.family<List<Job>, String>((ref, technicianId) async {
  final repo = ref.read(jobRepositoryProvider);
  return repo.fetchActiveJobsForTechnician(technicianId);
});

/// Technician Active Jobs screen — shows accepted jobs with "Mark Completed".
/// Hosted inside _TechnicianShell which already provides AppBar + TabBar.
class TechnicianActiveJobsScreen extends ConsumerWidget {
  final String technicianId;

  const TechnicianActiveJobsScreen({
    super.key,
    this.technicianId = 'tech-jorhat-001',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJobs = ref.watch(activeJobsProvider(technicianId));

    return asyncJobs.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1565C0)),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Failed to load active jobs',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(activeJobsProvider(technicianId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (jobs) {
        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1D2E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.work_off_rounded, size: 48, color: Colors.white24),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Active Jobs',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accept a job from the Live Feed to see it here.',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(activeJobsProvider(technicianId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF42A5F5),
          backgroundColor: const Color(0xFF1A1D2E),
          onRefresh: () async => ref.invalidate(activeJobsProvider(technicianId)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: jobs.length,
            itemBuilder: (context, index) => _ActiveJobCard(
              key: ValueKey(jobs[index].id),
              job: jobs[index],
              technicianId: technicianId,
              onCompleted: () => ref.invalidate(activeJobsProvider(technicianId)),
            ),
          ),
        );
      },
    );
  }
}

// ─── Active Job Card ──────────────────────────────────────────────────────────
class _ActiveJobCard extends ConsumerStatefulWidget {
  final Job job;
  final String technicianId;
  final VoidCallback onCompleted;

  const _ActiveJobCard({
    super.key,
    required this.job,
    required this.technicianId,
    required this.onCompleted,
  });

  @override
  ConsumerState<_ActiveJobCard> createState() => _ActiveJobCardState();
}

class _ActiveJobCardState extends ConsumerState<_ActiveJobCard> {
  bool _isCompleting = false;

  Future<void> _markCompleted() async {
    setState(() => _isCompleting = true);

    final repo = ref.read(jobRepositoryProvider);
    final result = await repo.completeJob(widget.job.id, widget.technicianId);

    if (!mounted) return;

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Job successfully completed!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onCompleted();
      },
      jobAlreadyTaken: (msg) => _showError(msg),
      networkError: (msg) => _showError('Network error: $msg'),
      timeout: (msg) => _showError('Timed out: $msg'),
      unknownError: (msg) => _showError(msg),
    );

    if (mounted) setState(() => _isCompleting = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.engineering_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    job.displayTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${job.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue description
                if (job.displayIssue.isNotEmpty &&
                    job.displayIssue != job.displayTitle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      job.displayIssue,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Contact
                if (job.displayContact.isNotEmpty)
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: job.displayContact,
                  ),

                // Address
                if (job.displayAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: job.displayAddress,
                  ),
                ],

                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Job #${job.id.substring(0, 8).toUpperCase()}',
                ),

                const SizedBox(height: 16),

                // ── Mark Completed button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isCompleting ? null : _markCompleted,
                    icon: _isCompleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      _isCompleting ? 'Completing...' : 'Mark as Completed',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1B5E20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
