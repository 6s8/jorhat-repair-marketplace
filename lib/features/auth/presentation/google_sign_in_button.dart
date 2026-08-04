import 'package:flutter/material.dart';

/// Reusable Google Sign-In button following Material 3 guidelines.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SVG / Styled Google "G" Badge
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: CustomPaint(
                      size: const Size(22, 22),
                      painter: _GoogleGLogoPainter(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Custom Painter rendering Google 'G' icon cleanly without assets dependency.
class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double radius = w / 2;

    final center = Offset(radius, radius);

    // Blue
    final pBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    // Green
    final pGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;

    // Yellow
    final pYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;

    // Red
    final pRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw Google G arcs
    canvas.drawArc(rect, -0.4, 1.8, true, pBlue);
    canvas.drawArc(rect, 1.4, 1.3, true, pGreen);
    canvas.drawArc(rect, 2.7, 0.8, true, pYellow);
    canvas.drawArc(rect, 3.5, 1.2, true, pRed);

    // Inner cutout
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.55, innerPaint);

    // Blue horizontal bar
    final barRect = Rect.fromLTRB(
      radius * 0.9,
      radius * 0.75,
      w * 0.95,
      radius * 1.25,
    );
    canvas.drawRect(barRect, pBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
