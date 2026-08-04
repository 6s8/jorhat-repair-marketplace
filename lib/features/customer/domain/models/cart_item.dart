import 'package:equatable/equatable.dart';
import '../../../retailer/models/spare_part_model.dart';

class CartItem extends Equatable {
  final SparePart part;
  final int quantity;

  const CartItem({
    required this.part,
    this.quantity = 1,
  });

  double get totalPrice => part.customerPrice * quantity;

  CartItem copyWith({
    SparePart? part,
    int? quantity,
  }) {
    return CartItem(
      part: part ?? this.part,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [part, quantity];
}
