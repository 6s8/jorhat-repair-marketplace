import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/job_model.dart';
import '../providers/technician_pending_jobs_provider.dart';

/// Interactive map showing all pending repair requests as pins.
/// Technicians can tap a pin to see job details and accept directly.
class JobFeedMapView extends ConsumerStatefulWidget {
  final String technicianId;
  const JobFeedMapView({super.key, required this.technicianId});

  @override
  ConsumerState<JobFeedMapView> createState() => _JobFeedMapViewState();
}

class _JobFeedMapViewState extends ConsumerState<JobFeedMapView> {
  Job? _selectedJob;
  final _mapController = MapController();

  // Jorhat city centre as default camera
  static const LatLng _jorhat = LatLng(26.7509, 94.2037);

  @override
  Widget build(BuildContext context) {
    final asyncJobs = ref.watch(technicianPendingJobsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return asyncJobs.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Text('Map error: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (jobs) {
        // Only plot jobs that have valid coordinates
        final mappableJobs = jobs
            .where((j) => j.latitude != null && j.longitude != null)
            .toList();

        return Stack(
          children: [
            // ── Map layer ────────────────────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mappableJobs.isNotEmpty
                    ? LatLng(mappableJobs.first.latitude!,
                        mappableJobs.first.longitude!)
                    : _jorhat,
                initialZoom: 13.5,
                onTap: (_, __) => setState(() => _selectedJob = null),
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.jorhat.repair_marketplace',
                  maxZoom: 19,
                ),
                // Job pins
                MarkerLayer(
                  markers: mappableJobs
                      .map((job) => _buildMarker(job, context))
                      .toList(),
                ),
              ],
            ),

            // ── OSM attribution ──────────────────────────────────────────
            Positioned(
              bottom: _selectedJob != null ? 240 : 85,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('© OpenStreetMap',
                    style: TextStyle(color: Colors.white70, fontSize: 9)),
              ),
            ),

            // ── Job count badge ──────────────────────────────────────────
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.accent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${mappableJobs.length} Request${mappableJobs.length == 1 ? '' : 's'} on Map',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Job detail card (positioned safely above floating navbar) ─────
            if (_selectedJob != null)
              Positioned(
                bottom: 85, // Positioned safely above the bottom floating nav bar (height ~70px)
                left: 14,
                right: 14,
                child: _JobDetailCard(
                  job: _selectedJob!,
                  onClose: () => setState(() => _selectedJob = null),
                ),
              ),
          ],
        );
      },
    );
  }

  Marker _buildMarker(Job job, BuildContext context) {
    final isSelected = _selectedJob?.id == job.id;
    return Marker(
      point: LatLng(job.latitude!, job.longitude!),
      width: isSelected ? 56 : 44,
      height: isSelected ? 72 : 58,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedJob = job);
          _mapController.move(
              LatLng(job.latitude!, job.longitude!), 14.5);
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 46 : 36,
              height: isSelected ? 46 : 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected
                            ? AppColors.primary
                            : AppColors.accent)
                        .withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                isSelected
                    ? Icons.person_pin_rounded
                    : Icons.build_circle_rounded,
                color: isSelected ? Colors.white : AppColors.text,
                size: isSelected ? 24 : 20,
              ),
            ),
            // Pin needle
            Container(
              width: 3,
              height: isSelected ? 16 : 12,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Job detail card (slides up on pin tap) ───────────────────────────────────
class _JobDetailCard extends ConsumerStatefulWidget {
  final Job job;
  final VoidCallback onClose;

  const _JobDetailCard({required this.job, required this.onClose});

  @override
  ConsumerState<_JobDetailCard> createState() => _JobDetailCardState();
}

class _JobDetailCardState extends ConsumerState<_JobDetailCard> {
  bool _isAccepting = false;

  Future<void> _handleAccept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);
    final result = await ref
        .read(technicianPendingJobsProvider.notifier)
        .acceptJob(widget.job.id);
    if (!mounted) return;
    setState(() => _isAccepting = false);

    if (result.isSuccess) {
      final messenger = ScaffoldMessenger.of(context);
      widget.onClose();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Job Accepted! Check Active Jobs tab.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Could not accept job. It may have been accepted by another technician.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(job.applianceCategory),
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.displayTitle,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.displayAddress.isNotEmpty
                          ? job.displayAddress
                          : 'Location: ${job.latitude?.toStringAsFixed(4)}, ${job.longitude?.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(
                icon: Icons.currency_rupee_rounded,
                label: '₹${job.price.toStringAsFixed(0)}',
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.circle,
                label: job.status.toUpperCase(),
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              if (job.distanceKm > 0)
                _Chip(
                  icon: Icons.near_me_rounded,
                  label: '${job.distanceKm.toStringAsFixed(1)} km',
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isAccepting ? null : _handleAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.text, // Charcoal text on Marigold for high contrast
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              icon: _isAccepting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.text,
                      ),
                    )
                  : const Icon(Icons.bolt_rounded, color: AppColors.text),
              label: Text(
                _isAccepting
                    ? 'ACCEPTING JOB...'
                    : 'ACCEPT JOB (₹${job.price.toStringAsFixed(0)})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String? cat) {
    if (cat == null) return Icons.build_rounded;
    final lower = cat.toLowerCase();
    if (lower.contains('ac')) return Icons.ac_unit_rounded;
    if (lower.contains('fridge') || lower.contains('refrigerator')) return Icons.kitchen_rounded;
    if (lower.contains('wash')) return Icons.local_laundry_service_rounded;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv_rounded;
    if (lower.contains('purifier') || lower.contains('ro')) return Icons.water_drop_rounded;
    if (lower.contains('microwave') || lower.contains('oven')) return Icons.microwave_rounded;
    if (lower.contains('geyser') || lower.contains('heater')) return Icons.water_rounded;
    if (lower.contains('chimney')) return Icons.sensor_window_rounded;
    return Icons.build_rounded;
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
