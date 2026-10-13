import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/sale.dart';
import 'api_service.dart';

final saleServiceProvider = Provider<SaleService>(
  (ref) => SaleService(ref.read(apiServiceProvider)),
);

class SalesPage {
  const SalesPage({required this.sales, required this.total});
  final List<Sale> sales;
  final int total;
}

class SaleService {
  SaleService(this._api);
  final ApiService _api;

  Future<Sale> createSale({
    required List<CartItem> items,
    required double discount,
    required double tax,
    required String paymentType,
    String? customerId,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/sales',
      data: {
        'items': items
            .map((item) => {'product': item.product.id, 'qty': item.quantity})
            .toList(),
        'discount': discount,
        'tax': tax,
        'paymentType': paymentType,
        ...?customerId == null ? null : {'customer': customerId},
      },
    );
    return Sale.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<SalesPage> getSales({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    String date(DateTime value) => value.toIso8601String().split('T').first;
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/sales',
      queryParameters: {
        if (startDate != null) 'startDate': date(startDate),
        if (endDate != null) 'endDate': date(endDate),
        'page': page,
        'limit': limit,
      },
    );
    final body = response.data ?? {};
    final pagination = body['pagination'] as Map<String, dynamic>? ?? {};
    return SalesPage(
      sales: (body['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Sale.fromJson)
          .toList(),
      total: (pagination['total'] as num?)?.toInt() ?? 0,
    );
  }
}
