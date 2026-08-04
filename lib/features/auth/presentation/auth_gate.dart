import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import 'access_restricted_screen.dart';
import 'auth_screen.dart';
import 'profile_name_dialog.dart';

/// Reusable Authentication Gate managing authentication, session restoration,
/// role onboarding, and role-based access validation across all three entry points.
class AuthGate extends ConsumerWidget {
  final String targetRole; // 'customer' | 'technician' | 'retailer'
  final Widget child;

  const AuthGate({
    super.key,
    required this.targetRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Monitor Authentication State
    final user = ref.watch(currentUserProvider);

    // If user is unauthenticated, show AuthScreen wrapped in a Navigator overlay
    if (user == null) {
      return _AuthGateView(child: AuthScreen(targetRole: targetRole));
    }

    // 2. Monitor Profile State
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => _AuthGateView(child: child),
      error: (err, st) => _AuthGateView(
        child: Stack(
          children: [
            AuthScreen(targetRole: targetRole),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: ProfileNameDialog(
                    userId: user.id,
                    defaultRole: targetRole,
                    initialName: user.userMetadata?['full_name'] as String? ??
                        user.userMetadata?['name'] as String?,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      data: (profile) {
        // 3. Handle Missing Profile / Onboarding
        if (profile == null || profile.role.isEmpty || profile.fullName.isEmpty) {
          return _AuthGateView(
            child: Stack(
              children: [
                AuthScreen(targetRole: targetRole),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: ProfileNameDialog(
                        userId: user.id,
                        defaultRole: targetRole,
                        initialName: user.userMetadata?['full_name'] as String? ??
                            user.userMetadata?['name'] as String?,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 4. Role Validation Enforcement
        if (profile.role.toLowerCase() != targetRole.toLowerCase()) {
          return _AuthGateView(
            child: AccessRestrictedScreen(
              currentRole: profile.role,
              targetRole: targetRole,
            ),
          );
        }

        // 5. Authorized & Validated -> Render App Child
        return child;
      },
    );
  }
}

/// Helper wrapper providing a Navigator & Overlay for authentication and onboarding views
class _AuthGateView extends StatelessWidget {
  final Widget child;

  const _AuthGateView({required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => child,
      ),
    );
  }
}
