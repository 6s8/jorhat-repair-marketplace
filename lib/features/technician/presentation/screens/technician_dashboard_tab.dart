import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/technician_profile_provider.dart';
import '../providers/technician_earnings_provider.dart';
import '../../../../features/auth/controllers/auth_controller.dart';
import 'radar_settings_screen.dart';

/// Technician Profile / Dashboard for Fixly Tech.
class TechnicianDashboardTab extends ConsumerWidget {
  const TechnicianDashboardTab({super.key});

  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final currentMode = ref.watch(themeModeProvider);
            final isDark = currentMode == ThemeMode.dark;
            final primaryColor = Theme.of(context).colorScheme.primary;

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings_rounded, color: primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Fixly Tech Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    secondary: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.accent,
                    ),
                    title: const Text(
                      'Dark Theme Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Enable dark appearance for night shifts'),
                    value: isDark,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(technicianProfileProvider);
    final summaryAsync = ref.watch(technicianEarningsSummaryProvider);
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Could not load profile\n$err',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedTextColor)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(technicianProfileProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(technicianProfileProvider);
            ref.invalidate(technicianCompletedJobsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Hero Header SliverAppBar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroHeader(
                    name: profile.name,
                    phone: profile.phone,
                    isOnline: profile.isOnline,
                    radiusKm: profile.workRadiusKm,
                    onToggle: (val) => ref
                        .read(technicianProfileProvider.notifier)
                        .toggleOnlineStatus(val),
                  ),
                  collapseMode: CollapseMode.parallax,
                ),
                title: const Text(
                  'My Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    tooltip: 'Fixly Tech Settings',
                    onPressed: () => _showSettingsModal(context, ref),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Body content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Settings Quick Tile
                    Consumer(
                      builder: (context, ref, _) {
                        final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: SwitchListTile(
                            secondary: Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: AppColors.accent,
                            ),
                            title: const Text('Dark Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Toggle dark mode appearance', style: TextStyle(fontSize: 12)),
                            value: isDark,
                            activeColor: AppColors.accent,
                            onChanged: (val) {
                              ref.read(themeModeProvider.notifier).toggleTheme();
                            },
                          ),
                        );
                      },
                    ),

                    // Earnings Snapshot
                    const _SectionLabel(label: 'EARNINGS SNAPSHOT'),
                    const SizedBox(height: 10),
                    summaryAsync.when(
                      loading: () => const _EarningsShimmer(),
                      error: (_, __) => const _EarningsError(),
                      data: (s) => _EarningsSnapshot(summary: s),
                    ),

                    const SizedBox(height: 24),

                    // Skills & Specializations
                    const _SectionLabel(label: 'SKILLS & SPECIALIZATIONS'),
                    const SizedBox(height: 10),
                    _SkillsCard(skills: profile.skills),

                    const SizedBox(height: 24),

                    // Radar Configuration
                    const _SectionLabel(label: 'RADAR CONFIGURATION'),
                    const SizedBox(height: 10),
                    _RadarCard(
                      radiusKm: profile.workRadiusKm,
                      alertSec: profile.alertTimerSec,
                      skillCount: profile.skills.length,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RadarSettingsScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contact & Identity
                    const _SectionLabel(label: 'CONTACT DETAILS'),
                    const SizedBox(height: 10),
                    _ContactCard(name: profile.name, phone: profile.phone),

                    const SizedBox(height: 24),

                    // Actions
                    _ActionRow(
                      onRefresh: () {
                        ref.invalidate(technicianProfileProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile refreshed!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String name;
  final String phone;
  final bool isOnline;
  final double radiusKm;
  final ValueChanged<bool> onToggle;

  const _HeroHeader({
    required this.name,
    required this.phone,
    required this.isOnline,
    required this.radiusKm,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  size: 40,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppColors.success
                                : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline
                              ? 'Online · ${radiusKm.toStringAsFixed(0)} km radar'
                              : 'Offline',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  Switch(
                    value: isOnline,
                    activeColor: Colors.white,
                    activeTrackColor: AppColors.success,
                    onChanged: onToggle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsSnapshot extends StatelessWidget {
  final TechnicianEarningsSummary summary;

  const _EarningsSnapshot({required this.summary});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL NET PAYOUT (ALL TIME)',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${summary.totalNetPayout.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${summary.completedJobsCount} jobs completed  ·  -₹${summary.totalCommission.toStringAsFixed(0)} commission (10%)',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Today',
                value: '₹${summary.todayEarnings.toStringAsFixed(0)}',
                icon: Icons.today_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStatCard(
                label: 'This Week',
                value: '₹${summary.weeklyEarnings.toStringAsFixed(0)}',
                icon: Icons.date_range_rounded,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStatCard(
                label: 'This Month',
                value: '₹${summary.monthlyEarnings.toStringAsFixed(0)}',
                icon: Icons.calendar_month_rounded,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: mutedTextColor)),
          ],
        ),
      ),
    );
  }
}

class _EarningsShimmer extends StatelessWidget {
  const _EarningsShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
          child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }
}

class _EarningsError extends StatelessWidget {
  const _EarningsError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('Could not load earnings data.',
          style: TextStyle(color: AppColors.error)),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  final List<String> skills;

  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: skills.isEmpty
            ? Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'No skills configured. Set them in Radar Settings.',
                    style: TextStyle(color: mutedTextColor, fontSize: 13),
                  ),
                ],
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) {
                  return Chip(
                    avatar: Icon(Icons.build_circle_rounded,
                        size: 16, color: primaryColor),
                    label: Text(
                      skill,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: primaryColor),
                    ),
                    backgroundColor: primaryColor.withValues(alpha: 0.12),
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _RadarCard extends StatelessWidget {
  final double radiusKm;
  final int alertSec;
  final int skillCount;
  final VoidCallback onTap;

  const _RadarCard({
    required this.radiusKm,
    required this.alertSec,
    required this.skillCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune_rounded,
                    color: AppColors.text, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Radar Settings & Skills',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${radiusKm.toStringAsFixed(0)} km radius  ·  ${alertSec}s alert  ·  $skillCount skill${skillCount == 1 ? "" : "s"}',
                      style: TextStyle(
                          color: mutedTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String phone;

  const _ContactCard({required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Row(icon: Icons.person_outline_rounded, label: 'Full Name', value: name),
            const Divider(height: 20),
            _Row(icon: Icons.phone_outlined, label: 'Mobile Number', value: phone),
            const Divider(height: 20),
            const _Row(
              icon: Icons.location_on_outlined,
              label: 'Service Base',
              value: 'Jorhat, Assam',
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: mutedTextColor)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _ActionRow({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh Data'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: mutedTextColor,
        letterSpacing: 0.6,
      ),
    );
  }
}
