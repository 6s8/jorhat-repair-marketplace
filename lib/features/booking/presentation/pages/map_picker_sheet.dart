import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerSheet extends StatefulWidget {
  final LatLng initialCenter;
  
  const MapPickerSheet({super.key, required this.initialCenter});

  static Future<LatLng?> show(BuildContext context, LatLng initialCenter) {
    return showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MapPickerSheet(initialCenter: initialCenter),
    );
  }

  @override
  State<MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<MapPickerSheet> {
  late final MapController _mapController;
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.initialCenter;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1426),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D2E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF42A5F5)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pick Service Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Map Area ────────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: 15.0,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture) {
                        setState(() => _currentCenter = pos.center);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.jorhat.repair_marketplace',
                    ),
                  ],
                ),
                
                // Fixed Center Pin
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40.0), // Offset for pin point
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.home_repair_service, color: Colors.white, size: 24),
                        ),
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Map attribution
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('© OpenStreetMap',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),

          // ── Footer ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1A1D2E),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pin Dropped: ${_currentCenter.latitude.toStringAsFixed(4)}° N, ${_currentCenter.longitude.toStringAsFixed(4)}° E',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_currentCenter),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
