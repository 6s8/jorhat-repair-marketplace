import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import 'google_sign_in_button.dart';
import 'otp_verification_view.dart';
import 'phone_login_view.dart';

/// Unified Authentication Screen shared across Customer, Technician, and Retailer apps.
class AuthScreen extends ConsumerWidget {
  final String? targetRole;

  const AuthScreen({
    super.key,
    this.targetRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    String roleBadgeLabel = 'Unified Portal';
    if (targetRole == 'customer') roleBadgeLabel = '🛒 Customer Portal';
    if (targetRole == 'technician') roleBadgeLabel = '🛠 Technician Portal';
    if (targetRole == 'retailer') roleBadgeLabel = '🏪 Retailer Portal';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: isDesktop
                  ? const EdgeInsets.all(32)
                  : const EdgeInsets.all(24),
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
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Branding Badge & Logo
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleBadgeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Brand Icon / Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.build_circle_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // App Title & Welcome Text
                  Text(
                    'Assam Repair & Parts Hub',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    uiState.isOtpSent
                        ? 'Verify your 6-digit OTP code'
                        : 'Sign in to access repair services & spare parts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Phone Input or OTP Verification View
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: uiState.isOtpSent
                        ? const OtpVerificationView(
                            key: ValueKey('OtpVerificationView'),
                          )
                        : const PhoneLoginView(
                            key: ValueKey('PhoneLoginView'),
                          ),
                  ),

                  // OR Divider (only shown in phone input state)
                  if (!uiState.isOtpSent) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google Sign In Button
                    GoogleSignInButton(
                      isLoading: uiState.isLoading,
                      onPressed: () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Terms & Privacy Footer
                  Text(
                    'By continuing, you agree to Assam Repair Hub\'s\nTerms of Service & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey.shade400,
                      height: 1.4,
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
