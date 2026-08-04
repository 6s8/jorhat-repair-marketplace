import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/technician_default_view_provider.dart';
import '../providers/technician_profile_provider.dart';

class RadarSettingsScreen extends ConsumerStatefulWidget {
  const RadarSettingsScreen({super.key});

  @override
  ConsumerState<RadarSettingsScreen> createState() => _RadarSettingsScreenState();
}

class _RadarSettingsScreenState extends ConsumerState<RadarSettingsScreen> {
  final List<String> _allSkills = const [
    'AC',
    'Refrigerator',
    'Washing Machine',
    'TV',
    'Microwave',
    'Water Purifier',
    'Geyser',
    'Air Cooler',
    'Water Pump',
    'Inverter',
    'Solar',
    'Electrical',
    'Plumbing',
  ];

  late Set<String> _selectedSkills;
  late double _workRadiusKm;
  late int _alertTimerSec;
  late bool _isMapViewDefault;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSkills = {'AC', 'Refrigerator', 'Washing Machine'};
    _workRadiusKm = 20.0;
    _alertTimerSec = 30;
    _isMapViewDefault = false;
  }

  void _initFromProfile(profile) {
    if (!_initialized && profile != null) {
      _selectedSkills = profile.skills.toSet();
      _workRadiusKm = profile.workRadiusKm.clamp(5.0, 50.0);
      _alertTimerSec = profile.alertTimerSec.clamp(15, 60);
      _isMapViewDefault = ref.read(technicianDefaultViewProvider);
      _initialized = true;
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one skill category.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final notifier = ref.read(technicianProfileProvider.notifier);

    await notifier.updateSkills(_selectedSkills.toList());
    await notifier.updateWorkRadius(_workRadiusKm);
    await notifier.updateAlertTimer(_alertTimerSec);

    ref.read(technicianDefaultViewProvider.notifier).setDefaultView(_isMapViewDefault);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Radar Settings Saved Successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(technicianProfileProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    profileState.whenData((profile) => _initFromProfile(profile));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar Job Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: profileState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Error loading settings: $err'),
        ),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.radar, color: primaryColor, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customize Job Discovery',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Only receive popup alerts for jobs within your work radius and matching your selected repair skills.',
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Default View Option (List vs Map)
              const Text(
                'Default Dispatch View',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose whether Live Dispatch Feed starts in List view or Map view.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('List View Default'),
                    icon: Icon(Icons.list_rounded),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Map View Default'),
                    icon: Icon(Icons.map_rounded),
                  ),
                ],
                selected: {_isMapViewDefault},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() => _isMapViewDefault = selection.first);
                },
              ),

              const SizedBox(height: 28),

              // Skill Filter Chips
              const Text(
                'Skill Filter (Select Your Categories)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap categories to toggle. You will only receive radar alerts for selected skills.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: _allSkills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(
                      skill,
                      style: TextStyle(
                        color: isSelected ? AppColors.text : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedSkills.add(skill);
                        } else {
                          _selectedSkills.remove(skill);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Work Radius Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Work Radius (Km)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_workRadiusKm.toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Maximum distance from Jorhat to scan for customer repair requests.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Slider(
                value: _workRadiusKm,
                min: 5.0,
                max: 50.0,
                divisions: 45,
                activeColor: primaryColor,
                label: '${_workRadiusKm.toStringAsFixed(0)} km',
                onChanged: (val) {
                  setState(() => _workRadiusKm = val);
                },
              ),
              const SizedBox(height: 24),

              // Alert Timer Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Radar Alert Countdown Timer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_alertTimerSec}s',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'How long the full-screen radar alert stays open before auto-dismissing.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Slider(
                value: _alertTimerSec.toDouble(),
                min: 15.0,
                max: 60.0,
                divisions: 9,
                activeColor: AppColors.accent,
                label: '${_alertTimerSec}s',
                onChanged: (val) {
                  setState(() => _alertTimerSec = val.toInt());
                },
              ),
              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.text, // Charcoal text on Marigold for high contrast
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.text,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.save_alt_rounded),
                  label: Text(
                    _isSaving ? 'SAVING...' : 'SAVE RADAR SETTINGS',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
