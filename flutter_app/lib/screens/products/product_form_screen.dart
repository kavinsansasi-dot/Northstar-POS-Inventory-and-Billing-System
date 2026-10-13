import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/api_service.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({this.product, this.productId, super.key});

  final Product? product;
  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _cost = TextEditingController(text: '0');
  final _stock = TextEditingController(text: '0');
  final _minStock = TextEditingController(text: '0');
  final _barcode = TextEditingController();
  Product? _product;
  bool _loadingExisting = false;
  bool _loadFailed = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    if (_product != null) {
      _fill(_product!);
    } else if (widget.productId != null) {
      _loadingExisting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    }
  }

  void _fill(Product product) {
    _name.text = product.name;
    _sku.text = product.sku;
    _category.text = product.category;
    _price.text = '${product.price}';
    _cost.text = '${product.cost}';
    _stock.text = '${product.stock}';
    _minStock.text = '${product.minStock}';
    _barcode.text = product.barcode ?? '';
  }

  Future<void> _loadProduct() async {
    try {
      final product = await ref
          .read(productServiceProvider)
          .getProduct(widget.productId!);
      if (mounted) {
        setState(() {
          _product = product;
          _loadingExisting = false;
        });
        _fill(product);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadingExisting = false;
          _loadFailed = true;
          _error = ApiService.errorMessage(error);
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _category.dispose();
    _price.dispose();
    _cost.dispose();
    _stock.dispose();
    _minStock.dispose();
    _barcode.dispose();
    super.dispose();
  }

  String? _requiredText(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  String? _number(String? value, String label) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || !parsed.isFinite) return 'Enter a valid $label.';
    if (parsed < 0) return '$label cannot be negative.';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final values = <String, dynamic>{
      'name': _name.text.trim(),
      'sku': _sku.text.trim(),
      'category': _category.text.trim(),
      'price': double.parse(_price.text.trim()),
      'cost': double.parse(_cost.text.trim()),
      'stock': double.parse(_stock.text.trim()),
      'minStock': double.parse(_minStock.text.trim()),
      'barcode': _barcode.text.trim(),
    };
    try {
      final service = ref.read(productServiceProvider);
      if (_product == null) {
        await service.createProduct(values);
      } else {
        await service.updateProduct(_product!.id, values);
      }
      if (!mounted) return;
      await ref.read(productsProvider.notifier).load();
      if (mounted) context.go('/products');
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ApiService.errorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingExisting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Could not load this product.'),
            TextButton(onPressed: _loadProduct, child: const Text('Retry')),
            TextButton(
              onPressed: () => context.go('/products'),
              child: const Text('Back to products'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _product == null ? 'Add product' : 'Edit product',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 520;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _field(
                              constraints,
                              wide,
                              CustomTextField(
                                controller: _name,
                                label: 'Name',
                                validator: (value) =>
                                    _requiredText(value, 'Name'),
                              ),
                            ),
                            _field(
                              constraints,
                              wide,
                              CustomTextField(
                                controller: _sku,
                                label: 'SKU',
                                validator: (value) =>
                                    _requiredText(value, 'SKU'),
                              ),
                            ),
                            _field(
                              constraints,
                              wide,
                              CustomTextField(
                                controller: _category,
                                label: 'Category',
                                validator: (value) =>
                                    _requiredText(value, 'Category'),
                              ),
                            ),
                            _field(
                              constraints,
                              wide,
                              CustomTextField(
                                controller: _barcode,
                                label: 'Barcode (optional)',
                              ),
                            ),
                            _field(
                              constraints,
                              wide,
                              _numericField(_price, 'Price'),
                            ),
                            _field(
                              constraints,
                              wide,
                              _numericField(_cost, 'Cost'),
                            ),
                            _field(
                              constraints,
                              wide,
                              _numericField(_stock, 'Stock'),
                            ),
                            _field(
                              constraints,
                              wide,
                              _numericField(_minStock, 'Minimum stock'),
                            ),
                          ],
                        );
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    CustomButton(
                      label: _product == null
                          ? 'Create product'
                          : 'Save changes',
                      loading: _saving,
                      onPressed: _save,
                    ),
                    TextButton(
                      onPressed: () => context.go('/products'),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numericField(TextEditingController controller, String label) =>
      CustomTextField(
        controller: controller,
        label: label,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => _number(value, label.toLowerCase()),
      );

  Widget _field(BoxConstraints constraints, bool wide, Widget child) =>
      SizedBox(
        width: wide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth,
        child: child,
      );
}
