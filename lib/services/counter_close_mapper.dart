import 'package:my_app/utils/sessionManager.dart';

double counterCloseNum(dynamic v, [double d = 0]) {
  if (v == null) return d;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? d;
}

int counterCloseInt(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? d;
}

/// Maps Counter-POS `/counter/summary` or `/counter/close` JSON → legacy UI/print keys.
Map<String, dynamic> mapCounterCloseForUi(
  Map<String, dynamic> api, {
  SessionManager? session,
  double? collectedOverride,
  double? differenceOverride,
}) {
  final totalCash = counterCloseNum(api['totalCash']);
  final creditReceiptCash = counterCloseNum(api['creditReceiptCash']);
  final cashIn = counterCloseNum(api['cashIn']);
  final cashOut = counterCloseNum(api['cashOut']);
  final refund = counterCloseNum(api['totalRefund']);
  final cashToCollect = counterCloseNum(api['cashToBeCollected']);
  final collected = collectedOverride ?? counterCloseNum(api['collectedCash']);
  final difference = differenceOverride ??
      counterCloseNum(api['cashDifference'], collected - cashToCollect);
  final gross = counterCloseNum(api['grossAmount']);
  final tax = counterCloseNum(api['totalTax']);
  final sm = session ?? SessionManager();
  final counterNo = api['counterNo']?.toString() ??
      sm.stationId ??
      '';

  return {
    // Raw API (camelCase) — keep for flexibility
    ...api,
    'totalCash': totalCash,
    'totalCredit': counterCloseNum(api['totalCredit']),
    'totalCard': counterCloseNum(api['totalCard']),
    'totalOnline': counterCloseNum(api['totalOnline']),
    'totalVoucher': counterCloseNum(api['totalVoucher']),
    'totalDiscount': counterCloseNum(api['totalDiscount']),
    'itemDiscountTotal': counterCloseNum(api['itemDiscountTotal']),
    'totalRefund': refund,
    'totalTax': tax,
    'grossAmount': gross,
    'cashIn': cashIn,
    'cashOut': cashOut,
    'creditReceiptCash': creditReceiptCash,
    'creditReceiptCard': counterCloseNum(api['creditReceiptCard']),
    'cashToBeCollected': cashToCollect,
    'collectedCash': collected,
    'cashDifference': difference,

    // Legacy UI / printDialog keys
    'AmountToBeCollected': cashToCollect,
    'CollectedAmount': collected,
    'CashDifference': difference,
    'ReceiptAmount': creditReceiptCash,
    'AdvanceReceived': 0.0,
    'CashIN': cashIn,
    'CashOUt': cashOut,
    'finalTotalCash': totalCash - refund,
    'RefundAmount': refund,
    'CreditAmount': counterCloseNum(api['totalCredit']),
    'CreditCardAmount': counterCloseNum(api['totalCard']),
    'OnlineAmount': counterCloseNum(api['totalOnline']),
    'ReceiptAmountCCard': counterCloseNum(api['creditReceiptCard']),
    'VoucherAmount': counterCloseNum(api['totalVoucher']),
    'ComplimentAmount': 0.0,
    'DiscountAmount': counterCloseNum(api['totalDiscount']),
    'TotalAmount': gross,
    'TaxAmount': tax,
    'TaxableAmount': (gross - tax).clamp(0.0, double.infinity),
    'BillCount': counterCloseInt(api['billCount']),
    'CashBillCount': counterCloseInt(api['cashBillCount']),
    'CreditCardBillCount': counterCloseInt(api['cardBillCount']),
    'MultiBillCount': counterCloseInt(api['multiBillCount']),
    'CreditBillCount': counterCloseInt(api['creditBillCount']),
    'ComplimentBillCount': counterCloseInt(api['complimentBillCount']),
    'CounterNo': counterNo,
    'cashierName': sm.staffName ?? api['staffName']?.toString() ?? '',
    'closeNo': (api['closeNo'] ?? '').toString(),
    'reportType': (api['reportType'] ?? '').toString(),
    'startBillNo': api['startBillNo'],
    'endBillNo': api['endBillNo'],
    'kotList': api['kotList'] ?? const [],
    'creditCardSales': api['creditCardSales'] ?? const [],
    'onlineSalesDetails': api['onlineSalesDetails'] ?? const [],
    'billCancelledAmount': 0.0,
    'itemCancelledAmount': 0.0,
    'totalCustomers': counterCloseInt(api['billCount']),
    'ReturnAmount': 0.0,
    'ReturnBillCount': 0,
    'RefundAmount2ndOne': 0.0,
    'Refund2ndBillCount': 0,
  };
}

/// Maps `/counter/history` row → Counter Close Reports table keys.
Map<String, dynamic> mapCounterCloseHistoryRow(Map<String, dynamic> api) {
  final closeNo = (api['closeNo'] ?? '').toString();
  DateTime? closeDt;
  final raw = api['closeDate'];
  if (raw != null) {
    closeDt = DateTime.tryParse(raw.toString());
  }
  return {
    ...api,
    'CounterNo': api['counterNo']?.toString() ?? '',
    'CounterCloseCode': '',
    'CounterCloseNo': closeNo,
    'CashierName': api['staffName']?.toString() ?? '',
    'CloseDate': closeDt?.toIso8601String() ?? raw?.toString(),
    'CloseTime': closeDt?.toIso8601String() ?? raw?.toString(),
    'TotalCash': counterCloseNum(api['totalCash']),
    'TotalCredit': counterCloseNum(api['totalCredit']),
    'TotalCard': counterCloseNum(api['totalCard']),
    'CashToBeCollected': counterCloseNum(api['cashToBeCollected']),
    'CollectedAmount': counterCloseNum(api['collectedCash']),
    'CashDifference': counterCloseNum(api['cashDifference']),
    'BillCount': counterCloseInt(api['billCount']),
    'closeId': api['closeId'],
  };
}
