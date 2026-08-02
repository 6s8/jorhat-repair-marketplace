import 'package:equatable/equatable.dart';

/// Immutable DTO request for creating a new repair job.
class JobCreateRequest extends Equatable {
  final String customerId;
  final String category;
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

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'issue': '$category Repair: $issueDescription',
      'price': estimatedPrice,
      'distance_km': 2.5, // Default distance estimate in Jorhat town area
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'house': house,
      'landmark': landmark,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'formatted_address': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'expires_at': DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        customerId,
        category,
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
