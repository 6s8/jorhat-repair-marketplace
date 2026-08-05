import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable Design System Progress Indicator
/// - Uses AppColors.accent (#F4A623) while in progress.
/// - Morphs smoothly to a checkmark in AppColors.success (#22C55E) when complete.
class AppProgressIndicator extends StatelessWidget {
  final bool isCompleted;
  final double size;
  final String? label;

  const AppProgressIndicator({
    super.key,
    this.isCompleted = false,
    this.size = 24.0,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: isCompleted
          ? Container(
              key: const ValueKey('completed'),
              width: size + 8,
              height: size + 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: size,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  key: const ValueKey('loading'),
                  width: size,
                  height: size,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                if (label != null && label!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    label!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
