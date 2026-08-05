import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/customer/presentation/screens/customer_store_screen.dart';
import '../../features/customer/presentation/shells/customer_shell.dart';
import '../../features/retailer/presentation/shells/retailer_shell.dart';
import '../../features/technician/presentation/screens/job_detail_screen.dart';
import '../../features/technician/presentation/screens/radar_settings_screen.dart';
import '../../features/technician/presentation/screens/technician_marketplace_orders_screen.dart';
import '../../features/technician/presentation/screens/technician_profile_screen.dart';
import '../../features/technician/presentation/shells/technician_shell.dart';
import '../../features/tracking/job_status_tracker_screen.dart';
import '../../models/job_model.dart';
import '../theme/app_colors.dart';

/// Riverpod Provider exposing the single unified GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) => notifier.redirect(context, state),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // ── Customer Routes ──
      GoRoute(
        path: '/customer',
        builder: (context, state) => const CustomerShell(),
        routes: [
          GoRoute(
            path: 'store',
            builder: (context, state) => const CustomerStoreScreen(),
          ),
          GoRoute(
            path: 'track-job',
            builder: (context, state) {
              final extra = state.extra is Map<String, dynamic>
                  ? state.extra as Map<String, dynamic>
                  : null;
              final jobId = extra?['jobId'] as String? ?? '';
              final category = extra?['category'] as String?;
              final customerName = extra?['customerName'] as String?;
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Fixly - Repair Tracker'),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                body: JobStatusTrackerScreen(
                  jobId: jobId,
                  applianceCategory: category,
                  customerName: customerName,
                ),
              );
            },
          ),
        ],
      ),

      // ── Technician Routes ──
      GoRoute(
        path: '/technician',
        builder: (context, state) => const TechnicianShell(),
        routes: [
          GoRoute(
            path: 'radar-settings',
            builder: (context, state) => const RadarSettingsScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const TechnicianProfileScreen(),
          ),
          GoRoute(
            path: 'job-detail',
            builder: (context, state) {
              final job = state.extra is Job ? state.extra as Job : null;
              if (job == null) {
                return const Scaffold(
                  body: Center(child: Text('Job details not found')),
                );
              }
              return JobDetailScreen(job: job);
            },
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) => const TechnicianMarketplaceOrdersScreen(),
          ),
        ],
      ),

      // ── Retailer Routes ──
      GoRoute(
        path: '/retailer',
        builder: (context, state) => const RetailerShell(),
      ),

      // Top-level legacy fallbacks for deep links
      GoRoute(
        path: '/track-job',
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Fixly - Repair Tracker'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: JobStatusTrackerScreen(
              jobId: extra?['jobId'] as String? ?? '',
              applianceCategory: extra?['category'] as String?,
              customerName: extra?['customerName'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/radar-settings',
        builder: (context, state) => const RadarSettingsScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const TechnicianMarketplaceOrdersScreen(),
      ),
      GoRoute(
        path: '/job-detail',
        builder: (context, state) {
          final job = state.extra is Job ? state.extra as Job : null;
          if (job == null) {
            return const Scaffold(body: Center(child: Text('Job not found')));
          }
          return JobDetailScreen(job: job);
        },
      ),
    ],
  );
});

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// RouterNotifier converts Riverpod Auth & Profile streams into a Listenable for GoRouter.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateStreamProvider, (_, __) => notifyListeners());
    _ref.listen(profileProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final user = _ref.read(currentUserProvider);
    final profileAsync = _ref.read(profileProvider);

    final loc = state.matchedLocation;
    final isLoggingIn = loc == '/login';
    final isRoleSelection = loc == '/role-selection';

    // 1. Unauthenticated -> Send to Login
    if (user == null) {
      return isLoggingIn ? null : '/login';
    }

    // 2. Authenticated -> Check Profile & Role
    return profileAsync.when(
      loading: () => null, // Wait until profile lookup resolves
      error: (_, __) {
        // On error (e.g. profile row doesn't exist yet), send to onboarding
        return isRoleSelection ? null : '/role-selection';
      },
      data: (profile) {
        // Missing profile or missing role -> Send to Onboarding
        if (profile == null || profile.role.isEmpty || profile.fullName.isEmpty) {
          return isRoleSelection ? null : '/role-selection';
        }

        final role = profile.role.toLowerCase().trim();
        final roleRoot = '/$role';

        // Logged in user visiting auth or onboarding pages -> Redirect to shell
        if (isLoggingIn || isRoleSelection || loc == '/') {
          return roleRoot;
        }

        // Enforce role-based boundaries
        if (loc.startsWith('/customer') && role != 'customer') {
          return roleRoot;
        }
        if (loc.startsWith('/technician') && role != 'technician') {
          return roleRoot;
        }
        if (loc.startsWith('/retailer') && role != 'retailer') {
          return roleRoot;
        }

        return null;
      },
    );
  }
}
