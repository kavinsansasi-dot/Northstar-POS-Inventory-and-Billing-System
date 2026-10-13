import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import 'api_service.dart';

final customerServiceProvider = Provider<CustomerService>(
  (ref) => CustomerService(ref.read(apiServiceProvider)),
);

class CustomerPage {
  const CustomerPage({
    required this.customers,
    required this.page,
    required this.total,
    required this.totalPages,
  });

  final List<Customer> customers;
  final int page;
  final int total;
  final int totalPages;
}

class CustomerService {
  CustomerService(this._api);
  final ApiService _api;

  Future<CustomerPage> getCustomers({
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/customers',
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'limit': limit,
      },
    );
    final body = response.data ?? {};
    final pagination = body['pagination'] as Map<String, dynamic>? ?? {};
    return CustomerPage(
      customers: (body['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Customer.fromJson)
          .toList(),
      page: (pagination['page'] as num?)?.toInt() ?? page,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  Future<CustomerDetails> getCustomer(String id) async {
    final response = await _api.dio.get<Map<String, dynamic>>('/customers/$id');
    return CustomerDetails.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<Customer> createCustomer(Map<String, dynamic> values) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/customers',
      data: values,
    );
    return Customer.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Customer> updateCustomer(
    String id,
    Map<String, dynamic> values,
  ) async {
    final response = await _api.dio.put<Map<String, dynamic>>(
      '/customers/$id',
      data: values,
    );
    return Customer.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> deleteCustomer(String id) async {
    await _api.dio.delete<void>('/customers/$id');
  }
}
