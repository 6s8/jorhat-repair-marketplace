import 'package:equatable/equatable.dart';

class RetailerOrder extends Equatable {
  final String id;
  final String customerId;
  final String retailerId;
  final String partId;
  final String partName;
  final int quantity;
  final String deliveryAddress;
  final double totalAmount;
  final String status; // 'pending', 'in_progress', 'ready_for_pickup', 'completed'
  final String orderType; // 'customer', 'technician'
  final DateTime createdAt;

  const RetailerOrder({
    required this.id,
    required this.customerId,
    required this.retailerId,
    required this.partId,
    required this.partName,
    required this.quantity,
    required this.deliveryAddress,
    required this.totalAmount,
    this.status = 'pending',
    this.orderType = 'customer',
    required this.createdAt,
  });

  factory RetailerOrder.fromJson(Map<String, dynamic> json) {
    return RetailerOrder(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      retailerId: json['retailer_id']?.toString() ?? '',
      partId: json['part_id']?.toString() ?? '',
      partName: json['part_name']?.toString() ?? 'Spare Part',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      orderType: json['order_type']?.toString() ??
          (json['customer_id']?.toString().startsWith('tech') == true
              ? 'technician'
              : 'customer'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'retailer_id': retailerId,
      'part_id': partId,
      'part_name': partName,
      'quantity': quantity,
      'delivery_address': deliveryAddress,
      'total_amount': totalAmount,
      'status': status,
      'order_type': orderType,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  RetailerOrder copyWith({
    String? id,
    String? customerId,
    String? retailerId,
    String? partId,
    String? partName,
    int? quantity,
    String? deliveryAddress,
    double? totalAmount,
    String? status,
    String? orderType,
    DateTime? createdAt,
  }) {
    return RetailerOrder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      retailerId: retailerId ?? this.retailerId,
      partId: partId ?? this.partId,
      partName: partName ?? this.partName,
      quantity: quantity ?? this.quantity,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        retailerId,
        partId,
        partName,
        quantity,
        deliveryAddress,
        totalAmount,
        status,
        orderType,
        createdAt,
      ];
}
