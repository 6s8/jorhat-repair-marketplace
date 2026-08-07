import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_progress_indicator.dart';
import '../../../customer/presentation/providers/customer_account_providers.dart';
import '../../controller/booking_controller.dart';
import 'map_picker_sheet.dart';

/// Step 4: Customer Contact & Location Address Page for Fixly.
class CustomerAddressPage extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onBack;

  const CustomerAddressPage({
    super.key,
    required this.onSuccess,
    required this.onBack,
  });

  @override
  ConsumerState<CustomerAddressPage> createState() => _CustomerAddressPageState();
}

class _CustomerAddressPageState extends ConsumerState<CustomerAddressPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _houseController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _areaController;
  late final TextEditingController _pinController;
  String _selectedCity = 'Jorhat';

  static const List<String> _assamCities = [
    'Guwahati', 'Jorhat', 'Dibrugarh', 'Silchar', 'Tezpur',
    'Tinsukia', 'Nagaon', 'Sivasagar', 'Bongaigaon', 'Goalpara',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(bookingControllerProvider);
    _nameController = TextEditingController(text: state.customerName);
    _phoneController = TextEditingController(text: state.customerPhone);
    _houseController = TextEditingController(text: state.house);
    _landmarkController = TextEditingController(text: state.landmark);
    _areaController = TextEditingController(text: state.area);
    _selectedCity = state.city.isNotEmpty ? state.city : 'Jorhat';
    _pinController = TextEditingController(text: state.pincode);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFieldChanged());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _landmarkController.dispose();
    _areaController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    ref.read(bookingControllerProvider.notifier).updateAddressFields(
          customerName: _nameController.text,
          customerPhone: _phoneController.text,
          house: _houseController.text,
          landmark: _landmarkController.text,
          area: _areaController.text,
          city: _selectedCity,
          stateName: 'Assam',
          pincode: _pinController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20.0,
        20.0,
        20.0,
        MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom + 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 4 of 5 — Address',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Address & Location',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your contact details and service address in Jorhat',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 16),

          // Saved Addresses Quick Selection
          Consumer(
            builder: (context, ref, _) {
              final savedAddresses = ref.watch(customerAddressesProvider);
              if (savedAddresses.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select from Saved Addresses:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: savedAddresses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final addr = savedAddresses[index];
                        return ActionChip(
                          avatar: Icon(
                            addr.label == 'Home'
                                ? Icons.home_rounded
                                : addr.label == 'Work'
                                    ? Icons.work_rounded
                                    : Icons.place_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            '${addr.label} (${addr.area})',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onPressed: () {
                            setState(() {
                              if (addr.name.isNotEmpty) _nameController.text = addr.name;
                              if (addr.phone.isNotEmpty) _phoneController.text = addr.phone;
                              _houseController.text = addr.house;
                              _landmarkController.text = addr.landmark;
                              _areaController.text = addr.area;
                              _pinController.text = addr.pincode;
                              _selectedCity = addr.city;
                            });
                            _onFieldChanged();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Selected address: ${addr.label} (${addr.name} - ${addr.phone})'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

          // Location Sharing Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isFetchingLocation
                      ? null
                      : () async {
                          await controller.getCurrentLocation();
                          if (!context.mounted) return;
                          final newState = ref.read(bookingControllerProvider);
                          setState(() {
                            if (newState.area.isNotEmpty) _areaController.text = newState.area;
                            if (newState.pincode.isNotEmpty) _pinController.text = newState.pincode;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newState.latitude != null
                                    ? 'GPS Location captured: ${newState.latitude!.toStringAsFixed(4)}° N, ${newState.longitude!.toStringAsFixed(4)}° E'
                                    : 'Could not acquire GPS signal. Defaulting to Jorhat.',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: state.isFetchingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: const Text(
                    'Use GPS Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isFetchingLocation
                      ? null
                      : () async {
                          final currentCenter = LatLng(
                            state.latitude ?? 26.7509,
                            state.longitude ?? 94.2037,
                          );
                          
                          final result = await MapPickerSheet.show(context, currentCenter);
                          
                          if (result != null) {
                            controller.updateLocationFromMap(result.latitude, result.longitude).then((_) {
                              if (mounted) {
                                setState(() {
                                  final newState = ref.read(bookingControllerProvider);
                                  if (newState.area.isNotEmpty) _areaController.text = newState.area;
                                  if (newState.pincode.isNotEmpty) _pinController.text = newState.pincode;
                                  if (newState.city.isNotEmpty) {
                                    _selectedCity = newState.city;
                                  }
                                });
                              }
                            });
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
                  label: Text(
                    state.latitude != null
                        ? 'Pin (${state.latitude!.toStringAsFixed(2)}°)'
                        : 'Pick on Map',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Customer Name & Phone
          TextField(
            controller: _nameController,
            onChanged: (_) => _onFieldChanged(),
            decoration: const InputDecoration(
              labelText: 'Customer Name *',
              prefixIcon: Icon(Icons.person, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            onChanged: (_) => _onFieldChanged(),
            decoration: const InputDecoration(
              labelText: 'Phone Number (10 digits) *',
              prefixIcon: Icon(Icons.phone, color: AppColors.primary),
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),

          // House / Flat & Landmark
          TextField(
            controller: _houseController,
            onChanged: (_) => _onFieldChanged(),
            decoration: const InputDecoration(
              labelText: 'House / Flat / Building No. *',
              prefixIcon: Icon(Icons.home, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _landmarkController,
            onChanged: (_) => _onFieldChanged(),
            decoration: const InputDecoration(
              labelText: 'Landmark (Optional)',
              prefixIcon: Icon(Icons.location_city, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),

          // Area & PIN Code
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _areaController,
                  onChanged: (_) => _onFieldChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Area / Street *',
                    prefixIcon: Icon(Icons.map, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: (_) => _onFieldChanged(),
                  decoration: const InputDecoration(
                    labelText: 'PIN *',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // City dropdown & State
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: (_selectedCity.isNotEmpty &&
                          (_assamCities.contains(_selectedCity) ||
                              !_assamCities.contains(_selectedCity)))
                      ? _selectedCity
                      : 'Jorhat',
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    prefixIcon: Icon(Icons.location_city, color: AppColors.primary),
                  ),
                  items: (_assamCities.contains(_selectedCity) || _selectedCity.isEmpty
                          ? _assamCities
                          : [..._assamCities, _selectedCity])
                      .map((city) => DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCity = val);
                      _onFieldChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'State',
                    prefixIcon: Icon(Icons.map_outlined, color: AppColors.primary),
                  ),
                  child: Text(
                    'Assam',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Error Message Display
          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Action Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          controller.previousStep();
                          widget.onBack();
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final ok = await controller.submitBooking();
                          if (ok) {
                            widget.onSuccess();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.text, // High contrast Charcoal text on Marigold
                  ),
                  child: state.isLoading
                      ? const AppProgressIndicator(size: 20)
                      : const Text(
                          'Book Repair Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
