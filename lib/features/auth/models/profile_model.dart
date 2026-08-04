import 'package:flutter/foundation.dart';

/// User profile model corresponding to Supabase `public.profiles` table.
@immutable
class ProfileModel {
  final String id;
  final String fullName;
  final String role; // 'customer' | 'technician' | 'retailer'
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.email,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOnboarded => role.isNotEmpty && fullName.isNotEmpty;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      role: (json['role'] as String? ?? '').toLowerCase(),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? role,
    String? phone,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          role == other.role &&
          phone == other.phone &&
          email == other.email &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      role.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      avatarUrl.hashCode;
}
