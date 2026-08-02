import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'job_status_tracker_provider.dart';

/// Real-time Customer Order Tracking Screen.
/// Shows a vertical animated stepper that reflects live Supabase job status changes.
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
      backgroundColor: const Color(0xFF0F1117),
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF0F1117),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF1565C0)],
                  ),
                ),
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
                              child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 24),
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
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
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
                  // Booking ID Card
                  _BookingIdCard(jobId: jobId, customerName: customerName),
                  const SizedBox(height: 20),

                  // Status Stepper
                  if (trackerState.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1565C0)),
                          SizedBox(height: 16),
                          Text('Connecting to live feed...', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  else if (trackerState.errorMessage != null)
                    _ErrorCard(message: trackerState.errorMessage!)
                  else
                    _StatusStepper(state: trackerState),

                  const SizedBox(height: 24),

                  // Live map — only shown when technician is on_the_way
                  if (!trackerState.isLoading &&
                      trackerState.status == TrackedJobStatus.inProgress &&
                      trackerState.customerLat != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _LiveTrackingMap(
                        customerLat: trackerState.customerLat!,
                        customerLng: trackerState.customerLng!,
                      ),
                    ),

                  // Live indicator
                  if (!trackerState.isLoading && trackerState.errorMessage == null)
                    _LiveIndicator(status: trackerState.status),

                  const SizedBox(height: 32),

                  // Help Section
                  _HelpCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Booking ID Card
// ─────────────────────────────────────────────
class _BookingIdCard extends StatelessWidget {
  final String jobId;
  final String? customerName;

  const _BookingIdCard({required this.jobId, this.customerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2D3E)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF42A5F5), size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Booking ID', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text(
                jobId.length > 8 ? jobId.substring(0, 8).toUpperCase() : jobId.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (customerName != null && customerName!.isNotEmpty)
                Text(customerName!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Vertical Status Stepper
// ─────────────────────────────────────────────
class _StatusStepper extends StatelessWidget {
  final TrackedJobState state;

  const _StatusStepper({required this.state});

  @override
  Widget build(BuildContext context) {
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
      const _StepData(
        icon: Icons.directions_bike_rounded,
        label: 'On the Way',
        subtitle: 'Technician is heading to your location',
        status: TrackedJobStatus.inProgress,
      ),
      const _StepData(
        icon: Icons.verified_rounded,
        label: 'Repair Completed',
        subtitle: 'Your appliance has been fixed',
        status: TrackedJobStatus.completed,
      ),
    ];

    final currentIndex = _stepIndexFor(state.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2D3E)),
      ),
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
    );
  }

  int _stepIndexFor(TrackedJobStatus status) {
    switch (status) {
      case TrackedJobStatus.requested:
        return 0;
      case TrackedJobStatus.assigned:
        return 1;
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
        ? const Color(0xFF43A047)
        : isActive
            ? const Color(0xFF1565C0)
            : const Color(0xFF2A2D3E);

    final Color lineColor = isDone ? const Color(0xFF43A047) : const Color(0xFF2A2D3E);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: circle + vertical line
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
                    ? [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)]
                    : null,
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : Icon(step.icon, color: isActive ? Colors.white : Colors.white30, size: 20),
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

        // Right: text
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 52 + 8, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    color: isPending ? Colors.white38 : Colors.white,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: isPending ? Colors.white24 : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                if (acceptedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(acceptedAt!),
                      style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 11),
                    ),
                  ),
                if (completedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(completedAt!),
                      style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 11),
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

// ─────────────────────────────────────────────
// Live Indicator
// ─────────────────────────────────────────────
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
          color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF66BB6A), size: 16),
            SizedBox(width: 8),
            Text('Job Completed', style: TextStyle(color: Color(0xFF66BB6A), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_pulse),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Color(0xFF42A5F5), size: 8),
            SizedBox(width: 8),
            Text('Tracking Live', style: TextStyle(color: Color(0xFF42A5F5), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error Card
// ─────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3E0808),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Help Card
// ─────────────────────────────────────────────
class _HelpCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2D3E)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.orange, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need Help?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('Call Jorhat Support: 1800-XXX-XXXX', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.call_rounded, color: Colors.orange.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Tracking Map — shown when technician is on_the_way
// Shows the customer's pinned location + an animated "technician moving" dot.
// ─────────────────────────────────────────────────────────────────────────────
class _LiveTrackingMap extends StatefulWidget {
  final double customerLat;
  final double customerLng;

  const _LiveTrackingMap({
    required this.customerLat,
    required this.customerLng,
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

    // Simulate technician ~0.8 km north-east of customer
    final techPoint = LatLng(
      widget.customerLat + 0.007,
      widget.customerLng + 0.007,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFF57C00)]),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Technician is on the way',
                  style: TextStyle(
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
                          color: Colors.white, shape: BoxShape.circle),
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

          // ── Map ─────────────────────────────────────────────────────────
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
                  userAgentPackageName:
                      'com.jorhat.repair_marketplace',
                ),
                // Route line (simplified straight line)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [techPoint, customerPoint],
                      strokeWidth: 3.5,
                      color: const Color(0xFF1565C0),
                      pattern: StrokePattern.dashed(segments: const [8, 6]),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Customer home pin
                    Marker(
                      point: customerPoint,
                      width: 50,
                      height: 65,
                      child: Column(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF1565C0)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8)
                            ],
                          ),
                          child: const Icon(Icons.home_rounded,
                              color: Colors.white, size: 20),
                        ),
                        Container(
                            width: 3,
                            height: 15,
                            color: const Color(0xFF1565C0)),
                      ]),
                    ),
                    // Technician animated marker
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
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF57C00),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFFF57C00)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2)
                                ],
                              ),
                              child: const Icon(
                                  Icons.directions_car_rounded,
                                  color: Colors.white,
                                  size: 20),
                            ),
                          ),
                          Container(
                              width: 3,
                              height: 15,
                              color: const Color(0xFFF57C00)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Footer legend ────────────────────────────────────────────────
          Container(
            color: const Color(0xFF1A1D2E),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: Color(0xFFF57C00),
                    label: 'Technician'),
                SizedBox(width: 20),
                _LegendDot(color: Color(0xFF1565C0),
                    label: 'Your Address'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
