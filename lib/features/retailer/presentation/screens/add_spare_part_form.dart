import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/refurbished_store_provider.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/image_picker_widget.dart';
import '../../controller/retailer_controller.dart';
import '../../models/refurbished_appliance_model.dart';
import '../../models/spare_part_model.dart';

/// Interactive "Add Item" Tab Container featuring two distinct windows:
/// Window 1: Add Spare Part Form (Dual Pricing & Stock)
/// Window 2: Add Refurbished Appliance Form (Certified Pre-Owned & Warranty)
class AddSparePartForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccessNavigateToInventory;
  final VoidCallback onSuccessNavigateToRefurbished;

  const AddSparePartForm({
    super.key,
    required this.onSuccessNavigateToInventory,
    required this.onSuccessNavigateToRefurbished,
  });

  @override
  ConsumerState<AddSparePartForm> createState() => _AddSparePartFormState();
}

class _AddSparePartFormState extends ConsumerState<AddSparePartForm> {
  int _activeFormWindow = 0; // 0 = Spare Part Form, 1 = Refurbished Appliance Form

  // Form Keys
  final _sparePartFormKey = GlobalKey<FormState>();
  final _refurbishedFormKey = GlobalKey<FormState>();

  // --- Spare Part Controllers ---
  final _partNameController = TextEditingController();
  final _custPriceController = TextEditingController();
  final _techPriceController = TextEditingController();
  final _stockQtyController = TextEditingController(text: '25');
  final _partNumberController = TextEditingController();
  String? _partImageUrl;

  String _selectedPartCategory = 'AC';
  String _selectedPartBrand = 'Universal / Multi-Brand';
  bool _partInStock = true;
  bool _isSubmittingPart = false;

  // --- Refurbished Appliance Controllers ---
  final _refTitleController = TextEditingController();
  final _refCustPriceController = TextEditingController();
  final _refOrigPriceController = TextEditingController();
  final _refDescController = TextEditingController();
  final _refPhoneController = TextEditingController(text: '+919876543210');
  String? _refImageUrl;

  String _selectedRefCategory = 'AC';
  String _selectedRefBrand = 'LG';
  String _selectedCondition = 'Certified Refurbished';
  String _selectedWarranty = '6 Months Shop Warranty';
  final bool _refInStock = true;
  bool _isSubmittingRefurbished = false;

  // Category & Brand Lists
  final List<String> _categories = const [
    'AC',
    'Refrigerator',
    'Washing Machine',
    'TV',
    'Water Purifier',
    'Microwave',
    'Air Cooler',
    'Inverter',
    'Geyser',
    'Chimney',
    'Car AC',
  ];

  final List<String> _brands = const [
    'Universal / Multi-Brand',
    'Samsung',
    'LG',
    'Godrej',
    'Whirlpool',
    'Haier',
    'Voltas',
    'Blue Star',
    'Panasonic',
    'IFB',
    'Bosch',
  ];

  final List<String> _conditions = const [
    'Certified Refurbished',
    'Like New (Grade A)',
    'Good Condition (Grade B)',
    'Refurbished with Warranty',
  ];

  final List<String> _warranties = const [
    '3 Months Shop Warranty',
    '6 Months Shop Warranty',
    '1 Year Shop Warranty',
    '30 Days Testing Warranty',
  ];

  @override
  void initState() {
    super.initState();
    _custPriceController.addListener(_updateState);
    _techPriceController.addListener(_updateState);
    _refCustPriceController.addListener(_updateState);
    _refOrigPriceController.addListener(_updateState);
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _custPriceController.dispose();
    _techPriceController.dispose();
    _stockQtyController.dispose();
    _partNumberController.dispose();

    _refTitleController.dispose();
    _refCustPriceController.dispose();
    _refOrigPriceController.dispose();
    _refDescController.dispose();
    _refPhoneController.dispose();
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  // --- Spare Part Calculations ---
  double get _partCustPrice => double.tryParse(_custPriceController.text.trim()) ?? 0.0;
  double get _partTechPrice => double.tryParse(_techPriceController.text.trim()) ?? 0.0;
  double get _partMargin => _partCustPrice - _partTechPrice;
  double get _partDiscountPct =>
      _partCustPrice > 0 ? ((_partMargin / _partCustPrice) * 100).clamp(0, 100) : 0.0;

  // --- Refurbished Calculations ---
  double get _refCustPrice => double.tryParse(_refCustPriceController.text.trim()) ?? 0.0;
  double get _refOrigPrice => double.tryParse(_refOrigPriceController.text.trim()) ?? 0.0;
  double get _refSavings => _refOrigPrice > _refCustPrice ? (_refOrigPrice - _refCustPrice) : 0.0;
  double get _refSavingsPct =>
      _refOrigPrice > 0 ? ((_refSavings / _refOrigPrice) * 100).clamp(0, 100) : 0.0;

  String _getDefaultImage(String category) {
    switch (category) {
      case 'AC':
      case 'Car AC':
        return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80';
      case 'Refrigerator':
        return 'https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?auto=format&fit=crop&w=600&q=80';
      case 'Washing Machine':
        return 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?auto=format&fit=crop&w=600&q=80';
      case 'TV':
        return 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?auto=format&fit=crop&w=600&q=80';
      case 'Water Purifier':
        return 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&w=600&q=80';
      default:
        return 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=600&q=80';
    }
  }

  // --- Submit Spare Part ---
  Future<void> _submitSparePart() async {
    if (!_sparePartFormKey.currentState!.validate()) return;

    if (_partTechPrice > _partCustPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Technician wholesale price cannot exceed retail price.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmittingPart = true);

    try {
      final user = supabase.auth.currentUser;
      final retailerId = user?.id ?? 'guest_retailer_001';
      final newId = const Uuid().v4();

      final finalImageUrl = (_partImageUrl != null && _partImageUrl!.isNotEmpty)
          ? _partImageUrl!
          : _getDefaultImage(_selectedPartCategory);

      final newPart = SparePart(
        id: newId,
        retailerId: retailerId,
        partName: _partNameController.text.trim(),
        category: _selectedPartCategory,
        brand: _selectedPartBrand,
        customerPrice: _partCustPrice,
        technicianPrice: _partTechPrice,
        inStock: _partInStock,
        stockStatus: _partInStock ? 'In Stock' : 'Out of Stock',
        imageUrl: finalImageUrl,
        createdAt: DateTime.now(),
      );

      try {
        await supabase.from('spare_parts').insert({
          'id': newId,
          'retailer_id': retailerId,
          'part_name': newPart.partName,
          'category': newPart.category,
          'brand': newPart.brand,
          'customer_price': newPart.customerPrice,
          'technician_price': newPart.technicianPrice,
          'in_stock': newPart.inStock,
          'stock_status': newPart.stockStatus,
          'image_url': newPart.imageUrl,
          'stock_quantity': int.tryParse(_stockQtyController.text.trim()) ?? 0,
          'part_number': _partNumberController.text.trim(),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }).timeout(const Duration(seconds: 2));
      } catch (_) {}

      ref.read(retailerControllerProvider.notifier).addPart(newPart);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newPart.partName} listed in Spare Parts Inventory!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _partNameController.clear();
      _custPriceController.clear();
      _techPriceController.clear();

      widget.onSuccessNavigateToInventory();
    } finally {
      if (mounted) setState(() => _isSubmittingPart = false);
    }
  }

  // --- Submit Refurbished Appliance ---
  Future<void> _submitRefurbishedAppliance() async {
    if (!_refurbishedFormKey.currentState!.validate()) return;

    setState(() => _isSubmittingRefurbished = true);

    try {
      final user = supabase.auth.currentUser;
      final retailerId = user?.id ?? 'guest_retailer_001';
      final newId = const Uuid().v4();

      final finalImageUrl = (_refImageUrl != null && _refImageUrl!.isNotEmpty)
          ? _refImageUrl!
          : _getDefaultImage(_selectedRefCategory);

      final newAppliance = RefurbishedAppliance(
        id: newId,
        retailerId: retailerId,
        title: _refTitleController.text.trim(),
        category: _selectedRefCategory,
        brand: _selectedRefBrand,
        condition: _selectedCondition,
        warrantyPeriod: _selectedWarranty,
        customerPrice: _refCustPrice,
        originalPrice: _refOrigPrice > 0 ? _refOrigPrice : null,
        imageUrl: finalImageUrl,
        description: _refDescController.text.trim().isNotEmpty
            ? _refDescController.text.trim()
            : 'Tested and certified refurbished appliance with shop warranty.',
        inStock: _refInStock,
        retailerPhone: _refPhoneController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref
          .read(refurbishedStoreProvider.notifier)
          .addOrUpdateAppliance(newAppliance);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newAppliance.title} listed in Refurbished Marketplace!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _refTitleController.clear();
      _refCustPriceController.clear();
      _refOrigPriceController.clear();
      _refDescController.clear();

      widget.onSuccessNavigateToRefurbished();
    } finally {
      if (mounted) setState(() => _isSubmittingRefurbished = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 110;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            children: [
              // Dual Window Selector Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeFormWindow = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeFormWindow == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeFormWindow == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.build_circle_outlined,
                                size: 18,
                                color: _activeFormWindow == 0 ? primaryColor : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Spare Part Form',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _activeFormWindow == 0 ? primaryColor : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeFormWindow = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeFormWindow == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeFormWindow == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                size: 18,
                                color: _activeFormWindow == 1 ? primaryColor : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Refurbished Form',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _activeFormWindow == 1 ? primaryColor : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Form Window
              AnimatedCrossFade(
                firstChild: _buildSparePartWindow(primaryColor),
                secondChild: _buildRefurbishedWindow(primaryColor),
                crossFadeState: _activeFormWindow == 0
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WINDOW 1: Spare Part Form ---
  Widget _buildSparePartWindow(Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _sparePartFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.inventory_2_rounded, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'List New Spare Part Component',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'List dual-priced component for retail & wholesale',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 28),

              TextFormField(
                controller: _partNameController,
                decoration: InputDecoration(
                  labelText: 'Part Name *',
                  hintText: 'e.g. 1.5 Ton AC Capacitor 36 MFD',
                  prefixIcon: const Icon(Icons.build_circle_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter part name' : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _selectedPartCategory,
                decoration: InputDecoration(
                  labelText: 'Appliance Category *',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPartCategory = val);
                },
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _selectedPartBrand,
                decoration: InputDecoration(
                  labelText: 'Brand Compatibility *',
                  prefixIcon: const Icon(Icons.branding_watermark_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPartBrand = val);
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _custPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Retail Price (₹) *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter price';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Enter a valid positive price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _techPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Wholesale Rate (₹) *',
                        prefixIcon: const Icon(Icons.engineering_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter rate';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Enter a valid positive price';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_partCustPrice > 0 && _partTechPrice > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _partMargin >= 0 ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _partMargin >= 0 ? Colors.green.shade300 : Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          color: _partMargin >= 0 ? Colors.green.shade800 : Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Technician Trade Margin: ₹${_partMargin.toStringAsFixed(0)} (${_partDiscountPct.toStringAsFixed(1)}% Off Retail)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _partMargin >= 0 ? Colors.green.shade900 : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockQtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stock Units',
                        prefixIcon: const Icon(Icons.inventory_sharp),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _partNumberController,
                      decoration: InputDecoration(
                        labelText: 'Part Code',
                        hintText: 'e.g. C-36MFD',
                        prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('In Stock & Ready to Ship', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                value: _partInStock,
                activeThumbColor: primaryColor,
                onChanged: (val) => setState(() => _partInStock = val),
              ),
              const SizedBox(height: 12),

              const Text(
                'Product Image (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              ImagePickerWidget(
                onImageSelected: (url) {
                  setState(() => _partImageUrl = url);
                },
                initialImageUrl: _partImageUrl,
                hint: 'Add spare part photo from gallery',
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmittingPart ? null : _submitSparePart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSubmittingPart
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.publish_rounded),
                  label: const Text('LIST SPARE PART IN MARKETPLACE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WINDOW 2: Refurbished Appliance Form ---
  Widget _buildRefurbishedWindow(Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _refurbishedFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_outlined, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'List Refurbished Appliance',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'List tested & certified pre-owned unit with shop warranty',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 28),

              TextFormField(
                controller: _refTitleController,
                decoration: InputDecoration(
                  labelText: 'Appliance Title *',
                  hintText: 'e.g. LG 260L Double Door Refrigerator',
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter appliance title' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedRefCategory,
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRefCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedRefBrand,
                      decoration: InputDecoration(
                        labelText: 'Brand *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRefBrand = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCondition,
                      decoration: InputDecoration(
                        labelText: 'Condition Grade *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCondition = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedWarranty,
                      decoration: InputDecoration(
                        labelText: 'Warranty Period *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _warranties.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedWarranty = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _refCustPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Selling Price (₹) *',
                        prefixIcon: const Icon(Icons.sell_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter selling price';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Enter a valid positive price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _refOrigPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Original MRP (₹)',
                        prefixIcon: const Icon(Icons.money_off_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_refOrigPrice > _refCustPrice && _refCustPrice > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.discount_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Buyer Savings: ₹${_refSavings.toStringAsFixed(0)} (${_refSavingsPct.toStringAsFixed(0)}% OFF original MRP)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _refDescController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Servicing & Inspection Notes',
                  hintText: 'e.g. New compressor relay fitted, gas refilled R32, tested 48 hours.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _refPhoneController,
                decoration: InputDecoration(
                  labelText: 'Retailer Inquiry Phone',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Appliance Image (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              ImagePickerWidget(
                onImageSelected: (url) {
                  setState(() => _refImageUrl = url);
                },
                initialImageUrl: _refImageUrl,
                hint: 'Add appliance photo from gallery',
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmittingRefurbished ? null : _submitRefurbishedAppliance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSubmittingRefurbished
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.verified_rounded),
                  label: const Text('LIST REFURBISHED ITEM IN MARKETPLACE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
