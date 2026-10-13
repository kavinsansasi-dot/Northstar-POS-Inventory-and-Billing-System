import 'dart:math' as math;

import 'product.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final double quantity;

  double get lineTotal => product.price * quantity;
  double get incrementAmount =>
      math.min(1, product.stock - quantity).clamp(0, 1).toDouble();

  CartItem copyWith({double? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}
