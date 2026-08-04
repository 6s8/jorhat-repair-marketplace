import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ModernNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int? badgeCount;

  const ModernNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });
}

class ModernFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ModernNavItem> items;

  const ModernFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? primaryColor.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.1))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  size: 22,
                                  color: isSelected
                                      ? (isDark ? primaryColor : AppColors.primary)
                                      : (isDark ? const Color(0xFF94A3B8) : AppColors.textMuted),
                                ),
                              ),
                              if (item.badgeCount != null && item.badgeCount! > 0)
                                Positioned(
                                  right: -6,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 14,
                                    ),
                                    child: Text(
                                      '${item.badgeCount}',
                                      style: const TextStyle(
                                        color: AppColors.text,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? primaryColor : AppColors.primary)
                                  : (isDark ? const Color(0xFF94A3B8) : AppColors.textMuted),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
