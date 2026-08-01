import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:my_app/core/providers/counter_close_provider.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/services/counter_close_mapper.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:thermal_printer/thermal_printer.dart';

class PrintPage extends ConsumerStatefulWidget {
  final String Type; // ✅ Determine X-Report or Z-Report
  final double collectedAmount;
  final double cashDifference;
  final String? selectedStaffId;
  /// When set (after X/Z API), used instead of re-fetching the provider.
  final Map<String, dynamic>? reportData;
  const PrintPage({
    Key? key,
    required this.Type,
    required this.collectedAmount,
    this.cashDifference = 0.0,
    this.selectedStaffId,
    this.reportData,
  }) : super(key: key);

  @override
  ConsumerState<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends ConsumerState<PrintPage> {
  List<BluetoothPrinter> devices = [];
  final printerManager = PrinterManager.instance;
  BluetoothPrinter? selectedPrinter;
  bool _isConnected = false;
  StreamSubscription<PrinterDevice>? _subscription;
  StreamSubscription<USBStatus>? _subscriptionUsbStatus;
  USBStatus _currentUsbStatus = USBStatus.none;

  @override
  void initState() {
    super.initState();
    _scanUSBPrinters();
    _subscriptionUsbStatus = printerManager.stateUSB.listen((status) {
      log('USB Status: $status');
      setState(() => _isConnected = status == USBStatus.connected);
    });
    print(widget.Type);

    // Add automatic printing after a short delay to allow printer discovery
    Future.delayed(Duration(milliseconds: 1000), () {
      _printReceipt();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionUsbStatus?.cancel();
    super.dispose();
  }

  void _scanUSBPrinters() {
    devices.clear();
    _subscription =
        printerManager.discovery(type: PrinterType.usb).listen((device) {
      setState(() {
        devices.add(BluetoothPrinter(
          deviceName: device.name,
          vendorId: device.vendorId,
          productId: device.productId,
          typePrinter: PrinterType.usb,
        ));
      });
    });
  }

  void _selectDefaultPrinter() {
    if (selectedPrinter == null && devices.isNotEmpty) {
      selectedPrinter = devices.firstWhere(
          (printer) => printer.deviceName?.toLowerCase() == "counter",
          orElse: () => devices.first);

      log('Using default printer: ${selectedPrinter!.deviceName}');
    }
  }

  /// ✅ Convert Arabic text into an image for printing
  Future<img.Image> generateArabicTextImage(String text) async {
    const double width = 380;
    const double height = 50;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFFFFFFFF); // White background
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

    final textPainter = TextPainter(
      textDirection: TextDirection.rtl, // ✅ Arabic needs RTL
      textAlign: TextAlign.center,
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 24,
          color: Color(0xFF000000), // ✅ Black text
        ),
      ),
    );

    textPainter.layout(minWidth: width, maxWidth: width);
    textPainter.paint(canvas, const Offset(10, 10));

    final picture = recorder.endRecording();
    final ui.Image uiImage =
        await picture.toImage(width.toInt(), height.toInt());
    final ByteData? byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception("Failed to convert UI image to byte data.");
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();
    return img.decodeImage(pngBytes)!; // ✅ Convert byte data to img.Image
  }

  String generateSeparatorLine(int length) {
    return List.filled(length, '-').join();
  }

  String _amt(dynamic v) =>
      counterCloseNum(v).toStringAsFixed(2);

  Future<void> _printReceipt() async {
    _selectDefaultPrinter(); // Ensure a printer is selected

    if (selectedPrinter == null) {
      log('No printers available.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No USB printers detected. Please connect a printer.')),
        );
      }
      return;
    }

    // ✅ Prefer data from X/Z close response; else load live summary
    try {
      Map<String, dynamic> counterCloseData;
      if (widget.reportData != null && widget.reportData!.isNotEmpty) {
        counterCloseData = Map<String, dynamic>.from(widget.reportData!);
      } else {
        counterCloseData = Map<String, dynamic>.from(await ref.read(
            counterCloseProvider(widget.selectedStaffId ?? "null").future));
      }

      final pendingKotCheck = ref.read(pendingKotCheckProvider);
      counterCloseData['pendingKotCheck'] = pendingKotCheck;
      if (widget.Type == 'Z-Report' || widget.collectedAmount > 0) {
        counterCloseData['CollectedAmount'] = widget.collectedAmount;
        counterCloseData['collectedCash'] = widget.collectedAmount;
        final toCollect =
            counterCloseNum(counterCloseData['AmountToBeCollected']);
        counterCloseData['CashDifference'] =
            widget.collectedAmount - toCollect;
        counterCloseData['cashDifference'] =
            widget.collectedAmount - toCollect;
      }

      if (counterCloseData.isEmpty) {
        log('No counter close data available.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data available to print.')),
          );
        }
        return;
      }
      // ✅ Use provider data directly when printing
      List<int> bytes = [];
      final profile = await CapabilityProfile.load(name: 'XP-N160I');
      final generator = Generator(PaperSize.mm80, profile);

      DateTime now = DateTime.now();
      String formattedDate = "${now.day}/${now.month}/${now.year}";
      String formattedTime =
          "${now.hour}:${now.minute}:${now.second} ${now.hour >= 12 ? 'PM' : 'AM'}";

      final company = ref.read(companyDetailsProvider);
      final h1 = (company['heading1'] ?? '').trim();
      final h2 = (company['heading2'] ?? '').trim();
      final h3 = (company['heading3'] ?? '').trim();
      final trn = (company['taxRegNo'] ?? '').trim();

      bytes += generator.text(
          h1.isNotEmpty ? h1 : 'SALON POS',
          styles: const PosStyles(align: PosAlign.center, bold: true));
      if (h2.isNotEmpty) {
        bytes += generator.text(h2,
            styles: const PosStyles(align: PosAlign.center));
      }
      if (h3.isNotEmpty) {
        bytes += generator.text(h3,
            styles: const PosStyles(align: PosAlign.center));
      }
      if (trn.isNotEmpty) {
        bytes += generator.text('TRN: $trn',
            styles: const PosStyles(align: PosAlign.center));
      }

      // ✅ Full-width separator line
      bytes += generator.text('-' * 48);

      // ✅ Print "X-Report" or "Z-Report" based on `widget.Type`
      bytes += generator.text('${widget.Type}',
          styles: const PosStyles(align: PosAlign.center, bold: true));

      // ✅ Full-width separator line
      bytes += generator.text('-' * 48);

      // ✅ Date & Time (Left & Right)
      bytes += generator.row([
        PosColumn(text: 'Date: $formattedDate', width: 6),
        PosColumn(
            text: 'Time: $formattedTime',
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      final closeNo = (counterCloseData['closeNo'] ?? '').toString();
      bytes += generator.row([
        PosColumn(
            text: closeNo.isNotEmpty
                ? 'Close#: $closeNo'
                : 'Counter Close#:',
            width: 6),
        PosColumn(
            text:
                'Counter:${counterCloseData['CounterNo']?.toString() ?? 'N/A'}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      // ✅ Bill Count & Cashier Name (Side-by-side)
      bytes += generator.row([
        PosColumn(
          text:
              'Bill Count: ${counterCloseData['BillCount']?.toString() ?? '0'}',
          width: 6,
        ),
        PosColumn(
          text: 'Cashier: ${counterCloseData['cashierName'] ?? 'Unknown'}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      final startBill = counterCloseData['startBillNo'];
      final endBill = counterCloseData['endBillNo'];
      if (startBill != null || endBill != null) {
        bytes += generator.row([
          PosColumn(text: 'First Bill: ${startBill ?? '—'}', width: 6),
          PosColumn(
              text: 'Last Bill: ${endBill ?? '—'}',
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      // ✅ Full-width separator line
      bytes += generator.text('-' * 48);
// ✅ Table Header (Description | Amount)
      bytes += generator.row([
        PosColumn(text: 'Description', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
            text: 'Amount',
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);

// ✅ Full-width separator line
      bytes += generator.text(generateSeparatorLine(48)); // 48 dashes

// ✅ Table Rows - Fetching values from Provider dynamically
      bytes += generator.row([
        PosColumn(text: 'Cash Sales:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['totalCash']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Credit Received:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['ReceiptAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Advance Received:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['AdvanceReceived']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Cash IN:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['CashIN']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Cash OUT:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['CashOUt']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
            text: _amt(counterCloseNum(counterCloseData['totalCash']) +
                counterCloseNum(counterCloseData['ReceiptAmount'])),
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Refund:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['RefundAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.text(generateSeparatorLine(48));

      bytes += generator.row([
        PosColumn(text: 'Cash To Be Collected:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
            text: _amt(counterCloseData['AmountToBeCollected']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Collected Cash:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['CollectedAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Cash Difference:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['CashDifference']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.text(generateSeparatorLine(48));

      bytes += generator.row([
        PosColumn(text: 'Credit Sales:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['CreditAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Credit Card Sales:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['CreditCardAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Online Sales:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['OnlineAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Receipt Credit Card:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['ReceiptAmountCCard']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Voucher Sales:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['VoucherAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Compliment Sales:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['ComplimentAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Cash Sales (Less Refund):', width: 6),
        PosColumn(
            text: _amt(counterCloseData['finalTotalCash']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Total Discount:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['DiscountAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Total Sales:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
            text: _amt(counterCloseData['TotalAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Taxable Amount:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['TaxableAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Tax Amount:', width: 6),
        PosColumn(
            text: _amt(counterCloseData['TaxAmount']),
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.text(generateSeparatorLine(48));
      bytes += generator.text('BILL COUNT',
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(generateSeparatorLine(48));

      bytes += generator.row([
        PosColumn(
            text: 'Cash Bill: ${counterCloseData['CashBillCount'] ?? 0}',
            width: 6),
        PosColumn(
            text:
                'Credit Card: ${counterCloseData['CreditCardBillCount'] ?? 0}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(
            text: 'Multi Pay: ${counterCloseData['MultiBillCount'] ?? 0}',
            width: 6),
        PosColumn(
            text: 'Credit Bill: ${counterCloseData['CreditBillCount'] ?? 0}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(
            text:
                'Compliment: ${counterCloseData['ComplimentBillCount'] ?? 0}',
            width: 6),
        PosColumn(text: '', width: 6),
      ]);

      bytes += generator.text(generateSeparatorLine(48));
      bytes += generator.text('${widget.Type} — End',
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.feed(2);
      bytes += generator.cut();

      await printerManager.connect(
        type: selectedPrinter!.typePrinter,
        model: UsbPrinterInput(
          name: selectedPrinter!.deviceName,
          productId: selectedPrinter!.productId,
          vendorId: selectedPrinter!.vendorId,
        ),
      );
      await printerManager.send(
          type: selectedPrinter!.typePrinter, bytes: bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.Type} printed'),
            backgroundColor: const Color(0xFF521C1D),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      log('Counter close print error: $e', stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Printing...', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
class BluetoothPrinter {
  String? deviceName;
  String? vendorId;
  String? productId;
  PrinterType typePrinter;

  BluetoothPrinter({
    this.deviceName,
    this.vendorId,
    this.productId,
    this.typePrinter = PrinterType.usb,
  });
}
