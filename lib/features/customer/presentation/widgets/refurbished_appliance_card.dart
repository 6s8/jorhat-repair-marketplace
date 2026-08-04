import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../retailer/models/refurbished_appliance_model.dart';

class RefurbishedApplianceCard extends StatelessWidget {
  final RefurbishedAppliance appliance;

  const RefurbishedApplianceCard({
    super.key,
    required this.appliance,
  });

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    final primaryColor = Theme.of(context).colorScheme.primary;

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contact Retailer: $phoneNumber'),
              backgroundColor: primaryColor,
              action: SnackBarAction(
                label: 'CALL',
                textColor: AppColors.accent,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call Retailer: $phoneNumber'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  Widget _buildApplianceImage(BuildContext context) {
    final img = appliance.imageUrl;
    if (img != null && img.isNotEmpty) {
      if (img.startsWith('http://') || img.startsWith('https://')) {
        return Image.network(
          img,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackCategoryBanner(context),
        );
      } else {
        return Image.asset(
          img,
          height: 160,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackCategoryBanner(context),
        );
      }
    }
    return _buildFallbackCategoryBanner(context);
  }

  Widget _buildFallbackCategoryBanner(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    IconData icon = Icons.kitchen_rounded;
    final cat = appliance.category.toLowerCase();
    if (cat.contains('ac')) icon = Icons.ac_unit_rounded;
    if (cat.contains('wash')) icon = Icons.local_laundry_service_rounded;
    if (cat.contains('tv') || cat.contains('televis')) icon = Icons.tv_rounded;
    if (cat.contains('water') || cat.contains('purifier')) icon = Icons.water_drop_rounded;

    return Container(
      height: 140,
      width: double.infinity,
      color: primaryColor.withValues(alpha: 0.12),
      child: Center(
        child: Icon(icon, size: 64, color: primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final String priceStr = currencyFormatter.format(appliance.customerPrice);
    final String? origPriceStr = appliance.originalPrice != null
        ? currencyFormatter.format(appliance.originalPrice)
        : null;

    int? discountPercent;
    if (appliance.originalPrice != null && appliance.originalPrice! > appliance.customerPrice) {
      discountPercent =
          (((appliance.originalPrice! - appliance.customerPrice) / appliance.originalPrice!) * 100)
              .round();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appliance Image Banner
          Stack(
            children: [
              _buildApplianceImage(context),

              // Condition Badge (Top Left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: AppColors.accent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        appliance.condition,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Warranty Tag (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    appliance.warrantyPeriod,
                    style: const TextStyle(
                      color: AppColors.text, // Charcoal on Marigold for high contrast accessibility
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Brand Chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Refurbished',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        appliance.brand,
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (discountPercent != null && discountPercent > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  appliance.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  appliance.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedTextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Price and Call Retailer Button Row
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priceStr,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        if (origPriceStr != null)
                          Text(
                            'MRP $origPriceStr',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedTextColor.withValues(alpha: 0.7),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(context, appliance.retailerPhone),
                      icon: const Icon(Icons.phone_in_talk, size: 18),
                      label: const Text('CALL RETAILER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.text, // Charcoal on Marigold for high contrast accessibility
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
