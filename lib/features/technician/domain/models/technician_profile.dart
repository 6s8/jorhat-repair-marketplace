import 'package:equatable/equatable.dart';

/// Immutable domain model representing a technician's profile and radar settings.
class TechnicianProfile extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? profilePhotoUrl;
  final List<String> skills;
  final double workRadiusKm;
  final int alertTimerSec;
  final bool isOnline;

  const TechnicianProfile({
    required this.id,
    this.name = 'Assam Expert Technician',
    this.phone = '+91 98765 43210',
    this.profilePhotoUrl,
    this.skills = const [
      'AC',
      'Refrigerator',
      'Washing Machine',
      'TV',
      'Television',
      'Microwave',
      'Water Purifier',
      'Geyser',
      'Air Cooler',
      'Water Pump',
      'Inverter',
      'Solar',
      'Electrical',
      'Plumbing',
    ],
    this.workRadiusKm = 20.0,
    this.alertTimerSec = 30,
    this.isOnline = true,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    List<String> parsedSkills = [];
    final skillsRaw = json['skills'];
    if (skillsRaw is List) {
      parsedSkills = skillsRaw.map((e) => e.toString()).toList();
    } else if (skillsRaw is String && skillsRaw.isNotEmpty) {
      parsedSkills = skillsRaw
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return TechnicianProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Assam Expert Technician',
      phone: json['phone']?.toString() ?? '+91 98765 43210',
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      skills: parsedSkills.isNotEmpty
          ? parsedSkills
          : const [
              'AC',
              'Refrigerator',
              'Washing Machine',
              'TV',
              'Microwave',
              'Water Purifier',
              'Geyser',
              'Air Cooler',
              'Water Pump',
              'Inverter',
              'Solar',
              'Electrical',
              'Plumbing',
            ],
      workRadiusKm: (json['work_radius_km'] as num?)?.toDouble() ?? 20.0,
      alertTimerSec: (json['alert_timer_sec'] as num?)?.toInt() ?? 30,
      isOnline: json['is_online'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'profile_photo_url': profilePhotoUrl,
      'skills': skills,
      'work_radius_km': workRadiusKm,
      'alert_timer_sec': alertTimerSec,
      'is_online': isOnline,
    };
  }

  TechnicianProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? profilePhotoUrl,
    List<String>? skills,
    double? workRadiusKm,
    int? alertTimerSec,
    bool? isOnline,
  }) {
    return TechnicianProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      skills: skills ?? this.skills,
      workRadiusKm: workRadiusKm ?? this.workRadiusKm,
      alertTimerSec: alertTimerSec ?? this.alertTimerSec,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        profilePhotoUrl,
        skills,
        workRadiusKm,
        alertTimerSec,
        isOnline,
      ];
}
