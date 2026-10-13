import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/sale.dart';
import '../../services/invoice_pdf_download.dart';
import '../../services/invoice_pdf.dart';
import '../../widgets/design_system.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({required this.sale, super.key});

  final Sale sale;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  static const _formatPreferenceKey = 'northstar_invoice_format';
  PdfPageFormat _pageFormat = PdfPageFormat.a4;
  bool _actionInProgress = false;

  Sale get sale => widget.sale;

  @override
  void initState() {
    super.initState();
    _restoreFormat();
  }

  Future<void> _restoreFormat() async {
    final preferences = await SharedPreferences.getInstance();
    final formatName = preferences.getString(_formatPreferenceKey);
    if (!mounted || formatName == null) return;
    setState(() {
      _pageFormat = formatName == 'thermal'
          ? PdfPageFormat.roll80
          : PdfPageFormat.a4;
    });
  }

  Future<void> _selectFormat(bool thermal) async {
    final nextFormat = thermal ? PdfPageFormat.roll80 : PdfPageFormat.a4;
    if (_pageFormat == nextFormat) return;
    setState(() => _pageFormat = nextFormat);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _formatPreferenceKey,
      thermal ? 'thermal' : 'a4',
    );
  }

  Future<void> _printInvoice() async {
    await _performAction(() async {
      await Printing.layoutPdf(
        name: invoicePdfFileName(sale),
        format: _pageFormat,
        dynamicLayout: false,
        onLayout: (_) => buildInvoicePdf(sale, _pageFormat),
      );
    }, 'Could not print the invoice.');
  }

  Future<void> _downloadInvoice() async {
    await _performAction(() async {
      final bytes = await buildInvoicePdf(sale, _pageFormat);
      await downloadInvoicePdf(bytes, invoicePdfFileName(sale));
    }, 'Could not download the invoice PDF.');
  }

  Future<void> _shareInvoice() async {
    await _performAction(() async {
      final bytes = await buildInvoicePdf(sale, _pageFormat);
      await Printing.sharePdf(bytes: bytes, filename: invoicePdfFileName(sale));
    }, 'Could not share the invoice PDF.');
  }

  Future<void> _performAction(
    Future<void> Function() action,
    String errorMessage,
  ) async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        AppToast.show(context, message: '$errorMessage $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shortNumber = invoiceDisplayNumber(sale);
    final currency = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/billing'),
              icon: const Icon(Icons.point_of_sale_rounded),
              label: const Text('Back to Billing'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 660;
                  final formatToggle = SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.description_outlined),
                        label: Text('A4'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.receipt_outlined),
                        label: Text('80mm'),
                      ),
                    ],
                    selected: {_pageFormat == PdfPageFormat.roll80},
                    onSelectionChanged: _actionInProgress
                        ? null
                        : (selection) => _selectFormat(selection.first),
                  );
                  final buttons = Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      FilledButton.icon(
                        onPressed: _actionInProgress ? null : _printInvoice,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Print'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _actionInProgress ? null : _downloadInvoice,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Download PDF'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _actionInProgress ? null : _shareInvoice,
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$shortNumber · ${kShopInfo.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            formatToggle,
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        buttons,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$shortNumber · ${kShopInfo.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      formatToggle,
                      const SizedBox(width: AppSpacing.md),
                      buttons,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AppCard(
                padding: EdgeInsets.zero,
                child: PdfPreview(
                  key: ValueKey(_pageFormat),
                  build: (format) => buildInvoicePdf(sale, _pageFormat),
                  initialPageFormat: _pageFormat,
                  pageFormats: {
                    _pageFormat == PdfPageFormat.roll80 ? '80mm' : 'A4':
                        _pageFormat,
                  },
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  useActions: false,
                  maxPageWidth: _pageFormat == PdfPageFormat.roll80 ? 420 : 900,
                  pdfFileName: invoicePdfFileName(sale),
                  loadingWidget: const Center(
                    child: ShimmerSkeleton(width: 180, height: 22),
                  ),
                  scrollViewDecoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${DateFormat.yMMMd().add_jm().format(sale.date)}'
              '  ·  ${sale.items.length} items'
              '  ·  $kCurrency ${currency.format(sale.total)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
