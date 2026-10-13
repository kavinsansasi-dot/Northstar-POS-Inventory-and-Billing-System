import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/api_service.dart';
import '../../services/sale_service.dart';
import '../../widgets/cart_tile.dart';
import '../../widgets/design_system.dart';
import '../../widgets/product_card.dart';
import '../customers/customer_screen.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  final _cashReceivedController = TextEditingController();
  bool _checkoutLoading = false;
  String _paymentType = 'cash';
  Customer? _customer;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cashReceivedController.dispose();
    super.dispose();
  }

  Future<void> _editAmount({
    required String title,
    required double current,
    required ValueChanged<double> onSave,
  }) async {
    final controller = TextEditingController(text: '$current');
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount >= 0) Navigator.pop(context, amount);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) onSave(value);
  }

  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;
    final receivedAmount = double.tryParse(_cashReceivedController.text.trim());
    if (_paymentType == 'cash' &&
        (receivedAmount == null || receivedAmount < cart.total)) {
      setState(() => _error = 'Amount received must cover the total.');
      return;
    }
    setState(() {
      _checkoutLoading = true;
      _error = null;
    });
    try {
      final saleResponse = await ref
          .read(saleServiceProvider)
          .createSale(
            items: cart.items,
            discount: cart.discount,
            tax: cart.tax,
            paymentType: _paymentType,
            customerId: _customer?.id,
          );
      final cashierName = ref.read(authProvider).user?.name;
      final sale = saleResponse.copyWith(
        cashierName: cashierName,
        customerName: _customer?.name,
        customerPhone: _customer?.phone,
        receivedAmount: _paymentType == 'cash' ? receivedAmount : null,
        changeAmount: _paymentType == 'cash'
            ? (receivedAmount! - cart.total)
            : null,
      );
      ref.read(cartProvider.notifier).clear();
      await ref.read(productsProvider.notifier).load();
      if (mounted) context.push('/invoice', extra: sale);
    } catch (error) {
      if (mounted) {
        setState(() => _error = ApiService.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _checkoutLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final filtered = products.products
        .where((product) => product.stock > 0)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _ProductPicker(
                    searchController: _searchController,
                    products: filtered,
                    loading: products.loading,
                    error: products.error,
                    onSearch: (value) => ref
                        .read(productsProvider.notifier)
                        .load(search: value, page: 1),
                    onAdd: (product) =>
                        ref.read(cartProvider.notifier).add(product),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 380,
                  child: _CartPanel(
                    selectedCustomer: _customer,
                    paymentType: _paymentType,
                    cashReceivedController: _cashReceivedController,
                    onCashReceivedChanged: () => setState(() {}),
                    loading: _checkoutLoading,
                    error: _error,
                    onPaymentChanged: (value) =>
                        setState(() => _paymentType = value),
                    onCustomerChanged: (value) =>
                        setState(() => _customer = value),
                    onAddCustomer: _addCustomer,
                    onDiscount: () => _editAmount(
                      title: 'Set discount',
                      current: cart.discount,
                      onSave: ref.read(cartProvider.notifier).setDiscount,
                    ),
                    onTax: () => _editAmount(
                      title: 'Set tax',
                      current: cart.tax,
                      onSave: ref.read(cartProvider.notifier).setTax,
                    ),
                    onCheckout: _checkout,
                  ),
                ),
              ],
            );
          }
          return ListView(
            children: [
              SizedBox(
                height: 460,
                child: _ProductPicker(
                  searchController: _searchController,
                  products: filtered,
                  loading: products.loading,
                  error: products.error,
                  onSearch: (value) => ref
                      .read(productsProvider.notifier)
                      .load(search: value, page: 1),
                  onAdd: (product) =>
                      ref.read(cartProvider.notifier).add(product),
                ),
              ),
              const SizedBox(height: 16),
              _CartPanel(
                selectedCustomer: _customer,
                paymentType: _paymentType,
                cashReceivedController: _cashReceivedController,
                onCashReceivedChanged: () => setState(() {}),
                loading: _checkoutLoading,
                error: _error,
                onPaymentChanged: (value) =>
                    setState(() => _paymentType = value),
                onCustomerChanged: (value) => setState(() => _customer = value),
                onAddCustomer: _addCustomer,
                onDiscount: () => _editAmount(
                  title: 'Set discount',
                  current: cart.discount,
                  onSave: ref.read(cartProvider.notifier).setDiscount,
                ),
                onTax: () => _editAmount(
                  title: 'Set tax',
                  current: cart.tax,
                  onSave: ref.read(cartProvider.notifier).setTax,
                ),
                onCheckout: _checkout,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addCustomer() async {
    final customer = await showCustomerFormDrawer(context, ref);
    if (customer != null && mounted) {
      setState(() => _customer = customer);
    }
  }
}

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({
    required this.searchController,
    required this.products,
    required this.loading,
    required this.onSearch,
    required this.onAdd,
    this.error,
  });

  final TextEditingController searchController;
  final List<Product> products;
  final bool loading;
  final String? error;
  final ValueChanged<String> onSearch;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        controller: searchController,
        onChanged: onSearch,
        decoration: const InputDecoration(
          hintText: 'Find product by name, SKU or barcode',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 12),
      if (loading && products.isEmpty)
        const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (error != null && products.isEmpty)
        Expanded(
          child: Center(child: Text(error!, textAlign: TextAlign.center)),
        )
      else if (products.isEmpty)
        const Expanded(child: Center(child: Text('No available products.')))
      else
        Expanded(
          child: GridView.builder(
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              mainAxisExtent: 185,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(product: product, onTap: () => onAdd(product));
            },
          ),
        ),
    ],
  );
}

class _CartPanel extends ConsumerWidget {
  const _CartPanel({
    required this.selectedCustomer,
    required this.paymentType,
    required this.cashReceivedController,
    required this.onCashReceivedChanged,
    required this.loading,
    required this.error,
    required this.onPaymentChanged,
    required this.onCustomerChanged,
    required this.onAddCustomer,
    required this.onDiscount,
    required this.onTax,
    required this.onCheckout,
  });

  final String paymentType;
  final Customer? selectedCustomer;
  final TextEditingController cashReceivedController;
  final VoidCallback onCashReceivedChanged;
  final bool loading;
  final String? error;
  final ValueChanged<String> onPaymentChanged;
  final ValueChanged<Customer?> onCustomerChanged;
  final VoidCallback onAddCustomer;
  final VoidCallback onDiscount;
  final VoidCallback onTax;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final currency = NumberFormat.currency(
      locale: 'en_US',
      symbol: '$kCurrency ',
      decimalDigits: 2,
    );
    final receivedAmount =
        double.tryParse(cashReceivedController.text.trim()) ?? 0;
    final changeAmount = (receivedAmount - cart.total).clamp(
      0,
      double.infinity,
    );
    final cashPaymentReady =
        paymentType != 'cash' || receivedAmount >= cart.total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Current bill',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text('${cart.itemCount} items'),
                IconButton(
                  tooltip: 'Clear cart',
                  onPressed: cart.items.isEmpty ? null : notifier.clear,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
            const Divider(),
            _CustomerPicker(
              selected: selectedCustomer,
              onSelected: onCustomerChanged,
              onAddCustomer: onAddCustomer,
            ),
            const SizedBox(height: 8),
            if (cart.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tap a product to add it to the bill.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...cart.items.map(
                (item) => CartTile(
                  item: item,
                  onQuantityChanged: (quantity) =>
                      notifier.setQuantity(item.product.id, quantity),
                  onRemove: () => notifier.remove(item.product.id),
                ),
              ),
            const Divider(),
            _SummaryLine(
              label: 'Subtotal',
              value: currency.format(cart.subtotal),
            ),
            _SummaryLine(
              label: 'Discount',
              value: currency.format(cart.discount),
              onTap: onDiscount,
            ),
            _SummaryLine(
              label: 'Tax',
              value: currency.format(cart.tax),
              onTap: onTax,
            ),
            _SummaryLine(
              label: 'Total',
              value: currency.format(cart.total),
              bold: true,
            ),
            const SizedBox(height: 12),
            if (paymentType == 'cash') ...[
              TextField(
                controller: cashReceivedController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount received',
                  prefixText: '$kCurrency ',
                ),
                onChanged: (_) => onCashReceivedChanged(),
              ),
              const SizedBox(height: 8),
              _SummaryLine(
                label: 'Change to return',
                value: currency.format(changeAmount),
                bold: true,
              ),
              const SizedBox(height: 8),
            ],
            DropdownButtonFormField<String>(
              initialValue: paymentType,
              decoration: const InputDecoration(labelText: 'Payment type'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
              ],
              onChanged: (value) {
                if (value != null) onPaymentChanged(value);
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: cart.items.isEmpty || loading || !cashPaymentReady
                  ? null
                  : onCheckout,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerPicker extends StatelessWidget {
  const _CustomerPicker({
    required this.selected,
    required this.onSelected,
    required this.onAddCustomer,
  });

  final Customer? selected;
  final ValueChanged<Customer?> onSelected;
  final VoidCallback onAddCustomer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final customer = await showDialog<Customer?>(
          context: context,
          builder: (context) => _CustomerSelectDialog(
            selected: selected,
            onAddCustomer: onAddCustomer,
          ),
        );
        if (customer != null) onSelected(customer);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: palette.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected?.name ?? 'Select customer (optional)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    selected?.phone ?? 'Link this sale to a customer',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected != null)
              IconButton(
                tooltip: 'Remove customer',
                visualDensity: VisualDensity.compact,
                onPressed: () => onSelected(null),
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            else
              const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }
}

class _CustomerSelectDialog extends ConsumerStatefulWidget {
  const _CustomerSelectDialog({
    required this.selected,
    required this.onAddCustomer,
  });

  final Customer? selected;
  final VoidCallback onAddCustomer;

  @override
  ConsumerState<_CustomerSelectDialog> createState() =>
      _CustomerSelectDialogState();
}

class _CustomerSelectDialogState extends ConsumerState<_CustomerSelectDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersProvider.notifier).load(search: '');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(customersProvider.notifier).load(search: value, page: 1);
    });
  }

  Future<void> _add() async {
    Navigator.of(context).pop();
    widget.onAddCustomer();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    return AlertDialog(
      title: const Text('Select a customer'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            AppTextField(
              controller: _controller,
              label: 'Search name or phone',
              prefixIcon: Icons.search_rounded,
              onChanged: _search,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: state.loading && state.customers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.customers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.error!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: () => ref
                                .read(customersProvider.notifier)
                                .load(search: _controller.text),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    )
                  : state.customers.isEmpty
                  ? const Center(child: Text('No matching customers.'))
                  : ListView.builder(
                      itemCount: state.customers.length,
                      itemBuilder: (context, index) {
                        final customer = state.customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(_customerInitials(customer.name)),
                          ),
                          title: Text(customer.name),
                          subtitle: Text(customer.phone),
                          trailing: customer.id == widget.selected?.id
                              ? const Icon(Icons.check_circle)
                              : null,
                          onTap: () => Navigator.of(context).pop(customer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add new customer'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

String _customerInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final result = parts.take(2).map((part) => part[0].toUpperCase()).join();
  return result.isEmpty ? '?' : result;
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.bold = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool bold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(label, style: style),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 14),
            ],
            const Spacer(),
            Text(value, style: style),
          ],
        ),
      ),
    );
  }
}
