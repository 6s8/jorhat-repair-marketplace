import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../retailer/models/spare_part_model.dart';
import '../../domain/models/cart_item.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return const [];
  }

  void addToCart(SparePart part, [int quantity = 1]) {
    final current = List<CartItem>.from(state);
    final index = current.indexWhere((item) => item.part.id == part.id);

    if (index >= 0) {
      final existing = current[index];
      current[index] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      current.add(CartItem(part: part, quantity: quantity));
    }

    state = current;
  }

  void removeFromCart(String partId) {
    state = state.where((item) => item.part.id != partId).toList();
  }

  void updateQuantity(String partId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(partId);
      return;
    }

    state = state.map((item) {
      if (item.part.id == partId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = const [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

final cartTotalItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

final cartSubtotalPriceProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});
