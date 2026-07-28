import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/utils/sessionManager.dart';

/// Windows-only: prints KOT (Kitchen Order Ticket) via native GDI - same layout as VB Print_KOT.
/// Uses method channel com.myapp/native_settlement_print, method printKotReceipt.
class WindowsNativeKOTPrinter {
  static const MethodChannel _channel =
      MethodChannel('com.myapp/native_settlement_print');

  /// Returns true if Windows native KOT printing is available.
  static bool get isAvailable => Platform.isWindows && useWindowsNativeKOTPrint;

  /// Print KOT from kotDetails (displayKots response) or from cart + metadata.
  /// kotDetails: { success, data: List<Map> } - each row has header + item fields.
  /// supplyType: DINE IN | PARCEL | DELIVERY
  /// title: "KITCHEN ORDER TICKET" | "Duplicate KOT" | "CANCEL KOT"
  static Future<void> printKOT({
    required Map<String, dynamic> kotDetails,
    String supplyType = 'DINE IN',
    String title = 'KITCHEN ORDER TICKET',
    String kitchenLocation = 'PASSING',
    void Function(String message)? onError,
  }) async {
    if (!Platform.isWindows) {
      onError?.call('Windows native KOT print is only available on Windows');
      return;
    }

    try {
      final data = kotDetails['data'] as List<dynamic>? ?? [];
      if (data.isEmpty) {
        onError?.call('No KOT data to print');
        return;
      }

      final first = data[0] as Map<String, dynamic>? ?? {};
      final kotPrefix =
          (first['KotPrefix'] ?? first['kotPrefix'] ?? '').toString();
      final kotNumber =
          (first['KotNumber'] ?? first['kotNumber'] ?? '0').toString();
      final areaName =
          (first['AreaName'] ?? first['areaName'] ?? '-').toString();
      final tableName =
          (first['TableName'] ?? first['tableName'] ?? '').toString();
      final counterNo = (first['CounterNo'] ??
              first['counterNo'] ??
              SessionManager().stationId ??
              '')
          .toString();
      final waiterId = first['WaiterID'] ?? first['waiterID'];
      final chairNo = (first['ChairNo'] ?? first['chairNo'] ?? 1);
      final kotTime = first['KotTime'] ?? first['kotTime'];

      String waiterName = '-';
      if (waiterId != null && waiterId.toString() != '0') {
        // Waiter name would come from StaffMaster - for now use ID or leave as -
        waiterName = 'Waiter #${waiterId}';
      }

      DateTime? dt;
      if (kotTime != null) {
        if (kotTime is DateTime) {
          dt = kotTime;
        } else if (kotTime is String) {
          dt = DateTime.tryParse(kotTime);
        }
      }
      final now = DateTime.now();
      final dateStr = dt != null
          ? DateFormat('dd/MM/yyyy').format(dt)
          : DateFormat('dd/MM/yyyy').format(now);
      final timeStr = dt != null
          ? DateFormat('hh:mm:ss a').format(dt)
          : DateFormat('hh:mm:ss a').format(now);

      final items = <Map<String, dynamic>>[];
      for (final row in data) {
        final m = row as Map<String, dynamic>? ?? {};
        final productId = m['ProductID'] ?? m['productID'];
        if (productId == null) continue;
        final qty = (m['Qty'] ?? m['qty'] ?? 1);
        final q = (qty is num)
            ? qty.toDouble()
            : double.tryParse(qty.toString()) ?? 1.0;
        items.add({
          'shortDescription':
              (m['ShortDescription'] ?? m['shortDescription'] ?? '-')
                  .toString(),
          'qty': q,
          'Qty': q,
          'modifier': (m['Modifier'] ?? m['modifier'] ?? '').toString(),
          'Modifier': (m['Modifier'] ?? m['modifier'] ?? '').toString(),
        });
      }

      String printerName;
      if (useMicrosoftPrintToPdfForKOT) {
        printerName = 'Microsoft Print to PDF';
      } else {
        printerName = kotPrintPrinterNameWindows.trim();
        if (printerName.isEmpty) printerName = settlementPrintPrinterNameWindows.trim();
        // Empty = let native code use Windows default printer (do not force PDF)
      }

      final args = <String, dynamic>{
        'title': title,
        'kitchenLocation': kitchenLocation,
        'supplyType': supplyType.toUpperCase(),
        'kotPrefix': kotPrefix,
        'kotNumber': kotNumber,
        'areaName': areaName,
        'tableName': tableName,
        'counterNo': counterNo,
        'dateStr': dateStr,
        'timeStr': timeStr,
        'waiterName': waiterName,
        'chairNo':
            chairNo is int ? chairNo : int.tryParse(chairNo.toString()) ?? 1,
        'printerName': printerName,
        'items': items,
      };

      await _channel.invokeMethod<void>('printKotReceipt', args);
      log('KOT print sent to Windows native (GDI)');
    } on PlatformException catch (e, st) {
      log('Windows native KOT print error: $e', stackTrace: st);
      onError?.call(e.message ?? 'KOT print failed: $e');
    } catch (e, st) {
      log('Windows native KOT print error: $e', stackTrace: st);
      onError?.call('KOT print failed: $e');
    }
  }
}
