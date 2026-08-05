import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import 'auth_screen.dart';
import 'role_selection_screen.dart';

/// Central Authentication Gate resolving session restoration, database profile role lookup,
/// and automatic onboarding for unassigned profiles.
class AuthGate extends ConsumerWidget {
  final Widget child;

  const AuthGate({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Check current authenticated user session
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const AuthScreen();
    }

    // 2. Resolve database profile from 'profiles' table
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const RoleSelectionScreen(),
      data: (profile) {
        if (profile == null || profile.role.isEmpty || profile.fullName.isEmpty) {
          return const RoleSelectionScreen();
        }
        return child;
      },
    );
  }
}
