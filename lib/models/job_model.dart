import 'package:equatable/equatable.dart';

/// Immutable Job model representing a technician dispatch job.
class Job extends Equatable {
  final String id;
  final String customerId;
  final String? technicianId;
  final String issue;
  final String status; // 'pending', 'accepted', 'completed'
  final double price;
  final double distanceKm;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  const Job({
    required this.id,
    required this.customerId,
    this.technicianId,
    required this.issue,
    this.status = 'pending',
    required this.price,
    this.distanceKm = 0.0,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.expiresAt,
    this.acceptedAt,
    this.completedAt,
  });

  /// Check if job countdown has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Remaining duration until expiry
  Duration get remainingDuration {
    if (expiresAt == null) return Duration.zero;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    // Derive issue string from issue, issue_description, or appliance_category
    String derivedIssue = json['issue']?.toString() ?? '';
    if (derivedIssue.isEmpty) {
      final category = json['appliance_category']?.toString() ?? 'General Repair';
      final description = json['issue_description']?.toString() ?? '';
      final address = json['address_text']?.toString() ?? json['formatted_address']?.toString() ?? '';
      derivedIssue = '[$category] $description${address.isNotEmpty ? "\nAddress: $address" : ""}';
    }

    return Job(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      technicianId: json['technician_id']?.toString(),
      issue: derivedIssue.isNotEmpty ? derivedIssue : 'General Repair Request',
      status: json['status']?.toString() ?? 'pending',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 2.5,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())?.toLocal()
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString())?.toLocal()
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'technician_id': technicianId,
      'issue': issue,
      'status': status,
      'price': price,
      'distance_km': distanceKm,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Job copyWith({
    String? id,
    String? customerId,
    String? technicianId,
    String? issue,
    String? status,
    double? price,
    double? distanceKm,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return Job(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      technicianId: technicianId ?? this.technicianId,
      issue: issue ?? this.issue,
      status: status ?? this.status,
      price: price ?? this.price,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        technicianId,
        issue,
        status,
        price,
        distanceKm,
        latitude,
        longitude,
        createdAt,
        expiresAt,
        acceptedAt,
        completedAt,
      ];
}
