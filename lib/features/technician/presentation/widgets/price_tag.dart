import 'package:flutter/material.dart';

/// Price tag component with green background and bold formatting.
class PriceTag extends StatelessWidget {
  final double price;

  const PriceTag({
    super.key,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Soft green
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E7D32),
          width: 1,
        ),
      ),
      child: Text(
        '₹${price.toStringAsFixed(0)}',
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
