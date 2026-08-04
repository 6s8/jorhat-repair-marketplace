import 'package:flutter/material.dart';

/// Strongly-typed domain model representing an appliance repair category.
class ApplianceCategory {
  final String id;
  final String title;
  final String imageAsset;
  final IconData fallbackIcon;
  final int baseInspectionFee;

  const ApplianceCategory({
    required this.id,
    required this.title,
    required this.imageAsset,
    required this.fallbackIcon,
    required this.baseInspectionFee,
  });
}

/// Centralized catalog of all supported repair appliance categories in Jorhat.
const List<ApplianceCategory> applianceCategories = [
  ApplianceCategory(
    id: 'ac',
    title: 'Split & Window AC',
    imageAsset: 'assets/appliances/ac.png',
    fallbackIcon: Icons.ac_unit_rounded,
    baseInspectionFee: 299,
  ),
  ApplianceCategory(
    id: 'fridge',
    title: 'Refrigerator',
    imageAsset: 'assets/appliances/refrigerator.png',
    fallbackIcon: Icons.kitchen_rounded,
    baseInspectionFee: 249,
  ),
  ApplianceCategory(
    id: 'washing_machine',
    title: 'Washing Machine',
    imageAsset: 'assets/appliances/washing_machine.png',
    fallbackIcon: Icons.local_laundry_service_rounded,
    baseInspectionFee: 249,
  ),
  ApplianceCategory(
    id: 'tv',
    title: 'Television / Smart TV',
    imageAsset: 'assets/appliances/television.png',
    fallbackIcon: Icons.tv_rounded,
    baseInspectionFee: 299,
  ),
  ApplianceCategory(
    id: 'purifier',
    title: 'Water Purifier / RO',
    imageAsset: 'assets/appliances/purifier.png',
    fallbackIcon: Icons.water_drop_rounded,
    baseInspectionFee: 199,
  ),
  ApplianceCategory(
    id: 'microwave',
    title: 'Microwave & Oven',
    imageAsset: 'assets/appliances/microwave.png',
    fallbackIcon: Icons.microwave_rounded,
    baseInspectionFee: 199,
  ),
  ApplianceCategory(
    id: 'cooler',
    title: 'Air Cooler',
    imageAsset: 'assets/appliances/cooler.png',
    fallbackIcon: Icons.mode_fan_off_rounded,
    baseInspectionFee: 199,
  ),
  ApplianceCategory(
    id: 'inverter',
    title: 'Inverter & Battery',
    imageAsset: 'assets/appliances/inverter.png',
    fallbackIcon: Icons.battery_charging_full_rounded,
    baseInspectionFee: 249,
  ),
  ApplianceCategory(
    id: 'geyser',
    title: 'Geyser / Water Heater',
    imageAsset: 'assets/appliances/geyser.png',
    fallbackIcon: Icons.water_rounded,
    baseInspectionFee: 199,
  ),
  ApplianceCategory(
    id: 'chimney',
    title: 'Kitchen Chimney',
    imageAsset: 'assets/appliances/chimney.png',
    fallbackIcon: Icons.sensor_window_rounded,
    baseInspectionFee: 249,
  ),
  ApplianceCategory(
    id: 'car_ac',
    title: 'Car AC Gas Charging',
    imageAsset: 'assets/appliances/car_ac.png',
    fallbackIcon: Icons.directions_car_rounded,
    baseInspectionFee: 399,
  ),
];
