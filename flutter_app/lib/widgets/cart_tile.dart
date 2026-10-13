import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cart_item.dart';

class CartTile extends StatelessWidget {
  const CartTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${currency.format(item.product.price)} each · ${currency.format(item.lineTotal)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            onPressed: () => onQuantityChanged(item.quantity - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            onPressed: item.incrementAmount > 0
                ? () => onQuantityChanged(item.quantity + item.incrementAmount)
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            tooltip: 'Remove item',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
