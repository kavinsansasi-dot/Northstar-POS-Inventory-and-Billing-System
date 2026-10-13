import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../services/api_service.dart';
import '../../services/customer_service.dart';
import '../../widgets/design_system.dart';

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key});

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersProvider.notifier).load();
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(customersProvider.notifier).load(search: value, page: 1);
    });
  }

  Future<void> _edit({Customer? customer}) async {
    await showCustomerFormDrawer(context, ref, customer: customer);
  }

  Future<void> _details(Customer customer) =>
      showCustomerDetailsDrawer(context, ref, customer);

  Future<void> _delete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.person_remove_outlined, color: context.palette.danger),
        title: const Text('Delete customer?'),
        content: Text(
          '${customer.name} will be permanently removed. Past sales remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(customersProvider.notifier).delete(customer);
      if (mounted) showAppToast(context, message: 'Customer deleted.');
    } catch (error) {
      if (mounted) {
        showAppToast(
          context,
          message: ApiService.errorMessage(error),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;
    final currency = NumberFormat.simpleCurrency();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customers',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.total} customer${state.total == 1 ? '' : 's'} in your directory',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PrimaryButton(
                label: 'Add customer',
                icon: Icons.person_add_alt_1_rounded,
                expand: false,
                onPressed: () => _edit(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SearchBarField(
              controller: _searchController,
              hint: 'Search customers by name or phone',
              onChanged: _search,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(customersProvider.notifier).load(),
              child: _buildBody(state, isAdmin, currency),
            ),
          ),
          if (state.totalPages > 1) _Pagination(state: state),
        ],
      ),
    );
  }

  Widget _buildBody(CustomersState state, bool isAdmin, NumberFormat currency) {
    if (state.loading && state.customers.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 8),
          ShimmerSkeleton(width: double.infinity, height: 64),
          SizedBox(height: 10),
          ShimmerSkeleton(width: double.infinity, height: 64),
          SizedBox(height: 10),
          ShimmerSkeleton(width: double.infinity, height: 64),
        ],
      );
    }
    if (state.error != null && state.customers.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: 260,
            child: EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load customers',
              message: state.error!,
              actionLabel: 'Try again',
              onAction: () => ref.read(customersProvider.notifier).load(),
            ),
          ),
        ],
      );
    }
    if (state.customers.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: 300,
            child: EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No customers yet',
              message: state.search.isEmpty
                  ? 'Add your first customer to keep their purchase history together.'
                  : 'No customers match “${state.search}”. Try another name or phone.',
              actionLabel: state.search.isEmpty ? 'Add customer' : null,
              onAction: state.search.isEmpty ? () => _edit() : null,
            ),
          ),
        ],
      );
    }

    return ListView(
      children: [
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.error!,
              style: TextStyle(color: context.palette.danger),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  for (final customer in state.customers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CustomerCard(
                        customer: customer,
                        currency: currency,
                        isAdmin: isAdmin,
                        onTap: () => _details(customer),
                        onEdit: () => _edit(customer: customer),
                        onDelete: () => _delete(customer),
                      ),
                    ),
                ],
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: AppDataTable(
                minWidth: 780,
                columns: const [
                  DataColumn(label: Text('CUSTOMER')),
                  DataColumn(label: Text('PHONE')),
                  DataColumn(label: Text('EMAIL')),
                  DataColumn(label: Text('TOTAL PURCHASES'), numeric: true),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: [
                  for (final customer in state.customers)
                    DataRow(
                      onSelectChanged: (_) => _details(customer),
                      cells: [
                        DataCell(_CustomerIdentity(customer: customer)),
                        DataCell(Text(customer.phone)),
                        DataCell(
                          Text(
                            customer.email?.isNotEmpty == true
                                ? customer.email!
                                : '—',
                          ),
                        ),
                        DataCell(
                          Text(currency.format(customer.totalPurchases)),
                        ),
                        DataCell(
                          _CustomerActions(
                            customer: customer,
                            isAdmin: isAdmin,
                            onDetails: () => _details(customer),
                            onEdit: () => _edit(customer: customer),
                            onDelete: () => _delete(customer),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.currency,
    required this.isAdmin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Customer customer;
  final NumberFormat currency;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _CustomerIdentity(customer: customer)),
            _CustomerActions(
              customer: customer,
              isAdmin: isAdmin,
              onDetails: onTap,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoLine(icon: Icons.phone_outlined, value: customer.phone),
        if (customer.email?.isNotEmpty == true)
          _InfoLine(icon: Icons.mail_outline_rounded, value: customer.email!),
        const SizedBox(height: 8),
        Text(
          'Total purchases  ${currency.format(customer.totalPurchases)}',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _CustomerIdentity extends StatelessWidget {
  const _CustomerIdentity({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: palette.primarySoft,
          child: Text(
            _initials(customer.name),
            style: TextStyle(
              color: palette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            customer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CustomerActions extends StatelessWidget {
  const _CustomerActions({
    required this.customer,
    required this.isAdmin,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final Customer customer;
  final bool isAdmin;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Customer actions',
    onSelected: (value) {
      if (value == 'details') onDetails();
      if (value == 'edit') onEdit();
      if (value == 'delete') onDelete();
    },
    itemBuilder: (context) => [
      const PopupMenuItem(value: 'details', child: Text('View details')),
      const PopupMenuItem(value: 'edit', child: Text('Edit')),
      if (isAdmin)
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(color: context.palette.danger),
          ),
        ),
    ],
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: context.palette.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

class _Pagination extends ConsumerWidget {
  const _Pagination({required this.state});
  final CustomersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Page ${state.page} of ${state.totalPages}'),
        IconButton(
          tooltip: 'Previous page',
          onPressed: state.page <= 1
              ? null
              : () => ref
                    .read(customersProvider.notifier)
                    .load(page: state.page - 1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: state.page >= state.totalPages
              ? null
              : () => ref
                    .read(customersProvider.notifier)
                    .load(page: state.page + 1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
  );
}

Future<Customer?> showCustomerFormDrawer(
  BuildContext context,
  WidgetRef ref, {
  Customer? customer,
}) async {
  final result = await showGeneralDialog<Customer>(
    context: context,
    barrierLabel: 'Customer editor',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      final width = MediaQuery.sizeOf(context).width;
      return SafeArea(
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: context.palette.surface,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: width < 500 ? width : 460,
              height: double.infinity,
              child: _CustomerEditor(customer: customer, ref: ref),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
  );
  if (result != null && context.mounted) {
    showAppToast(
      context,
      message: customer == null ? 'Customer added.' : 'Customer updated.',
    );
  }
  return result;
}

class _CustomerEditor extends StatefulWidget {
  const _CustomerEditor({required this.customer, required this.ref});
  final Customer? customer;
  final WidgetRef ref;

  @override
  State<_CustomerEditor> createState() => _CustomerEditorState();
}

class _CustomerEditorState extends State<_CustomerEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _name = TextEditingController(text: customer?.name ?? '');
    _phone = TextEditingController(text: customer?.phone ?? '');
    _email = TextEditingController(text: customer?.email ?? '');
    _address = TextEditingController(text: customer?.address ?? '');
    _notes = TextEditingController(text: customer?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final values = {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'notes': _notes.text.trim(),
      };
      final notifier = widget.ref.read(customersProvider.notifier);
      final saved = widget.customer == null
          ? await notifier.create(values)
          : await notifier.update(widget.customer!.id, values);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = ApiService.errorMessage(error);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.customer == null ? 'Add customer' : 'Edit customer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: _saving ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
      Divider(height: 1, color: context.palette.border),
      Expanded(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Keep contact details and purchase history in one place.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 22),
              AppTextField(
                controller: _name,
                label: 'Full name',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phone,
                label: 'Phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Phone is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _email,
                label: 'Email (optional)',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)
                      ? null
                      : 'Enter a valid email address.';
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _address,
                label: 'Address (optional)',
                prefixIcon: Icons.location_on_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _notes,
                label: 'Notes (optional)',
                prefixIcon: Icons.notes_rounded,
                textInputAction: TextInputAction.newline,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: TextStyle(color: context.palette.danger)),
              ],
            ],
          ),
        ),
      ),
      Divider(height: 1, color: context.palette.border),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Cancel',
                onPressed: _saving ? null : () => Navigator.pop(context),
                expand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: widget.customer == null
                    ? 'Add customer'
                    : 'Save changes',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<void> showCustomerDetailsDrawer(
  BuildContext context,
  WidgetRef ref,
  Customer customer,
) async {
  await showGeneralDialog<void>(
    context: context,
    barrierLabel: 'Customer details',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      final width = MediaQuery.sizeOf(context).width;
      return SafeArea(
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: context.palette.surface,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: width < 500 ? width : 500,
              height: double.infinity,
              child: _CustomerDetailsPanel(customer: customer, ref: ref),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
  );
}

class _CustomerDetailsPanel extends StatelessWidget {
  const _CustomerDetailsPanel({required this.customer, required this.ref});
  final Customer customer;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Customer details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
      Divider(height: 1, color: context.palette.border),
      Expanded(
        child: FutureBuilder<CustomerDetails>(
          future: ref.read(customerServiceProvider).getCustomer(customer.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load customer',
                message: ApiService.errorMessage(snapshot.error!),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerSkeleton(width: 140, height: 24),
                      SizedBox(height: 16),
                      ShimmerSkeleton(width: double.infinity, height: 60),
                    ],
                  ),
                ),
              );
            }
            return _CustomerDetailsContent(details: snapshot.data!);
          },
        ),
      ),
    ],
  );
}

class _CustomerDetailsContent extends StatelessWidget {
  const _CustomerDetailsContent({required this.details});
  final CustomerDetails details;

  @override
  Widget build(BuildContext context) {
    final customer = details.customer;
    final currency = NumberFormat.simpleCurrency();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: context.palette.primarySoft,
                child: Text(
                  _initials(customer.name),
                  style: TextStyle(
                    color: context.palette.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                customer.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                customer.phone,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              _DetailLine(
                label: 'Email',
                value: customer.email ?? 'Not provided',
              ),
              _DetailLine(
                label: 'Address',
                value: customer.address ?? 'Not provided',
              ),
              if (customer.notes?.isNotEmpty == true)
                _DetailLine(label: 'Notes', value: customer.notes!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lifetime purchases',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                currency.format(customer.totalPurchases),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Recent purchase history',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (details.recentSales.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No purchases yet',
            message: 'Purchases linked to this customer will appear here.',
          )
        else
          for (final sale in details.recentSales)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.invoiceNo,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat.yMMMd().format(sale.date)} · ${sale.items.length} items · ${sale.paymentType.toUpperCase()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currency.format(sale.total),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
  return initials.isEmpty ? '?' : initials;
}
