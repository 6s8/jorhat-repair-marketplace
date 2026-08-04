import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/modern_floating_nav_bar.dart';
import '../../../../core/providers/refurbished_store_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controller/retailer_controller.dart';
import '../../controller/retailer_orders_controller.dart';
import '../../models/refurbished_appliance_model.dart';
import '../../models/spare_part_model.dart';
import '../../models/retailer_order_model.dart';
import '../../../auth/controllers/auth_controller.dart';
import 'add_spare_part_form.dart';
import 'retailer_profile_dashboard_tab.dart';

class RetailerDashboardScreen extends ConsumerStatefulWidget {
  const RetailerDashboardScreen({super.key});

  @override
  ConsumerState<RetailerDashboardScreen> createState() =>
      _RetailerDashboardScreenState();
}

class _RetailerDashboardScreenState
    extends ConsumerState<RetailerDashboardScreen> {
  int _selectedTab = 0; // 0 = Spare Parts, 1 = Refurbished, 2 = Orders, 3 = Store Profile
  final _formKey = GlobalKey<FormState>();
  final _refurbishedFormKey = GlobalKey<FormState>();

  final String _retailerId = 'guest_retailer_001';

  // Spare Part Form Controllers


  // Refurbished Appliance Form Controllers
  final _refTitleController = TextEditingController();
  final _refBrandController = TextEditingController();
  final _refCustPriceController = TextEditingController();
  final _refOrigPriceController = TextEditingController();
  final _refDescController = TextEditingController();
  final _refPhoneController = TextEditingController(text: '+919876543210');
  final _refImageUrlController = TextEditingController();

  String _selectedRefCategory = 'AC';
  String _selectedCondition = 'Certified Refurbished';
  String _selectedWarranty = '6 Months Shop Warranty';
  String _orderTypeFilter = 'All';

  final List<String> _categories = const [
    'AC',
    'Refrigerator',
    'Washing Machine',
    'Television',
    'Car AC',
    'Water Purifier',
    'Air Cooler',
    'Microwave',
    'Other'
  ];

  final List<String> _conditions = const [
    'Certified Refurbished',
    'Like New (Refurbished)',
    'Good Condition',
    'Factory Refurbished',
  ];

  final List<String> _warranties = const [
    '3 Months Shop Warranty',
    '6 Months Shop Warranty',
    '1 Year Shop Warranty',
    'No Warranty',
  ];

  @override
  void dispose() {


    _refTitleController.dispose();
    _refBrandController.dispose();
    _refCustPriceController.dispose();
    _refOrigPriceController.dispose();
    _refDescController.dispose();
    _refPhoneController.dispose();
    _refImageUrlController.dispose();
    super.dispose();
  }

  String _getDefaultImageForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('ac')) return 'assets/appliances/ac.png';
    if (cat.contains('fridge') || cat.contains('refrig')) return 'assets/appliances/refrigerator.png';
    if (cat.contains('wash')) return 'assets/appliances/washing_machine.png';
    if (cat.contains('tv') || cat.contains('telev')) return 'assets/appliances/television.png';
    if (cat.contains('water') || cat.contains('purif')) return 'assets/appliances/purifier.png';
    if (cat.contains('micro')) return 'assets/appliances/microwave.png';
    if (cat.contains('cool')) return 'assets/appliances/cooler.png';
    if (cat.contains('geys')) return 'assets/appliances/geyser.png';
    return 'assets/appliances/refrigerator.png';
  }



  void _submitRefurbishedForm() {
    if (_refurbishedFormKey.currentState!.validate()) {
      final customUrl = _refImageUrlController.text.trim();
      final finalImg = customUrl.isNotEmpty
          ? customUrl
          : _getDefaultImageForCategory(_selectedRefCategory);

      final item = RefurbishedAppliance(
        id: const Uuid().v4(),
        retailerId: _retailerId,
        title: _refTitleController.text.trim(),
        category: _selectedRefCategory,
        brand: _refBrandController.text.trim().isEmpty
            ? 'Generic'
            : _refBrandController.text.trim(),
        condition: _selectedCondition,
        warrantyPeriod: _selectedWarranty,
        customerPrice: double.tryParse(_refCustPriceController.text.trim()) ?? 0.0,
        originalPrice: _refOrigPriceController.text.trim().isNotEmpty
            ? double.tryParse(_refOrigPriceController.text)
            : null,
        imageUrl: finalImg,
        description: _refDescController.text.trim().isEmpty
            ? 'Certified refurbished appliance in top working condition.'
            : _refDescController.text.trim(),
        retailerPhone: _refPhoneController.text.trim().isEmpty
            ? '+919876543210'
            : _refPhoneController.text.trim(),
        createdAt: DateTime.now(),
      );

      ref.read(refurbishedStoreProvider.notifier).addOrUpdateAppliance(item);
      _clearRefurbishedForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refurbished appliance listed with picture!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }



  void _clearRefurbishedForm() {
    _refTitleController.clear();
    _refBrandController.clear();
    _refCustPriceController.clear();
    _refOrigPriceController.clear();
    _refDescController.clear();
    _refImageUrlController.clear();
    setState(() {
      _selectedRefCategory = 'AC';
      _selectedCondition = 'Certified Refurbished';
      _selectedWarranty = '6 Months Shop Warranty';
    });
  }

  void _showEditDialog(SparePart part) {
    final editNameCtrl = TextEditingController(text: part.partName);
    final editBrandCtrl = TextEditingController(text: part.brand);
    final editImgCtrl = TextEditingController(text: part.imageUrl ?? '');
    final editCustPriceCtrl =
        TextEditingController(text: part.customerPrice.toString());
    final editTechPriceCtrl =
        TextEditingController(text: part.technicianPrice.toString());
    String editCategory = part.category;
    bool editInStock = part.inStock;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Listed Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editNameCtrl,
                    decoration: const InputDecoration(labelText: 'Part Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editBrandCtrl,
                    decoration: const InputDecoration(labelText: 'Brand'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: editCategory,
                    isExpanded: true,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => editCategory = val);
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editImgCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Image URL (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editCustPriceCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Customer Price (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editTechPriceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Technician Price (Wholesale ₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('In Stock'),
                    value: editInStock,
                    onChanged: (val) => setDialogState(() => editInStock = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final updatedPart = part.copyWith(
                    partName: editNameCtrl.text.trim(),
                    brand: editBrandCtrl.text.trim().isEmpty
                        ? 'Generic'
                        : editBrandCtrl.text.trim(),
                    imageUrl: editImgCtrl.text.trim().isEmpty
                        ? null
                        : editImgCtrl.text.trim(),
                    category: editCategory,
                    customerPrice: double.tryParse(editCustPriceCtrl.text) ??
                        part.customerPrice,
                    technicianPrice: double.tryParse(editTechPriceCtrl.text) ??
                        part.technicianPrice,
                    inStock: editInStock,
                    updatedAt: DateTime.now(),
                  );
                  ref
                      .read(retailerControllerProvider.notifier)
                      .updatePart(updatedPart);
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      editNameCtrl.dispose();
      editBrandCtrl.dispose();
      editImgCtrl.dispose();
      editCustPriceCtrl.dispose();
      editTechPriceCtrl.dispose();
    });
  }

  void _deletePart(String partId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Listed Item'),
        content: const Text('Are you sure you want to delete this listed item from the marketplace?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(retailerControllerProvider.notifier).deletePart(partId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _deleteRefurbishedItem(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Refurbished Item'),
        content: const Text('Are you sure you want to delete this pre-owned appliance?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(refurbishedStoreProvider.notifier).removeAppliance(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(retailerControllerProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Fixly Retailer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out Account',
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          // Tab 0: Spare Parts Inventory
          _buildListedItemsTab(state),

          // Tab 1: Refurbished Appliances
          _buildRefurbishedTab(),

          // Tab 2: Dedicated Add Item Form (Dual Windows)
          AddSparePartForm(
            onSuccessNavigateToInventory: () {
              setState(() => _selectedTab = 0);
            },
            onSuccessNavigateToRefurbished: () {
              setState(() => _selectedTab = 1);
            },
          ),

          // Tab 3: Orders & Fulfillment
          _buildOrdersTab(),

          // Tab 4: Store Profile & Dashboard
          const RetailerProfileDashboardTab(),
        ],
      ),
      bottomNavigationBar: ModernFloatingNavBar(
        currentIndex: _selectedTab,
        onTap: (idx) => setState(() => _selectedTab = idx),
        items: const [
          ModernNavItem(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2,
            label: 'Spare Parts',
          ),
          ModernNavItem(
            icon: Icons.verified_outlined,
            selectedIcon: Icons.verified,
            label: 'Refurbished',
          ),
          ModernNavItem(
            icon: Icons.add_circle_outline_rounded,
            selectedIcon: Icons.add_circle_rounded,
            label: 'Add Item',
          ),
          ModernNavItem(
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment_rounded,
            label: 'Orders',
          ),
          ModernNavItem(
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront,
            label: 'Store Profile',
          ),
        ],
      ),
    );
  }

  // Inventory List Tab
  Widget _buildListedItemsTab(RetailerState state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Inventory (${state.parts.length} Parts)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Text(
                      'Manage active stock levels & prices',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedTab = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(child: _buildListedItemsList(state)),
      ],
    );
  }


  Widget _buildListedItemsList(RetailerState state) {
    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (state.parts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No listed items found for this retailer.',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.parts.length,
      itemBuilder: (context, index) {
        final part = state.parts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1.5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.build_rounded, color: AppColors.primary),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    part.partName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        part.inStock ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    part.displayStockStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          part.inStock ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${part.category} • Brand: ${part.brand}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  'Customer Price: ₹${part.customerPrice.toStringAsFixed(0)} | Wholesale: ₹${part.technicianPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showEditDialog(part),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _deletePart(part.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Refurbished Appliances Tab
  Widget _buildRefurbishedTab() {
    final refurbishedItems = ref.watch(refurbishedStoreProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildRefurbishedFormCard()),
              Expanded(
                  flex: 2, child: _buildRefurbishedList(refurbishedItems)),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildRefurbishedFormCard(),
              SizedBox(
                  height: 460,
                  child: _buildRefurbishedList(refurbishedItems)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRefurbishedFormCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _refurbishedFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'List Refurbished Appliance with Picture',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _refTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Appliance Title (e.g. LG 260L Refrigerator)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _refBrandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand (e.g. LG, Samsung, IFB)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRefCategory,
                  isExpanded: true,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRefCategory = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCondition,
                  isExpanded: true,
                  items: _conditions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCondition = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Condition',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedWarranty,
                  isExpanded: true,
                  items: _warranties
                      .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWarranty = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Warranty Period',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _refImageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Appliance Image URL / Asset Path (optional)',
                    hintText: 'e.g. assets/appliances/refrigerator.png or http://...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _refCustPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (₹)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _refOrigPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Original MRP (₹)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _refDescController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description / Repair Details',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _refPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Store Direct Phone (For Customer Calls)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitRefurbishedForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.text,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('List Refurbished Appliance with Picture',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefurbishedList(List<RefurbishedAppliance> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No refurbished appliances listed yet.',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1.5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? (item.imageUrl!.startsWith('http')
                        ? Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.kitchen_rounded, color: AppColors.accent))
                        : Image.asset(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.kitchen_rounded, color: AppColors.accent)))
                    : const Icon(Icons.kitchen_rounded, color: AppColors.accent),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.condition,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${item.brand} • ${item.category} | ${item.warrantyPeriod}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Price: ₹${item.customerPrice.toStringAsFixed(0)} | Phone: ${item.retailerPhone}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _deleteRefurbishedItem(item.id),
            ),
          ),
        );
      },
    );
  }

  // Orders Tab
  Widget _buildOrdersTab() {
    final ordersAsync = ref.watch(retailerOrdersProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Filter: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All'),
                selected: _orderTypeFilter == 'All',
                onSelected: (_) => setState(() => _orderTypeFilter = 'All'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Customer Orders'),
                selected: _orderTypeFilter == 'Customer',
                onSelected: (_) =>
                    setState(() => _orderTypeFilter = 'Customer'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Technician Orders'),
                selected: _orderTypeFilter == 'Technician',
                onSelected: (_) =>
                    setState(() => _orderTypeFilter = 'Technician'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ordersAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
            error: (err, _) => Center(
              child: Text('Error loading orders: $err'),
            ),
            data: (allOrders) {
              final orders = allOrders.where((o) {
                if (_orderTypeFilter == 'Customer') {
                  return o.orderType.toLowerCase() == 'customer';
                }
                if (_orderTypeFilter == 'Technician') {
                  return o.orderType.toLowerCase() == 'technician';
                }
                return true;
              }).toList();

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No incoming orders found.',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(order);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(RetailerOrder order) {
    final isTech = order.orderType.toLowerCase() == 'technician';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTech
                        ? Colors.blue.shade50
                        : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTech
                          ? Colors.blue.shade200
                          : Colors.purple.shade200,
                    ),
                  ),
                  child: Text(
                    isTech ? 'TECHNICIAN ORDER' : 'CUSTOMER ORDER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isTech
                          ? Colors.blue.shade800
                          : Colors.purple.shade800,
                    ),
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.partName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Quantity: ${order.quantity}  •  Total Amount: ₹${order.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (order.deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Address: ${order.deliveryAddress}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.status == 'pending')
                  ElevatedButton(
                    onPressed: () => ref
                        .read(retailerOrderActionProvider.notifier)
                        .updateStatus(order.id, 'in_progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Start Preparing'),
                  ),
                if (order.status == 'in_progress')
                  ElevatedButton(
                    onPressed: () => ref
                        .read(retailerOrderActionProvider.notifier)
                        .updateStatus(order.id, 'ready_for_pickup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.text,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Ready for Pickup'),
                  ),
                if (order.status == 'ready_for_pickup' || order.status == 'in_progress') ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(retailerOrderActionProvider.notifier)
                        .updateStatus(order.id, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Complete Order'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.accent;
    String label = status.toUpperCase();

    if (status == 'completed') {
      color = AppColors.success;
      label = 'COMPLETED';
    } else if (status == 'in_progress') {
      color = Colors.blue;
      label = 'IN PROGRESS';
    } else if (status == 'ready_for_pickup') {
      color = AppColors.accent;
      label = 'READY FOR PICKUP';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
