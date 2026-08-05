import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/modern_floating_nav_bar.dart';
import '../features/technician/presentation/providers/technician_profile_provider.dart';
import '../features/technician/presentation/screens/active_jobs_tab.dart';
import '../features/technician/presentation/screens/earnings_tab.dart';
import '../features/technician/presentation/screens/marketplace_tab.dart';
import '../features/technician/presentation/screens/pending_jobs_tab.dart';
import '../features/technician/presentation/screens/technician_dashboard_tab.dart';

class TechnicianHomeScreen extends ConsumerStatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  ConsumerState<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends ConsumerState<TechnicianHomeScreen> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Pending Radar Jobs',
    'Active Repair Jobs',
    'Wholesale Spare Parts',
    'Earnings & Payouts',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(technicianProfileProvider);
    final profile = profileState.value;
    final isOnline = profile?.isOnline ?? false;

    return Scaffold(
      extendBody: true,
      appBar: _currentIndex == 0 || _currentIndex == 4
          ? null
          : AppBar(
              title: Text(
                _titles[_currentIndex],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.success.withValues(alpha: 0.9)
                        : AppColors.textMuted.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Radar Settings',
                  onPressed: () => context.push('/technician/radar-settings'),
                ),
                if (_currentIndex == 2)
                  AnimatedOrdersButton(
                    onTap: () => context.push('/technician/orders'),
                  ),
                const SizedBox(width: 4),
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          PendingJobsTab(),
          ActiveJobsTab(),
          MarketplaceTab(),
          EarningsTab(),
          TechnicianDashboardTab(),
        ],
      ),
      bottomNavigationBar: ModernFloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          ModernNavItem(
            icon: Icons.radar_outlined,
            selectedIcon: Icons.radar,
            label: 'Radar',
          ),
          ModernNavItem(
            icon: Icons.assignment_turned_in_outlined,
            selectedIcon: Icons.assignment_turned_in,
            label: 'Active',
          ),
          ModernNavItem(
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront,
            label: 'Wholesale',
          ),
          ModernNavItem(
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet,
            label: 'Earnings',
          ),
          ModernNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class AnimatedOrdersButton extends StatefulWidget {
  final VoidCallback onTap;

  const AnimatedOrdersButton({super.key, required this.onTap});

  @override
  State<AnimatedOrdersButton> createState() => _AnimatedOrdersButtonState();
}

class _AnimatedOrdersButtonState extends State<AnimatedOrdersButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.12,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - _controller.value,
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleTap,
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.white.withValues(alpha: 0.4),
                highlightColor: Colors.white.withValues(alpha: 0.2),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'My Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
