import 'package:equatable/equatable.dart';

class SparePart extends Equatable {
  final String id;
  final String retailerId;
  final String partName;
  final String category;
  final String brand;
  final String? imageUrl;
  final double customerPrice;
  final double technicianPrice;
  final bool inStock;
  final String? stockStatus;
  final String? retailerPhone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SparePart({
    required this.id,
    required this.retailerId,
    required this.partName,
    required this.category,
    this.brand = 'Generic',
    this.imageUrl,
    required this.customerPrice,
    required this.technicianPrice,
    this.inStock = true,
    this.stockStatus,
    this.retailerPhone,
    required this.createdAt,
    this.updatedAt,
  });

  String get displayStockStatus {
    if (stockStatus != null && stockStatus!.isNotEmpty) return stockStatus!;
    return inStock ? 'In Stock' : 'Out of Stock';
  }

  factory SparePart.fromJson(Map<String, dynamic> json) {
    final rawPrice = (json['price'] as num?)?.toDouble() ?? 0.0;
    final custPrice = (json['customer_price'] as num?)?.toDouble() ??
        (rawPrice > 0 ? rawPrice : 0.0);
    final techPrice = (json['technician_price'] as num?)?.toDouble() ??
        (custPrice > 0 ? (custPrice * 0.85).roundToDouble() : 0.0);

    final isStockNull = json['in_stock'] == null;
    final inStockVal = isStockNull
        ? true
        : (json['in_stock'] == true ||
            json['stock_status']?.toString().toLowerCase() == 'in stock');

    return SparePart(
      id: json['id']?.toString() ?? '',
      retailerId: json['retailer_id']?.toString() ?? 'guest_retailer_001',
      partName: json['part_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      brand: json['brand']?.toString() ?? 'Generic',
      imageUrl: json['image_url']?.toString(),
      customerPrice: custPrice,
      technicianPrice: techPrice,
      inStock: inStockVal,
      stockStatus:
          json['stock_status']?.toString() ?? (inStockVal ? 'In Stock' : 'Out of Stock'),
      retailerPhone: json['retailer_phone']?.toString() ?? '+919876543210',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailer_id': retailerId,
      'part_name': partName,
      'category': category,
      'brand': brand,
      'image_url': imageUrl,
      'customer_price': customerPrice,
      'technician_price': technicianPrice,
      'in_stock': inStock,
      'stock_status': stockStatus ?? (inStock ? 'In Stock' : 'Out of Stock'),
      'retailer_phone': retailerPhone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  SparePart copyWith({
    String? id,
    String? retailerId,
    String? partName,
    String? category,
    String? brand,
    String? imageUrl,
    double? customerPrice,
    double? technicianPrice,
    bool? inStock,
    String? stockStatus,
    String? retailerPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SparePart(
      id: id ?? this.id,
      retailerId: retailerId ?? this.retailerId,
      partName: partName ?? this.partName,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      customerPrice: customerPrice ?? this.customerPrice,
      technicianPrice: technicianPrice ?? this.technicianPrice,
      inStock: inStock ?? this.inStock,
      stockStatus: stockStatus ?? this.stockStatus,
      retailerPhone: retailerPhone ?? this.retailerPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        retailerId,
        partName,
        category,
        brand,
        imageUrl,
        customerPrice,
        technicianPrice,
        inStock,
        stockStatus,
        retailerPhone,
        createdAt,
        updatedAt,
      ];
}
