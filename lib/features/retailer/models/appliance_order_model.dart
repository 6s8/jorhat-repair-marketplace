import 'package:equatable/equatable.dart';

class ApplianceOrder extends Equatable {
  final String id;
  final String customerId;
  final String retailerId;
  final String applianceId;
  final String applianceTitle;
  final String applianceCategory;
  final String brand;
  final String condition;
  final double totalAmount;
  final String deliveryAddress;
  final String status; // 'pending', 'in_progress', 'ready_for_pickup', 'completed'
  final String customerPhone;
  final DateTime createdAt;

  const ApplianceOrder({
    required this.id,
    required this.customerId,
    required this.retailerId,
    required this.applianceId,
    required this.applianceTitle,
    this.applianceCategory = '',
    this.brand = '',
    this.condition = '',
    required this.totalAmount,
    this.deliveryAddress = '',
    this.status = 'pending',
    this.customerPhone = '',
    required this.createdAt,
  });

  factory ApplianceOrder.fromJson(Map<String, dynamic> json) {
    return ApplianceOrder(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      retailerId: json['retailer_id']?.toString() ?? '',
      applianceId: json['appliance_id']?.toString() ?? '',
      applianceTitle:
          json['appliance_title']?.toString() ?? json['title']?.toString() ?? 'Appliance',
      applianceCategory: json['appliance_category']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      condition: json['condition']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      customerPhone: json['customer_phone']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'retailer_id': retailerId,
        'appliance_id': applianceId,
        'appliance_title': applianceTitle,
        'appliance_category': applianceCategory,
        'brand': brand,
        'condition': condition,
        'total_amount': totalAmount,
        'delivery_address': deliveryAddress,
        'status': status,
        'customer_phone': customerPhone,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  ApplianceOrder copyWith({
    String? id,
    String? customerId,
    String? retailerId,
    String? applianceId,
    String? applianceTitle,
    String? applianceCategory,
    String? brand,
    String? condition,
    double? totalAmount,
    String? deliveryAddress,
    String? status,
    String? customerPhone,
    DateTime? createdAt,
  }) {
    return ApplianceOrder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      retailerId: retailerId ?? this.retailerId,
      applianceId: applianceId ?? this.applianceId,
      applianceTitle: applianceTitle ?? this.applianceTitle,
      applianceCategory: applianceCategory ?? this.applianceCategory,
      brand: brand ?? this.brand,
      condition: condition ?? this.condition,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      customerPhone: customerPhone ?? this.customerPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, customerId, retailerId, applianceId, applianceTitle,
        applianceCategory, brand, condition, totalAmount,
        deliveryAddress, status, customerPhone, createdAt,
      ];
}
