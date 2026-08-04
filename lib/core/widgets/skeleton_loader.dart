import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Lightweight, layout-preserving Skeleton Loader with smooth pulsing animation.
/// Replaces blank circular progress indicators to prevent UI layout jumps.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Pre-built Skeleton Card for job feeds and marketplace items.
class SkeletonCard extends StatelessWidget {
  final double height;

  const SkeletonCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SkeletonLoader(width: 42, height: 42, borderRadius: 21),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 140, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonLoader(width: 90, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const SkeletonLoader(width: double.infinity, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Pre-built Skeleton List for feeds.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.count = 4,
    this.itemHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => SkeletonCard(height: itemHeight),
    );
  }
}
