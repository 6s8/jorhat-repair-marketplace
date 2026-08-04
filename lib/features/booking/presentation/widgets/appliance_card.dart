import 'package:flutter/material.dart';
import '../../../../core/constants/appliance_categories.dart';
import '../../../../core/theme/app_colors.dart';

/// Material 3 Appliance Card with interactive scale animation, selection badge, and inspection fee tag.
class ApplianceCard extends StatefulWidget {
  final ApplianceCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const ApplianceCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ApplianceCard> createState() => _ApplianceCardState();
}

class _ApplianceCardState extends State<ApplianceCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedScale(
      scale: _isPressed ? 0.95 : (isSelected ? 1.02 : 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapCancel: () => setState(() => _isPressed = false),
          onTapUp: (_) => setState(() => _isPressed = false),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : Colors.grey.withValues(alpha: 0.25),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Visual Image Container with Fallback Icon
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark ? Colors.white10 : Colors.grey.shade100,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            widget.category.imageAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  widget.category.fallbackIcon,
                                  size: 42,
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade700),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Appliance Title
                      Text(
                        widget.category.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primaryColor : null,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Base Inspection Fee Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Inspection ',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? AppColors.text
                                    : (isDark ? AppColors.accent : AppColors.textMuted),
                              ),
                            ),
                            Text(
                              '₹${widget.category.baseInspectionFee}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.text : primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected Checkmark Overlay Badge
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
