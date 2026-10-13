class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.cost,
    required this.stock,
    required this.minStock,
    this.barcode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String sku;
  final String category;
  final double price;
  final double cost;
  final double stock;
  final double minStock;
  final String? barcode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLowStock => stock <= minStock;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: _asDouble(json['price']),
      cost: _asDouble(json['cost']),
      stock: _asDouble(json['stock']),
      minStock: _asDouble(json['minStock']),
      barcode: json['barcode'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sku': sku,
    'category': category,
    'price': price,
    'cost': cost,
    'stock': stock,
    'minStock': minStock,
    if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
  };
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
