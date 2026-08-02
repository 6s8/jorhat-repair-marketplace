import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../booking/controller/booking_controller.dart';
import '../../booking/presentation/pages/booking_success_page.dart';
import '../../booking/presentation/pages/customer_address_page.dart';
import '../../booking/presentation/pages/customer_category_page.dart';
import '../../booking/presentation/pages/customer_issue_page.dart';
import '../../technician/presentation/screens/job_feed_screen.dart';

/// Main navigation shell with bottom navigation bar.
/// Uses IndexedStack to preserve Customer Booking state and Technician Feed state.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentTabIndex = 0; // 0: Customer View, 1: Technician View

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingControllerProvider);

    return Scaffold(
      appBar: _currentTabIndex == 0
          ? AppBar(
              title: Text(
                bookingState.currentStep == 3
                    ? 'Booking Confirmed'
                    : 'Book Repair (${bookingState.currentStep + 1}/3)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              actions: [
                if (bookingState.currentStep > 0 && bookingState.currentStep < 3)
                  TextButton(
                    onPressed: () {
                      ref.read(bookingControllerProvider.notifier).reset();
                    },
                    child: const Text('Reset'),
                  ),
              ],
            )
          : null, // JobFeedScreen renders its own M3 AppBar
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // Tab 0: Customer Booking Flow Stepper
          _buildCustomerBookingFlow(bookingState.currentStep),

          // Tab 1: Technician Realtime Feed
          const JobFeedScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Customer View',
          ),
          NavigationDestination(
            icon: Icon(Icons.engineering_outlined),
            selectedIcon: Icon(Icons.engineering),
            label: 'Technician View',
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerBookingFlow(int step) {
    switch (step) {
      case 0:
        return CustomerCategoryPage(
          onNext: () {},
        );
      case 1:
        return CustomerIssuePage(
          onNext: () {},
          onBack: () {},
        );
      case 2:
        return CustomerAddressPage(
          onSuccess: () {},
          onBack: () {},
        );
      case 3:
        return BookingSuccessPage(
          onBackHome: () {
            ref.read(bookingControllerProvider.notifier).reset();
          },
        );
      default:
        return CustomerCategoryPage(
          onNext: () {},
        );
    }
  }
}
