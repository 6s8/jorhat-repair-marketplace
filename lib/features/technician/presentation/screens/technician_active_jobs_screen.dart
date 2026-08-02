import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';
import '../../../booking/pricing/pricing_breakdown.dart';

// ─── Provider: fetch active jobs for this technician ─────────────────────────
final activeJobsProvider = FutureProvider.family<List<Job>, String>(
  (ref, technicianId) async {
    final repo = ref.read(jobRepositoryProvider);
    return repo.fetchActiveJobsForTechnician(technicianId);
  },
);

/// Returns all active jobs — both 'accepted' and 'on_the_way' statuses.
/// The repository's fetchActiveJobsForTechnician already filters by technician.
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
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load active jobs',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(activeJobsProvider(technicianId)),
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
                const Text(
                    'Accept a job from the Live Feed to see it here.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(activeJobsProvider(technicianId)),
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
          onRefresh: () async =>
              ref.invalidate(activeJobsProvider(technicianId)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: jobs.length,
            itemBuilder: (context, index) => _ActiveJobCard(
              key: ValueKey(jobs[index].id),
              job: jobs[index],
              technicianId: technicianId,
              onRefresh: () => ref.invalidate(activeJobsProvider(technicianId)),
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
  final VoidCallback onRefresh;

  const _ActiveJobCard({
    super.key,
    required this.job,
    required this.technicianId,
    required this.onRefresh,
  });

  @override
  ConsumerState<_ActiveJobCard> createState() => _ActiveJobCardState();
}

class _ActiveJobCardState extends ConsumerState<_ActiveJobCard> {
  bool _isUpdatingStatus = false;
  bool _showSpareParts = false;
  double _spareParts = 0.0;
  bool _isUpdatingPrice = false;
  final _sparePartsController = TextEditingController();

  @override
  void dispose() {
    _sparePartsController.dispose();
    super.dispose();
  }

  // ── Status transitions ──────────────────────────────────────────────────────
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    final result = await ref
        .read(jobRepositoryProvider)
        .updateJobStatus(widget.job.id, widget.technicianId, newStatus);

    if (!mounted) return;
    result.when(
      success: (_) {
        final msg = newStatus == 'on_the_way'
            ? '🚗 Journey started! Customer notified.'
            : '✅ Job completed successfully!';
        _showSnackbar(msg,
            newStatus == 'completed'
                ? const Color(0xFF2E7D32)
                : const Color(0xFF1565C0));
        widget.onRefresh();
      },
      jobAlreadyTaken: (msg) => _showError(msg),
      networkError: (msg) => _showError('Network error: $msg'),
      timeout: (msg) => _showError('Timed out: $msg'),
      unknownError: (msg) => _showError(msg),
    );
    if (mounted) setState(() => _isUpdatingStatus = false);
  }

  // ── Google Maps navigation ──────────────────────────────────────────────────
  Future<void> _openGoogleMaps() async {
    final lat = widget.job.latitude;
    final lng = widget.job.longitude;
    if (lat == null || lng == null) {
      _showError('No location data for this job.');
      return;
    }
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    
    try {
      // First try external application (works better on mobile)
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback to default mode (works on web)
        final fallbackLaunched = await launchUrl(url);
        if (!fallbackLaunched) {
          _showError('Could not open Google Maps.');
        }
      }
    } catch (e) {
      _showError('Error opening Google Maps.');
    }
  }

  // ── Call & WhatsApp ─────────────────────────────────────────────────────────
  Future<void> _callCustomer() async {
    final phone = widget.job.customerPhone;
    if (phone == null || phone.isEmpty) {
      _showError('No phone number provided.');
      return;
    }
    final url = Uri.parse('tel:$phone');
    try {
      final launched = await launchUrl(url);
      if (!launched) _showError('Could not launch dialer.');
    } catch (e) {
      _showError('Could not launch dialer.');
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.job.customerPhone;
    if (phone == null || phone.isEmpty) {
      _showError('No phone number provided.');
      return;
    }
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.length == 10) {
      formattedPhone = '91$formattedPhone';
    }
    final name = widget.job.customerName ?? 'Customer';
    final cat = widget.job.applianceCategory ?? 'appliance';
    final text = 'Hello $name, I am your technician for your $cat repair.';
    final url = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(text)}');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallbackLaunched = await launchUrl(url);
        if (!fallbackLaunched) _showError('Could not launch WhatsApp.');
      }
    } catch (e) {
      _showError('Could not launch WhatsApp.');
    }
  }

  // ── Spare parts ─────────────────────────────────────────────────────────────
  Future<void> _applySpareParts() async {
    final parts = double.tryParse(_sparePartsController.text.trim()) ?? 0.0;
    if (parts <= 0) return;
    setState(() => _isUpdatingPrice = true);
    final newTotal = widget.job.price + parts;
    try {
      await ref
          .read(jobRepositoryProvider)
          .updateJobPrice(widget.job.id, newTotal);
      if (!mounted) return;
      setState(() {
        _spareParts = 0.0;
        _isUpdatingPrice = false;
        _showSpareParts = false;
        _sparePartsController.clear();
      });
      _showSnackbar(
          '🔧 Spare parts ₹${parts.toStringAsFixed(0)} added to invoice.',
          const Color(0xFF1565C0));
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingPrice = false);
      _showError('Failed to update price: $e');
    }
  }

  void _showSnackbar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
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
    final status = job.status; // 'accepted' | 'on_the_way' | 'completed'
    final breakdown =
        PricingBreakdown(baseServiceCharge: job.price, spareParts: _spareParts);

    // Determine which action button to show based on current status
    final bool isAccepted = status == 'accepted';
    final bool isOnTheWay = status == 'on_the_way';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor(status).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: _borderColor(status).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _gradientColors(status)),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(_headerIcon(status), color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.displayTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${job.id.substring(0, 6).toUpperCase()}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11),
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
                // ── Job details ───────────────────────────────────────────
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

                // ── Invoice breakdown ─────────────────────────────────────
                const Text('INVOICE BREAKDOWN',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                const SizedBox(height: 10),
                _PriceRow(
                    label: 'Service Charge',
                    amount: breakdown.baseServiceStr,
                    color: Colors.white70),
                if (_spareParts > 0) ...[
                  const SizedBox(height: 5),
                  _PriceRow(
                      label: 'Spare Parts (preview)',
                      amount: breakdown.sparePartsStr,
                      color: const Color(0xFF42A5F5)),
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
                  child: Column(children: [
                    _PriceRow(
                        label: '👤  Customer Total',
                        amount: breakdown.customerTotalStr,
                        color: Colors.white,
                        bold: true),
                    const SizedBox(height: 6),
                    _PriceRow(
                        label: '🏢  Platform Fee (20%)',
                        amount: '− ${breakdown.platformFeeStr}',
                        color: Colors.white38),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _PriceRow(
                        label: '💰  Your Payout (80%)',
                        amount: breakdown.technicianPayoutStr,
                        color: const Color(0xFF66BB6A),
                        bold: true),
                  ]),
                ),

                const SizedBox(height: 14),

                // ── Spare parts toggle ────────────────────────────────────
                GestureDetector(
                  onTap: () =>
                      setState(() => _showSpareParts = !_showSpareParts),
                  child: Row(children: [
                    Icon(
                      _showSpareParts
                          ? Icons.expand_less_rounded
                          : Icons.add_circle_outline_rounded,
                      color: const Color(0xFF42A5F5),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showSpareParts ? 'Cancel' : 'Add spare parts cost',
                      style: const TextStyle(
                          color: Color(0xFF42A5F5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),

                if (_showSpareParts) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _sparePartsController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter amount (₹)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF0D1426),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.white12)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.white12)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1565C0))),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) => setState(
                            () => _spareParts = double.tryParse(val) ?? 0.0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: _isUpdatingPrice ? null : _applySpareParts,
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
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Apply',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ],

                const SizedBox(height: 16),
                
                // ── Call & WhatsApp buttons ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _callCustomer,
                        icon: const Icon(Icons.phone, size: 18, color: Colors.green),
                        label: const Text('Call', style: TextStyle(color: Colors.green)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                        label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF25D366))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF25D366)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Google Maps navigation button ─────────────────────────
                if (job.latitude != null && job.longitude != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _openGoogleMaps,
                      icon: const Icon(Icons.map_rounded,
                          size: 18, color: Color(0xFF42A5F5)),
                      label: const Text(
                        'Open Google Maps Navigation',
                        style: TextStyle(
                            color: Color(0xFF42A5F5),
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1565C0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Step-by-step status action button ─────────────────────
                if (isAccepted)
                  _StatusButton(
                    label: '🚗  Start Journey',
                    sublabel: 'Notify customer you\'re on the way',
                    color: const Color(0xFF1565C0),
                    icon: Icons.directions_car_rounded,
                    isLoading: _isUpdatingStatus,
                    onTap: () => _updateStatus('on_the_way'),
                  )
                else if (isOnTheWay)
                  _StatusButton(
                    label: '✅  Arrived — Complete Repair',
                    sublabel: 'Mark job as completed & close invoice',
                    color: const Color(0xFF2E7D32),
                    icon: Icons.check_circle_rounded,
                    isLoading: _isUpdatingStatus,
                    onTap: () => _updateStatus('completed'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Color _borderColor(String status) {
    switch (status) {
      case 'on_the_way':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return const Color(0xFF1565C0);
    }
  }

  List<Color> _gradientColors(String status) {
    switch (status) {
      case 'on_the_way':
        return [const Color(0xFFE65100), const Color(0xFFF57C00)];
      case 'completed':
        return [const Color(0xFF1B5E20), const Color(0xFF2E7D32)];
      default:
        return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
    }
  }

  IconData _headerIcon(String status) {
    switch (status) {
      case 'on_the_way':
        return Icons.directions_car_rounded;
      case 'completed':
        return Icons.verified_rounded;
      default:
        return Icons.engineering_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'on_the_way':
        return 'On the way';
      case 'completed':
        return 'Completed';
      default:
        return 'Assigned';
    }
  }
}

// ─── Status Action Button ─────────────────────────────────────────────────────
class _StatusButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(sublabel,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
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

  const _PriceRow(
      {required this.label,
      required this.amount,
      required this.color,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        color: color,
        fontSize: bold ? 14 : 13,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(amount, style: style)],
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
