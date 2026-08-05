import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import 'google_sign_in_button.dart';
import 'otp_verification_view.dart';
import 'phone_login_view.dart';

/// Unified Authentication Screen shared across Customer, Technician, and Retailer apps.
class AuthScreen extends ConsumerStatefulWidget {
  final String? targetRole;

  const AuthScreen({
    super.key,
    this.targetRole,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    // Role-specific config
    String roleLabel = 'Welcome Back';
    String roleSubtitle = 'Sign in to continue';
    List<Color> roleGradient = [const Color(0xFF1E3A5F), const Color(0xFF0F2744)];

    if (widget.targetRole == 'customer') {
      roleLabel = 'Customer Portal';
      roleSubtitle = 'Order parts & book repair services';
      roleGradient = [const Color(0xFF1E3A5F), const Color(0xFF1D4ED8)];
    } else if (widget.targetRole == 'technician') {
      roleLabel = 'Technician Portal';
      roleSubtitle = 'Manage jobs & buy wholesale parts';
      roleGradient = [const Color(0xFF0F2744), const Color(0xFF1E3A5F)];
    } else if (widget.targetRole == 'retailer') {
      roleLabel = 'Retailer Portal';
      roleSubtitle = 'Manage inventory & process orders';
      roleGradient = [const Color(0xFF1E3A5F), const Color(0xFF0E7490)];
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: roleGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CustomPaint(
                  painter: _BubblePainter(_bgController.value),
                ),
              );
            },
          ),

          // ── Top branding area ──
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fixly logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fixly',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assam Repair & Parts Hub',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom card ──
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _cardController,
              builder: (_, child) {
                return Transform.translate(
                  offset: Offset(0, _cardSlide.value),
                  child: Opacity(
                    opacity: _cardFade.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: isDesktop ? 460 : double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 40,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 28),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Heading
                        Text(
                          uiState.isOtpSent ? 'Enter OTP' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          uiState.isOtpSent
                              ? 'We sent a 6-digit code to your number'
                              : roleSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey.shade500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Phone Input or OTP View
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.05, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: uiState.isOtpSent
                              ? const OtpVerificationView(
                                  key: ValueKey('otp'),
                                )
                              : const PhoneLoginView(
                                  key: ValueKey('phone'),
                                ),
                        ),

                        if (!uiState.isOtpSent) ...[
                          const SizedBox(height: 24),

                          // OR divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade200),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade300,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade200),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Google Sign In
                          GoogleSignInButton(
                            isLoading: uiState.isLoading,
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle(),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Terms footer
                        Center(
                          child: Text(
                            'By continuing, you agree to Assam Repair Hub\'s\nTerms of Service & Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey.shade300,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative animated floating bubbles painter
class _BubblePainter extends CustomPainter {
  final double t;
  _BubblePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final bubbles = [
      const _Bubble(0.15, 0.25, 90, 0.07),
      const _Bubble(0.8, 0.15, 60, 0.05),
      const _Bubble(0.6, 0.4, 120, 0.06),
      const _Bubble(0.1, 0.65, 50, 0.08),
      const _Bubble(0.9, 0.6, 80, 0.05),
      const _Bubble(0.4, 0.1, 40, 0.09),
      const _Bubble(0.55, 0.7, 70, 0.06),
    ];

    for (final b in bubbles) {
      final dy = math.sin(t * 2 * math.pi) * 18;
      final cx = size.width * b.xFrac;
      final cy = size.height * b.yFrac + dy;
      paint.color = Colors.white.withValues(alpha: b.opacity);
      canvas.drawCircle(Offset(cx, cy), b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.t != t;
}

class _Bubble {
  final double xFrac;
  final double yFrac;
  final double radius;
  final double opacity;

  const _Bubble(this.xFrac, this.yFrac, this.radius, this.opacity);
}
