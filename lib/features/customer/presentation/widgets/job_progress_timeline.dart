import 'package:flutter/material.dart';

/// Reusable horizontal/responsive progress timeline for live job tracking.
/// Displays steps: Pending -> Accepted -> On The Way / Arrived -> Repair In Progress -> Completed.
class JobProgressTimeline extends StatelessWidget {
  final String status;

  const JobProgressTimeline({
    super.key,
    required this.status,
  });

  int get _currentStepIndex {
    switch (status) {
      case 'accepted':
        return 1;
      case 'on_the_way':
        return 2;
      case 'in_progress':
        return 3;
      case 'completed':
        return 4;
      case 'pending':
      default:
        return 0;
    }
  }

  List<Map<String, dynamic>> get _steps {
    final bool hasArrived = status == 'in_progress' || status == 'completed';
    return [
      {'title': 'Pending', 'icon': Icons.hourglass_top_rounded},
      {'title': 'Accepted', 'icon': Icons.person_add_alt_1_rounded},
      {
        'title': hasArrived ? 'Arrived' : 'On The Way',
        'icon': hasArrived ? Icons.home_work_rounded : Icons.directions_bike_rounded,
      },
      {'title': 'In Progress', 'icon': Icons.build_rounded},
      {'title': 'Completed', 'icon': Icons.task_alt_rounded},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentStepIndex;
    final steps = _steps;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2D3E)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (i) {
              final step = steps[i];
              final isDone = i < currentIndex;
              final isActive = i == currentIndex;
              final isFuture = i > currentIndex;

              final Color color = isDone
                  ? const Color(0xFF43A047)
                  : isActive
                      ? const Color(0xFF1565C0)
                      : Colors.white24;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isCompact ? 28 : 34,
                            height: isCompact ? 28 : 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF1565C0)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isDone
                                  ? Icons.check_rounded
                                  : (step['icon'] as IconData),
                              color: isFuture ? Colors.white38 : Colors.white,
                              size: isCompact ? 14 : 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              color: isFuture ? Colors.white30 : Colors.white,
                              fontSize: isCompact ? 9 : 10,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        height: 2,
                        width: isCompact ? 8 : 16,
                        color: isDone
                            ? const Color(0xFF43A047)
                            : const Color(0xFF2A2D3E),
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
