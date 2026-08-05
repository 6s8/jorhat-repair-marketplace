import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../core/supabase/supabase_providers.dart';
import '../../../providers/job_repository_provider.dart';
import '../models/job_create_request.dart';
import '../state/booking_state.dart';

/// Riverpod Controller managing customer repair booking flow state and actions.
class BookingController extends StateNotifier<BookingState> {
  final Ref _ref;

  BookingController(this._ref) : super(const BookingState());

  void selectCategory(String category, {int? inspectionFee}) {
    final fee = inspectionFee ?? 299;
    state = state.copyWith(
      selectedCategory: category,
      baseInspectionFee: fee,
      estimatedPrice: fee.toDouble(),
      errorMessage: null,
    );
  }

  void selectBrand(String brand) {
    state = state.copyWith(
      applianceBrand: brand,
      errorMessage: null,
    );
  }

  void setCustomBrand(String text) {
    state = state.copyWith(
      customBrand: text,
      errorMessage: null,
    );
  }

  void setModelNumber(String text) {
    state = state.copyWith(
      applianceModel: text,
      errorMessage: null,
    );
  }

  void toggleIssueChip(String issue) {
    final currentChips = List<String>.from(state.selectedIssueChips);
    if (currentChips.contains(issue)) {
      currentChips.remove(issue);
    } else {
      currentChips.add(issue);
    }
    state = state.copyWith(
      selectedIssueChips: currentChips,
      errorMessage: null,
    );
  }

  void setComplaint(String text) {
    state = state.copyWith(
      customComplaint: text,
      errorMessage: null,
    );
  }

  void updateAddressFields({
    String? customerName,
    String? customerPhone,
    String? house,
    String? landmark,
    String? area,
    String? city,
    String? stateName,
    String? pincode,
  }) {
    final name = customerName ?? state.customerName;
    final phone = customerPhone ?? state.customerPhone;
    final h = house ?? state.house;
    final lm = landmark ?? state.landmark;
    final a = area ?? state.area;
    final c = city ?? state.city;
    final st = stateName ?? state.state;
    final pin = pincode ?? state.pincode;

    final formatted = '$h, ${lm.isNotEmpty ? "$lm, " : ""}$a, $c, $st - $pin';

    state = state.copyWith(
      customerName: name,
      customerPhone: phone,
      house: h,
      landmark: lm,
      area: a,
      city: c,
      state: st,
      pincode: pin,
      formattedAddress: formatted,
      errorMessage: null,
    );
  }

  /// Capture current device location coordinates via Geolocator
  Future<void> getCurrentLocation() async {
    state = state.copyWith(isFetchingLocation: true, errorMessage: null);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isFetchingLocation: false,
          latitude: 26.7509,
          longitude: 94.2037,
          area: state.area.isEmpty ? 'Jorhat Town' : state.area,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isFetchingLocation: false,
            latitude: 26.7509,
            longitude: 94.2037,
            area: state.area.isEmpty ? 'Jorhat Town' : state.area,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isFetchingLocation: false,
          latitude: 26.7509,
          longitude: 94.2037,
          area: state.area.isEmpty ? 'Jorhat Town' : state.area,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      state = state.copyWith(
        isFetchingLocation: false,
        latitude: position.latitude,
        longitude: position.longitude,
        area: state.area.isEmpty ? 'Jorhat Central' : state.area,
      );
    } catch (e) {
      state = state.copyWith(
        isFetchingLocation: false,
        latitude: 26.7509,
        longitude: 94.2037,
        area: state.area.isEmpty ? 'Jorhat Town' : state.area,
      );
    }
  }

  /// Update location from map picker and attempt reverse geocoding
  Future<void> updateLocationFromMap(double lat, double lng) async {
    // Optimistically update coordinates
    state = state.copyWith(latitude: lat, longitude: lng);

    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng');
      final response = await http.get(uri, headers: {
        'User-Agent': 'com.jorhat.repair_marketplace',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final area = address['suburb'] ?? address['neighbourhood'] ?? address['road'] ?? address['village'] ?? state.area;
          final pin = address['postcode'] ?? state.pincode;
          
          state = state.copyWith(
            area: area,
            pincode: pin,
          );
        }
      }
    } catch (e) {
      // Silently fail reverse geocoding, coordinates are already saved
    }
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step, errorMessage: null);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1, errorMessage: null);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, errorMessage: null);
    }
  }

  /// Submit repair booking request to Supabase
  Future<bool> submitBooking() async {
    if (!state.canSubmit) {
      final List<String> errors = [];
      if (!state.isCategoryValid) errors.add('Category');
      if (state.customerName.trim().isEmpty) errors.add('Name');
      if (!state.isPhoneValid) errors.add('Valid 10-digit Phone');
      if (state.house.trim().isEmpty) errors.add('House/Flat No');
      if (state.area.trim().isEmpty) errors.add('Area/Street');
      if (!state.isPincodeValid) errors.add('Valid 6-digit PIN');
      
      state = state.copyWith(errorMessage: 'Please fix: ${errors.join(', ')}');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final supabase = _ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;

    // customer_id must be a valid UUID — use auth user id if available,
    // otherwise generate a deterministic guest UUID (all-zeroes namespace + timestamp hash)
    String customerId;
    if (user != null) {
      customerId = user.id;
    } else {
      // Generate a v4-style UUID from current timestamp so it passes UUID validation
      final ts = DateTime.now().millisecondsSinceEpoch;
      final hex = ts.toRadixString(16).padLeft(12, '0');
      customerId = '00000000-0000-4000-8000-${hex.substring(0, 12)}';
    }

    final request = JobCreateRequest(
      customerId: customerId,
      category: state.selectedCategory!,
      applianceBrand: state.effectiveBrand,
      applianceModel: state.applianceModel.trim().isNotEmpty ? state.applianceModel.trim() : null,
      issueDescription: state.issueDescription.trim(),
      estimatedPrice: state.estimatedPrice ?? 399.0,
      customerName: state.customerName.trim(),
      customerPhone: state.customerPhone.trim(),
      house: state.house.trim(),
      landmark: state.landmark.trim(),
      area: state.area.trim(),
      city: state.city,
      state: state.state,
      pincode: state.pincode.trim(),
      formattedAddress: state.formattedAddress,
      latitude: state.latitude ?? 26.7509,
      longitude: state.longitude ?? 94.2037,
      status: 'pending',
    );

    final repository = _ref.read(jobRepositoryProvider);
    final result = await repository.createJob(request);

    return result.when(
      success: (createdJob) {
        state = state.copyWith(
          isLoading: false,
          createdJob: createdJob,
          currentStep: 4, // Step 4 -> Success Page
        );
        return true;
      },
      jobAlreadyTaken: (msg) {
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      },
      networkError: (msg) {
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      },
      timeout: (msg) {
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      },
      unknownError: (msg) {
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      },
    );
  }

  void goToNextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void goToPreviousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void reset() {
    state = const BookingState();
  }
}

/// Riverpod Provider for [BookingController]
final bookingControllerProvider =
    StateNotifierProvider<BookingController, BookingState>((ref) {
  return BookingController(ref);
});
