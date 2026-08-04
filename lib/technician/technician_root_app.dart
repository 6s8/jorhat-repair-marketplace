import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_scroll_behavior.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/modern_floating_nav_bar.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/technician/presentation/providers/technician_profile_provider.dart';
import '../features/technician/presentation/screens/active_jobs_tab.dart';
import '../features/technician/presentation/screens/earnings_tab.dart';
import '../features/technician/presentation/screens/marketplace_tab.dart';
import '../features/technician/presentation/screens/pending_jobs_tab.dart';
import '../features/technician/presentation/screens/radar_settings_screen.dart';
import '../features/technician/presentation/screens/technician_dashboard_tab.dart';
import '../features/technician/presentation/screens/technician_profile_screen.dart';
import '../features/technician/presentation/screens/job_detail_screen.dart';
import '../models/job_model.dart';

class TechnicianHomeScreen extends ConsumerStatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  ConsumerState<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends ConsumerState<TechnicianHomeScreen> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Pending Radar Jobs',
    'Active Repair Jobs',
    'Wholesale Spare Parts',
    'Earnings & Payouts',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(technicianProfileProvider);
    final profile = profileState.value;
    final isOnline = profile?.isOnline ?? false;

    return Scaffold(
      extendBody: true,
      appBar: _currentIndex == 0 || _currentIndex == 4
          ? null
          : AppBar(
              title: Text(
                _titles[_currentIndex],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.success.withValues(alpha: 0.9)
                        : AppColors.textMuted.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Radar Settings',
                  onPressed: () => context.push('/radar-settings'),
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          PendingJobsTab(),
          ActiveJobsTab(),
          MarketplaceTab(),
          EarningsTab(),
          TechnicianDashboardTab(),
        ],
      ),
      bottomNavigationBar: ModernFloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          ModernNavItem(
            icon: Icons.radar_outlined,
            selectedIcon: Icons.radar,
            label: 'Radar',
          ),
          ModernNavItem(
            icon: Icons.assignment_turned_in_outlined,
            selectedIcon: Icons.assignment_turned_in,
            label: 'Active',
          ),
          ModernNavItem(
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront,
            label: 'Wholesale',
          ),
          ModernNavItem(
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet,
            label: 'Earnings',
          ),
          ModernNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

final technicianRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TechnicianHomeScreen(),
    ),
    GoRoute(
      path: '/radar-settings',
      builder: (context, state) => const RadarSettingsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const TechnicianProfileScreen(),
    ),
    GoRoute(
      path: '/job-detail',
      builder: (context, state) {
        final job = state.extra is Job ? state.extra as Job : null;
        if (job == null) return const Scaffold(body: Center(child: Text('Job not found')));
        return JobDetailScreen(job: job);
      },
    ),
  ],
);

class TechnicianRootApp extends ConsumerWidget {
  const TechnicianRootApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Fixly Tech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      scrollBehavior: const AppStretchScrollBehavior(),
      routerConfig: technicianRouter,
      builder: (context, child) {
        return AuthGate(
          targetRole: 'technician',
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
