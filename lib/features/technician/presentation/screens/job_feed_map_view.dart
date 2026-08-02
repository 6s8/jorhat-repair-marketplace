import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/realtime_job_list_provider.dart';

/// Interactive map showing all pending repair requests as pins.
/// Technicians can tap a pin to see job details.
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
    final asyncJobs = ref.watch(realtimeJobListProvider);

    return asyncJobs.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0))),
      error: (e, _) => Center(
        child: Text('Map error: $e',
            style: const TextStyle(color: Colors.redAccent)),
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
                // OpenStreetMap tiles — no API key needed
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
              bottom: _selectedJob != null ? 168 : 8,
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
                    color: const Color(0xFF1A1D2E).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Color(0xFF42A5F5), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${mappableJobs.length} Request${mappableJobs.length == 1 ? '' : 's'} on Map',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Job detail card (appears on pin tap) ─────────────────────
            if (_selectedJob != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
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
                    ? const Color(0xFF1565C0)
                    : const Color(0xFFE53935),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected
                            ? const Color(0xFF1565C0)
                            : const Color(0xFFE53935))
                        .withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                isSelected
                    ? Icons.person_pin_rounded
                    : Icons.build_circle_rounded,
                color: Colors.white,
                size: isSelected ? 24 : 20,
              ),
            ),
            // Pin needle
            Container(
              width: 3,
              height: isSelected ? 16 : 12,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1565C0)
                    : const Color(0xFFE53935),
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
class _JobDetailCard extends StatelessWidget {
  final Job job;
  final VoidCallback onClose;

  const _JobDetailCard({required this.job, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcon(job.applianceCategory),
                  color: const Color(0xFF42A5F5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.displayTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      job.displayAddress.isNotEmpty
                          ? job.displayAddress
                          : 'Location: ${job.latitude?.toStringAsFixed(4)}, ${job.longitude?.toStringAsFixed(4)}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white38, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(
                  icon: Icons.attach_money_rounded,
                  label: '₹${job.price.toStringAsFixed(0)}',
                  color: const Color(0xFF42A5F5)),
              const SizedBox(width: 8),
              _Chip(
                  icon: Icons.circle,
                  label: job.status.toUpperCase(),
                  color: Colors.orange),
              const SizedBox(width: 8),
              if (job.distanceKm > 0)
                _Chip(
                    icon: Icons.social_distance_rounded,
                    label: '${job.distanceKm.toStringAsFixed(1)} km',
                    color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'AC':
        return Icons.ac_unit;
      case 'Refrigerator':
        return Icons.kitchen;
      case 'Washing Machine':
        return Icons.local_laundry_service;
      case 'Television':
        return Icons.tv;
      default:
        return Icons.build_rounded;
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
