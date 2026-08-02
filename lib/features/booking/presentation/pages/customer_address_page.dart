import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../controller/booking_controller.dart';
import 'map_picker_sheet.dart';

/// Step 3: Customer Contact & Location Address Page.
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
    // Pre-fill Assam and selected city into booking state
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
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address & Location',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your contact details and service address in Jorhat',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 20),

          // Pick Location on Map Button
          OutlinedButton.icon(
            onPressed: state.isFetchingLocation
                ? null
                : () async {
                    // Set default center to Jorhat or current selected location
                    final currentCenter = LatLng(
                      state.latitude ?? 26.7509,
                      state.longitude ?? 94.2037,
                    );
                    
                    final result = await MapPickerSheet.show(context, currentCenter);
                    
                    if (result != null) {
                      // Show loading state while reverse geocoding
                      controller.updateLocationFromMap(result.latitude, result.longitude).then((_) {
                        // After reverse geocoding completes, sync local controllers
                        if (mounted) {
                          setState(() {
                            final newState = ref.read(bookingControllerProvider);
                            if (newState.area.isNotEmpty) _areaController.text = newState.area;
                            if (newState.pincode.isNotEmpty) _pinController.text = newState.pincode;
                            if (newState.city.isNotEmpty && _assamCities.contains(newState.city)) {
                              _selectedCity = newState.city;
                            }
                          });
                        }
                      });
                    }
                  },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: state.latitude != null ? const Color(0xFF1565C0).withValues(alpha: 0.1) : null,
              side: BorderSide(
                color: state.latitude != null ? const Color(0xFF1565C0) : Colors.grey[400]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: state.isFetchingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    state.latitude != null ? Icons.check_circle : Icons.map_rounded,
                    color: state.latitude != null ? const Color(0xFF1565C0) : const Color(0xFF0F52BA),
                  ),
            label: Text(
              state.latitude != null
                  ? 'Pin Dropped: ${state.latitude!.toStringAsFixed(4)}° N, ${state.longitude!.toStringAsFixed(4)}° E'
                  : 'Pick Location on Map',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: state.latitude != null ? const Color(0xFF1565C0) : const Color(0xFF0F52BA),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Customer Name & Phone
          TextField(
            controller: _nameController,
            onChanged: (_) => _onFieldChanged(),
            decoration: const InputDecoration(
              labelText: 'Customer Name *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
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
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
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
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _landmarkController,
            onChanged: (_) => _onFieldChanged(),
            decoration: const InputDecoration(
              labelText: 'Landmark (Optional)',
              prefixIcon: Icon(Icons.location_city),
              border: OutlineInputBorder(),
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
                    prefixIcon: Icon(Icons.map),
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // City dropdown (Assam cities) & locked State
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'City *',
                    prefixIcon: const Icon(Icons.location_city),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  items: _assamCities
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
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  child: Text(
                    'Assam',
                    style: TextStyle(fontSize: 15),
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
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: state.canSubmit && !state.isLoading
                      ? () async {
                          final ok = await controller.submitBooking();
                          if (ok) {
                            widget.onSuccess();
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Book Repair',
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
