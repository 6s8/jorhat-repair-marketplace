import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_progress_indicator.dart';
import 'job_status_tracker_provider.dart';

/// Real-time Customer Order Tracking Screen for Fixly.
class JobStatusTrackerScreen extends ConsumerWidget {
  final String jobId;
  final String? applianceCategory;
  final String? customerName;

  const JobStatusTrackerScreen({
    super.key,
    required this.jobId,
    this.applianceCategory,
    this.customerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerState = ref.watch(jobStatusTrackerProvider(jobId));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.track_changes_rounded, color: AppColors.accent, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Live Repair Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (applianceCategory != null)
                                    Text(
                                      applianceCategory!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _BookingIdCard(jobId: jobId, customerName: customerName),
                  const SizedBox(height: 20),

                  if (trackerState.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: AppProgressIndicator(label: 'Connecting to live feed...'),
                    )
                  else if (trackerState.errorMessage != null)
                    _ErrorCard(message: trackerState.errorMessage!)
                  else
                    _StatusStepper(state: trackerState),

                  const SizedBox(height: 24),

                  if (!trackerState.isLoading && trackerState.errorMessage == null)
                    _buildOtpCard(trackerState),

                  const SizedBox(height: 24),

                  if (!trackerState.isLoading &&
                      (trackerState.status == TrackedJobStatus.assigned ||
                          trackerState.status == TrackedJobStatus.onTheWay ||
                          trackerState.status == TrackedJobStatus.inProgress) &&
                      trackerState.customerLat != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _LiveTrackingMap(
                        customerLat: trackerState.customerLat!,
                        customerLng: trackerState.customerLng!,
                        techLat: trackerState.techLat,
                        techLng: trackerState.techLng,
                        isArrived: trackerState.status == TrackedJobStatus.inProgress ||
                            trackerState.status == TrackedJobStatus.completed,
                      ),
                    ),

                  if (!trackerState.isLoading && trackerState.errorMessage == null)
                    _LiveIndicator(status: trackerState.status),

                  const SizedBox(height: 32),

                  const _HelpCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard(TrackedJobState state) {
    if (state.status == TrackedJobStatus.assigned || state.status == TrackedJobStatus.onTheWay) {
      return _OtpCard(
        title: 'Arrival Verification OTP',
        otp: state.arrivalOtp,
        description: 'Share this code with your technician upon arrival.',
        accentColor: AppColors.primary,
      );
    } else if (state.status == TrackedJobStatus.inProgress) {
      return _OtpCard(
        title: 'Completion Verification OTP',
        otp: state.completionOtp,
        description: 'Share this code only after the repair work is completed.',
        accentColor: AppColors.success,
      );
    }
    return const SizedBox.shrink();
  }
}

class _BookingIdCard extends StatelessWidget {
  final String jobId;
  final String? customerName;

  const _BookingIdCard({required this.jobId, this.customerName});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Booking ID', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text(
                  jobId.length > 8 ? jobId.substring(0, 8).toUpperCase() : jobId.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppColors.primary,
                  ),
                ),
                if (customerName != null && customerName!.isNotEmpty)
                  Text(customerName!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final TrackedJobState state;

  const _StatusStepper({required this.state});

  @override
  Widget build(BuildContext context) {
    final bool hasArrived = state.status == TrackedJobStatus.inProgress ||
        state.status == TrackedJobStatus.completed;

    final steps = [
      const _StepData(
        icon: Icons.send_rounded,
        label: 'Request Sent',
        subtitle: 'Your repair request is live',
        status: TrackedJobStatus.requested,
      ),
      const _StepData(
        icon: Icons.person_pin_rounded,
        label: 'Technician Assigned',
        subtitle: 'A technician has accepted your request',
        status: TrackedJobStatus.assigned,
      ),
      _StepData(
        icon: hasArrived
            ? Icons.home_work_rounded
            : Icons.directions_bike_rounded,
        label: hasArrived ? 'Technician Arrived' : 'On the Way',
        subtitle: hasArrived
            ? 'Technician reached your location & verified arrival OTP'
            : 'Technician is heading to your location',
        status: TrackedJobStatus.onTheWay,
      ),
      const _StepData(
        icon: Icons.verified_rounded,
        label: 'Repair Completed',
        subtitle: 'Your appliance has been fixed',
        status: TrackedJobStatus.completed,
      ),
    ];

    final currentIndex = _stepIndexFor(state.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(steps.length, (i) {
            final step = steps[i];
            final isDone = i < currentIndex;
            final isActive = i == currentIndex;
            final isPending = i > currentIndex;
            final isLast = i == steps.length - 1;

            return _StepRow(
              step: step,
              isDone: isDone,
              isActive: isActive,
              isPending: isPending,
              isLast: isLast,
              acceptedAt: (i == 1 && state.acceptedAt != null) ? state.acceptedAt : null,
              completedAt: (i == 3 && state.completedAt != null) ? state.completedAt : null,
            );
          }),
        ),
      ),
    );
  }

  int _stepIndexFor(TrackedJobStatus status) {
    switch (status) {
      case TrackedJobStatus.requested:
        return 0;
      case TrackedJobStatus.assigned:
        return 1;
      case TrackedJobStatus.onTheWay:
        return 2;
      case TrackedJobStatus.inProgress:
        return 2;
      case TrackedJobStatus.completed:
        return 3;
      case TrackedJobStatus.unknown:
        return 0;
    }
  }
}

class _StepData {
  final IconData icon;
  final String label;
  final String subtitle;
  final TrackedJobStatus status;

  const _StepData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.status,
  });
}

class _StepRow extends StatelessWidget {
  final _StepData step;
  final bool isDone;
  final bool isActive;
  final bool isPending;
  final bool isLast;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  const _StepRow({
    required this.step,
    required this.isDone,
    required this.isActive,
    required this.isPending,
    required this.isLast,
    this.acceptedAt,
    this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    final Color nodeColor = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : Colors.grey.shade300;

    final Color lineColor = isDone ? AppColors.success : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)]
                      : null,
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : Icon(step.icon, color: isActive ? Colors.white : Colors.grey.shade600, size: 20),
              ),
              if (!isLast)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: 2,
                  height: 52,
                  color: lineColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 52 + 8, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                    color: isPending ? AppColors.textMuted : AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (acceptedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(acceptedAt!),
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (completedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(completedAt!),
                      style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return 'at $h:$m';
  }
}

class _LiveIndicator extends StatefulWidget {
  final TrackedJobStatus status;
  const _LiveIndicator({required this.status});

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == TrackedJobStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.success),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
            SizedBox(width: 8),
            Text('Job Completed', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_pulse),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: AppColors.accent, size: 8),
            SizedBox(width: 8),
            Text('Tracking Live Feed', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.support_agent_rounded, color: AppColors.text, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need Help?', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Call Fixly Support: +91 94351 00000', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.call_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _LiveTrackingMap extends StatefulWidget {
  final double customerLat;
  final double customerLng;
  final double? techLat;
  final double? techLng;
  final bool isArrived;

  const _LiveTrackingMap({
    required this.customerLat,
    required this.customerLng,
    this.techLat,
    this.techLng,
    this.isArrived = false,
  });

  @override
  State<_LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<_LiveTrackingMap>
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
    _pulseAnim =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerPoint =
        LatLng(widget.customerLat, widget.customerLng);

    final techPoint = LatLng(
      widget.techLat ?? (widget.customerLat + 0.007),
      widget.techLng ?? (widget.customerLng + 0.007),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primary,
            child: Row(
              children: [
                Icon(
                  widget.isArrived
                      ? Icons.home_work_rounded
                      : Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isArrived
                      ? 'Technician has arrived'
                      : 'Technician is on the way',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Opacity(
                    opacity: _pulseAnim.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.accent, shape: BoxShape.circle),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  (customerPoint.latitude + techPoint.latitude) / 2,
                  (customerPoint.longitude + techPoint.longitude) / 2,
                ),
                initialZoom: 14.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      width: 50,
                      height: 65,
                      child: Column(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(Icons.home_rounded,
                              color: Colors.white, size: 20),
                        ),
                        Container(
                            width: 3,
                            height: 15,
                            color: AppColors.primary),
                      ]),
                    ),
                    Marker(
                      point: techPoint,
                      width: 50,
                      height: 65,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Column(children: [
                          Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
                              ),
                              child: const Icon(
                                  Icons.directions_car_rounded,
                                  color: AppColors.text,
                                  size: 20),
                            ),
                          ),
                          Container(
                              width: 3,
                              height: 15,
                              color: AppColors.accent),
                        ]),
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
}

class _OtpCard extends StatelessWidget {
  final String title;
  final String? otp;
  final String description;
  final Color accentColor;

  const _OtpCard({
    required this.title,
    required this.otp,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (otp == null || otp!.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            otp!,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 36,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
