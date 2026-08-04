import 'package:flutter/material.dart';

const List<String> applianceBrands = [
  'Samsung',
  'LG',
  'Godrej',
  'Whirlpool',
  'Haier',
  'Voltas',
  'Blue Star',
  'Panasonic',
  'IFB',
  'Others',
];

/// Reusable Material 3 Brand Dropdown widget for customer booking flow
class BrandDropdownField extends StatelessWidget {
  final String? selectedBrand;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const BrandDropdownField({
    super.key,
    required this.selectedBrand,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: (selectedBrand != null && applianceBrands.contains(selectedBrand))
          ? selectedBrand
          : null,
      decoration: InputDecoration(
        labelText: 'Select Brand',
        hintText: 'Choose your appliance brand',
        prefixIcon: const Icon(Icons.branding_watermark_rounded, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.teal),
      isExpanded: true,
      items: applianceBrands.map((brand) {
        return DropdownMenuItem<String>(
          value: brand,
          child: Text(
            brand,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator ??
          (val) {
            if (val == null || val.isEmpty) {
              return 'Please select a brand';
            }
            return null;
          },
    );
  }
}
