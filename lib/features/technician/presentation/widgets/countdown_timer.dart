import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/countdown_provider.dart';

/// Countdown timer component for job expiry with color transitions.
class CountdownTimerWidget extends ConsumerWidget {
  final DateTime? expiresAt;
  final VoidCallback? onExpired;

  const CountdownTimerWidget({
    super.key,
    required this.expiresAt,
    this.onExpired,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to second ticker
    ref.watch(countdownTickerProvider);

    if (expiresAt == null) {
      return const SizedBox.shrink();
    }

    final remaining = expiresAt!.difference(DateTime.now());

    if (remaining.isNegative || remaining == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onExpired?.call();
      });
      return const SizedBox.shrink();
    }

    final totalSeconds = remaining.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final formattedTime = '$minutes:$seconds';

    // Color logic: Orange under 10s, Red under 5s
    Color timerColor = Theme.of(context).colorScheme.primary;
    if (totalSeconds <= 5) {
      timerColor = const Color(0xFFD32F2F); // Deep Red
    } else if (totalSeconds <= 10) {
      timerColor = const Color(0xFFE65100); // Deep Orange
    }

    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 20,
          color: timerColor,
        ),
        const SizedBox(width: 6),
        Text(
          'Expires in ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            formattedTime,
            key: ValueKey(formattedTime),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: timerColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
