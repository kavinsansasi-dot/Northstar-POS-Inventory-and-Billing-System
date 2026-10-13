import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../services/api_service.dart';
import '../services/customer_service.dart';

final customersProvider = NotifierProvider<CustomersNotifier, CustomersState>(
  CustomersNotifier.new,
);

class CustomersState {
  const CustomersState({
    this.customers = const [],
    this.loading = false,
    this.error,
    this.search = '',
    this.page = 1,
    this.total = 0,
    this.totalPages = 0,
  });

  final List<Customer> customers;
  final bool loading;
  final String? error;
  final String search;
  final int page;
  final int total;
  final int totalPages;

  CustomersState copyWith({
    List<Customer>? customers,
    bool? loading,
    String? error,
    bool clearError = false,
    String? search,
    int? page,
    int? total,
    int? totalPages,
  }) => CustomersState(
    customers: customers ?? this.customers,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    search: search ?? this.search,
    page: page ?? this.page,
    total: total ?? this.total,
    totalPages: totalPages ?? this.totalPages,
  );
}

class CustomersNotifier extends Notifier<CustomersState> {
  @override
  CustomersState build() => const CustomersState();

  Future<void> load({String? search, int? page}) async {
    final next = state.copyWith(
      search: search,
      page: page,
      loading: true,
      clearError: true,
    );
    state = next;
    try {
      final result = await ref
          .read(customerServiceProvider)
          .getCustomers(search: next.search, page: next.page);
      state = next.copyWith(
        customers: result.customers,
        loading: false,
        page: result.page,
        total: result.total,
        totalPages: result.totalPages,
      );
    } catch (error) {
      state = next.copyWith(
        loading: false,
        error: ApiService.errorMessage(error),
      );
    }
  }

  Future<Customer> create(Map<String, dynamic> values) async {
    final customer = await ref
        .read(customerServiceProvider)
        .createCustomer(values);
    await load();
    return customer;
  }

  Future<Customer> update(String id, Map<String, dynamic> values) async {
    final customer = await ref
        .read(customerServiceProvider)
        .updateCustomer(id, values);
    await load();
    return customer;
  }

  Future<void> delete(Customer customer) async {
    await ref.read(customerServiceProvider).deleteCustomer(customer.id);
    await load();
  }
}
