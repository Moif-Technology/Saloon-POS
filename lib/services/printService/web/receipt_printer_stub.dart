// Web receipt/KOT printer stub for non-web platforms.
//
// This file is selected when dart.library.html is NOT available (desktop, mobile).
// The methods are no-ops so imports work safely everywhere.

Future<void> printSettlementWeb({
  required Map<String, dynamic> result,
  required Map<String, dynamic> orderData,
  required String customerName,
  required int currencyDecimals,
}) async {
  // No-op on non-web platforms.
}

Future<void> printKOTWeb({
  required Map<String, dynamic> kotDetails,
  required String supplyType,
  required String title,
}) async {
  // No-op on non-web platforms.
}

