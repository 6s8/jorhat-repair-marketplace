import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../booking/controller/booking_controller.dart';
import '../../booking/presentation/pages/booking_success_page.dart';
import '../../booking/presentation/pages/customer_address_page.dart';
import '../../booking/presentation/pages/customer_category_page.dart';
import '../../booking/presentation/pages/customer_issue_page.dart';
import '../../booking/state/booking_state.dart';
import '../../technician/presentation/screens/job_feed_screen.dart';
import '../../technician/presentation/screens/technician_active_jobs_screen.dart';

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

    // Auto-navigate to Live Tracker immediately when booking succeeds
    ref.listen<BookingState>(bookingControllerProvider, (previous, next) {
      if (next.currentStep == 3 &&
          (previous?.currentStep ?? 0) != 3 &&
          next.createdJob != null) {
        final job = next.createdJob!;
        context.push('/track-job', extra: {
          'jobId': job.id,
          'category': next.selectedCategory,
          'customerName': next.customerName,
        });
      }
    });

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
          : null, // Technician shell renders its own AppBar
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // Tab 0: Customer Booking Flow Stepper
          _buildCustomerBookingFlow(bookingState.currentStep),

          // Tab 1: Technician View with Feed + Active Jobs sub-tabs
          const _TechnicianShell(),
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
        return CustomerCategoryPage(onNext: () {});
      case 1:
        return CustomerIssuePage(onNext: () {}, onBack: () {});
      case 2:
        return CustomerAddressPage(onSuccess: () {}, onBack: () {});
      case 3:
        // Shown briefly until the auto-navigate listener fires.
        return BookingSuccessPage(
          onBackHome: () {
            ref.read(bookingControllerProvider.notifier).reset();
          },
        );
      default:
        return CustomerCategoryPage(onNext: () {});
    }
  }
}

// ─── Technician Shell: Job Feed + Active Jobs tabs ───────────────────────────
class _TechnicianShell extends StatelessWidget {
  const _TechnicianShell();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1117),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1117),
          title: const Text(
            'Technician Portal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          bottom: const TabBar(
            labelColor: Color(0xFF42A5F5),
            unselectedLabelColor: Colors.white38,
            indicatorColor: Color(0xFF1565C0),
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: Icon(Icons.wifi_rounded, size: 18),
                text: 'Live Feed',
              ),
              Tab(
                icon: Icon(Icons.engineering_rounded, size: 18),
                text: 'Active Jobs',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            JobFeedScreen(),
            TechnicianActiveJobsScreen(),
          ],
        ),
      ),
    );
  }
}
