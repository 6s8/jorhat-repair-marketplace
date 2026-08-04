import 'dart:convert';

class CustomerProfileModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String city;
  final String addressSummary;

  const CustomerProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
    required this.addressSummary,
  });

  CustomerProfileModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? city,
    String? addressSummary,
  }) {
    return CustomerProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      addressSummary: addressSummary ?? this.addressSummary,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'city': city,
        'addressSummary': addressSummary,
      };

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) =>
      CustomerProfileModel(
        id: json['id'] as String? ?? 'cust-123',
        name: json['name'] as String? ?? 'Anay Sharma',
        phone: json['phone'] as String? ?? '+91 98765 43210',
        email: json['email'] as String? ?? 'anay.sharma@example.com',
        city: json['city'] as String? ?? 'Jorhat, Assam',
        addressSummary: json['addressSummary'] as String? ?? 'Tarazan / Rupali Nagar, Jorhat',
      );
}

class CustomerAddressModel {
  final String id;
  final String label; // Home, Work, Other
  final String name;
  final String phone;
  final String house;
  final String area;
  final String landmark;
  final String city;
  final String pincode;
  final bool isDefault;

  const CustomerAddressModel({
    required this.id,
    required this.label,
    this.name = 'Anay Sharma',
    this.phone = '+91 98765 43210',
    required this.house,
    required this.area,
    required this.landmark,
    required this.city,
    required this.pincode,
    this.isDefault = false,
  });

  String get fullAddressText =>
      '${name.isNotEmpty ? "$name ($phone)\n" : ""}$house, $area${landmark.isNotEmpty ? " (Near $landmark)" : ""}, $city, Assam - $pincode';

  CustomerAddressModel copyWith({
    String? id,
    String? label,
    String? name,
    String? phone,
    String? house,
    String? area,
    String? landmark,
    String? city,
    String? pincode,
    bool? isDefault,
  }) {
    return CustomerAddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      house: house ?? this.house,
      area: area ?? this.area,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'name': name,
        'phone': phone,
        'house': house,
        'area': area,
        'landmark': landmark,
        'city': city,
        'pincode': pincode,
        'isDefault': isDefault,
      };

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) =>
      CustomerAddressModel(
        id: json['id'] as String,
        label: json['label'] as String? ?? 'Home',
        name: json['name'] as String? ?? 'Anay Sharma',
        phone: json['phone'] as String? ?? '+91 98765 43210',
        house: json['house'] as String? ?? '',
        area: json['area'] as String? ?? '',
        landmark: json['landmark'] as String? ?? '',
        city: json['city'] as String? ?? 'Jorhat',
        pincode: json['pincode'] as String? ?? '785001',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class CustomerPaymentMethodModel {
  final String id;
  final String type; // UPI, Card, COD
  final String title; // Google Pay, PhonePe, etc.
  final String details; // e.g. anay@okicici, **** 4821
  final bool isDefault;

  const CustomerPaymentMethodModel({
    required this.id,
    required this.type,
    required this.title,
    required this.details,
    this.isDefault = false,
  });

  CustomerPaymentMethodModel copyWith({
    String? id,
    String? type,
    String? title,
    String? details,
    bool? isDefault,
  }) {
    return CustomerPaymentMethodModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'details': details,
        'isDefault': isDefault,
      };

  factory CustomerPaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      CustomerPaymentMethodModel(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'UPI',
        title: json['title'] as String? ?? 'Google Pay',
        details: json['details'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
