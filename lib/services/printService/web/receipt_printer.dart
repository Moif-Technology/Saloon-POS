// Public API for web receipt/KOT printing.
//
// This file conditionally exports the real web implementation when running on
// Flutter web (dart.library.html), and a stub (no-op) implementation on other
// platforms. Import this file from widgets and call printSettlementWeb /
// printKOTWeb without worrying about the platform.

export 'receipt_printer_stub.dart'
    if (dart.library.html) 'receipt_printer_web_impl.dart';

