import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

class CartState {
  const CartState({this.items = const [], this.discount = 0, this.tax = 0});

  final List<CartItem> items;
  final double discount;
  final double tax;

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  double get total => subtotal - discount + tax;
  int get itemCount => items.length;

  CartState copyWith({List<CartItem>? items, double? discount, double? tax}) =>
      CartState(
        items: items ?? this.items,
        discount: discount ?? this.discount,
        tax: tax ?? this.tax,
      );
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void add(Product product) {
    final index = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (index < 0) {
      if (product.stock <= 0) return;
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(
            product: product,
            quantity: product.stock < 1 ? product.stock : 1,
          ),
        ],
      );
      return;
    }
    setQuantity(
      product.id,
      state.items[index].quantity + state.items[index].incrementAmount,
    );
  }

  void setQuantity(String productId, double quantity) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    if (quantity <= 0) {
      items.removeAt(index);
    } else if (quantity <= items[index].product.stock) {
      items[index] = items[index].copyWith(quantity: quantity);
    }
    state = state.copyWith(items: items);
  }

  void remove(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void setDiscount(double amount) {
    state = state.copyWith(
      discount: amount.clamp(0, state.subtotal).toDouble(),
    );
  }

  void setTax(double amount) {
    state = state.copyWith(tax: amount < 0 ? 0 : amount);
  }

  void clear() => state = const CartState();
}
