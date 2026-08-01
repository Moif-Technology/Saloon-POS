import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:my_app/config/api_config.dart';
import 'package:my_app/services/printService/android_escpos_sender.dart';
import 'package:my_app/services/printService/kot_receipt_printer.dart';
import 'package:my_app/services/printService/settlement_receipt_printer.dart';
import 'package:my_app/services/printService/web/receipt_printer.dart'
    as web_print;
import 'package:my_app/services/printService/windows_native_kot_printer.dart';
import 'package:my_app/services/printService/windows_native_settlement_printer.dart';

/// Platform-aware print entry points for settlement, sales receipt, and KOT.
///
/// Routes:
/// - Web → browser print window
/// - Windows → native GDI (when flags enabled)
/// - Android → Sunmi built-in, else network/USB ESC/POS
class PosPrint {
  static Future<void> printSettlement({
    required Map<String, dynamic> result,
    required Map<String, dynamic> orderData,
    required String customerName,
    int currencyDecimals = 2,
    void Function(String message)? onError,
  }) async {
    if (kIsWeb) {
      await web_print.printSettlementWeb(
        result: result,
        orderData: orderData,
        customerName: customerName,
        currencyDecimals: currencyDecimals,
      );
      return;
    }

    if (Platform.isWindows &&
        useWindowsNativeSettlementPrint &&
        WindowsNativeSettlementPrinter.isAvailable) {
      await WindowsNativeSettlementPrinter.printSettlement(
        result: result,
        orderData: orderData,
        customerName: customerName,
        currencyDecimals: currencyDecimals,
        onError: onError,
      );
      return;
    }

    if (AndroidEscPosSender.isEnabled) {
      await SettlementReceiptPrinter.printReceipt(
        result: result,
        orderData: orderData,
        customerName: customerName,
        currencyDecimals: currencyDecimals,
        onError: onError,
      );
      return;
    }

    onError?.call('Settlement print is not available on this platform');
  }

  static Future<void> printSalesReceipt({
    required Map<String, dynamic> receiptData,
    int currencyDecimals = 2,
    void Function(String message)? onError,
  }) async {
    if (kIsWeb) {
      onError?.call('Sales receipt print is not available on web.');
      return;
    }

    if (Platform.isWindows &&
        useWindowsNativeSalesReceiptPrint &&
        WindowsNativeSettlementPrinter.isSalesReceiptAvailable) {
      await WindowsNativeSettlementPrinter.printSalesReceipt(
        receiptData: receiptData,
        currencyDecimals: currencyDecimals,
        onError: onError,
      );
      return;
    }

    if (AndroidEscPosSender.isEnabled) {
      await SettlementReceiptPrinter.printSalesReceipt(
        receiptData: receiptData,
        currencyDecimals: currencyDecimals,
        onError: onError,
      );
      return;
    }

    onError?.call('Sales receipt print is not available on this platform');
  }

  static Future<void> printKOT({
    required Map<String, dynamic> kotDetails,
    String supplyType = 'DINE IN',
    String title = 'JOB TICKET',
    String kitchenLocation = 'PASSING',
    void Function(String message)? onError,
  }) async {
    if (kIsWeb) {
      await web_print.printKOTWeb(
        kotDetails: kotDetails,
        supplyType: supplyType,
        title: title,
      );
      return;
    }

    if (WindowsNativeKOTPrinter.isAvailable) {
      await WindowsNativeKOTPrinter.printKOT(
        kotDetails: kotDetails,
        supplyType: supplyType,
        title: title,
        kitchenLocation: kitchenLocation,
        onError: onError,
      );
      return;
    }

    if (AndroidEscPosSender.isEnabled) {
      await KotReceiptPrinter.printKOT(
        kotDetails: kotDetails,
        supplyType: supplyType,
        title: title,
        kitchenLocation: kitchenLocation,
        onError: onError,
      );
      return;
    }

    onError?.call('Job print not available on this platform');
  }
}
