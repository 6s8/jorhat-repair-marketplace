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
  /// Only contains valid database schema keys:
  /// 'appliance_category', 'issue_description', 'issue', 'price', 'status', 'address_text', 'customer_id', 'latitude', 'longitude'.
  Map<String, dynamic> toSanitizedJson() {
    final addressText = formattedAddress.isNotEmpty
        ? formattedAddress
        : '$house, ${landmark.isNotEmpty ? "$landmark, " : ""}$area, $city, $state - $pincode';

    final String detailedIssue = '[$category] $issueDescription\nContact: $customerName ($customerPhone)\nAddress: $addressText';

    return {
      'customer_id': customerId,
      'appliance_category': category,
      'issue_description': issueDescription,
      'issue': detailedIssue,
      'price': estimatedPrice,
      'status': status,
      'address_text': addressText,
      'latitude': latitude,
      'longitude': longitude,
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
