import 'dart:math';
import 'package:equatable/equatable.dart';

/// Immutable DTO request for creating a new repair job.
class JobCreateRequest extends Equatable {
  final String customerId;
  final String category;
  final String? applianceBrand;
  final String? applianceModel;
  final String issueDescription;
  final double estimatedPrice;
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
  final String status;

  const JobCreateRequest({
    required this.customerId,
    required this.category,
    this.applianceBrand,
    this.applianceModel,
    required this.issueDescription,
    required this.estimatedPrice,
    required this.customerName,
    required this.customerPhone,
    required this.house,
    this.landmark = '',
    required this.area,
    this.city = 'Jorhat',
    this.state = 'Assam',
    required this.pincode,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.status = 'pending',
  });

  /// Converts to a JSON payload matching the ACTUAL live Supabase jobs table schema.
  /// Columns confirmed via REST API query on the live project:
  ///   appliance_category, appliance_brand, appliance_model, issue_description, price, status, address_text,
  ///   location_lat, location_lng, updated_at, customer_name, customer_phone, customer_id.
  Map<String, dynamic> toSanitizedJson() {
    final addressText = formattedAddress.isNotEmpty
        ? formattedAddress
        : '$house, ${landmark.isNotEmpty ? "$landmark, " : ""}$area, $city, $state - $pincode';

    final now = DateTime.now().toUtc().toIso8601String();
    
    final random = Random();
    final arrivalOtp = (1000 + random.nextInt(9000)).toString();
    final completionOtp = (1000 + random.nextInt(9000)).toString();

    final Map<String, dynamic> payload = {
      'appliance_category': category,
      'issue_description': issueDescription,
      'price': estimatedPrice,
      'status': status,
      'address_text': addressText,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'updated_at': now,
      'arrival_otp': arrivalOtp,
      'completion_otp': completionOtp,
    };

    if (applianceBrand != null && applianceBrand!.trim().isNotEmpty) {
      payload['appliance_brand'] = applianceBrand!.trim();
    }
    if (applianceModel != null && applianceModel!.trim().isNotEmpty) {
      payload['appliance_model'] = applianceModel!.trim();
    }

    // customer_id is nullable in live table — only send if present
    if (customerId.isNotEmpty) payload['customer_id'] = customerId;

    // Live table uses location_lat / location_lng (NOT latitude / longitude)
    if (latitude != null) payload['location_lat'] = latitude;
    if (longitude != null) payload['location_lng'] = longitude;

    return payload;
  }

  Map<String, dynamic> toJson() => toSanitizedJson();

  @override
  List<Object?> get props => [
        customerId,
        category,
        applianceBrand,
        applianceModel,
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
        status,
      ];
}
