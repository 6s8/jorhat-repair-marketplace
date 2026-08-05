import 'package:flutter/material.dart';
import '../../../../core/constants/appliance_brands.dart';
import 'brand_chip.dart';

/// Responsive brand selection grid with a custom brand text field that
/// animates in/out when "Others" is chosen.
///
/// This widget is purely presentational — it receives the current selection
/// and fires callbacks so the parent/controller can update Riverpod state.
class BrandSelectionSection extends StatelessWidget {
  final String? selectedBrand;
  final TextEditingController customBrandController;
  final TextEditingController modelController;
  final ValueChanged<String> onBrandSelected;
  final ValueChanged<String> onCustomBrandChanged;
  final ValueChanged<String> onModelChanged;
  final String? customBrandError;

  const BrandSelectionSection({
    super.key,
    required this.selectedBrand,
    required this.customBrandController,
    required this.modelController,
    required this.onBrandSelected,
    required this.onCustomBrandChanged,
    required this.onModelChanged,
    this.customBrandError,
  });

  bool get _isOthers => selectedBrand == 'Others';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Brand Grid ─────────────────────────────────────────────────────
        _BrandGrid(
          selectedBrand: selectedBrand,
          onBrandSelected: onBrandSelected,
        ),

        // ── Custom Brand Field (animated, only shown for "Others") ─────────
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: _isOthers
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _CustomBrandField(
                    controller: customBrandController,
                    onChanged: onCustomBrandChanged,
                    errorText: customBrandError,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // ── Model Number Field ─────────────────────────────────────────────
        const SizedBox(height: 4),
        _ModelNumberField(
          controller: modelController,
          onChanged: onModelChanged,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal: Responsive Brand Grid
// ─────────────────────────────────────────────────────────────────────────────

class _BrandGrid extends StatelessWidget {
  final String? selectedBrand;
  final ValueChanged<String> onBrandSelected;

  const _BrandGrid({
    required this.selectedBrand,
    required this.onBrandSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 3 cols on phone, 4 on tablet
        final crossCount = constraints.maxWidth >= 600 ? 4 : 3;

        return GridView.builder(
          // Non-scrollable when embedded in a SingleChildScrollView
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: 1.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 6,
          ),
          itemCount: applianceBrands.length,
          itemBuilder: (context, index) {
            final brand = applianceBrands[index];
            return BrandChip(
              brand: brand,
              isSelected: selectedBrand == brand,
              onTap: () => onBrandSelected(brand),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal: Custom Brand Text Field
// ─────────────────────────────────────────────────────────────────────────────

class _CustomBrandField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const _CustomBrandField({
    required this.controller,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: 50,
      textCapitalization: TextCapitalization.words,
      onChanged: onChanged,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter your brand name';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Custom Brand Name *',
        hintText: 'e.g. Lloyd, Bosch, Sansui',
        prefixIcon: const Icon(
          Icons.edit_note_rounded,
          color: Colors.deepOrange,
        ),
        errorText: errorText,
        filled: true,
        fillColor: Colors.deepOrange.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.deepOrange.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal: Model Number Field
// ─────────────────────────────────────────────────────────────────────────────

class _ModelNumberField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _ModelNumberField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 16, color: Colors.blueGrey),
            const SizedBox(width: 6),
            Text(
              'Model Number helps technicians bring exact spare parts',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        TextFormField(
          controller: controller,
          maxLength: 50,
          enableIMEPersonalizedLearning: false,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: onChanged,
          // Allow alphanumeric + common separators; no over-restriction
          inputFormatters: const [],
          decoration: InputDecoration(
            labelText: 'Model Number',
            hintText: 'e.g. RT28T3022S8 (Optional)',
            prefixIcon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.deepOrange,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            counterStyle: const TextStyle(fontSize: 11),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
