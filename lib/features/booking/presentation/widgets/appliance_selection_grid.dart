import 'package:flutter/material.dart';
import '../../../../core/constants/appliance_categories.dart';
import 'appliance_card.dart';

/// Responsive Grid layout for appliance category selection with dynamic search filter.
class ApplianceSelectionGrid extends StatefulWidget {
  final String? selectedCategoryTitle;
  final ValueChanged<ApplianceCategory> onSelectAppliance;

  const ApplianceSelectionGrid({
    super.key,
    required this.selectedCategoryTitle,
    required this.onSelectAppliance,
  });

  @override
  State<ApplianceSelectionGrid> createState() => _ApplianceSelectionGridState();
}

class _ApplianceSelectionGridState extends State<ApplianceSelectionGrid> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = applianceCategories.where((category) {
      if (_searchQuery.isEmpty) return true;
      return category.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Modular Search Bar
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search appliance (e.g. AC, TV, Fridge)...',
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.deepOrange),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
              ),
            ),
          ),
        ),

        // Grid View
        Expanded(
          child: filteredCategories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No appliances found for "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive Column Count
                    int crossAxisCount = 2; // Phone default
                    if (constraints.maxWidth >= 900) {
                      crossAxisCount = 4; // Large tablet/desktop
                    } else if (constraints.maxWidth >= 600) {
                      crossAxisCount = 3; // Small tablet
                    }

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.82,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        final isSelected = widget.selectedCategoryTitle == category.title;

                        return Semantics(
                          label: '${category.title}, Base Inspection Fee ₹${category.baseInspectionFee}',
                          button: true,
                          selected: isSelected,
                          child: ApplianceCard(
                            category: category,
                            isSelected: isSelected,
                            onTap: () => widget.onSelectAppliance(category),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
