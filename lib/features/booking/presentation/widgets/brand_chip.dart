import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/brand_logos.dart';
import '../../../../core/theme/app_colors.dart';

/// A Material 3 selectable brand card showing the real downloaded brand logo.
class BrandChip extends StatelessWidget {
  final String brand;
  final bool isSelected;
  final VoidCallback onTap;

  const BrandChip({
    super.key,
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  bool get _isOthers => brand == 'Others';

  String? get _assetPath => brandLogoAssets[brand];

  bool get _isSvg {
    final p = _assetPath;
    return p != null && p.endsWith('.svg');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = AppColors.primary;
    final selectedBg = primary.withValues(alpha: 0.08);

    return Semantics(
      label: '$brand brand${isSelected ? ", selected" : ""}',
      button: true,
      selected: isSelected,
      child: AnimatedScale(
        scale: isSelected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primary : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? primary.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isSelected ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: _isOthers
                              ? _OthersIcon(isSelected: isSelected)
                              : _LogoWidget(
                                  assetPath: _assetPath,
                                  isSvg: _isSvg,
                                  brand: brand,
                                  isSelected: isSelected,
                                ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        brand,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? primary
                              : colorScheme.onSurface
                                  .withValues(alpha: 0.72),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isSelected)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 10,
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

class _LogoWidget extends StatelessWidget {
  final String? assetPath;
  final bool isSvg;
  final String brand;
  final bool isSelected;

  const _LogoWidget({
    required this.assetPath,
    required this.isSvg,
    required this.brand,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath == null) {
      return _FallbackInitials(brand: brand, isSelected: isSelected);
    }

    if (isSvg) {
      return SvgPicture.asset(
        assetPath!,
        height: 28,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _shimmer(),
      );
    }

    return Image.asset(
      assetPath!,
      height: 28,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          _FallbackInitials(brand: brand, isSelected: isSelected),
    );
  }

  Widget _shimmer() => Container(
        height: 28,
        width: 64,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

class _OthersIcon extends StatelessWidget {
  final bool isSelected;

  const _OthersIcon({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add_rounded,
        size: 18,
        color: isSelected ? AppColors.primary : Colors.grey.shade600,
      ),
    );
  }
}

class _FallbackInitials extends StatelessWidget {
  final String brand;
  final bool isSelected;

  const _FallbackInitials({required this.brand, required this.isSelected});

  String get _initials {
    final words = brand.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return brand.substring(0, brand.length.clamp(0, 3)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 64,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isSelected ? AppColors.primary : Colors.blueGrey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
