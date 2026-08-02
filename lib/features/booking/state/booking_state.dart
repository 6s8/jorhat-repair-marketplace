import 'package:equatable/equatable.dart';
import '../../../models/job_model.dart';

/// Immutable Booking State for Riverpod controller
class BookingState extends Equatable {
  final int currentStep; // 0: Category, 1: Issue, 2: Address, 3: Success
  final String? selectedCategory;
  final String issueDescription;
  final double? estimatedPrice;
  final String customerName;
  final String customerPhone;
  final String house;
  final String landmark;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final bool isFetchingLocation;
  final bool isLoading;
  final String? errorMessage;
  final Job? createdJob;

  const BookingState({
    this.currentStep = 0,
    this.selectedCategory,
    this.issueDescription = '',
    this.estimatedPrice,
    this.customerName = '',
    this.customerPhone = '',
    this.house = '',
    this.landmark = '',
    this.area = '',
    this.city = 'Jorhat',
    this.state = 'Assam',
    this.pincode = '785001',
    this.formattedAddress = '',
    this.latitude,
    this.longitude,
    this.isFetchingLocation = false,
    this.isLoading = false,
    this.errorMessage,
    this.createdJob,
  });

  // Validations
  bool get isCategoryValid => selectedCategory != null && selectedCategory!.isNotEmpty;
  bool get isIssueValid => issueDescription.trim().length >= 15 && issueDescription.trim().length <= 500;
  bool get isPhoneValid => RegExp(r'^[0-9]{10}$').hasMatch(customerPhone.trim());
  bool get isPincodeValid => RegExp(r'^[0-9]{6}$').hasMatch(pincode.trim());
  bool get isAddressValid =>
      customerName.trim().isNotEmpty &&
      isPhoneValid &&
      house.trim().isNotEmpty &&
      area.trim().isNotEmpty &&
      isPincodeValid;

  bool get canSubmit => isCategoryValid && isIssueValid && isAddressValid;

  BookingState copyWith({
    int? currentStep,
    String? selectedCategory,
    String? issueDescription,
    double? estimatedPrice,
    String? customerName,
    String? customerPhone,
    String? house,
    String? landmark,
    String? area,
    String? city,
    String? state,
    String? pincode,
    String? formattedAddress,
    double? latitude,
    double? longitude,
    bool? isFetchingLocation,
    bool? isLoading,
    String? errorMessage,
    Job? createdJob,
  }) {
    return BookingState(
      currentStep: currentStep ?? this.currentStep,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      issueDescription: issueDescription ?? this.issueDescription,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      house: house ?? this.house,
      landmark: landmark ?? this.landmark,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      createdJob: createdJob ?? this.createdJob,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        selectedCategory,
        issueDescription,
        estimatedPrice,
        customerName,
        customerPhone,
        house,
        landmark,
        area,
        city,
        state,
        pincode,
        formattedAddress,
        latitude,
        longitude,
        isFetchingLocation,
        isLoading,
        errorMessage,
        createdJob,
      ];
}
