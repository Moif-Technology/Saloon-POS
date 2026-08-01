import 'dart:developer';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:my_app/config/api_config.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:thermal_printer/thermal_printer.dart';

/// Sends raw ESC/POS bytes on Android.
/// Order: Sunmi built-in (if present) → network IP → USB ("counter" / "innerprinter" / "sunmi").
class AndroidEscPosSender {
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get isEnabled => isAndroid && useAndroidPrinting;

  static final SunmiPrinterPlus _sunmi = SunmiPrinterPlus();

  static bool? _sunmiAvailable;

  /// True when this device has a usable Sunmi inner printer.
  static Future<bool> detectSunmi() async {
    if (!isEnabled || !preferSunmiBuiltInPrinter) {
      _sunmiAvailable = false;
      return false;
    }
    if (_sunmiAvailable != null) return _sunmiAvailable!;

    try {
      await _sunmi.rebindPrinter();
      final status = await _sunmi.getStatus();
      final type = await _sunmi.getType();
      final ok = status != null &&
          status.trim().isNotEmpty &&
          !status.toUpperCase().contains('ERROR') &&
          !status.toUpperCase().contains('OFFLINE') &&
          !status.toUpperCase().contains('NULL');
      _sunmiAvailable = ok || (type != null && type.trim().isNotEmpty);
      log('Sunmi detect: status=$status type=$type available=$_sunmiAvailable');
    } catch (e, st) {
      log('Sunmi not available: $e', stackTrace: st);
      _sunmiAvailable = false;
    }
    return _sunmiAvailable!;
  }

  /// Force re-check next time (e.g. after docking / wake).
  static void resetSunmiCache() => _sunmiAvailable = null;

  static bool _isUsbReceiptPrinter(String deviceName) {
    final n = deviceName.trim().toLowerCase();
    return n == 'counter' ||
        n.contains('counter') ||
        n.contains('innerprinter') ||
        n.contains('inner printer') ||
        n.contains('sunmi');
  }

  /// Send ESC/POS [bytes] to the best available Android printer.
  static Future<void> send(
    List<int> bytes, {
    void Function(String message)? onError,
  }) async {
    if (!isEnabled) {
      onError?.call('Android printing is not available on this platform');
      return;
    }

    try {
      if (preferSunmiBuiltInPrinter && await detectSunmi()) {
        await _sunmi.rebindPrinter();
        await _sunmi.printEscPos(bytes);
        log('ESC/POS sent to Sunmi built-in printer');
        return;
      }

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
        log('ESC/POS sent to network printer $ip:$receiptPrinterPort');
        return;
      }

      _UsbTarget? selected;
      final sub = printerManager.discovery(type: PrinterType.usb).listen((device) {
        if (selected == null && _isUsbReceiptPrinter(device.name.toString())) {
          selected = _UsbTarget(
            name: device.name,
            vendorId: device.vendorId,
            productId: device.productId,
          );
        }
      });

      await Future.delayed(const Duration(seconds: 3));
      await sub.cancel();

      final printer = selected;
      if (printer == null) {
        const msg =
            'No Android printer found. Use a Sunmi device, set receiptPrinterIP, or connect a USB printer named "counter".';
        log(msg);
        onError?.call(msg);
        return;
      }

      await printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: printer.name,
          productId: printer.productId,
          vendorId: printer.vendorId,
        ),
      );
      await printerManager.send(type: PrinterType.usb, bytes: bytes);
      log('ESC/POS sent to USB ${printer.name}');
    } catch (e, st) {
      log('Android ESC/POS send error: $e', stackTrace: st);
      onError?.call('Print failed: $e');
    }
  }
}

class _UsbTarget {
  final String? name;
  final String? vendorId;
  final String? productId;
  _UsbTarget({this.name, this.vendorId, this.productId});
}
