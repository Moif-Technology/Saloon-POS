// Web implementation for receipt and KOT printing.
// Layout matches Windows native (native_settlement_printer.cpp) - 48 chars, same labels and order.

import 'dart:html' as html;
import 'package:intl/intl.dart';

String _buildSeparator([int width = 48]) => '-' * width;

String _padRight(String s, int width) {
  if (s.length >= width) return s.substring(0, width);
  return s + ' ' * (width - s.length);
}

String _padLeft(String s, int width) {
  if (s.length >= width) return s.substring(0, width);
  return ' ' * (width - s.length) + s;
}

String _center(String s, int width) {
  if (s.length >= width) return s.substring(0, width);
  final leftPad = (width - s.length) ~/ 2;
  final rightPad = width - s.length - leftPad;
  return (' ' * leftPad) + s + (' ' * rightPad);
}

String _buildSettlementText({
  required Map<String, dynamic> result,
  required Map<String, dynamic> orderData,
  required String customerName,
  required int currencyDecimals,
}) {
  const width = 48;
  final sep = _buildSeparator(width);
  const leftCol = 24;
  const rightCol = 24;

  double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  final billNo = result['billNo']?.toString() ?? '';
  final paidAmount = _num(result['paidAmount']);
  final balancePaid = _num(result['balancePaid']);
  final paymentMode = result['paymentMode']?.toString().toUpperCase() ?? 'CASH';

  final netAmount = _num(orderData['netAmount'] ?? orderData['subTotalM']);
  final taxableAmount =
      _num(orderData['taxableAmount'] ?? orderData['subTotal'] ?? netAmount);
  final tax1Amount = _num(orderData['tax1Amount'] ?? orderData['tax1AmountM']);
  final tax1Rate = _num(orderData['tax1Rate'] ?? orderData['tax1RateM'] ?? 0.0);

  final counterNo = orderData['counterNo']?.toString() ?? '';
  final orderNo = ((orderData['kotPrefix']?.toString() ?? '') +
          (orderData['kotNumber']?.toString() ?? ''))
      .trim();
  final orderNoDisplay =
      orderNo.isNotEmpty ? orderNo : (orderData['kotId']?.toString() ?? '--');
  final orderType =
      orderData['orderType']?.toString().toUpperCase() ?? 'DINE IN';
  final tableName = orderData['tableName']?.toString() ??
      orderData['tableId']?.toString() ??
      '-';
  final waiterName = orderData['waiterName']?.toString() ??
      orderData['waiterId']?.toString() ??
      '-';
  final cashierName = orderData['cashierName']?.toString() ?? 'CASHIER';
  final comments = orderData['comments']?.toString() ?? '0';

  final now = DateTime.now();
  final dateStr = DateFormat('dd/MMM/yyyy').format(now);
  final timeStr = DateFormat('hh:mm:ss a').format(now);

  final buf = StringBuffer();
  buf.writeln(sep);
  buf.writeln(_center('Tax Invoice', width));
  buf.writeln(sep);
  buf.writeln(_padRight('OrderNo : $orderNoDisplay', leftCol) + _padLeft(orderType, rightCol));
  buf.writeln(sep);
  buf.writeln('Inv No #    $billNo');
  buf.writeln('Inv Date : $dateStr $timeStr');
  buf.writeln(_padRight('Cntr: $counterNo', leftCol) + _padLeft('Cashier : $cashierName', rightCol));
  buf.writeln(_padRight('Table : $tableName', leftCol) + _padLeft('Waiter : $waiterName', rightCol));
  buf.writeln('Comments : $comments');
  buf.writeln(sep);
  buf.writeln(_padRight('Description     ', 17) + _padLeft('Qty', 4) + _padLeft('Price', 8) + _padLeft('Total', 9) + (' ' * (width - 17 - 4 - 8 - 9)));
  buf.writeln(sep);

  final items =
      List<Map<String, dynamic>>.from(orderData['items'] ?? const <Map>[]);
  for (final it in items) {
    final desc =
        (it['shortDescription'] ?? it['ShortDescription'] ?? '-').toString();
    final qty = _num(it['qty'] ?? it['Qty']);
    final unitPrice = _num(it['unitPrice']);
    final lineTotal =
        _num(it['lineTotal'] ?? it['subTotalC'] ?? qty * unitPrice);

    final descTrim =
        desc.length > 16 ? desc.substring(0, 16) : _padRight(desc, 16);
    final qtyStr = qty.toStringAsFixed(0);
    final priceStr = unitPrice.toStringAsFixed(currencyDecimals);
    final totalStr = lineTotal.toStringAsFixed(currencyDecimals);
    buf.writeln(_padRight(descTrim, 16) + _padLeft(qtyStr, 4) + _padLeft(priceStr, 8) + _padLeft(totalStr, 9) + (' ' * (width - 16 - 4 - 8 - 9)));
    final taxLine = it['taxLineStr']?.toString() ?? '';
    if (taxLine.isNotEmpty) buf.writeln(taxLine);
  }

  buf.writeln(sep);
  buf.writeln(_padRight('TOTAL  :', leftCol) + _padLeft(netAmount.toStringAsFixed(currencyDecimals), rightCol));
  buf.writeln(sep);
  buf.writeln('Settlement : $paymentMode');
  buf.writeln(_padRight('Items : ${items.length}', leftCol) + _padLeft('Bill Amt : ${netAmount.toStringAsFixed(currencyDecimals)}', rightCol));
  buf.writeln(_padRight('Qty : ${items.length}', leftCol) + _padLeft('Paid Amt : ${paidAmount.toStringAsFixed(currencyDecimals)}', rightCol));
  buf.writeln(_padRight('', leftCol) + _padLeft('Bal. Amount: ${balancePaid.toStringAsFixed(currencyDecimals)}', rightCol));
  buf.writeln(sep);
  buf.writeln(_center('Tax Details', width));
  buf.writeln(sep);
  buf.writeln(_padRight('Taxable Amt', 14) + _padRight('VAT@${tax1Rate.toStringAsFixed(0)}%', 12) + _padRight('Bill Amt', 11));
  buf.writeln(_padRight(taxableAmount.toStringAsFixed(currencyDecimals), 14) + _padRight(tax1Amount.toStringAsFixed(currencyDecimals), 12) + _padRight(netAmount.toStringAsFixed(currencyDecimals), 11));
  buf.writeln(sep);
  buf.writeln(_center('Thank You... Visit Again', width));
  buf.writeln(sep);

  return buf.toString();
}

String _buildKOTText({
  required Map<String, dynamic> kotDetails,
  required String supplyType,
  required String title,
  String kitchenLocation = 'PASSING',
}) {
  const width = 48;
  final sep = _buildSeparator(width);
  final data = List<Map<String, dynamic>>.from(kotDetails['data'] ?? const []);
  if (data.isEmpty) return 'NO KOT DATA';
  final first = data.first;

  String s(dynamic v, [String def = '']) =>
      v == null ? def : v.toString().trim();

  final kotPrefix = s(first['KotPrefix'] ?? first['kotPrefix']);
  final kotNumber = s(first['KotNumber'] ?? first['kotNumber'] ?? '0');
  final areaName = s(first['AreaName'] ?? first['areaName'] ?? '-');
  final tableName = s(first['TableName'] ?? first['tableName'] ?? '');
  final counterNo = s(first['CounterNo'] ?? first['counterNo'] ?? '');
  final waiterId = first['WaiterID'] ?? first['waiterID'];
  final chairNo = first['ChairNo'] ?? first['chairNo'] ?? 1;
  final kotTime = first['KotTime'] ?? first['kotTime'];

  String waiterName = '-';
  if (waiterId != null && waiterId.toString() != '0') {
    waiterName = 'Waiter #$waiterId';
  }
  final chair = chairNo is int ? chairNo : int.tryParse(chairNo.toString()) ?? 1;

  DateTime? dt;
  if (kotTime != null) {
    if (kotTime is DateTime) {
      dt = kotTime;
    } else if (kotTime is String) {
      dt = DateTime.tryParse(kotTime);
    }
  }
  final now = DateTime.now();
  final useDt = dt ?? now;
  final dateStr = DateFormat('dd/MM/yyyy').format(useDt);
  final timeStr = DateFormat('hh:mm:ss a').format(useDt);
  final printedTime = DateFormat('hh:mm a').format(now);

  final buf = StringBuffer();
  buf.writeln(_center(title.toUpperCase(), width));
  buf.writeln(sep);
  buf.writeln(_padRight('             $kitchenLocation - ${supplyType.toUpperCase()}', width));
  buf.writeln(sep);
  buf.writeln('KOT#$kotPrefix$kotNumber-$areaName');
  if (tableName.isNotEmpty) {
    buf.writeln('Table No - $tableName');
  }
  buf.writeln('');
  buf.writeln(sep);
  buf.writeln('Counter : $counterNo  $dateStr  $timeStr');
  String waiterLine = 'Waiter:$waiterName';
  if (chair > 1) waiterLine += '    Chair No:$chair';
  buf.writeln(waiterLine);
  buf.writeln(sep);
  buf.writeln('Qty  Description            ');
  buf.writeln(sep);

  const kLineLen = 22;
  double totalQty = 0;
  for (final m in data) {
    final desc = s(m['ShortDescription'] ?? m['shortDescription'] ?? '-');
    final qty = (m['Qty'] ?? m['qty'] ?? 1) is num
        ? ((m['Qty'] ?? m['qty'] ?? 1) as num).toDouble()
        : double.tryParse((m['Qty'] ?? m['qty'] ?? '1').toString()) ?? 1.0;
    totalQty += qty < 0 ? -qty : qty;
    final qtyStr = qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toString();
    final itemStr = '$qtyStr  -$desc';
    final line = itemStr.length > kLineLen ? itemStr.substring(0, kLineLen) : itemStr;
    buf.writeln(line);
    final mod = s(m['Modifier'] ?? m['modifier'] ?? '');
    if (mod.isNotEmpty) {
      for (final part in mod.split('-')) {
        final p = part.trim();
        if (p.isNotEmpty) buf.writeln('+++ $p +++');
      }
    }
  }

  buf.writeln(sep);
  buf.writeln('Items  : ${data.length}');
  buf.writeln('Qty      : ${totalQty.toInt()}');
  buf.writeln(sep);
  buf.writeln('Printed Time : $printedTime');

  return buf.toString();
}

String _escapeHtml(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

void _openPrintWindow(String title, String bodyText) {
  print('_openPrintWindow called for $title, length=${bodyText.length}');
  final escaped = _escapeHtml(bodyText);
  final htmlContent = '''<!DOCTYPE html><html><head><meta charset="utf-8"><title>${_escapeHtml(title)}</title>
<style>
  @page { size: 80mm auto; margin: 0; }
  body, pre { margin: 0; padding: 2mm; }
  pre { font-family: Courier New, monospace; font-size: 12pt; line-height: 1.2; font-weight: bold; }
</style></head>
<body><pre>$escaped</pre>
<script>setTimeout(function(){window.print()},600);</script></body></html>''';

  final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, 'receipt', 'width=350,height=500');
  Future.delayed(const Duration(seconds: 5), () => html.Url.revokeObjectUrl(url));
}

Future<void> printSettlementWeb({
  required Map<String, dynamic> result,
  required Map<String, dynamic> orderData,
  required String customerName,
  required int currencyDecimals,
}) async {
  final text = _buildSettlementText(
    result: result,
    orderData: orderData,
    customerName: customerName,
    currencyDecimals: currencyDecimals,
  );
  _openPrintWindow('Settlement Receipt', text);
}

Future<void> printKOTWeb({
  required Map<String, dynamic> kotDetails,
  required String supplyType,
  required String title,
}) async {
  final text = _buildKOTText(
    kotDetails: kotDetails,
    supplyType: supplyType,
    title: title,
  );
  _openPrintWindow('KOT', text);
}
