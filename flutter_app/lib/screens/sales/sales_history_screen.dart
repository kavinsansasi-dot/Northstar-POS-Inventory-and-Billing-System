import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/constants.dart';
import '../../models/sale.dart';
import '../../providers/sales_provider.dart';
import '../../services/api_service.dart';
import '../../services/invoice_pdf.dart';
import '../../widgets/design_system.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _page = 1;

  SalesFilter get _filter =>
      SalesFilter(startDate: _startDate, endDate: _endDate, page: _page);

  Future<void> _selectDate({required bool start}) async {
    final value = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (value == null) return;
    setState(() {
      if (start) {
        _startDate = value;
      } else {
        _endDate = value;
      }
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(salesProvider(_filter));
    final dateFormat = DateFormat.yMMMd();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _selectDate(start: true),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _startDate == null
                      ? 'Start date'
                      : dateFormat.format(_startDate!),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _selectDate(start: false),
                icon: const Icon(Icons.event),
                label: Text(
                  _endDate == null ? 'End date' : dateFormat.format(_endDate!),
                ),
              ),
              TextButton(
                onPressed: _startDate == null && _endDate == null
                    ? null
                    : () => setState(() {
                        _startDate = null;
                        _endDate = null;
                        _page = 1;
                      }),
                child: const Text('Clear filter'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sales.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorPanel(
                message: ApiService.errorMessage(error),
                onRetry: () => ref.invalidate(salesProvider(_filter)),
              ),
              data: (result) {
                if (result.sales.isEmpty) {
                  return const Center(child: Text('No sales found.'));
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: result.sales.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _SaleCard(sale: result.sales[index]),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _page > 1
                              ? () => setState(() => _page -= 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Page $_page · ${result.total} bills'),
                        IconButton(
                          onPressed: _page * 20 < result.total
                              ? () => setState(() => _page += 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale});
  final Sale sale;

  Future<void> _reprint(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        name: invoicePdfFileName(sale),
        format: PdfPageFormat.a4,
        onLayout: (_) => buildInvoicePdf(sale, PdfPageFormat.a4),
      );
    } catch (error) {
      if (context.mounted) {
        AppToast.show(
          context,
          message: 'Could not reprint the invoice. $error',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0.00', 'en_US');
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
        title: Text(sale.invoiceNo),
        subtitle: Text(
          '${DateFormat.yMMMd().add_jm().format(sale.date)} · '
          '${sale.items.length} items · ${sale.paymentType.toUpperCase()}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$kCurrency ${currency.format(sale.total)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              tooltip: 'Reprint invoice',
              visualDensity: VisualDensity.compact,
              onPressed: () => _reprint(context),
              icon: const Icon(Icons.print_outlined),
            ),
          ],
        ),
        onTap: () => context.push('/invoice', extra: sale),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
