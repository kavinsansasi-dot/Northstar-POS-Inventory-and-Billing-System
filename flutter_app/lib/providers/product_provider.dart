import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';

final productsProvider = NotifierProvider<ProductsNotifier, ProductsState>(
  ProductsNotifier.new,
);

class ProductsState {
  const ProductsState({
    this.products = const [],
    this.loading = false,
    this.error,
    this.search = '',
    this.category = '',
    this.page = 1,
    this.total = 0,
    this.totalPages = 0,
  });

  final List<Product> products;
  final bool loading;
  final String? error;
  final String search;
  final String category;
  final int page;
  final int total;
  final int totalPages;

  ProductsState copyWith({
    List<Product>? products,
    bool? loading,
    String? error,
    bool clearError = false,
    String? search,
    String? category,
    int? page,
    int? total,
    int? totalPages,
  }) => ProductsState(
    products: products ?? this.products,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    search: search ?? this.search,
    category: category ?? this.category,
    page: page ?? this.page,
    total: total ?? this.total,
    totalPages: totalPages ?? this.totalPages,
  );
}

class ProductsNotifier extends Notifier<ProductsState> {
  @override
  ProductsState build() => const ProductsState();

  Future<void> load({String? search, String? category, int? page}) async {
    final next = state.copyWith(
      search: search,
      category: category,
      page: page,
      loading: true,
      clearError: true,
    );
    state = next;
    try {
      final result = await ref
          .read(productServiceProvider)
          .getProducts(
            search: next.search,
            category: next.category,
            page: next.page,
          );
      state = next.copyWith(
        products: result.products,
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

  Future<void> delete(Product product) async {
    await ref.read(productServiceProvider).deleteProduct(product.id);
    await load();
  }
}
