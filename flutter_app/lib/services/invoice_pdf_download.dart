import 'dart:typed_data';

import 'invoice_pdf_download_stub.dart'
    if (dart.library.html) 'invoice_pdf_download_web.dart' as platform;

Future<void> downloadInvoicePdf(Uint8List bytes, String filename) =>
    platform.downloadInvoicePdf(bytes, filename);
