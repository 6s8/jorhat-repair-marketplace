import 'package:equatable/equatable.dart';

/// Immutable Job model representing a technician dispatch job.
/// Field names are aligned to the live Supabase `jobs` table schema.
class Job extends Equatable {
  final String id;
  final String customerId;
  final String? technicianId;

  // Live DB rich columns
  final String? applianceCategory;
  final String? issueDescription;
  final String? customerName;
  final String? customerPhone;
  final String? addressText;

  final String issue; // derived display string
  final String status; // 'pending', 'accepted', 'completed'
  final double price;
  final double distanceKm;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Legacy nullable fields kept for compat (not in live DB)
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  const Job({
    required this.id,
    required this.customerId,
    this.technicianId,
    this.applianceCategory,
    this.issueDescription,
    this.customerName,
    this.customerPhone,
    this.addressText,
    required this.issue,
    this.status = 'pending',
    required this.price,
    this.distanceKm = 0.0,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
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

  /// Human-readable display title derived from rich columns or issue text
  String get displayTitle {
    if (applianceCategory != null && applianceCategory!.isNotEmpty) {
      return applianceCategory!;
    }
    final lines = issue.split('\n');
    return lines.first.replaceAll(RegExp(r'^\[.*?\]\s*'), '').trim();
  }

  /// Human-readable issue summary
  String get displayIssue {
    if (issueDescription != null && issueDescription!.isNotEmpty) {
      return issueDescription!;
    }
    return issue;
  }

  /// Display address
  String get displayAddress {
    if (addressText != null && addressText!.isNotEmpty) return addressText!;
    final lines = issue.split('\n');
    for (final l in lines) {
      if (l.startsWith('Address:')) return l.replaceFirst('Address:', '').trim();
    }
    return '';
  }

  /// Display contact
  String get displayContact {
    final name = customerName ?? '';
    final phone = customerPhone ?? '';
    if (name.isNotEmpty || phone.isNotEmpty) {
      return [name, phone].where((s) => s.isNotEmpty).join(' • ');
    }
    final lines = issue.split('\n');
    for (final l in lines) {
      if (l.startsWith('Contact:')) return l.replaceFirst('Contact:', '').trim();
    }
    return '';
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    // Derive combined issue string for legacy display
    String derivedIssue = json['issue']?.toString() ?? '';
    final category = json['appliance_category']?.toString() ?? '';
    final description = json['issue_description']?.toString() ?? '';
    final address = json['address_text']?.toString() ?? '';

    if (derivedIssue.isEmpty) {
      final parts = <String>[];
      if (category.isNotEmpty) parts.add('[$category]');
      if (description.isNotEmpty) parts.add(description);
      if (address.isNotEmpty) parts.add('\nAddress: $address');
      derivedIssue = parts.join(' ');
    }

    return Job(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      technicianId: json['technician_id']?.toString(),
      applianceCategory: category.isNotEmpty ? category : null,
      issueDescription: description.isNotEmpty ? description : null,
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      addressText: address.isNotEmpty ? address : null,
      issue: derivedIssue.isNotEmpty ? derivedIssue : 'General Repair Request',
      status: json['status']?.toString() ?? 'pending',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (json['location_lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (json['location_lng'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
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
      'appliance_category': applianceCategory,
      'issue_description': issueDescription,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'address_text': addressText,
      'issue': issue,
      'status': status,
      'price': price,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Job copyWith({
    String? id,
    String? customerId,
    String? technicianId,
    String? applianceCategory,
    String? issueDescription,
    String? customerName,
    String? customerPhone,
    String? addressText,
    String? issue,
    String? status,
    double? price,
    double? distanceKm,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return Job(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      technicianId: technicianId ?? this.technicianId,
      applianceCategory: applianceCategory ?? this.applianceCategory,
      issueDescription: issueDescription ?? this.issueDescription,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      addressText: addressText ?? this.addressText,
      issue: issue ?? this.issue,
      status: status ?? this.status,
      price: price ?? this.price,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
        applianceCategory,
        issueDescription,
        customerName,
        customerPhone,
        addressText,
        issue,
        status,
        price,
        distanceKm,
        latitude,
        longitude,
        createdAt,
        updatedAt,
      ];
}
