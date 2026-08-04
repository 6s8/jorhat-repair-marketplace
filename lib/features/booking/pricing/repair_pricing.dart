import 'package:flutter/material.dart';

/// Central pricing configuration for Jorhat Repair Marketplace.
class RepairPricing {
  static const Map<String, double> basePrice = {
    'Split & Window AC': 299.0,
    'Refrigerator': 249.0,
    'Washing Machine': 249.0,
    'Television / Smart TV': 299.0,
    'Water Purifier / RO': 199.0,
    'Microwave & Oven': 199.0,
    'Air Cooler': 199.0,
    'Inverter & Battery': 249.0,
    'Geyser / Water Heater': 199.0,
    'Kitchen Chimney': 249.0,
    'Car AC Gas Charging': 399.0,
  };

  static const Map<String, IconData> categoryIcons = {
    'Split & Window AC': Icons.ac_unit_rounded,
    'Refrigerator': Icons.kitchen_rounded,
    'Washing Machine': Icons.local_laundry_service_rounded,
    'Television / Smart TV': Icons.tv_rounded,
    'Water Purifier / RO': Icons.water_drop_rounded,
    'Microwave & Oven': Icons.microwave_rounded,
    'Air Cooler': Icons.mode_fan_off_rounded,
    'Inverter & Battery': Icons.battery_charging_full_rounded,
    'Geyser / Water Heater': Icons.water_rounded,
    'Kitchen Chimney': Icons.sensor_window_rounded,
    'Car AC Gas Charging': Icons.directions_car_rounded,
  };

  static double getPrice(String category) {
    return basePrice[category] ?? 399.0;
  }

  static IconData getIcon(String category) {
    return categoryIcons[category] ?? Icons.build;
  }
}
