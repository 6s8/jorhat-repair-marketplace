import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_scroll_behavior.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/modern_floating_nav_bar.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/booking/controller/booking_controller.dart';
import '../../features/booking/presentation/pages/appliance_issue_screen.dart';
import '../../features/booking/presentation/pages/booking_success_page.dart';
import '../../features/booking/presentation/pages/customer_address_page.dart';
import '../../features/booking/presentation/pages/customer_brand_model_page.dart';
import '../../features/booking/presentation/pages/customer_category_page.dart';
import '../../features/customer/presentation/providers/cart_provider.dart';
import '../../features/customer/presentation/screens/customer_order_history_screen.dart';
import '../../features/customer/presentation/screens/customer_profile_dashboard_screen.dart';
import '../../features/customer/presentation/screens/customer_store_screen.dart';
import '../../features/tracking/job_status_tracker_screen.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Book Repair Service',
    'My Booking History',
    'Marketplace & Store',
    'My Profile & Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartTotalItemCountProvider);

    return Scaffold(
      extendBody: true,
      appBar: _currentIndex != 2 && _currentIndex != 3
          ? AppBar(
              title: Text(
                _titles[_currentIndex],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _BookingFlowWrapper(),
          const CustomerOrderHistoryScreen(),
          const CustomerStoreScreen(),
          CustomerProfileDashboardScreen(
            onNavigateTab: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
      bottomNavigationBar: ModernFloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: [
          const ModernNavItem(
            icon: Icons.build_outlined,
            selectedIcon: Icons.build_rounded,
            label: 'Book Repair',
          ),
          const ModernNavItem(
            icon: Icons.history_outlined,
            selectedIcon: Icons.history_rounded,
            label: 'Bookings',
          ),
          ModernNavItem(
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront_rounded,
            label: 'Marketplace',
            badgeCount: cartCount > 0 ? cartCount : null,
          ),
          const ModernNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _BookingFlowWrapper extends ConsumerWidget {
  const _BookingFlowWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(bookingControllerProvider).currentStep;
    return IndexedStack(
      index: step,
      children: [
        CustomerCategoryPage(
          onNext: () =>
              ref.read(bookingControllerProvider.notifier).goToNextStep(),
        ),
        CustomerBrandModelPage(
          onBack: () =>
              ref.read(bookingControllerProvider.notifier).goToPreviousStep(),
          onNext: () =>
              ref.read(bookingControllerProvider.notifier).goToNextStep(),
        ),
        ComplaintDetailsScreen(
          onBack: () =>
              ref.read(bookingControllerProvider.notifier).goToPreviousStep(),
          onNext: () =>
              ref.read(bookingControllerProvider.notifier).goToNextStep(),
        ),
        CustomerAddressPage(
          onBack: () =>
              ref.read(bookingControllerProvider.notifier).goToPreviousStep(),
          onSuccess: () =>
              ref.read(bookingControllerProvider.notifier).goToNextStep(),
        ),
        BookingSuccessPage(
          onBackHome: () =>
              ref.read(bookingControllerProvider.notifier).reset(),
        ),
      ],
    );
  }
}

final customerRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CustomerHomeScreen(),
    ),
    GoRoute(
      path: '/store',
      builder: (context, state) => const CustomerStoreScreen(),
    ),
    GoRoute(
      path: '/track-job',
      builder: (context, state) {
        final extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
        final jobId = extra?['jobId'] as String? ?? '';
        final category = extra?['category'] as String?;
        final customerName = extra?['customerName'] as String?;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Fixly - Repair Tracker'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: JobStatusTrackerScreen(
            jobId: jobId,
            applianceCategory: category,
            customerName: customerName,
          ),
        );
      },
    ),
  ],
);

class CustomerRootApp extends ConsumerWidget {
  const CustomerRootApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Fixly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      scrollBehavior: const AppStretchScrollBehavior(),
      routerConfig: customerRouter,
      builder: (context, child) {
        return AuthGate(
          targetRole: 'customer',
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
