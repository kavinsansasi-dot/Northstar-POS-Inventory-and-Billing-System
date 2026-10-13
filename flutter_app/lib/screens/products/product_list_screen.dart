import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(productsProvider.notifier).load(search: value, page: 1);
    });
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('“${product.name}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(productsProvider.notifier).delete(product);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_message(error))));
      }
    }
  }

  String _message(Object error) => ApiService.errorMessage(error);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;
    final categories = state.products
        .map((product) => product.category)
        .toSet()
        .toList();
    if (state.category.isNotEmpty && !categories.contains(state.category)) {
      categories.add(state.category);
    }
    categories.sort();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 600;
              final searchWidth = narrow
                  ? constraints.maxWidth
                  : constraints.maxWidth - 210 - (isAdmin ? 145 : 0);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: searchWidth,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _search,
                      decoration: const InputDecoration(
                        hintText: 'Search name, SKU, category or barcode',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: narrow ? constraints.maxWidth : 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.category.isEmpty
                          ? ''
                          : state.category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('All categories'),
                        ),
                        ...categories.map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        ),
                      ],
                      onChanged: (value) => ref
                          .read(productsProvider.notifier)
                          .load(category: value ?? '', page: 1),
                    ),
                  ),
                  if (isAdmin)
                    FilledButton.icon(
                      onPressed: () async {
                        await context.push('/products/new');
                        if (mounted) ref.read(productsProvider.notifier).load();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add product'),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(productsProvider.notifier).load(),
              child: _buildBody(state, isAdmin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ProductsState state, bool isAdmin) {
    if (state.loading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.products.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 90),
          Center(child: Text(state.error!)),
          Center(
            child: TextButton(
              onPressed: () => ref.read(productsProvider.notifier).load(),
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }
    if (state.products.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No products found.')),
        ],
      );
    }

    return ListView(
      children: [
        if (state.error != null)
          MaterialBanner(
            content: Text(state.error!),
            actions: [
              TextButton(
                onPressed: () => ref.read(productsProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 250).floor().clamp(1, 5);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 195,
              ),
              itemBuilder: (context, index) {
                final product = state.products[index];
                return ProductCard(
                  product: product,
                  isAdmin: isAdmin,
                  onTap: () {},
                  onEdit: () async {
                    await context.push(
                      '/products/edit/${product.id}',
                      extra: product,
                    );
                    if (mounted) ref.read(productsProvider.notifier).load();
                  },
                  onDelete: () => _delete(product),
                );
              },
            );
          },
        ),
        if (state.totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: state.page > 1
                      ? () => ref
                            .read(productsProvider.notifier)
                            .load(page: state.page - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${state.page} / ${state.totalPages}  (${state.total})'),
                IconButton(
                  onPressed: state.page < state.totalPages
                      ? () => ref
                            .read(productsProvider.notifier)
                            .load(page: state.page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
