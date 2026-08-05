import 'package:flutter/material.dart';
import '../screens/retailer_dashboard_screen.dart';

/// Retailer Application Shell housing inventory, orders, and sales dashboard.
class RetailerShell extends StatelessWidget {
  const RetailerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const RetailerDashboardScreen();
  }
}
