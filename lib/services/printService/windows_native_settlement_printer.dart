import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/utils/sessionManager.dart';

/// Windows-only: prints settlement receipt via native GDI (same as VB).
/// Uses method channel com.myapp/native_settlement_print.
/// Android implementation can be added later for big-screen POS.
class WindowsNativeSettlementPrinter {
  static const MethodChannel _channel =
      MethodChannel('com.myapp/native_settlement_print');

  /// Returns true if Windows native settlement printing is available.
  static bool get isAvailable =>
      Platform.isWindows && useWindowsNativeSettlementPrint;

  /// Call after successful settlement. Sends receipt data to Windows native code
  /// which prints via GDI (Courier New, same layout as VB).
  static Future<void> printSettlement({
    required Map<String, dynamic> result,
    required Map<String, dynamic> orderData,
    required String customerName,
    int currencyDecimals = 2,
    void Function(String message)? onError,
  }) async {
    if (!Platform.isWindows) {
      onError?.call(
          'Windows native settlement print is only available on Windows');
      return;
    }
    try {
      await _printWithCustomPrinter(
        result: result,
        orderData: orderData,
        customerName: customerName,
        currencyDecimals: currencyDecimals,
        useSalesReceiptPrinter: false,
        onError: onError,
      );
      log('Settlement print sent to Windows native (GDI)');
    } on PlatformException catch (e, st) {
      log('Windows native settlement print error: $e', stackTrace: st);
      onError?.call(e.message ?? 'Print failed: $e');
    } catch (e, st) {
      log('Windows native settlement print error: $e', stackTrace: st);
      onError?.call('Print failed: $e');
    }
  }

  /// Returns true if Windows native sales receipt printing is available.
  static bool get isSalesReceiptAvailable =>
      Platform.isWindows && useWindowsNativeSalesReceiptPrint;

  /// Print sales receipt (reprint from Sales Viewer) via Windows native GDI.
  /// Converts receipt data { header, items } from fetchReceiptData to settlement format.
  /// Physical thermal or Microsoft Print to PDF - same layout as settlement.
  static Future<void> printSalesReceipt({
    required Map<String, dynamic> receiptData,
    int currencyDecimals = 2,
    void Function(String message)? onError,
  }) async {
    if (!Platform.isWindows) {
      onError?.call(
          'Windows native sales receipt print is only available on Windows');
      return;
    }
    try {
      final header = receiptData['header'] as Map<String, dynamic>? ?? {};
      final items = List<Map<String, dynamic>>.from(receiptData['items'] ?? []);

      double _parse(dynamic v) {
        if (v == null) return 0.0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0.0;
      }

      final billNo = header['BillNo']?.toString() ?? '';
      final paidAmount = _parse(header['PaidAmount']);
      final balancePaid = _parse(header['BalancePaid']);
      final paymentMode =
          header['PaymentMode']?.toString().toUpperCase() ?? 'CASH';
      final taxableAmount = _parse(header['TaxableAmount']);
      final tax1Amount = _parse(header['Tax1AmountM']);
      double netAmount = _parse(header['Amount']);
      if (netAmount == 0) {
        for (final it in items) {
          netAmount += _parse(it['LineTotal']);
        }
      }
      if (netAmount == 0) {
        netAmount = taxableAmount + tax1Amount;
      }
      double tax1Rate = 0;
      for (final it in items) {
        final r = _parse(it['Tax1RateC']);
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
        'orderType': (header['SupplyType']?.toString() ?? 'DINE IN').toUpperCase(),
        'tableName': '-',
        'waiterName': '-',
        'cashierName': header['CashierName']?.toString() ?? 'CASHIER',
        'comments': '0',
        'items': items.map((it) {
          final qty = _parse(it['Qty']);
          final unitPrice = _parse(it['UnitPrice']);
          final lineTotal = _parse(it['LineTotal']);
          final taxAmt = _parse(it['Tax1AmountC']);
          final taxRate = _parse(it['Tax1RateC']);
          final desc = (it['ShortDescription'] ?? '-').toString();
          final descTrim = desc.length > 17 ? desc.substring(0, 17) : desc;
          String taxLineStr = '';
          if (taxAmt > 0 && taxRate > 0) {
            taxLineStr =
                '                  VAT@${taxRate.toStringAsFixed(0)}%  (${taxAmt.toStringAsFixed(2)})';
          }
          return {
            'shortDescription': descTrim,
            'qty': qty,
            'unitPrice': unitPrice,
            'subTotalC': lineTotal,
            'lineTotal': lineTotal,
            'tax1AmountC': taxAmt,
            'tax1RateC': taxRate,
            'taxLineStr': taxLineStr,
          };
        }).toList(),
      };

      final result = <String, dynamic>{
        'billNo': billNo,
        'paidAmount': paidAmount,
        'balancePaid': balancePaid,
        'paymentMode': paymentMode,
      };

      String? dateStr;
      String? timeStr;
      if (header['BillDate'] != null || header['BillTime'] != null) {
        try {
          final d = header['BillDate']?.toString();
          final t = header['BillTime']?.toString();
          if (d != null && d.isNotEmpty) {
            final dt = DateTime.tryParse(d);
            if (dt != null) {
              dateStr = DateFormat('dd/MMM/yyyy').format(dt);
            }
          }
          if (t != null && t.isNotEmpty) {
            final dt = DateTime.tryParse('2000-01-01 $t');
            if (dt != null) {
              timeStr = DateFormat('hh:mm:ss a').format(dt);
            }
          }
        } catch (_) {}
      }

      await _printWithCustomPrinter(
        result: result,
        orderData: orderData,
        customerName: 'Customer',
        currencyDecimals: currencyDecimals,
        dateStr: dateStr,
        timeStr: timeStr,
        useSalesReceiptPrinter: true,
        onError: onError,
      );
      log('Sales receipt print sent to Windows native (GDI)');
    } on PlatformException catch (e, st) {
      log('Windows native sales receipt print error: $e', stackTrace: st);
      onError?.call(e.message ?? 'Print failed: $e');
    } catch (e, st) {
      log('Windows native sales receipt print error: $e', stackTrace: st);
      onError?.call('Print failed: $e');
    }
  }

  static Future<void> _printWithCustomPrinter({
    required Map<String, dynamic> result,
    required Map<String, dynamic> orderData,
    required String customerName,
    int currencyDecimals = 2,
    String? dateStr,
    String? timeStr,
    bool useSalesReceiptPrinter = false,
    void Function(String message)? onError,
  }) async {
    if (!Platform.isWindows) return;
    try {
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
      double parseAmt(dynamic v) {
        if (v == null) return 0.0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0.0;
      }
      final outstandingBalance = parseAmt(
        result['customerOsBalance'] ??
            result['outstandingBalance'] ??
            orderData['customerOsBalance'] ??
            orderData['outstandingBalance'],
      );
      final netAmount = (orderData['netAmount'] as num?)?.toDouble() ??
          (orderData['subTotalM'] as num?)?.toDouble() ??
          0.0;
      final taxableAmount = (orderData['taxableAmount'] as num?)?.toDouble() ??
          (orderData['subTotal'] as num?)?.toDouble() ??
          netAmount;
      final tax1Amount = (orderData['tax1Amount'] as num?)?.toDouble() ??
          (orderData['tax1AmountM'] as num?)?.toDouble() ??
          0.0;
      final tax1Rate = (orderData['tax1Rate'] as num?)?.toDouble() ??
          (orderData['tax1RateM'] as num?)?.toDouble() ??
          0.0;

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
          paymentSplits.add({
            'payMode': mode.toUpperCase(),
            'amount': amount,
            'amountStr': amount.toStringAsFixed(currencyDecimals),
          });
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
      final orderType =
          orderData['orderType']?.toString().toUpperCase() ?? 'WALK-IN';
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
          (orderData['address'] ?? orderData['Address'] ?? '')
              .toString()
              .trim();
      final customerTrn = (orderData['taxRegNo'] ?? orderData['CustTRN'] ?? '')
          .toString()
          .trim();
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

      final now = DateTime.now();
      final finalDateStr = dateStr ?? DateFormat('dd/MMM/yyyy').format(now);
      final finalTimeStr = timeStr ?? DateFormat('hh:mm:ss a').format(now);

      final List<Map<String, dynamic>> itemsPayload = [];
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
        final desc =
            (item['shortDescription'] ?? item['ShortDescription'] ?? '-')
                .toString();
        final descTrim = desc.length > 17 ? desc.substring(0, 17) : desc;
        String taxLineStr = '';
        if (taxAmt > 0 && taxRate > 0) {
          taxLineStr =
              '                  VAT@${taxRate.toStringAsFixed(0)}%  (${taxAmt.toStringAsFixed(2)})';
        }
        itemsPayload.add({
          'shortDescription': descTrim,
          'qty': qty,
          'unitPrice': unitPrice,
          'lineTotal': lineTotalComputed,
          'tax1AmountC': taxAmt,
          'tax1RateC': taxRate,
          'taxLineStr': taxLineStr,
        });
      }

      String printerName;
      if (useSalesReceiptPrinter) {
        final name = salesReceiptPrintPrinterNameWindows.trim();
        if (useMicrosoftPrintToPdfForSettlement) {
          printerName = 'Microsoft Print to PDF';
        } else {
          printerName = name.isNotEmpty ? name : settlementPrintPrinterNameWindows.trim();
          // Empty = let native code use Windows default printer (do not force PDF)
        }
      } else {
        if (useMicrosoftPrintToPdfForSettlement) {
          printerName = 'Microsoft Print to PDF';
        } else {
          printerName = settlementPrintPrinterNameWindows.trim();
          // Empty = let native code use Windows default printer (do not force PDF)
        }
      }

      final Map<String, dynamic> args = {
        'billNo': billNo,
        'jobNo': orderNoDisplay,
        'paidAmount': paidAmount,
        'balancePaid': balancePaid,
        'paymentMode': paymentMode,
        'outstandingBalance': outstandingBalance,
        'netAmount': netAmount,
        'taxableAmount': taxableAmount,
        'tax1Amount': tax1Amount,
        'tax1Rate': tax1Rate,
        'counterNo': counterNo,
        'orderNoDisplay': orderNoDisplay,
        'orderType': orderType,
        'tableName': tableName,
        'waiterName': waiterName,
        'cashierName': cashierName,
        'comments': comments,
        'customerName': printCustomerName,
        'customerCode': customerCode,
        'mobileNo': customerMobile,
        'address': customerAddress,
        'taxRegNo': customerTrn,
        'showCustomer': !isWalkIn,
        'dateStr': finalDateStr,
        'timeStr': finalTimeStr,
        'printerName': printerName,
        'currencyDecimals': currencyDecimals,
        'items': itemsPayload,
        if (paymentSplits.isNotEmpty) 'paymentSplits': paymentSplits,
      };

      await _channel.invokeMethod<void>('printSettlementReceipt', args);
    } on PlatformException catch (e, st) {
      log('Windows native print error: $e', stackTrace: st);
      onError?.call(e.message ?? 'Print failed: $e');
    } catch (e, st) {
      log('Windows native print error: $e', stackTrace: st);
      onError?.call('Print failed: $e');
    }
  }
}
