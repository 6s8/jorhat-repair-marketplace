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

  /// Convert to sanitized JSON payload for Supabase insertion.
  /// ONLY uses columns that exist in the live jobs table schema:
  /// customer_id, issue, price, status, distance_km, latitude, longitude, expires_at.
  /// All address/category/contact details are embedded inside the `issue` text field.
  Map<String, dynamic> toSanitizedJson() {
    final addressText = formattedAddress.isNotEmpty
        ? formattedAddress
        : '$house, ${landmark.isNotEmpty ? "$landmark, " : ""}$area, $city, $state - $pincode';

    // Embed all rich info into the `issue` text (the only free-text field in the DB schema)
    final String detailedIssue =
        '[$category] $issueDescription\n'
        'Contact: $customerName ($customerPhone)\n'
        'Address: $addressText';

    return {
      'customer_id': customerId,
      'issue': detailedIssue,
      'price': estimatedPrice,
      'status': status,
      'distance_km': 2.5,
      'latitude': latitude,
      'longitude': longitude,
      'expires_at': DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toSanitizedJson();

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
