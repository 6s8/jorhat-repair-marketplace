import 'package:flutter/material.dart';

/// Memory-optimized image loader widget.
/// Enforces memory cache decoding boundaries (`memCacheWidth` & `memCacheHeight`)
/// and provides skeleton placeholders and error fallbacks.
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData fallbackIcon;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.fallbackIcon = Icons.image_not_supported_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    Widget imageWidget;
    if (isNetwork) {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        // Memory cache size optimization to reduce GPU/RAM allocation
        cacheWidth: width != null && width! > 0 ? (width! * 1.5).toInt() : 400,
        cacheHeight: height != null && height! > 0 ? (height! * 1.5).toInt() : 400,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.withValues(alpha: 0.1),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    } else {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withValues(alpha: 0.12),
      child: Icon(
        fallbackIcon,
        color: Colors.grey.shade400,
        size: 24,
      ),
    );
  }
}
