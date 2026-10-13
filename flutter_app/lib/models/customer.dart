import 'sale.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalPurchases,
    this.email,
    this.address,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? notes;
  final double totalPurchases;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: (json['_id'] ?? json['id'] ?? '').toString(),
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String?,
    address: json['address'] as String?,
    notes: json['notes'] as String?,
    totalPurchases: _asDouble(json['totalPurchases']),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (address != null && address!.isNotEmpty) 'address': address,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}

class CustomerDetails {
  const CustomerDetails({required this.customer, required this.recentSales});

  final Customer customer;
  final List<Sale> recentSales;

  factory CustomerDetails.fromJson(Map<String, dynamic> json) =>
      CustomerDetails(
        customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
        recentSales: (json['recentSales'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Sale.fromJson)
            .toList(),
      );
}

double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
