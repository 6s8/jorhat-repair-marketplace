import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_progress_indicator.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';
import '../providers/technician_active_jobs_provider.dart';
import '../widgets/complaint_image_viewer.dart';

class ActiveJobsTab extends ConsumerStatefulWidget {
  const ActiveJobsTab({super.key});

  @override
  ConsumerState<ActiveJobsTab> createState() => _ActiveJobsTabState();
}

class _ActiveJobsTabState extends ConsumerState<ActiveJobsTab> {
  final Set<String> _loadingIds = {};

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open external app.')),
      );
    }
  }

  Future<void> _handleStartNavigation(Job job) async {
    if (_loadingIds.contains(job.id)) return;
    setState(() => _loadingIds.add(job.id));

    final err = await ref
        .read(technicianActiveJobsProvider.notifier)
        .startNavigation(job.id);

    if (!mounted) return;
    setState(() => _loadingIds.remove(job.id));

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated to On The Way!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (job.latitude != null && job.longitude != null) {
        final mapsUrl =
            'https://www.google.com/maps/dir/?api=1&destination=${job.latitude},${job.longitude}';
        _launchUrl(mapsUrl);
      }
    }
  }

  void _showArrivalOtpModal(Job job) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;
        final primaryColor = Theme.of(context).colorScheme.primary;
        final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Enter Customer Arrival OTP',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask ${job.customerName ?? "the customer"} for their Arrival Verification Code.',
                    style: TextStyle(color: mutedTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: '4-digit Arrival OTP',
                      prefixIcon: Icon(Icons.verified_user_outlined, color: primaryColor),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          if (otp.isEmpty) return;
                          setModalState(() => isSubmitting = true);
                          final err = await ref
                              .read(technicianActiveJobsProvider.notifier)
                              .verifyArrivalOtp(job.id, otp);
                          if (!mounted) return;
                          try { setModalState(() => isSubmitting = false); } catch (_) {}
                          if (err != null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else {
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Arrival verified! Job is In Progress.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.text,
                  ),
                  child: isSubmitting
                      ? const AppProgressIndicator(size: 18)
                      : const Text('VERIFY & START REPAIR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCompletionOtpModal(Job job) {
    final otpController = TextEditingController();
    final amountController =
        TextEditingController(text: job.price.toStringAsFixed(0));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;
        final primaryColor = Theme.of(context).colorScheme.primary;
        final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Complete Repair & Final Bill',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the Final Total Bill Amount (including spare parts if any) and ask ${job.customerName ?? "the customer"} for their Completion Verification Code.',
                      style: TextStyle(color: mutedTextColor, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Final Repair Bill Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: '4-digit Completion OTP',
                        prefixIcon: Icon(Icons.lock_open, color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          final amount =
                              double.tryParse(amountController.text.trim()) ??
                                  job.price;
                          if (otp.isEmpty) return;

                          setModalState(() => isSubmitting = true);
                          final err = await ref
                              .read(technicianActiveJobsProvider.notifier)
                              .verifyCompletionOtpAndComplete(
                                job.id,
                                otp,
                                amount,
                              );
                          if (!mounted) return;
                          try { setModalState(() => isSubmitting = false); } catch (_) {}
                          if (err != null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else {
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Job Completed Successfully! Earnings added.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const AppProgressIndicator(size: 18)
                      : const Text('COMPLETE JOB', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(technicianActiveJobsProvider);
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(technicianActiveJobsProvider);
        },
        child: activeState.when(
          loading: () => const Center(
            child: AppProgressIndicator(label: 'Loading active jobs...'),
          ),
          error: (err, _) => Center(
            child: Text('Error loading active jobs: $err', style: const TextStyle(color: AppColors.error)),
          ),
          data: (jobs) {
            if (jobs.isEmpty) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 64,
                            color: mutedTextColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Active Repair Jobs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: mutedTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accepted repair requests will appear here.\nCheck the Pending Jobs tab to accept incoming jobs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: mutedTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _buildActiveJobCard(context, job);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveJobCard(BuildContext context, Job job) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = job.status == 'accepted'
        ? primaryColor
        : job.status == 'on_the_way'
            ? AppColors.accent
            : AppColors.secondary;

    final statusText = job.status == 'accepted'
        ? 'ACCEPTED - WAITING TO START'
        : job.status == 'on_the_way'
            ? 'ON THE WAY TO CUSTOMER'
            : 'IN PROGRESS / REPAIRING';

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: (statusColor == AppColors.accent && !isDark) ? AppColors.text : statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '₹${job.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.applianceCategory ?? job.issue,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: mutedTextColor),
                const SizedBox(width: 6),
                Text(
                  job.customerName ?? 'Fixly Customer',
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                      style: TextStyle(color: mutedTextColor),
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
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final phone = job.customerPhone ?? '+919876543210';
                      _launchUrl('tel:$phone');
                    },
                    icon: const Icon(Icons.phone, size: 18, color: AppColors.success),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final phone = (job.customerPhone ?? '919876543210')
                          .replaceAll('+', '')
                          .replaceAll(' ', '');
                      _launchUrl('https://wa.me/$phone');
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.secondary),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (job.latitude != null && job.longitude != null) {
                        final mapsUrl =
                            'https://www.google.com/maps/dir/?api=1&destination=${job.latitude},${job.longitude}';
                        _launchUrl(mapsUrl);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GPS coordinates not available.')),
                        );
                      }
                    },
                    icon: Icon(Icons.map_outlined, size: 18, color: primaryColor),
                    label: const Text('Maps'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SparePartsInvoiceCard(job: job),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: job.status == 'accepted'
                  ? ElevatedButton.icon(
                      onPressed: _loadingIds.contains(job.id)
                          ? null
                          : () => _handleStartNavigation(job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text(
                        'START NAVIGATION / ON THE WAY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : job.status == 'on_the_way'
                      ? ElevatedButton.icon(
                          onPressed: () => _showArrivalOtpModal(job),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.text, // Charcoal text on Marigold for contrast
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.location_on),
                          label: const Text(
                            'ARRIVED - ENTER ARRIVAL OTP',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _showCompletionOtpModal(job),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'COMPLETE REPAIR - ENTER OTP',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparePartsInvoiceCard extends ConsumerStatefulWidget {
  final Job job;
  const _SparePartsInvoiceCard({required this.job});

  @override
  ConsumerState<_SparePartsInvoiceCard> createState() =>
      _SparePartsInvoiceCardState();
}

class _SparePartsInvoiceCardState
    extends ConsumerState<_SparePartsInvoiceCard> {
  bool _isExpanded = false;
  bool _isUpdating = false;
  final TextEditingController _partsController = TextEditingController();
  double _addedPartsCost = 0.0;

  @override
  void dispose() {
    _partsController.dispose();
    super.dispose();
  }

  Future<void> _applyPartsCost() async {
    final amount = double.tryParse(_partsController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isUpdating = true);
    final newTotal = widget.job.price + amount;

    try {
      await ref
          .read(jobRepositoryProvider)
          .updateJobPrice(widget.job.id, newTotal);
      if (!mounted) return;
      setState(() {
        _addedPartsCost += amount;
        _isUpdating = false;
        _isExpanded = false;
        _partsController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Spare parts ₹${amount.toStringAsFixed(0)} added! New invoice: ₹${newTotal.toStringAsFixed(0)}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update invoice: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = widget.job.price - _addedPartsCost;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('INVOICE BREAKDOWN',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: mutedTextColor)),
              TextButton.icon(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                    _isExpanded
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    size: 16,
                    color: primaryColor),
                label: Text(_isExpanded ? 'Hide Parts' : '+ Add Spare Parts',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Base Service Charge:',
                  style: TextStyle(fontSize: 13)),
              Text('₹${basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          if (_addedPartsCost > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Spare Parts Added:',
                    style: TextStyle(fontSize: 13, color: AppColors.success)),
                Text('+ ₹${_addedPartsCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Estimated Bill:',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              Text('₹${widget.job.price.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor)),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _partsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Spare Parts Cost (₹)',
                      hintText: 'e.g. 1200',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isUpdating ? null : _applyPartsCost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.text,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isUpdating
                      ? const AppProgressIndicator(size: 16)
                      : const Text('Apply'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
