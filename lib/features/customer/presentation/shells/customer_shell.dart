import 'package:flutter/material.dart';
import '../../../../customer/customer_root_app.dart';

/// Customer Application Shell housing customer navigation and screens.
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerHomeScreen();
  }
}
