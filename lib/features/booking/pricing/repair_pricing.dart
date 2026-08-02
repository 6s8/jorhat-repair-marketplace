import 'package:flutter/material.dart';

/// Central pricing configuration for Jorhat Repair Marketplace.
class RepairPricing {
  static const Map<String, double> basePrice = {
    'AC': 399.0,
    'Refrigerator': 349.0,
    'Washing Machine': 449.0,
    'Car AC': 599.0,
    'Television': 299.0,
  };

  static const Map<String, IconData> categoryIcons = {
    'AC': Icons.ac_unit,
    'Refrigerator': Icons.kitchen,
    'Washing Machine': Icons.local_laundry_service,
    'Car AC': Icons.directions_car,
    'Television': Icons.tv,
  };

  static double getPrice(String category) {
    return basePrice[category] ?? 399.0;
  }

  static IconData getIcon(String category) {
    return categoryIcons[category] ?? Icons.build;
  }
}
