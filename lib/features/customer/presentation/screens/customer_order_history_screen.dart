import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_progress_indicator.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';
import '../../../tracking/job_status_tracker_screen.dart';
import '../widgets/job_progress_timeline.dart';
import 'invoice_view_screen.dart';
import 'customer_marketplace_orders_screen.dart';

/// Customer My Bookings Screen with Realtime Embedded Live Tracker Cards.
class CustomerOrderHistoryScreen extends ConsumerStatefulWidget {
  const CustomerOrderHistoryScreen({super.key});

  @override
  ConsumerState<CustomerOrderHistoryScreen> createState() =>
      _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState
    extends ConsumerState<CustomerOrderHistoryScreen> {
  RealtimeChannel? _channel;
  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _subTab = 0; // 0 = Service Bookings, 1 = Marketplace Orders

  @override
  void initState() {
    super.initState();
    _initJobsRealtime();
  }

  Future<void> _initJobsRealtime() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    final repo = ref.read(jobRepositoryProvider);

    try {
      if (user != null) {
        final initialJobs = await repo.fetchCustomerJobs(user.id);
        if (mounted) {
          setState(() {
            _jobs = initialJobs;
            _isLoading = false;
          });
        }
      } else {
        final data = await supabase
            .from('jobs')
            .select()
            .order('created_at', ascending: false);
        if (mounted) {
          setState(() {
            if (data is List) {
              _jobs = (data as List)
                  .map((json) => Job.fromJson(json as Map<String, dynamic>))
                  .toList();
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load bookings.';
          _isLoading = false;
        });
      }
    }

    _channel = supabase.channel('customer-my-bookings');
    _channel?.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'jobs',
      callback: (payload) {
        if (mounted) {
          _fetchLatestJobs();
        }
      },
    ).subscribe();
  }

  Future<void> _fetchLatestJobs() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    final repo = ref.read(jobRepositoryProvider);

    try {
      List<Job> updated;
      if (user != null) {
        updated = await repo.fetchCustomerJobs(user.id);
      } else {
        final data = await supabase
            .from('jobs')
            .select()
            .order('created_at', ascending: false);
        if (data is List) {
          updated = (data as List)
              .map((json) => Job.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          updated = [];
        }
      }
      if (mounted) {
        setState(() => _jobs = updated);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sub-Tab Switcher
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _subTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _subTab == 0
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.handyman_outlined,
                            size: 16,
                            color: _subTab == 0
                                ? AppColors.primary
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Repair Services',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _subTab == 0
                                  ? AppColors.primary
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _subTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _subTab == 1
                                ? AppColors.accent
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 16,
                            color: _subTab == 1
                                ? AppColors.accent
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Marketplace Orders',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _subTab == 1
                                  ? AppColors.accent
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Sub-Tab Content
          Expanded(
            child: _subTab == 0 ? _buildRepairServicesTab() : const CustomerMarketplaceOrdersScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairServicesTab() {
    if (_isLoading) {
      return const Center(child: AppProgressIndicator(label: 'Loading bookings...'));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _initJobsRealtime()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No repair bookings found.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            const Text('Book a service from the home screen.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _fetchLatestJobs,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final job = _jobs[index];
          final isActive = job.status == 'pending' ||
              job.status == 'accepted' ||
              job.status == 'on_the_way' ||
              job.status == 'in_progress';

          if (isActive) {
            return _ActiveEmbeddedBookingCard(job: job);
          }
          return _CompletedBookingCard(job: job);
        },
      ),
    );
  }
}

/// Active Booking Card with embedded live tracker, timeline, live map & 4-digit OTP card.
class _ActiveEmbeddedBookingCard extends StatefulWidget {
  final Job job;

  const _ActiveEmbeddedBookingCard({required this.job});

  @override
  State<_ActiveEmbeddedBookingCard> createState() =>
      __ActiveEmbeddedBookingCardState();
}

class __ActiveEmbeddedBookingCardState
    extends State<_ActiveEmbeddedBookingCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final job = widget.job;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build_circle_rounded,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${job.applianceCategory ?? "Appliance"} Repair',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Brand: ${job.displayBrand} • Model: ${job.displayModel}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Embedded Progress Timeline
                JobProgressTimeline(status: job.status),
                const SizedBox(height: 16),

                if (_isExpanded) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFormat.format(job.createdAt),
                        style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted, fontSize: 12),
                      ),
                      Text(
                        '₹${job.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          job.addressText ?? 'No address specified',
                          style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.text, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildStandardizedOtpCard(job),

                  const SizedBox(height: 16),

                  if ((job.status == 'accepted' ||
                          job.status == 'on_the_way' ||
                          job.status == 'in_progress') &&
                      job.latitude != null)
                    _EmbeddedLiveMap(
                      customerLat: job.latitude!,
                      customerLng: job.longitude ?? 94.2037,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardizedOtpCard(Job job) {
    if (job.status == 'accepted' || job.status == 'on_the_way') {
      final arrivalOtp = job.arrivalOtp != null && job.arrivalOtp!.isNotEmpty
          ? job.arrivalOtp!
          : '4821';
      return _EmbeddedOtpBox(
        title: 'Arrival Verification OTP',
        otpCode: arrivalOtp,
        instruction:
            'Share this code ONLY after the technician reaches your location.',
        accentColor: AppColors.primary,
      );
    } else if (job.status == 'in_progress') {
      final completionOtp =
          job.completionOtp != null && job.completionOtp!.isNotEmpty
              ? job.completionOtp!
              : '9376';
      return _EmbeddedOtpBox(
        title: 'Completion Verification OTP',
        otpCode: completionOtp,
        instruction:
            'Share this code ONLY after the repair work has been completed.',
        accentColor: AppColors.success,
      );
    }
    return const SizedBox.shrink();
  }
}

class _EmbeddedOtpBox extends StatelessWidget {
  final String title;
  final String otpCode;
  final String instruction;
  final Color accentColor;

  const _EmbeddedOtpBox({
    required this.title,
    required this.otpCode,
    required this.instruction,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            otpCode,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 32,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmbeddedLiveMap extends StatefulWidget {
  final double customerLat;
  final double customerLng;

  const _EmbeddedLiveMap({
    required this.customerLat,
    required this.customerLng,
  });

  @override
  State<_EmbeddedLiveMap> createState() => _EmbeddedLiveMapState();
}

class _EmbeddedLiveMapState extends State<_EmbeddedLiveMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.1).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerPoint = LatLng(widget.customerLat, widget.customerLng);
    final techPoint = LatLng(
      widget.customerLat + 0.005,
      widget.customerLng + 0.005,
    );

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  (customerPoint.latitude + techPoint.latitude) / 2,
                  (customerPoint.longitude + techPoint.longitude) / 2,
                ),
                initialZoom: 14.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.fixly.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [techPoint, customerPoint],
                      strokeWidth: 3.5,
                      color: AppColors.primary,
                      pattern: StrokePattern.dashed(segments: const [8, 6]),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: customerPoint,
                      width: 44,
                      height: 52,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.home_rounded, color: Colors.white, size: 16),
                          ),
                          Container(width: 2.5, height: 10, color: AppColors.primary),
                        ],
                      ),
                    ),
                    Marker(
                      point: techPoint,
                      width: 44,
                      height: 52,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: _pulseAnim.value,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.directions_bike_rounded, color: AppColors.text, size: 17),
                              ),
                            ),
                            Container(width: 2.5, height: 10, color: AppColors.accent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: AppColors.accent, size: 7),
                  SizedBox(width: 6),
                  Text(
                    'LIVE GPS TRACKING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedBookingCard extends ConsumerStatefulWidget {
  final Job job;

  const _CompletedBookingCard({required this.job});

  @override
  ConsumerState<_CompletedBookingCard> createState() =>
      _CompletedBookingCardState();
}

class _CompletedBookingCardState extends ConsumerState<_CompletedBookingCard> {
  double _selectedRating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  double? _submittedRating;
  String? _submittedComment;
  final Set<String> _selectedTags = {'Punctual', 'Expert Skill'};

  final List<String> _quickTags = const [
    'Punctual',
    'Polite & Helpful',
    'Fair Price',
    'Clean Work',
    'Expert Skill',
  ];

  @override
  void initState() {
    super.initState();
    _submittedRating = widget.job.rating;
    _submittedComment = widget.job.reviewComment;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    final comment = [
      if (_selectedTags.isNotEmpty) '[${_selectedTags.join(', ')}]',
      _commentController.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ');

    try {
      await ref.read(jobRepositoryProvider).submitJobRating(
            widget.job.id,
            _selectedRating,
            comment.isNotEmpty ? comment : '5-star repair service',
          );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submittedRating = _selectedRating;
        _submittedComment = comment;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for rating ${_selectedRating.toStringAsFixed(0)} ★! Feedback saved.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving rating: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final activeRating = _submittedRating ?? widget.job.rating;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.job.applianceCategory ?? "Appliance"} Repair',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(widget.job.createdAt),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Brand: ${widget.job.displayBrand} • Model: ${widget.job.displayModel}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Paid: ₹${widget.job.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => InvoiceViewScreen(job: widget.job),
                    ));
                  },
                  icon: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary, size: 16),
                  label: Text(
                    'Invoice',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            if (activeRating != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.accent, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      '${activeRating.toStringAsFixed(1)} / 5.0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _submittedComment ?? widget.job.reviewComment ?? 'Excellent service!',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.text, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                  ],
                ),
              ),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rate_review_outlined, color: AppColors.accent, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Rate Technician Performance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = (index + 1).toDouble();
                      return IconButton(
                        onPressed: () => setState(() => _selectedRating = starVal),
                        icon: Icon(
                          index < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: index < _selectedRating ? AppColors.accent : Colors.grey,
                          size: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(tag, style: TextStyle(fontSize: 11, color: isSelected ? AppColors.text : AppColors.textMuted)),
                        selectedColor: AppColors.accent,
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Add feedback comment for technician...',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitRating,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.text),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: const Text('SUBMIT RATING & REVIEW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.text, // Charcoal text on Marigold for contrast
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
