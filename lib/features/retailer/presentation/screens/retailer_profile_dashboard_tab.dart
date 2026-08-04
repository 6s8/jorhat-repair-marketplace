import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/refurbished_store_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../controller/retailer_controller.dart';
import '../../controller/retailer_orders_controller.dart';

class RetailerProfileDashboardTab extends ConsumerStatefulWidget {
  const RetailerProfileDashboardTab({super.key});

  @override
  ConsumerState<RetailerProfileDashboardTab> createState() =>
      _RetailerProfileDashboardTabState();
}

class _RetailerProfileDashboardTabState
    extends ConsumerState<RetailerProfileDashboardTab> {
  bool _isStoreOpen = true;
  bool _expressDeliveryEnabled = true;

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final currentMode = ref.watch(themeModeProvider);
            final isDark = currentMode == ThemeMode.dark;
            final primaryColor = Theme.of(context).colorScheme.primary;

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings_rounded, color: primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Fixly Retailer Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    secondary: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.accent,
                    ),
                    title: const Text(
                      'Dark Theme Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Enable dark appearance for retail dashboard'),
                    value: isDark,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final retailerState = ref.watch(retailerControllerProvider);
    final refurbishedItems = ref.watch(refurbishedStoreProvider);
    final ordersAsync = ref.watch(retailerOrdersProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    final partsCount = retailerState.parts.length;
    final refurbishedCount = refurbishedItems.length;

    int totalOrdersCount = 0;
    double totalRevenue = 0.0;
    ordersAsync.whenData((orders) {
      totalOrdersCount = orders.length;
      totalRevenue = orders.fold(0.0, (sum, item) => sum + item.totalAmount);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Identity Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.store_rounded,
                            size: 36,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Fixly Retailer - Jorhat Hub',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified,
                                          size: 12, color: AppColors.success),
                                      SizedBox(width: 4),
                                      Text(
                                        'VERIFIED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Proprietor: Rajesh Sharma • GSTIN: 18AABCU9603R1ZM',
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 A.T. Road, Near Old Bus Stand, Jorhat, Assam 785001',
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_rounded, color: primaryColor),
                        tooltip: 'Fixly Retailer Settings',
                        onPressed: () => _showSettingsModal(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isStoreOpen ? Icons.storefront : Icons.storefront_outlined,
                            color: _isStoreOpen ? AppColors.success : AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isStoreOpen ? 'Store Open & Accepting Orders' : 'Store Currently Closed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _isStoreOpen ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isStoreOpen,
                        activeColor: AppColors.success,
                        onChanged: (val) => setState(() => _isStoreOpen = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Business KPI Snapshot Grid
          Text(
            'Business Overview & Metrics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard(
                title: 'Parts Listed',
                value: '$partsCount Items',
                icon: Icons.inventory_2_outlined,
                color: primaryColor,
              ),
              _buildKpiCard(
                title: 'Refurbished Listed',
                value: '$refurbishedCount Items',
                icon: Icons.verified_outlined,
                color: AppColors.accent,
              ),
              _buildKpiCard(
                title: 'Orders Processed',
                value: '$totalOrdersCount Orders',
                icon: Icons.local_shipping_outlined,
                color: isDark ? const Color(0xFFC084FC) : Colors.purple,
              ),
              _buildKpiCard(
                title: 'Total Revenue',
                value: '₹${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Settings & Bank Account
          Text(
            'Store Operations & Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.accent,
                  ),
                  title: const Text('Dark Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Enable dark appearance for Retailer Hub'),
                  value: isDark,
                  activeColor: AppColors.accent,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.flash_on_outlined, color: AppColors.accent),
                  title: const Text('Same-Day Express Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Offer 2-hour doorstep delivery for technicians & customers in Jorhat'),
                  value: _expressDeliveryEnabled,
                  onChanged: (val) => setState(() => _expressDeliveryEnabled = val),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.account_balance_outlined, color: primaryColor),
                  title: const Text('Bank Payout Account', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('HDFC Bank • A/C ********4321 (UPI: assamparts@hdfcbank)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payout Account: Verified HDFC Bank')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.receipt_long_outlined, color: primaryColor),
                  title: const Text('GST Tax Reports & Earnings Statement', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Download monthly GST B2B invoice summary'),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading GST Monthly Sales Statement...')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.headset_mic_outlined, color: primaryColor),
                  title: const Text('Fixly Retailer Partner Support', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Helpline: +91 98765 00000 • Priority Retail Support'),
                  trailing: const Icon(Icons.phone_in_talk_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling Fixly Retailer Support...')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: mutedTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
