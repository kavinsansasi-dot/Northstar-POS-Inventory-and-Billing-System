import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import 'api_service.dart';

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(ref.read(apiServiceProvider)),
);

class ProductPage {
  const ProductPage({
    required this.products,
    required this.page,
    required this.total,
    required this.totalPages,
  });

  final List<Product> products;
  final int page;
  final int total;
  final int totalPages;
}

class ProductService {
  ProductService(this._api);
  final ApiService _api;

  Future<ProductPage> getProducts({
    String search = '',
    String category = '',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (category.isNotEmpty) 'category': category,
        'page': page,
        'limit': limit,
      },
    );
    final body = response.data ?? {};
    final pagination = body['pagination'] as Map<String, dynamic>? ?? {};
    return ProductPage(
      products: (body['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(),
      page: (pagination['page'] as num?)?.toInt() ?? page,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Product> getProduct(String id) async {
    final response = await _api.dio.get<Map<String, dynamic>>('/products/$id');
    return Product.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Product> createProduct(Map<String, dynamic> values) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/products',
      data: values,
    );
    return Product.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> values) async {
    final response = await _api.dio.put<Map<String, dynamic>>(
      '/products/$id',
      data: values,
    );
    return Product.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) async {
    await _api.dio.delete<void>('/products/$id');
  }
}
