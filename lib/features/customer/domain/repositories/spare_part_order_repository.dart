import 'package:equatable/equatable.dart';

class SparePartOrderRequest extends Equatable {
  final String customerId;
  final String retailerId;
  final String partId;
  final String partName;
  final int quantity;
  final String deliveryAddress;
  final double totalAmount;
  final String status;

  const SparePartOrderRequest({
    required this.customerId,
    required this.retailerId,
    required this.partId,
    required this.partName,
    required this.quantity,
    required this.deliveryAddress,
    required this.totalAmount,
    this.status = 'pending',
  });

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
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        customerId,
        retailerId,
        partId,
        partName,
        quantity,
        deliveryAddress,
        totalAmount,
        status,
      ];
}

abstract class SparePartOrderRepository {
  Future<bool> placeOrder(SparePartOrderRequest request);
}
