import 'dart:developer';

import 'package:intl/intl.dart';
import 'package:my_app/services/printService/android_escpos_sender.dart';
import 'package:my_app/utils/sessionManager.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';

/// Job / KOT ticket via ESC/POS (Android Sunmi / network / USB).
/// Layout mirrors Windows native / web KOT text.
class KotReceiptPrinter {
  static Future<void> printKOT({
    required Map<String, dynamic> kotDetails,
    String supplyType = 'DINE IN',
    String title = 'JOB TICKET',
    String kitchenLocation = 'PASSING',
    void Function(String message)? onError,
  }) async {
    try {
      final data = kotDetails['data'] as List<dynamic>? ?? [];
      if (data.isEmpty) {
        onError?.call('No job data to print');
        return;
      }

      final bytes = await _buildBytes(
        data: data,
        supplyType: supplyType,
        title: title,
        kitchenLocation: kitchenLocation,
      );

      if (AndroidEscPosSender.isEnabled) {
        await AndroidEscPosSender.send(bytes, onError: onError);
      } else {
        onError?.call('Job print is only available on Android thermal printers');
      }
    } catch (e, st) {
      log('KOT ESC/POS print error: $e', stackTrace: st);
      onError?.call('Job print failed: $e');
    }
  }

  static Future<List<int>> _buildBytes({
    required List<dynamic> data,
    required String supplyType,
    required String title,
    required String kitchenLocation,
  }) async {
    final first = data[0] as Map<String, dynamic>? ?? {};
    String s(dynamic v) => (v ?? '').toString().trim();

    final kotPrefix = s(first['KotPrefix'] ?? first['kotPrefix']);
    final kotNumber = s(first['KotNumber'] ?? first['kotNumber'] ?? '0');
    final areaName = s(first['AreaName'] ?? first['areaName'] ?? '-');
    final tableName = s(first['TableName'] ?? first['tableName']);
    final counterNo = s(first['CounterNo'] ??
        first['counterNo'] ??
        SessionManager().stationId ??
        '');
    final waiterId = first['WaiterID'] ?? first['waiterID'];
    final chairNo = first['ChairNo'] ?? first['chairNo'] ?? 1;
    final chair = chairNo is int
        ? chairNo
        : int.tryParse(chairNo.toString()) ?? 1;
    final kotTime = first['KotTime'] ?? first['kotTime'];

    String waiterName = '-';
    if (waiterId != null && waiterId.toString() != '0') {
      waiterName = 'Waiter #$waiterId';
    }

    DateTime? dt;
    if (kotTime is DateTime) {
      dt = kotTime;
    } else if (kotTime is String) {
      dt = DateTime.tryParse(kotTime);
    }
    final now = DateTime.now();
    final useDt = dt ?? now;
    final dateStr = DateFormat('dd/MM/yyyy').format(useDt);
    final timeStr = DateFormat('hh:mm:ss a').format(useDt);
    final printedTime = DateFormat('hh:mm a').format(now);

    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm80, profile);
    const sep = '------------------------------------------------------------';

    List<int> bytes = [];
    bytes += generator.text(title.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(
        '$kitchenLocation - ${supplyType.toUpperCase()}',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Job#$kotPrefix$kotNumber-$areaName',
        styles: const PosStyles(bold: true));
    if (tableName.isNotEmpty) {
      bytes += generator.text('Table No - $tableName',
          styles: const PosStyles(bold: true));
    }
    bytes += generator.feed(1);
    bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Counter : $counterNo  $dateStr  $timeStr',
        styles: const PosStyles(bold: true));
    String waiterLine = 'Waiter:$waiterName';
    if (chair > 1) waiterLine += '    Chair No:$chair';
    bytes += generator.text(waiterLine, styles: const PosStyles(bold: true));
    bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Qty  Description',
        styles: const PosStyles(bold: true));
    bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));

    double totalQty = 0;
    int itemCount = 0;
    for (final row in data) {
      final m = row as Map<String, dynamic>? ?? {};
      final productId = m['ProductID'] ?? m['productID'];
      if (productId == null) continue;
      itemCount++;
      final desc = s(m['ShortDescription'] ?? m['shortDescription'] ?? '-');
      final qtyRaw = m['Qty'] ?? m['qty'] ?? 1;
      final qty = qtyRaw is num
          ? qtyRaw.toDouble()
          : double.tryParse(qtyRaw.toString()) ?? 1.0;
      totalQty += qty < 0 ? -qty : qty;
      final qtyStr =
          qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toString();
      final line = '$qtyStr  -$desc';
      bytes += generator.text(
          line.length > 42 ? line.substring(0, 42) : line,
          styles: const PosStyles(bold: true));
      final mod = s(m['Modifier'] ?? m['modifier']);
      if (mod.isNotEmpty) {
        for (final part in mod.split('-')) {
          final p = part.trim();
          if (p.isNotEmpty) {
            bytes += generator.text('+++ $p +++');
          }
        }
      }
    }

    bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Items  : $itemCount');
    bytes += generator.text('Qty      : ${totalQty.toInt()}');
    bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Printed Time : $printedTime');
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }
}
