import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controller/booking_controller.dart';
import '../widgets/brand_selection_section.dart';

/// Step 2 of the Customer Booking Flow — Brand & Model Selection.
class CustomerBrandModelPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CustomerBrandModelPage({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<CustomerBrandModelPage> createState() =>
      _CustomerBrandModelPageState();
}

class _CustomerBrandModelPageState
    extends ConsumerState<CustomerBrandModelPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _customBrandController;
  late TextEditingController _modelController;

  String? _customBrandError;

  @override
  void initState() {
    super.initState();
    final s = ref.read(bookingControllerProvider);
    _customBrandController = TextEditingController(text: s.customBrand);
    _modelController = TextEditingController(text: s.applianceModel);
  }

  @override
  void dispose() {
    _customBrandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final state = ref.read(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);

    controller.setModelNumber(_modelController.text.trim());

    if (state.applianceBrand == 'Others') {
      final custom = _customBrandController.text.trim();
      if (custom.isEmpty) {
        setState(() => _customBrandError = 'Please enter your brand name');
        return;
      }
      setState(() => _customBrandError = null);
      controller.setCustomBrand(custom);
    }

    if (_formKey.currentState!.validate()) {
      widget.onNext();
    }
  }

  void _onBrandSelected(String brand) {
    ref.read(bookingControllerProvider.notifier).selectBrand(brand);
    if (brand != 'Others' && _customBrandError != null) {
      setState(() => _customBrandError = null);
    }
    if (brand != 'Others') {
      _customBrandController.clear();
      ref.read(bookingControllerProvider.notifier).setCustomBrand('');
    }
  }

  void _onCustomBrandChanged(String text) {
    ref.read(bookingControllerProvider.notifier).setCustomBrand(text);
    if (text.trim().isNotEmpty && _customBrandError != null) {
      setState(() => _customBrandError = null);
    }
  }

  void _onModelChanged(String text) {
    ref.read(bookingControllerProvider.notifier).setModelNumber(text);
  }

  @override
  Widget build(BuildContext context) {
    final selectedBrand =
        ref.watch(bookingControllerProvider.select((s) => s.applianceBrand));
    final selectedCategory = ref
        .watch(bookingControllerProvider.select((s) => s.selectedCategory));
    final baseInspectionFee = ref
        .watch(bookingControllerProvider.select((s) => s.baseInspectionFee));
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isBrandSelected =
        selectedBrand != null && selectedBrand.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), // Bottom padding set to 100px for floating navbar clearance
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              onBack: widget.onBack,
              selectedCategory: selectedCategory ?? 'Appliance',
              inspectionFee: baseInspectionFee,
            ),
            const SizedBox(height: 6),

            const _SectionLabel(
              icon: Icons.branding_watermark_outlined,
              title: 'Select Appliance Brand',
              required: true,
            ),
            const SizedBox(height: 4),

            BrandSelectionSection(
              selectedBrand: selectedBrand,
              customBrandController: _customBrandController,
              modelController: _modelController,
              onBrandSelected: _onBrandSelected,
              onCustomBrandChanged: _onCustomBrandChanged,
              onModelChanged: _onModelChanged,
              customBrandError: _customBrandError,
            ),

            if (!isBrandSelected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Tap a brand above to continue',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text(
                        'Back',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton.icon(
                        key: ValueKey(isBrandSelected),
                        onPressed: isBrandSelected ? _handleNext : null,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(
                          'Continue to Issue',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.text,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String selectedCategory;
  final int inspectionFee;

  const _StepHeader({
    required this.onBack,
    required this.selectedCategory,
    required this.inspectionFee,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_rounded, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Step 2 of 5 — Brand & Model',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Brand & Model Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: primaryColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Category: ',
                        style: TextStyle(color: mutedTextColor),
                      ),
                      TextSpan(
                        text: selectedCategory,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹$inspectionFee',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool required;

  const _SectionLabel({
    required this.icon,
    required this.title,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}
