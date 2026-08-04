import 'package:equatable/equatable.dart';

class RefurbishedAppliance extends Equatable {
  final String id;
  final String retailerId;
  final String title;
  final String category; // 'AC', 'Refrigerator', 'Washing Machine', 'TV', etc.
  final String brand;
  final String condition; // 'Like New (Refurbished)', 'Good Condition', 'Certified Refurbished'
  final String warrantyPeriod; // '6 Months Warranty', '1 Year Warranty', '3 Months Warranty'
  final double customerPrice;
  final double? originalPrice;
  final String? imageUrl;
  final String description;
  final bool inStock;
  final String retailerPhone;
  final DateTime createdAt;

  const RefurbishedAppliance({
    required this.id,
    required this.retailerId,
    required this.title,
    required this.category,
    required this.brand,
    this.condition = 'Certified Refurbished',
    this.warrantyPeriod = '6 Months Warranty',
    required this.customerPrice,
    this.originalPrice,
    this.imageUrl,
    required this.description,
    this.inStock = true,
    this.retailerPhone = '+919876543210',
    required this.createdAt,
  });

  factory RefurbishedAppliance.fromJson(Map<String, dynamic> json) {
    return RefurbishedAppliance(
      id: json['id']?.toString() ?? '',
      retailerId: json['retailer_id']?.toString() ?? 'guest_retailer_001',
      title: json['title']?.toString() ?? json['part_name']?.toString() ?? 'Refurbished Appliance',
      category: json['category']?.toString() ?? 'AC',
      brand: json['brand']?.toString() ?? 'Generic',
      condition: json['condition']?.toString() ?? 'Certified Refurbished',
      warrantyPeriod: json['warranty_period']?.toString() ?? '6 Months Warranty',
      customerPrice: (json['customer_price'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      imageUrl: json['image_url']?.toString(),
      description: json['description']?.toString() ??
          'Fully tested and certified refurbished appliance with warranty.',
      inStock: json['in_stock'] == true || json['in_stock'] == null,
      retailerPhone: json['retailer_phone']?.toString() ?? '+919876543210',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailer_id': retailerId,
      'title': title,
      'category': category,
      'brand': brand,
      'condition': condition,
      'warranty_period': warrantyPeriod,
      'customer_price': customerPrice,
      'original_price': originalPrice,
      'image_url': imageUrl,
      'description': description,
      'in_stock': inStock,
      'retailer_phone': retailerPhone,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  RefurbishedAppliance copyWith({
    String? id,
    String? retailerId,
    String? title,
    String? category,
    String? brand,
    String? condition,
    String? warrantyPeriod,
    double? customerPrice,
    double? originalPrice,
    String? imageUrl,
    String? description,
    bool? inStock,
    String? retailerPhone,
    DateTime? createdAt,
  }) {
    return RefurbishedAppliance(
      id: id ?? this.id,
      retailerId: retailerId ?? this.retailerId,
      title: title ?? this.title,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      condition: condition ?? this.condition,
      warrantyPeriod: warrantyPeriod ?? this.warrantyPeriod,
      customerPrice: customerPrice ?? this.customerPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      inStock: inStock ?? this.inStock,
      retailerPhone: retailerPhone ?? this.retailerPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        retailerId,
        title,
        category,
        brand,
        condition,
        warrantyPeriod,
        customerPrice,
        originalPrice,
        imageUrl,
        description,
        inStock,
        retailerPhone,
        createdAt,
      ];
}
