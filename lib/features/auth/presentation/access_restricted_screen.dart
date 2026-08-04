import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

/// Screen displayed when user logs in with an unauthorized role for the current application.
class AccessRestrictedScreen extends ConsumerWidget {
  final String currentRole;
  final String targetRole;

  const AccessRestrictedScreen({
    super.key,
    required this.currentRole,
    required this.targetRole,
  });

  String _getRoleTitle(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return 'Customer';
      case 'technician':
        return 'Technician';
      case 'retailer':
        return 'Retailer / Spare Parts Vendor';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: const Icon(
                      Icons.gpp_maybe_rounded,
                      size: 48,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Access Restricted',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Current Account Role:',
                              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                            ),
                            Text(
                              _getRoleTitle(currentRole),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Target App Required:',
                              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                            ),
                            Text(
                              _getRoleTitle(targetRole),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'You are currently signed in as a ${_getRoleTitle(currentRole)}. This application entry point is restricted to ${_getRoleTitle(targetRole)} accounts only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: uiState.isLoading
                          ? null
                          : () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Sign Out & Switch Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
