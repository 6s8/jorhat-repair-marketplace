import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';

// ─── Provider for active jobs ─────────────────────────────────────────────────
final _activeJobsProvider = FutureProvider.family<List<Job>, String>((ref, technicianId) async {
  final repo = ref.read(jobRepositoryProvider);
  return repo.fetchActiveJobsForTechnician(technicianId);
});

/// Technician Active Jobs screen — shows accepted jobs with "Mark Completed" action.
class TechnicianActiveJobsScreen extends ConsumerWidget {
  final String technicianId;

  const TechnicianActiveJobsScreen({
    super.key,
    this.technicianId = 'tech-jorhat-001',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJobs = ref.watch(_activeJobsProvider(technicianId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        title: const Text(
          'Active Jobs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => ref.invalidate(_activeJobsProvider(technicianId)),
          ),
        ],
      ),
      body: asyncJobs.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load active jobs', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(_activeJobsProvider(technicianId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1D2E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.work_off_rounded, size: 48, color: Colors.white30),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Active Jobs',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Accept a job from the feed to see it here.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) => _ActiveJobCard(
              job: jobs[index],
              technicianId: technicianId,
              onCompleted: () => ref.invalidate(_activeJobsProvider(technicianId)),
            ),
          );
        },
      ),
    );
  }
}

// ─── Active Job Card ──────────────────────────────────────────────────────────
class _ActiveJobCard extends ConsumerStatefulWidget {
  final Job job;
  final String technicianId;
  final VoidCallback onCompleted;

  const _ActiveJobCard({
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
                Icon(Icons.verified_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Job marked as completed!'),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        widget.onCompleted();
      },
      jobAlreadyTaken: (msg) => _showError(msg),
      networkError: (msg) => _showError(msg),
      timeout: (msg) => _showError(msg),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    // Parse the issue text for display
    final lines = job.issue.split('\n');
    final title = lines.isNotEmpty ? lines[0] : job.issue;
    final address = lines.length > 2 ? lines[2].replaceFirst('Address: ', '') : '';
    final contact = lines.length > 1 ? lines[1].replaceFirst('Contact: ', '') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.4)),
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
          // Header strip
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
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${job.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contact.isNotEmpty)
                  _InfoRow(icon: Icons.person_rounded, label: contact),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.location_on_rounded, label: address),
                ],
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.confirmation_number_rounded,
                  label: 'ID: ${job.id.substring(0, 8).toUpperCase()}',
                ),
                const SizedBox(height: 16),

                // Mark Completed Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isCompleting ? null : _markCompleted,
                    icon: _isCompleting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(_isCompleting ? 'Completing...' : 'Mark as Completed'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
