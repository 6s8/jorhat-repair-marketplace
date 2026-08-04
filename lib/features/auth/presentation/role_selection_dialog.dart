import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Role Selection Component for Onboarding or Role Switch.
class RoleSelectionWidget extends StatefulWidget {
  final String? initialRole;
  final ValueChanged<String> onRoleSelected;

  const RoleSelectionWidget({
    super.key,
    this.initialRole,
    required this.onRoleSelected,
  });

  @override
  State<RoleSelectionWidget> createState() => _RoleSelectionWidgetState();
}

class _RoleSelectionWidgetState extends State<RoleSelectionWidget> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole?.toLowerCase() ?? 'customer';
  }

  void _select(String role) {
    setState(() => _selectedRole = role);
    widget.onRoleSelected(role);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoleCard(
          roleKey: 'customer',
          title: 'Customer',
          subtitle: 'Book repair experts, buy spare parts, & track service jobs',
          icon: Icons.shopping_bag_outlined,
          emoji: '🛒',
          isSelected: _selectedRole == 'customer',
          onTap: () => _select('customer'),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          roleKey: 'technician',
          title: 'Technician',
          subtitle: 'Accept repair requests in Jorhat, order wholesale parts, & earn',
          icon: Icons.build_outlined,
          emoji: '🛠',
          isSelected: _selectedRole == 'technician',
          onTap: () => _select('technician'),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          roleKey: 'retailer',
          title: 'Retailer',
          subtitle: 'Sell spare parts to technicians & customers, & manage inventory',
          icon: Icons.storefront_outlined,
          emoji: '🏪',
          isSelected: _selectedRole == 'retailer',
          onTap: () => _select('retailer'),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String roleKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.roleKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? primary : Colors.grey.shade300,
          width: isSelected ? 2.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? primary.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 12 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? primary : AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Selected',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? primary : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
