import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../providers/technician_profile_provider.dart';
import 'radar_settings_screen.dart';

class TechnicianProfileScreen extends ConsumerWidget {
  const TechnicianProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(technicianProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: profileState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
        error: (err, _) => Center(
          child: Text('Error loading profile: $err'),
        ),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Online / Offline Status Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: profile.isOnline
                        ? [Colors.green.shade800, Colors.green.shade600]
                        : [Colors.grey.shade800, Colors.grey.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (profile.isOnline ? Colors.green : Colors.grey)
                          .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Icon(
                            profile.isOnline
                                ? Icons.radar
                                : Icons.power_settings_new,
                            color: profile.isOnline
                                ? Colors.green.shade800
                                : Colors.grey.shade800,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.isOnline ? 'ONLINE & SCANNING' : 'OFFLINE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.isOnline
                                  ? 'Receiving job requests within ${profile.workRadiusKm.toStringAsFixed(0)} km'
                                  : 'Not visible to customer requests',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: profile.isOnline,
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.green.shade400,
                      inactiveTrackColor: Colors.grey.shade700,
                      onChanged: (val) async {
                        await ref
                            .read(technicianProfileProvider.notifier)
                            .toggleOnlineStatus(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Personal Info Card
              _buildSectionTitle('TECHNICIAN DETAILS'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'Full Name',
                      value: profile.name,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Mobile Number',
                      value: profile.phone,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Service Base Location',
                      value: 'Jorhat, Assam (${profile.workRadiusKm.toStringAsFixed(0)} km radius)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Radar Settings Quick Link Card
              _buildSectionTitle('RADAR CONFIGURATION'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RadarSettingsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Radar Settings & Skills',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${profile.skills.length} skills • ${profile.workRadiusKm.toStringAsFixed(0)} km radius • ${profile.alertTimerSec}s alert',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.deepOrange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Current Skills Chips Display
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.skills.map((skill) {
                  return Chip(
                    label: Text(skill, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    backgroundColor: Colors.deepOrange.shade50,
                    labelStyle: const TextStyle(color: Colors.deepOrange),
                    side: BorderSide(color: Colors.deepOrange.shade200),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Sign out button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Sign Out Account',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ref.invalidate(technicianProfileProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile refreshed!')),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Profile Data'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
