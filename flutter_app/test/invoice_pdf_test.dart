import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import 'package:flutter_app/models/sale.dart';
import 'package:flutter_app/services/invoice_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sale = Sale(
    id: 'sale-id',
    invoiceNo: 'INV-123456',
    items: List.generate(
      35,
      (index) => SaleItem(
        productId: 'product-$index',
        name: 'Northstar item $index with a long description for wrapping',
        price: 1250.5,
        quantity: 2,
      ),
    ),
    subtotal: 87535,
    discount: 500,
    tax: 150,
    total: 87185,
    paymentType: 'cash',
    date: DateTime(2026, 10, 12, 14, 30),
    cashierName: 'Alex Cashier',
    customerName: 'Jamie Customer',
    customerPhone: '+94 77 123 4567',
    receivedAmount: 90000,
    changeAmount: 2815,
  );

  test('generates A4 invoice PDFs with long item lists', () async {
    final bytes = await buildInvoicePdf(sale, PdfPageFormat.a4);
    final pageCount = RegExp(
      r'/Type\s*/Page\b',
    ).allMatches(latin1.decode(bytes)).length;

    expect(latin1.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(1000));
    expect(pageCount, greaterThan(1));
  });

  test('generates 80mm receipt PDFs with long item lists', () async {
    final bytes = await buildInvoicePdf(sale, PdfPageFormat.roll80);

    expect(latin1.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test(
    'formats the visible invoice number and filename without mutating sale',
    () {
      expect(invoiceDisplayNumber(sale), 'INV-123456');
      expect(invoicePdfFileName(sale), 'Northstar-INV-123456.pdf');
      expect(sale.invoiceNo, 'INV-123456');
    },
  );

  test('encodes plain text summary in QR code data under 200 characters', () {
    final qrData = invoiceQrCodeData(sale);
    expect(
      qrData,
      'Northstar Retail\n'
      'Invoice: INV-123456\n'
      'Date: 12 Oct 2026 2:30 PM\n'
      'Total: Rs. 87,185.00\n'
      'Payment: cash',
    );
    expect(qrData.length, lessThan(200));
  });
}

