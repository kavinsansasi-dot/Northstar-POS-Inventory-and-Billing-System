import 'package:barcode/barcode.dart' as barcode;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants.dart';
import '../models/sale.dart';

const PdfColor _indigo = PdfColor(0.31, 0.27, 0.90);
const PdfColor _violet = PdfColor(0.49, 0.23, 0.93);
const PdfColor _softIndigo = PdfColor(0.933, 0.949, 1);
const PdfColor _border = PdfColor(0.898, 0.906, 0.922);
const PdfColor _text = PdfColor(0.067, 0.094, 0.153);
const PdfColor _muted = PdfColor(0.42, 0.45, 0.50);
const PdfColor _green = PdfColor(0.063, 0.725, 0.506);
const PdfColor _lightRow = PdfColor(0.976, 0.980, 0.992);

Future<Uint8List> buildInvoicePdf(Sale sale, PdfPageFormat format) async {
  final fonts = await _loadFonts();
  final logo = await _loadLogo();
  final document = pw.Document(
    theme: pw.ThemeData.withFont(base: fonts.body, bold: fonts.bodyBold),
  );

  if (format.width < 120 * PdfPageFormat.mm) {
    document.addPage(
      pw.MultiPage(
        pageFormat: format.copyWith(height: _thermalPageHeight(sale)),
        margin: const pw.EdgeInsets.symmetric(
          horizontal: 7 * PdfPageFormat.mm,
          vertical: 8 * PdfPageFormat.mm,
        ),
        maxPages: 100,
        theme: pw.ThemeData.withFont(base: fonts.body, bold: fonts.bodyBold),
        build: (context) => _thermalContent(sale, fonts, logo),
      ),
    );
  } else {
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        maxPages: 100,
        theme: pw.ThemeData.withFont(base: fonts.body, bold: fonts.bodyBold),
        build: (context) => _a4Content(sale, fonts, logo),
      ),
    );
  }

  return document.save();
}

double _thermalPageHeight(Sale sale) {
  const estimatedCharactersPerLine = 26;
  const baseHeight = 170.0;
  const itemHeight = 16.0;
  const wrappedLineHeight = 4.0;
  final itemContentHeight = sale.items.fold<double>(
    0,
    (height, item) =>
        height +
        itemHeight +
        ((item.name.length + estimatedCharactersPerLine - 1) ~/
                estimatedCharactersPerLine) *
            wrappedLineHeight,
  );
  return (baseHeight + itemContentHeight) * PdfPageFormat.mm;
}

String invoiceDisplayNumber(Sale sale) {
  final storedNumber = sale.invoiceNo.trim();
  final suffix = storedNumber.length <= 6
      ? storedNumber
      : storedNumber.substring(storedNumber.length - 6);
  return 'INV-${suffix.toUpperCase()}';
}

String invoicePdfFileName(Sale sale) =>
    'Northstar-${invoiceDisplayNumber(sale)}.pdf';

String invoiceQrCodeData(Sale sale) =>
    '${kShopInfo.name}\n'
    'Invoice: ${invoiceDisplayNumber(sale)}\n'
    'Date: ${DateFormat('dd MMM yyyy h:mm a').format(sale.date)}\n'
    'Total: ${_currency(sale.total)}\n'
    'Payment: ${sale.paymentType}';

String _formatAmount(double amount) =>
    NumberFormat('#,##0.00', 'en_US').format(amount);

String _currency(double amount) => '$kCurrency ${_formatAmount(amount)}';

Future<_InvoiceFonts> _loadFonts() async => _InvoiceFonts(
  body: await PdfGoogleFonts.interRegular(),
  bodyBold: await PdfGoogleFonts.interBold(),
  heading: await PdfGoogleFonts.plusJakartaSansRegular(),
  headingBold: await PdfGoogleFonts.plusJakartaSansBold(),
);

Future<pw.MemoryImage?> _loadLogo() async {
  final path = kShopInfo.logoAsset;
  if (path == null || path.isEmpty) return null;
  final data = await rootBundle.load(path);
  return pw.MemoryImage(data.buffer.asUint8List());
}

class _InvoiceFonts {
  const _InvoiceFonts({
    required this.body,
    required this.bodyBold,
    required this.heading,
    required this.headingBold,
  });

  final pw.Font body;
  final pw.Font bodyBold;
  final pw.Font heading;
  final pw.Font headingBold;
}

pw.TextStyle _body(
  _InvoiceFonts fonts, {
  double size = 9,
  PdfColor color = _text,
  bool bold = false,
}) => pw.TextStyle(
  font: bold ? fonts.bodyBold : fonts.body,
  fontSize: size,
  color: color,
);

pw.TextStyle _heading(
  _InvoiceFonts fonts, {
  double size = 12,
  PdfColor color = _text,
  bool bold = false,
}) => pw.TextStyle(
  font: bold ? fonts.headingBold : fonts.heading,
  fontSize: size,
  color: color,
);

List<pw.Widget> _a4Content(
  Sale sale,
  _InvoiceFonts fonts,
  pw.MemoryImage? logo,
) => [
  _a4Header(sale, fonts, logo),
  pw.SizedBox(height: 22),
  pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 36),
    child: pw.TableHelper.fromTextArray(
      headers: const ['ITEM', 'QTY', 'PRICE', 'AMOUNT'],
      headerCount: 1,
      headerHeight: 34,
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      headerStyle: _body(fonts, size: 8, color: _indigo, bold: true),
      cellStyle: _body(fonts, size: 9),
      headerDecoration: const pw.BoxDecoration(color: _softIndigo),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: _lightRow),
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: _border, width: 0.6),
        bottom: const pw.BorderSide(color: _border, width: 0.6),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(4.5),
        1: const pw.FlexColumnWidth(0.9),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(1.7),
      },
      headerAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      data: sale.items
          .map(
            (item) => [
              item.name,
              _formatQuantity(item.quantity),
              _currency(item.price),
              _currency(item.price * item.quantity),
            ],
          )
          .toList(),
    ),
  ),
  pw.SizedBox(height: 24),
  pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 36),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _thankYou(fonts, centered: false)),
        pw.SizedBox(width: 28),
        pw.SizedBox(width: 240, child: _a4Totals(sale, fonts)),
      ],
    ),
  ),
  pw.SizedBox(height: 26),
  pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 36),
    child: _a4Footer(sale, fonts),
  ),
  pw.SizedBox(height: 28),
];

pw.Widget _a4Header(Sale sale, _InvoiceFonts fonts, pw.MemoryImage? logo) =>
    pw.SizedBox(
      height: 224,
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: pw.SizedBox(
              height: 178,
              child: pw.ClipRect(
                child: pw.Stack(
                  children: [
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        gradient: pw.LinearGradient(
                          begin: pw.Alignment.topLeft,
                          end: pw.Alignment.bottomRight,
                          colors: [_indigo, _violet],
                        ),
                      ),
                    ),
                    pw.Positioned(
                      right: -34,
                      top: -74,
                      child: _softCircle(215, 0.10),
                    ),
                    pw.Positioned(
                      right: 150,
                      bottom: -86,
                      child: _softCircle(150, 0.08),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.fromLTRB(36, 32, 36, 54),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _logoMark(logo, 42),
                                pw.SizedBox(width: 12),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        kShopInfo.name,
                                        style: _heading(
                                          fonts,
                                          size: 19,
                                          color: PdfColors.white,
                                          bold: true,
                                        ),
                                      ),
                                      pw.SizedBox(height: 5),
                                      pw.Text(
                                        kShopInfo.address,
                                        style: _body(
                                          fonts,
                                          size: 9,
                                          color: PdfColors.white,
                                        ),
                                      ),
                                      pw.SizedBox(height: 3),
                                      pw.Text(
                                        kShopInfo.phone,
                                        style: _body(
                                          fonts,
                                          size: 9,
                                          color: PdfColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'INVOICE',
                                style: _heading(
                                  fonts,
                                  size: 26,
                                  color: PdfColors.white,
                                  bold: true,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                '#${invoiceDisplayNumber(sale)}',
                                style: _body(
                                  fonts,
                                  size: 11,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          pw.Positioned(
            top: 128,
            left: 36,
            right: 36,
            child: _a4InfoCard(sale, fonts),
          ),
        ],
      ),
    );

pw.Widget _softCircle(double size, double opacity) => pw.Container(
  width: size,
  height: size,
  decoration: pw.BoxDecoration(
    color: PdfColor(1, 1, 1, opacity),
    shape: pw.BoxShape.circle,
  ),
);

pw.Widget _logoMark(pw.MemoryImage? logo, double size) => pw.Container(
  width: size,
  height: size,
  padding: const pw.EdgeInsets.all(7),
  decoration: pw.BoxDecoration(
    color: PdfColor(1, 1, 1, 0.96),
    borderRadius: pw.BorderRadius.circular(12),
  ),
  child: logo == null
      ? pw.Center(
          child: pw.Text(
            'N',
            style: pw.TextStyle(
              fontSize: size * 0.58,
              fontWeight: pw.FontWeight.bold,
              color: _indigo,
            ),
          ),
        )
      : pw.Image(logo, fit: pw.BoxFit.contain),
);

pw.Widget _a4InfoCard(Sale sale, _InvoiceFonts fonts) {
  final customerVisible =
      _hasText(sale.customerName) || _hasText(sale.customerPhone);
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: _border, width: 0.8),
      borderRadius: pw.BorderRadius.circular(14),
      boxShadow: const [
        pw.BoxShadow(
          color: PdfColor(0.06, 0.09, 0.16, 0.08),
          blurRadius: 12,
          offset: PdfPoint(0, 3),
        ),
      ],
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (customerVisible)
          pw.Expanded(
            child: _infoColumn(fonts, 'BILLED TO', [
              if (_hasText(sale.customerName)) sale.customerName!,
              if (_hasText(sale.customerPhone)) sale.customerPhone!,
            ]),
          ),
        if (customerVisible) _verticalDivider(),
        pw.Expanded(
          child: _infoColumn(fonts, 'DATE', [
            DateFormat.yMMMd().format(sale.date),
            DateFormat.jm().format(sale.date),
          ]),
        ),
        _verticalDivider(),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _label(fonts, 'PAYMENT'),
              pw.SizedBox(height: 7),
              pw.Row(
                children: [
                  _badge(
                    sale.paymentType.toUpperCase(),
                    _softIndigo,
                    _indigo,
                    fonts,
                  ),
                  pw.SizedBox(width: 6),
                  _badge('PAID', PdfColor(0.88, 0.98, 0.94), _green, fonts),
                ],
              ),
              if (_hasText(sale.cashierName)) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Cashier: ${sale.cashierName}',
                  style: _body(fonts, size: 8, color: _muted),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _verticalDivider() => pw.Container(
  width: 1,
  height: 47,
  margin: const pw.EdgeInsets.symmetric(horizontal: 16),
  color: _border,
);

pw.Widget _infoColumn(_InvoiceFonts fonts, String label, List<String> values) =>
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _label(fonts, label),
        pw.SizedBox(height: 8),
        for (final value in values)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(value, style: _body(fonts, size: 9, bold: true)),
          ),
      ],
    );

pw.Widget _label(_InvoiceFonts fonts, String value) =>
    pw.Text(value, style: _body(fonts, size: 7.5, color: _muted, bold: true));

pw.Widget _badge(
  String label,
  PdfColor background,
  PdfColor foreground,
  _InvoiceFonts fonts,
) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: pw.BoxDecoration(
    color: background,
    borderRadius: pw.BorderRadius.circular(20),
  ),
  child: pw.Text(
    label,
    style: _body(fonts, size: 7, color: foreground, bold: true),
  ),
);

pw.Widget _a4Totals(Sale sale, _InvoiceFonts fonts) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
  children: [
    _totalLine(fonts, 'Subtotal', _currency(sale.subtotal)),
    _totalLine(fonts, 'Discount', _currency(sale.discount)),
    _totalLine(fonts, 'Tax', _currency(sale.tax)),
    pw.SizedBox(height: 7),
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _softIndigo,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'TOTAL',
              style: _heading(fonts, size: 12, color: _indigo, bold: true),
            ),
          ),
          pw.Text(
            _currency(sale.total),
            style: _heading(fonts, size: 20, color: _indigo, bold: true),
          ),
        ],
      ),
    ),
    if (sale.receivedAmount != null) ...[
      pw.SizedBox(height: 9),
      _totalLine(fonts, 'Received (Cash)', _currency(sale.receivedAmount!)),
    ],
    if (sale.changeAmount != null)
      _totalLine(
        fonts,
        'Change',
        _currency(sale.changeAmount!),
        valueColor: _green,
        bold: true,
      ),
  ],
);

pw.Widget _totalLine(
  _InvoiceFonts fonts,
  String label,
  String value, {
  PdfColor valueColor = _text,
  bool bold = false,
}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 4),
  child: pw.Row(
    children: [
      pw.Expanded(child: pw.Text(label, style: _body(fonts, size: 9))),
      pw.Text(
        value,
        style: _body(fonts, size: 9, color: valueColor, bold: bold),
      ),
    ],
  ),
);

pw.Widget _thankYou(_InvoiceFonts fonts, {required bool centered}) => pw.Column(
  crossAxisAlignment: centered
      ? pw.CrossAxisAlignment.center
      : pw.CrossAxisAlignment.start,
  children: [
    pw.Text(
      'Thank you for shopping with us!',
      textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      style: _heading(fonts, size: 13, color: _indigo, bold: true),
    ),
    pw.SizedBox(height: 6),
    pw.Text(
      'We appreciate your business. We look forward to seeing you again.',
      textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      style: _body(fonts, size: 8, color: _muted),
    ),
  ],
);

pw.Widget _a4Footer(Sale sale, _InvoiceFonts fonts) => pw.Column(
  children: [
    pw.Container(height: 0.8, color: _border),
    pw.SizedBox(height: 13),
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                kShopInfo.name,
                style: _heading(fonts, size: 9, color: _text, bold: true),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                kShopInfo.footerNote,
                style: _body(fonts, size: 8, color: _muted),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '${kShopInfo.address} · ${kShopInfo.phone}',
                style: _body(fonts, size: 8, color: _muted),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Column(
          children: [
            pw.BarcodeWidget(
              barcode: barcode.Barcode.qrCode(
                errorCorrectLevel: barcode.BarcodeQRCorrectionLevel.medium,
              ),
              data: invoiceQrCodeData(sale),
              width: 70,
              height: 70,
              drawText: false,
              backgroundColor: PdfColors.white,
              padding: const pw.EdgeInsets.all(4),
              margin: const pw.EdgeInsets.all(4),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Scan for bill details',
              style: _body(fonts, size: 7, color: _muted),
            ),
          ],
        ),
      ],
    ),
  ],
);

List<pw.Widget> _thermalContent(
  Sale sale,
  _InvoiceFonts fonts,
  pw.MemoryImage? logo,
) {
  final rows = <pw.Widget>[
    pw.Center(child: _logoMark(logo, 38)),
    pw.SizedBox(height: 7),
    pw.Center(
      child: pw.Text(
        kShopInfo.name,
        textAlign: pw.TextAlign.center,
        style: _heading(fonts, size: 15, bold: true),
      ),
    ),
    pw.SizedBox(height: 3),
    pw.Center(
      child: pw.Text(
        kShopInfo.address,
        textAlign: pw.TextAlign.center,
        style: _body(fonts, size: 8, color: _muted),
      ),
    ),
    pw.Center(
      child: pw.Text(
        kShopInfo.phone,
        textAlign: pw.TextAlign.center,
        style: _body(fonts, size: 8, color: _muted),
      ),
    ),
    pw.SizedBox(height: 8),
    _dashedSeparator(fonts),
    pw.SizedBox(height: 7),
    pw.Center(
      child: pw.Text(
        'INVOICE  #${invoiceDisplayNumber(sale)}',
        textAlign: pw.TextAlign.center,
        style: _body(fonts, size: 10, bold: true),
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Center(
      child: pw.Text(
        DateFormat.yMMMd().add_jm().format(sale.date),
        textAlign: pw.TextAlign.center,
        style: _body(fonts, size: 8, color: _muted),
      ),
    ),
    if (_hasText(sale.customerName))
      pw.Center(
        child: pw.Text(
          'Customer: ${sale.customerName}',
          textAlign: pw.TextAlign.center,
          style: _body(fonts, size: 8),
        ),
      ),
    if (_hasText(sale.cashierName))
      pw.Center(
        child: pw.Text(
          'Cashier: ${sale.cashierName}',
          textAlign: pw.TextAlign.center,
          style: _body(fonts, size: 8),
        ),
      ),
    pw.SizedBox(height: 8),
    _dashedSeparator(fonts),
    pw.SizedBox(height: 6),
  ];

  for (final item in sale.items) {
    rows
      ..add(pw.Text(item.name, style: _body(fonts, size: 9, bold: true)))
      ..add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, bottom: 7),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${_formatQuantity(item.quantity)} x ${_currency(item.price)}',
                  style: _body(fonts, size: 8, color: _muted),
                ),
              ),
              pw.Text(
                _currency(item.price * item.quantity),
                style: _body(fonts, size: 8, bold: true),
              ),
            ],
          ),
        ),
      );
  }

  rows
    ..add(_dashedSeparator(fonts))
    ..add(pw.SizedBox(height: 7))
    ..add(_thermalTotal(fonts, 'Subtotal', _currency(sale.subtotal)))
    ..add(_thermalTotal(fonts, 'Discount', _currency(sale.discount)))
    ..add(_thermalTotal(fonts, 'Tax', _currency(sale.tax)))
    ..add(_thermalTotal(fonts, 'TOTAL', _currency(sale.total), bold: true));
  if (sale.receivedAmount != null) {
    rows.add(_thermalTotal(fonts, 'Received', _currency(sale.receivedAmount!)));
  }
  if (sale.changeAmount != null) {
    rows.add(
      _thermalTotal(
        fonts,
        'Change',
        _currency(sale.changeAmount!),
        color: _green,
        bold: true,
      ),
    );
  }
  rows
    ..add(pw.SizedBox(height: 7))
    ..add(_dashedSeparator(fonts))
    ..add(pw.SizedBox(height: 10))
    ..add(
      pw.Center(
        child: pw.BarcodeWidget(
          barcode: barcode.Barcode.qrCode(
            errorCorrectLevel: barcode.BarcodeQRCorrectionLevel.medium,
          ),
          data: invoiceQrCodeData(sale),
          width: 28 * PdfPageFormat.mm,
          height: 28 * PdfPageFormat.mm,
          drawText: false,
          backgroundColor: PdfColors.white,
          padding: const pw.EdgeInsets.all(4),
          margin: const pw.EdgeInsets.all(4),
        ),
      ),
    )
    ..add(pw.SizedBox(height: 8))
    ..add(_thankYou(fonts, centered: true))
    ..add(pw.SizedBox(height: 8))
    ..add(
      pw.Center(
        child: pw.Text(
          kShopInfo.footerNote,
          textAlign: pw.TextAlign.center,
          style: _body(fonts, size: 7, color: _muted),
        ),
      ),
    );

  return rows;
}

pw.Widget _dashedSeparator(_InvoiceFonts fonts) => pw.Center(
  child: pw.Text(
    '--------------------------------',
    style: _body(fonts, size: 8, color: _muted),
  ),
);

pw.Widget _thermalTotal(
  _InvoiceFonts fonts,
  String label,
  String value, {
  bool bold = false,
  PdfColor color = _text,
}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 2),
  child: pw.Row(
    children: [
      pw.Expanded(
        child: pw.Text(label, style: _body(fonts, size: 9, bold: bold)),
      ),
      pw.Text(
        value,
        style: _body(fonts, size: 9, color: color, bold: bold),
      ),
    ],
  ),
);

String _formatQuantity(double quantity) => quantity == quantity.roundToDouble()
    ? quantity.toInt().toString()
    : NumberFormat('#,##0.##', 'en_US').format(quantity);

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
