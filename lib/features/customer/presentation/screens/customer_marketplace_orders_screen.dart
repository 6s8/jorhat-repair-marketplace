import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';

/// Displays all marketplace orders (spare parts + appliances) placed by the customer
/// with a live status timeline.
class CustomerMarketplaceOrdersScreen extends StatefulWidget {
  const CustomerMarketplaceOrdersScreen({super.key});

  @override
  State<CustomerMarketplaceOrdersScreen> createState() =>
      _CustomerMarketplaceOrdersScreenState();
}

class _CustomerMarketplaceOrdersScreenState
    extends State<CustomerMarketplaceOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _spareOrders = [];
  List<Map<String, dynamic>> _applianceOrders = [];
  bool _isLoading = true;

  RealtimeChannel? _spareChannel;
  RealtimeChannel? _applianceChannel;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
    _subscribeRealtime();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _fetchSpareOrders();
        _fetchApplianceOrders();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    _spareChannel?.unsubscribe();
    _applianceChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await Future.wait([_fetchSpareOrders(), _fetchApplianceOrders()]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSpareOrders() async {
    try {
      final data = await supabase
          .from('spare_part_orders')
          .select()
          .order('created_at', ascending: false);
      if (mounted && data is List) {
        setState(() => _spareOrders =
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {}
  }

  Future<void> _fetchApplianceOrders() async {
    try {
      final data = await supabase
          .from('appliance_orders')
          .select()
          .order('created_at', ascending: false);
      if (mounted && data is List) {
        setState(() => _applianceOrders =
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {}
  }

  void _subscribeRealtime() {
    _spareChannel = supabase
        .channel('customer-spare-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'spare_part_orders',
          callback: (_) { if (mounted) _fetchSpareOrders(); },
        )
        .subscribe();

    _applianceChannel = supabase
        .channel('customer-appliance-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appliance_orders',
          callback: (_) { if (mounted) _fetchApplianceOrders(); },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.build_circle_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('Spare Parts'),
                  if (_spareOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(_spareOrders.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.kitchen_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Appliances'),
                  if (_applianceOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(_applianceOrders.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSpareOrdersList(),
                _buildApplianceOrdersList(),
              ],
            ),
    );
  }

  Widget _buildSpareOrdersList() {
    if (_spareOrders.isEmpty) {
      return _EmptyOrders(
        icon: Icons.build_circle_outlined,
        message: 'No spare part orders yet.',
        subtitle: 'Order parts from the Marketplace.',
      );
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _fetchSpareOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _spareOrders.length,
        itemBuilder: (_, i) => _SpareOrderCard(order: _spareOrders[i]),
      ),
    );
  }

  Widget _buildApplianceOrdersList() {
    if (_applianceOrders.isEmpty) {
      return _EmptyOrders(
        icon: Icons.kitchen_outlined,
        message: 'No appliance orders yet.',
        subtitle: 'Browse refurbished appliances in the Marketplace.',
      );
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _fetchApplianceOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _applianceOrders.length,
        itemBuilder: (_, i) => _ApplianceOrderCard(order: _applianceOrders[i]),
      ),
    );
  }
}

// ─── Shared Status Timeline ────────────────────────────────────────────────

const _spareStages = ['pending', 'in_progress', 'ready_for_pickup', 'completed'];
const _stageLabels = {
  'pending': 'Order Placed',
  'in_progress': 'Being Prepared',
  'ready_for_pickup': 'Ready for Pickup',
  'completed': 'Delivered',
};
const _stageIcons = {
  'pending': Icons.receipt_long_rounded,
  'in_progress': Icons.handyman_rounded,
  'ready_for_pickup': Icons.local_shipping_rounded,
  'completed': Icons.check_circle_rounded,
};

int _getStageIndex(String rawStatus) {
  final s = rawStatus.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');
  if (s == 'completed' || s == 'delivered' || s == 'done' || s == 'fulfilled') return 3;
  if (s == 'ready_for_pickup' || s == 'ready' || s == 'shipped' || s == 'out_for_delivery' || s == 'on_the_way') return 2;
  if (s == 'in_progress' || s == 'processing' || s == 'preparing' || s == 'accepted' || s == 'confirmed') return 1;
  return 0; // pending / order placed
}

class _OrderTimeline extends StatelessWidget {
  final String currentStatus;
  final Color activeColor;

  const _OrderTimeline({
    required this.currentStatus,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final currentIdx = _getStageIndex(currentStatus);

    return Column(
      children: List.generate(_spareStages.length, (i) {
        final stage = _spareStages[i];
        final isDone = i <= currentIdx;
        final isActive = i == currentIdx;
        final isLast = i == _spareStages.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line + dot
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? (isActive ? activeColor : activeColor.withValues(alpha: 0.6))
                        : Colors.grey.shade200,
                    border: isActive
                        ? Border.all(color: activeColor, width: 2.5)
                        : null,
                  ),
                  child: Icon(
                    _stageIcons[stage] ?? Icons.circle,
                    size: 16,
                    color: isDone ? Colors.white : Colors.grey.shade400,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: isDone && i < currentIdx
                        ? activeColor.withValues(alpha: 0.4)
                        : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stageLabels[stage] ?? stage,
                      style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                        color: isDone
                            ? (isActive
                                ? activeColor
                                : Colors.grey.shade700)
                            : Colors.grey.shade400,
                      ),
                    ),
                    if (isActive)
                      Text(
                        stage == 'pending'
                            ? 'Retailer is reviewing your order'
                            : stage == 'in_progress'
                                ? 'Your order is being prepared'
                                : stage == 'ready_for_pickup'
                                    ? 'Ready! Contact retailer to pick up'
                                    : 'Order completed successfully',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Spare Part Order Card ──────────────────────────────────────────────────

class _SpareOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  const _SpareOrderCard({required this.order});

  @override
  State<_SpareOrderCard> createState() => _SpareOrderCardState();
}

class _SpareOrderCardState extends State<_SpareOrderCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order['status']?.toString() ?? 'pending';
    final partName = order['part_name']?.toString() ?? 'Spare Part';
    final quantity = order['quantity']?.toString() ?? '1';
    final total = (order['total_amount'] as num?)?.toStringAsFixed(0) ?? '0';
    final orderId = order['id']?.toString() ?? '';
    final shortId = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.build_circle_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Order #$shortId',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      _StatusChip(status: status, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoPill(Icons.shopping_bag_outlined, 'Qty: $quantity'),
                      const SizedBox(width: 8),
                      _InfoPill(Icons.currency_rupee_rounded, '₹$total'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _expanded ? 'Hide Timeline' : 'View Timeline',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: _OrderTimeline(
                  currentStatus: status, activeColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Appliance Order Card ──────────────────────────────────────────────────

class _ApplianceOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  const _ApplianceOrderCard({required this.order});

  @override
  State<_ApplianceOrderCard> createState() => _ApplianceOrderCardState();
}

class _ApplianceOrderCardState extends State<_ApplianceOrderCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order['status']?.toString() ?? 'pending';
    final title = order['appliance_title']?.toString() ?? 'Appliance';
    final category = order['appliance_category']?.toString() ?? '';
    final brand = order['brand']?.toString() ?? '';
    final total = (order['total_amount'] as num?)?.toStringAsFixed(0) ?? '0';
    final orderId = order['id']?.toString() ?? '';
    final shortId = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.kitchen_rounded,
                            color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              [if (category.isNotEmpty) category, if (brand.isNotEmpty) brand].join(' • '),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            Text('Order #$shortId',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                      _StatusChip(status: status, color: AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoPill(Icons.currency_rupee_rounded, '₹$total'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _expanded ? 'Hide Timeline' : 'View Timeline',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: _OrderTimeline(
                  currentStatus: status, activeColor: AppColors.accent),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = {
      'pending': 'Pending',
      'in_progress': 'Preparing',
      'ready_for_pickup': 'Ready',
      'completed': 'Done',
      'cancelled': 'Cancelled',
    }[status] ?? status.toUpperCase();

    final chipColor = status == 'completed'
        ? Colors.green
        : status == 'cancelled'
            ? Colors.red
            : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: chipColor,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  const _EmptyOrders(
      {required this.icon, required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
