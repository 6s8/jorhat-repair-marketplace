import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/job_model.dart';
import '../providers/technician_pending_jobs_provider.dart';
import '../providers/technician_profile_provider.dart';
import 'complaint_image_viewer.dart';

class RadarJobAlertDialog extends ConsumerStatefulWidget {
  final Job job;

  const RadarJobAlertDialog({super.key, required this.job});

  static String? _currentlyShowingJobId;

  static void show(BuildContext context, Job job) {
    if (_currentlyShowingJobId == job.id) return;
    _currentlyShowingJobId = job.id;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RadarJobAlertDialog(job: job),
    ).then((_) {
      _currentlyShowingJobId = null;
    });
  }

  @override
  ConsumerState<RadarJobAlertDialog> createState() => _RadarJobAlertDialogState();
}

class _RadarJobAlertDialogState extends ConsumerState<RadarJobAlertDialog> {
  late int _remainingSec;
  late int _totalSec;
  Timer? _timer;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(technicianProfileProvider).value;
    _totalSec = profile?.alertTimerSec ?? 30;
    _remainingSec = _totalSec;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSec <= 1) {
        timer.cancel();
        ref.read(technicianPendingJobsProvider.notifier).rejectJob(widget.job.id);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() => _remainingSec--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);
    _timer?.cancel();
    ref.read(latestAlertJobProvider.notifier).clearAlert();

    final result = await ref
        .read(technicianPendingJobsProvider.notifier)
        .acceptJob(widget.job.id);

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job Accepted! Check Active Jobs tab.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Job already accepted by another technician.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _handleReject() {
    _timer?.cancel();
    ref.read(technicianPendingJobsProvider.notifier).rejectJob(widget.job.id);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _remainingSec / _totalSec;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Alert Badge & Countdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.radar,
                        color: Colors.deepOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'NEW JOB RADAR ALERT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _remainingSec <= 10
                        ? Colors.red.withValues(alpha: 0.15)
                        : Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_remainingSec}s left',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _remainingSec <= 10 ? Colors.red : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Countdown progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                color: _remainingSec <= 10 ? Colors.red : Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 16),
            // Appliance Category & Distance Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.job.applianceCategory ?? widget.job.issue,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.deepOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.job.distanceKm} km away',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Customer Info & Address
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  widget.job.customerName ?? 'Assam Customer',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (widget.job.addressText != null && widget.job.addressText!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home_outlined, size: 18, color: Colors.black54),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.job.addressText!,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Issue Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complaint Details:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.job.issueDescription ?? widget.job.issue,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            // Complaint Images Preview
            if (widget.job.imageUrls != null && widget.job.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Complaint Photos (Tap to enlarge):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.job.imageUrls!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final url = widget.job.imageUrls![index];
                    return GestureDetector(
                      onTap: () => ComplaintImageViewer.show(
                        context,
                        widget.job.imageUrls!,
                        initialIndex: index,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Estimated Earnings Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estimated Payout (90%):',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  Text(
                    '₹${(widget.job.price * 0.9).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleReject,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isAccepting ? null : _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isAccepting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'ACCEPT JOB',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
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
