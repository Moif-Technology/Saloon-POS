import 'dart:developer';

import 'package:intl/intl.dart';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/services/printService/android_escpos_sender.dart';
import 'package:my_app/utils/sessionManager.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:thermal_printer/thermal_printer.dart';

/// Settlement (counter) receipt — same layout and wording as VB HMS (GeneralModuleForm Print_printpage).
/// Android: Sunmi built-in → network IP → USB ("counter").
/// Other platforms: network IP or USB printer whose name contains "counter".
class SettlementReceiptPrinter {
  static bool _isCounterPrinter(String deviceName) {
    final n = deviceName.toString().trim().toLowerCase();
    return n == 'counter' ||
        n.contains('counter') ||
        n.contains('innerprinter') ||
        n.contains('sunmi');
  }

  static const int _discoverySeconds = 3;

  /// VB: 48 dashes
  static String get _sep => '------------------------------------------------------------';

  static Future<void> printReceipt({
    required Map<String, dynamic> result,
    required Map<String, dynamic> orderData,
    required String customerName,
    int currencyDecimals = 2,
    void Function(String message)? onError,
  }) async {
    try {
      final bytes = await _buildReceiptBytes(
        result: result,
        orderData: orderData,
        customerName: customerName,
        currencyDecimals: currencyDecimals,
      );

      if (AndroidEscPosSender.isEnabled) {
        await AndroidEscPosSender.send(bytes, onError: onError);
        return;
      }

      await _sendViaThermalPrinter(bytes, onError: onError);
    } catch (e, st) {
      log('Settlement receipt print error: $e', stackTrace: st);
      onError?.call('Print failed: $e');
    }
  }

  /// Sales / bill reprint — converts {header, items} then prints like settlement.
  static Future<void> printSalesReceipt({
    required Map<String, dynamic> receiptData,
    int currencyDecimals = 2,
    void Function(String message)? onError,
  }) async {
    try {
      final header = receiptData['header'] as Map<String, dynamic>? ?? {};
      final items = List<Map<String, dynamic>>.from(
          receiptData['items'] ?? receiptData['salesItems'] ?? []);

      double parse(dynamic v) {
        if (v == null) return 0.0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0.0;
      }

      final billNo = header['BillNo']?.toString() ?? '';
      final paidAmount = parse(header['PaidAmount']);
      final balancePaid = parse(header['BalancePaid']);
      final paymentMode =
          header['PaymentMode']?.toString().toUpperCase() ?? 'CASH';
      final taxableAmount = parse(header['TaxableAmount']);
      final tax1Amount = parse(header['Tax1AmountM']);
      double netAmount = parse(header['Amount']);
      if (netAmount == 0) {
        for (final it in items) {
          netAmount += parse(it['LineTotal']);
        }
      }
      if (netAmount == 0) {
        netAmount = taxableAmount + tax1Amount;
      }
      double tax1Rate = 0;
      for (final it in items) {
        final r = parse(it['Tax1RateC']);
        if (r > 0) {
          tax1Rate = r;
          break;
        }
      }
      if (tax1Rate == 0) tax1Rate = 5.0;

      final orderData = <String, dynamic>{
        'netAmount': netAmount,
        'taxableAmount': taxableAmount,
        'tax1Amount': tax1Amount,
        'tax1RateM': tax1Rate,
        'counterNo': header['CounterNo']?.toString() ?? '',
        'kotPrefix': '',
        'kotNumber': '',
        'kotId': header['KOTNumber']?.toString() ?? '--',
        'tableName': '-',
        'waiterName': '-',
        'cashierName': header['CashierName']?.toString() ?? 'CASHIER',
        'comments': '0',
        'customerName': header['CustomerName']?.toString() ?? 'Cash Customer',
        'items': items.map((it) {
          return {
            'shortDescription': (it['ShortDescription'] ?? '-').toString(),
            'qty': parse(it['Qty']),
            'unitPrice': parse(it['UnitPrice']),
            'subTotalC': parse(it['LineTotal']),
            'tax1AmountC': parse(it['Tax1AmountC']),
            'tax1RateC': parse(it['Tax1RateC']),
          };
        }).toList(),
      };

      final result = <String, dynamic>{
        'billNo': billNo,
        'paidAmount': paidAmount,
        'balancePaid': balancePaid,
        'paymentMode': paymentMode,
      };

      await printReceipt(
        result: result,
        orderData: orderData,
        customerName:
            header['CustomerName']?.toString() ?? 'Cash Customer',
        currencyDecimals: currencyDecimals,
        onError: onError,
      );
    } catch (e, st) {
      log('Sales receipt ESC/POS print error: $e', stackTrace: st);
      onError?.call('Print failed: $e');
    }
  }

  static Future<void> _sendViaThermalPrinter(
    List<int> bytes, {
    void Function(String message)? onError,
  }) async {
    final printerManager = PrinterManager.instance;
    final ip = receiptPrinterIP.trim();

    if (ip.isNotEmpty) {
      final connected = await printerManager.connect(
        type: PrinterType.network,
        model: TcpPrinterInput(
          ipAddress: ip,
          port: receiptPrinterPort,
          timeout: const Duration(seconds: 5),
        ),
      );
      if (!connected) {
        final msg =
            'Could not connect to receipt printer at $ip:$receiptPrinterPort';
        log(msg);
        onError?.call(msg);
        return;
      }
      await printerManager.send(type: PrinterType.network, bytes: bytes);
      log('Settlement receipt sent to network printer $ip:$receiptPrinterPort');
      return;
    }

    _PrinterDevice? selectedPrinter;
    final sub = printerManager
        .discovery(type: PrinterType.usb)
        .listen((PrinterDevice device) {
      final p = _PrinterDevice(
        deviceName: device.name,
        vendorId: device.vendorId,
        productId: device.productId,
        typePrinter: PrinterType.usb,
      );
      if (_isCounterPrinter(device.name.toString())) {
        selectedPrinter ??= p;
      }
    });

    await Future.delayed(Duration(seconds: _discoverySeconds));
    sub.cancel();

    final printer = selectedPrinter;
    if (printer == null) {
      final msg =
          'Receipt printer "counter" not found. Set receiptPrinterIP in api_config for network printer.';
      log(msg);
      onError?.call(msg);
      return;
    }

    await printerManager.connect(
      type: printer.typePrinter,
      model: UsbPrinterInput(
        name: printer.deviceName,
        productId: printer.productId,
        vendorId: printer.vendorId,
      ),
    );

    printerManager.send(type: PrinterType.usb, bytes: bytes);
    log('Settlement receipt sent to USB ${printer.deviceName}');
  }

  static Future<List<int>> _buildReceiptBytes({
    required Map<String, dynamic> result,
    required Map<String, dynamic> orderData,
    required String customerName,
    required int currencyDecimals,
  }) async {
    final billNo = result['billNo']?.toString() ?? '';
    final jobNo = (result['jobNo'] ??
            orderData['jobNo'] ??
            orderData['JobNo'] ??
            '')
        .toString()
        .trim();
    final paidAmount = (result['paidAmount'] as num?)?.toDouble() ??
        (orderData['paidAmount'] as num?)?.toDouble() ??
        0.0;
    final balancePaid = (result['balancePaid'] as num?)?.toDouble() ?? 0.0;
    final paymentMode =
        result['paymentMode']?.toString().toUpperCase() ?? 'CASH';
    final netAmount =
        (orderData['netAmount'] as num?)?.toDouble() ??
        (orderData['subTotalM'] as num?)?.toDouble() ??
        0.0;
    final taxableAmount = (orderData['taxableAmount'] as num?)?.toDouble() ??
        (orderData['subTotal'] as num?)?.toDouble() ??
        netAmount;
    final tax1Amount = (orderData['tax1Amount'] as num?)?.toDouble() ??
        (orderData['tax1AmountM'] as num?)?.toDouble() ?? 0.0;
    final tax1Rate = (orderData['tax1Rate'] as num?)?.toDouble() ??
        (orderData['tax1RateM'] as num?)?.toDouble() ?? 0.0;

    final rawSplits = result['paymentSplits'] ?? orderData['paymentSplits'];
    final List<Map<String, dynamic>> paymentSplits = [];
    if (rawSplits is List) {
      for (final s in rawSplits) {
        if (s is! Map) continue;
        final mode = (s['payMode'] ?? s['PayMode'] ?? '').toString().trim();
        final amount = (s['amount'] as num?)?.toDouble() ??
            (s['billAmount'] as num?)?.toDouble() ??
            double.tryParse('${s['amount'] ?? s['billAmount'] ?? ''}') ??
            0.0;
        if (mode.isEmpty || amount <= 0) continue;
        paymentSplits.add({'payMode': mode.toUpperCase(), 'amount': amount});
      }
    }

    final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
    final counterNo = orderData['counterNo']?.toString() ?? '';
    final orderNo = (orderData['kotPrefix']?.toString() ?? '') +
        (orderData['kotNumber']?.toString() ?? '');
    final orderNoDisplay = jobNo.isNotEmpty
        ? jobNo
        : (orderNo.isNotEmpty
            ? orderNo
            : (orderData['kotId']?.toString() ?? '--'));
    final tableName = orderData['tableName']?.toString() ??
        orderData['chairName']?.toString() ??
        orderData['tableId']?.toString() ??
        '-';
    final waiterName = orderData['waiterName']?.toString() ??
        orderData['stylistName']?.toString() ??
        orderData['waiterId']?.toString() ??
        '-';
    final cashierName = orderData['cashierName']?.toString() ??
        SessionManager().staffName ??
        'CASHIER';
    final comments = orderData['comments']?.toString() ?? '';
    final printCustomerName = customerName.trim().isNotEmpty
        ? customerName.trim()
        : (orderData['customerName'] ?? orderData['CustomerName'] ?? '')
            .toString()
            .trim();
    final customerCode = (orderData['customerCode'] ??
            orderData['CustomerCode'] ??
            '')
        .toString()
        .trim();
    final customerMobile = (orderData['mobileNo'] ??
            orderData['MobileNo'] ??
            orderData['telephone'] ??
            '')
        .toString()
        .trim();
    final customerAddress =
        (orderData['address'] ?? orderData['Address'] ?? '').toString().trim();
    final customerTrn =
        (orderData['taxRegNo'] ?? orderData['CustTRN'] ?? '').toString().trim();
    final customerId = (orderData['customerId'] ??
            orderData['CustomerID'] ??
            result['customerId'] ??
            '')
        .toString()
        .trim();
    final nameLower = printCustomerName.toLowerCase();
    final isWalkIn = customerId.isEmpty ||
        customerId == '0' ||
        nameLower.isEmpty ||
        nameLower == 'walk-in' ||
        nameLower == 'walkin' ||
        nameLower == 'walk in' ||
        nameLower == 'cash customer' ||
        nameLower == 'select customer';

    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MMM/yyyy').format(now);
    final timeStr = DateFormat('hh:mm:ss a').format(now);

    bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('  Tax Invoice',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('  فاتورة ضريبية',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'BILL # : $billNo', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
          text: '$dateStr $timeStr',
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    if (orderNoDisplay.isNotEmpty && orderNoDisplay != '--') {
      bytes += generator.text('JOB #  : $orderNoDisplay',
          styles: const PosStyles(bold: true));
    }

    bytes += generator.row([
      PosColumn(text: 'COUNTER : $counterNo', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
          text: 'CASHIER : $cashierName',
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'CHAIR : $tableName', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
          text: 'STYLIST : $waiterName',
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    if (!isWalkIn) {
      bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Customer : $printCustomerName',
          styles: const PosStyles(bold: true));
      if (customerCode.isNotEmpty) {
        bytes += generator.text('Code     : $customerCode',
            styles: const PosStyles(bold: true));
      }
      if (customerTrn.isNotEmpty) {
        bytes += generator.text('TRN      : $customerTrn',
            styles: const PosStyles(bold: true));
      }
      if (customerMobile.isNotEmpty) {
        bytes += generator.text('Tel      : $customerMobile',
            styles: const PosStyles(bold: true));
      }
      if (customerAddress.isNotEmpty) {
        bytes += generator.text('Address  : $customerAddress',
            styles: const PosStyles(bold: true));
      }
    }
    if (comments.isNotEmpty && comments != '0') {
      bytes += generator.text('Comments : $comments', styles: const PosStyles(bold: true));
    }
    bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text('Description    Qty  Price  Total',
        styles: const PosStyles(bold: true));
    bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));

    for (final item in items) {
      final qty = (item['qty'] as num?)?.toDouble() ?? 0.0;
      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
      final lineTotal = (item['subTotalC'] as num?)?.toDouble() ??
          (item['tax1AmountC'] as num?)?.toDouble() ?? 0.0;
      final lineTotalComputed = lineTotal > 0
          ? lineTotal
          : (qty * unitPrice) +
              ((item['tax1AmountC'] as num?)?.toDouble() ?? 0.0);
      final taxAmt = (item['tax1AmountC'] as num?)?.toDouble() ?? 0.0;
      final taxRate = (item['tax1RateC'] as num?)?.toDouble() ?? 0.0;
      final desc = (item['shortDescription'] ??
              item['ShortDescription'] ??
              '-')
          .toString();
      final descTrim = desc.length > 17 ? desc.substring(0, 17) : desc;

      bytes += generator.row([
        PosColumn(text: descTrim, width: 6),
        PosColumn(
            text: qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2),
            width: 1,
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            text: unitPrice.toStringAsFixed(currencyDecimals),
            width: 2,
            styles: const PosStyles(align: PosAlign.right)),
        PosColumn(
            text: lineTotalComputed.toStringAsFixed(currencyDecimals),
            width: 3,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      if (taxAmt > 0 && taxRate > 0) {
        bytes += generator.text(
            '                  VAT@${taxRate.toStringAsFixed(0)}%  (${taxAmt.toStringAsFixed(2)})');
      }
    }

    bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'TOTAL  : ', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
          text: netAmount.toStringAsFixed(currencyDecimals),
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Settlement : $paymentMode',
        styles: const PosStyles(bold: true));
    for (final s in paymentSplits) {
      bytes += generator.row([
        PosColumn(
            text: s['payMode'].toString(),
            width: 6,
            styles: const PosStyles(bold: true)),
        PosColumn(
            text: (s['amount'] as num).toStringAsFixed(currencyDecimals),
            width: 6,
            styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'Items : ${items.length}', width: 6),
      PosColumn(
          text: 'Bill Amount  : ${netAmount.toStringAsFixed(currencyDecimals)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Qty : ${items.length}', width: 6),
      PosColumn(
          text: 'Paid Amount : ${paidAmount.toStringAsFixed(currencyDecimals)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Bal. Amount:', width: 6),
      PosColumn(
          text: balancePaid.toStringAsFixed(currencyDecimals),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text('          Tax Details',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));
    final taxLabel =
        tax1Rate > 0 ? 'VAT@${tax1Rate.toStringAsFixed(0)}%' : 'VAT@5%';
    bytes += generator.row([
      PosColumn(text: 'Taxable Amount', width: 5),
      PosColumn(text: taxLabel, width: 3, styles: const PosStyles(align: PosAlign.center)),
      PosColumn(text: 'Bill Amount', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: taxableAmount.toStringAsFixed(currencyDecimals), width: 5),
      PosColumn(
          text: tax1Amount.toStringAsFixed(currencyDecimals),
          width: 3,
          styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          text: netAmount.toStringAsFixed(currencyDecimals),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text(_sep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Thank You... Visit Again',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}

class _PrinterDevice {
  final String? deviceName;
  final String? vendorId;
  final String? productId;
  final PrinterType typePrinter;
  _PrinterDevice({
    this.deviceName,
    this.vendorId,
    this.productId,
    this.typePrinter = PrinterType.usb,
  });
}
