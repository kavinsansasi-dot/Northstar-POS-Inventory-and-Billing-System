class SaleItem {
  const SaleItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String productId;
  final String name;
  final double price;
  final double quantity;

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    productId: (json['product'] ?? '').toString(),
    name: json['name'] as String? ?? '',
    price: _toDouble(json['price']),
    quantity: _toDouble(json['qty']),
  );
}

class Sale {
  const Sale({
    required this.id,
    required this.invoiceNo,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentType,
    required this.date,
    this.cashierName,
    this.customerName,
    this.customerPhone,
    this.receivedAmount,
    this.changeAmount,
  });

  final String id;
  final String invoiceNo;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentType;
  final DateTime date;
  final String? cashierName;
  final String? customerName;
  final String? customerPhone;
  final double? receivedAmount;
  final double? changeAmount;

  Sale copyWith({
    String? cashierName,
    String? customerName,
    String? customerPhone,
    double? receivedAmount,
    double? changeAmount,
  }) => Sale(
    id: id,
    invoiceNo: invoiceNo,
    items: items,
    subtotal: subtotal,
    discount: discount,
    tax: tax,
    total: total,
    paymentType: paymentType,
    date: date,
    cashierName: cashierName ?? this.cashierName,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    receivedAmount: receivedAmount ?? this.receivedAmount,
    changeAmount: changeAmount ?? this.changeAmount,
  );

  factory Sale.fromJson(Map<String, dynamic> json) {
    final cashier = json['cashier'];
    final customer = json['customer'];
    return Sale(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      invoiceNo: json['invoiceNo'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SaleItem.fromJson)
          .toList(),
      subtotal: _toDouble(json['subtotal']),
      discount: _toDouble(json['discount']),
      tax: _toDouble(json['tax']),
      total: _toDouble(json['total']),
      paymentType: json['paymentType'] as String? ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      cashierName: cashier is Map<String, dynamic>
          ? cashier['name'] as String?
          : null,
      customerName: customer is Map<String, dynamic>
          ? customer['name'] as String?
          : null,
      customerPhone: customer is Map<String, dynamic>
          ? customer['phone'] as String?
          : null,
      receivedAmount: json['receivedAmount'] == null
          ? null
          : _toDouble(json['receivedAmount']),
      changeAmount: json['changeAmount'] == null
          ? null
          : _toDouble(json['changeAmount']),
    );
  }
}

double _toDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
