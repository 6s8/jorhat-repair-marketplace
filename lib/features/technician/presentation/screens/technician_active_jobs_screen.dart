import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';
import '../../../booking/pricing/pricing_breakdown.dart';

// ─── Provider: fetch active (accepted) jobs for this technician ───────────────
final activeJobsProvider = FutureProvider.family<List<Job>, String>((ref, technicianId) async {
  final repo = ref.read(jobRepositoryProvider);
  return repo.fetchActiveJobsForTechnician(technicianId);
});

/// Technician Active Jobs screen — shows accepted jobs with pricing breakdown
/// and "Mark Completed". Hosted inside _TechnicianShell (AppBar+TabBar already provided).
class TechnicianActiveJobsScreen extends ConsumerWidget {
  final String technicianId;

  const TechnicianActiveJobsScreen({
    super.key,
    this.technicianId = '00000000-0000-4000-8000-000000000001',
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
              const Text('Failed to load active jobs',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
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
                  child: const Icon(Icons.work_off_rounded,
                      size: 48, color: Colors.white24),
                ),
                const SizedBox(height: 24),
                const Text('No Active Jobs',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Accept a job from the Live Feed to see it here.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(activeJobsProvider(technicianId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0)),
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
  bool _showSpareParts = false;
  double _spareParts = 0.0; // live preview value while typing
  bool _isUpdatingPrice = false;
  final _sparePartsController = TextEditingController();

  @override
  void dispose() {
    _sparePartsController.dispose();
    super.dispose();
  }

  /// Update price in DB = base + spare parts, then refresh local state.
  Future<void> _applySpareParts() async {
    final parts = double.tryParse(_sparePartsController.text.trim()) ?? 0.0;
    if (parts <= 0) return;

    setState(() => _isUpdatingPrice = true);

    final newTotal = widget.job.price + parts;
    try {
      await ref.read(jobRepositoryProvider).updateJobPrice(widget.job.id, newTotal);
      if (!mounted) return;
      setState(() {
        _spareParts = 0.0; // reset preview — DB now holds updated value
        _isUpdatingPrice = false;
        _showSpareParts = false;
        _sparePartsController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.build_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Spare parts ₹${parts.toStringAsFixed(0)} added to invoice'),
          ]),
          backgroundColor: const Color(0xFF1565C0),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Refresh list so the card re-fetches updated price from DB
      widget.onCompleted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingPrice = false);
      _showError('Failed to update price: $e');
    }
  }

  Future<void> _markCompleted() async {
    setState(() => _isCompleting = true);
    final result = await ref
        .read(jobRepositoryProvider)
        .completeJob(widget.job.id, widget.technicianId);

    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Job successfully completed!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red[700],
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    // `price` in DB is the customer total. _spareParts is a live typing preview.
    final breakdown = PricingBreakdown(
      baseServiceCharge: job.price,
      spareParts: _spareParts,
    );

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
          // ── Gradient header ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.engineering_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    job.displayTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Job #${job.id.substring(0, 6).toUpperCase()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Job info rows ─────────────────────────────────────────
                if (job.displayIssue.isNotEmpty &&
                    job.displayIssue != job.displayTitle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(job.displayIssue,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                if (job.displayContact.isNotEmpty)
                  _InfoRow(
                      icon: Icons.person_rounded,
                      label: job.displayContact),
                if (job.displayAddress.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: job.displayAddress),
                ],

                const SizedBox(height: 14),
                const Divider(color: Color(0xFF2A2D3E)),
                const SizedBox(height: 12),

                // ── INVOICE BREAKDOWN ─────────────────────────────────────
                const Text(
                  'INVOICE BREAKDOWN',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                _PriceRow(
                  label: 'Service Charge',
                  amount: breakdown.baseServiceStr,
                  color: Colors.white70,
                ),
                if (_spareParts > 0) ...[
                  const SizedBox(height: 5),
                  _PriceRow(
                    label: 'Spare Parts (preview)',
                    amount: breakdown.sparePartsStr,
                    color: const Color(0xFF42A5F5),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1426),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _PriceRow(
                        label: '👤  Customer Total',
                        amount: breakdown.customerTotalStr,
                        color: Colors.white,
                        bold: true,
                      ),
                      const SizedBox(height: 7),
                      _PriceRow(
                        label: '🏢  Platform Fee (20%)',
                        amount: '− ${breakdown.platformFeeStr}',
                        color: Colors.white38,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 7),
                        child: Divider(color: Colors.white10, height: 1),
                      ),
                      _PriceRow(
                        label: '💰  Your Payout (80%)',
                        amount: breakdown.technicianPayoutStr,
                        color: const Color(0xFF66BB6A),
                        bold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Add Spare Parts toggle ────────────────────────────────
                GestureDetector(
                  onTap: () =>
                      setState(() => _showSpareParts = !_showSpareParts),
                  child: Row(
                    children: [
                      Icon(
                        _showSpareParts
                            ? Icons.expand_less_rounded
                            : Icons.add_circle_outline_rounded,
                        color: const Color(0xFF42A5F5),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showSpareParts
                            ? 'Cancel'
                            : 'Add spare parts cost',
                        style: const TextStyle(
                          color: Color(0xFF42A5F5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Spare parts input (expandable) ────────────────────────
                if (_showSpareParts) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sparePartsController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter amount (₹)',
                            hintStyle:
                                const TextStyle(color: Colors.white38),
                            prefixText: '₹ ',
                            prefixStyle:
                                const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF0D1426),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.white12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1565C0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (val) {
                            // Live preview: update breakdown in real-time
                            setState(() =>
                                _spareParts = double.tryParse(val) ?? 0.0);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed:
                              _isUpdatingPrice ? null : _applySpareParts,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isUpdatingPrice
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Apply',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // ── Mark as Completed ─────────────────────────────────────
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      _isCompleting ? 'Completing...' : 'Mark as Completed',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1B5E20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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

// ─── Price Row ────────────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool bold;

  const _PriceRow({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontSize: bold ? 14 : 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount, style: style),
      ],
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
          child: Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ),
      ],
    );
  }
}
