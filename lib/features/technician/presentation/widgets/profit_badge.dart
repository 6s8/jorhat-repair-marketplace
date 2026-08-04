import 'package:flutter/material.dart';

/// Green badge showing the technician profit margin for a part.
class ProfitBadge extends StatelessWidget {
  final double technicianPrice;
  final double customerPrice;

  const ProfitBadge({
    super.key,
    required this.technicianPrice,
    required this.customerPrice,
  });

  double get _profit => customerPrice - technicianPrice;

  bool get _hasValidPricing =>
      technicianPrice > 0 && customerPrice >= technicianPrice;

  @override
  Widget build(BuildContext context) {
    if (!_hasValidPricing) {
      return const SizedBox.shrink();
    }

    final profit = _profit;

    if (profit <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'No Margin',
          style: TextStyle(fontSize: 11, color: Colors.black45),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, size: 13, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            'Profit ₹${profit.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
