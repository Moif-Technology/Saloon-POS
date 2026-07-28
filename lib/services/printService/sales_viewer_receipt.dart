import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:thermal_printer/thermal_printer.dart';

class SalesViewerPrinting extends ConsumerStatefulWidget {
  const SalesViewerPrinting({Key? key}) : super(key: key);

  @override
  ConsumerState<SalesViewerPrinting> createState() =>
      _SalesViewerPrintingState();
}

class _SalesViewerPrintingState extends ConsumerState<SalesViewerPrinting> {
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

    // ✅ Check if data from provider is available
    Future.microtask(() {
      final data = ref.read(salesViewerPrintDataProvider);
      log("🧾 Receipt Data from Provider:\n${data.toString()}");
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
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.right,
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 24,
          color: Color(0xFF000000),
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
    return img.decodeImage(pngBytes)!;
  }

  String generateSeparatorLine(int length) {
    return List.filled(length, '-').join();
  }

  Future<img.Image> generateDualLangTitle(
      String englishText, String arabicText) async {
    const double width = 380;
    const double height = 40;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

    // English left aligned
    final englishPainter = TextPainter(
      textDirection: ui.TextDirection.rtl,
      text: TextSpan(
        text: englishText,
        style: const TextStyle(fontSize: 24, color: Colors.black),
      ),
    );
    englishPainter.layout();
    englishPainter.paint(canvas, const Offset(0, 8)); // top-left

    // Arabic right aligned
    final arabicPainter = TextPainter(
      textDirection: ui.TextDirection.rtl,
      text: TextSpan(
        text: arabicText,
        style: const TextStyle(fontSize: 24, color: Colors.black),
      ),
    );
    arabicPainter.layout(maxWidth: width);
    arabicPainter.paint(
        canvas, Offset(width - arabicPainter.width, 8)); // top-right

    final picture = recorder.endRecording();
    final ui.Image uiImage =
        await picture.toImage(width.toInt(), height.toInt());
    final ByteData? byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception("Failed to convert UI image to byte data.");
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();
    return img.decodeImage(pngBytes)!;
  }

  Future<void> _printReceipt() async {
    _selectDefaultPrinter();

    if (selectedPrinter == null) {
      log('No printers available.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No USB printers detected. Please connect a printer.'),
        ),
      );
      return;
    }

    final data = ref.read(salesViewerPrintDataProvider);
    final header = data['header'] ?? {};
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

    final billNo = header['BillNo'] ?? '';
    final billDate = DateTime.tryParse(header['BillDate'] ?? '')?.toLocal();
    final billTime = DateTime.tryParse(header['BillTime'] ?? '')?.toLocal();
    final counterNo = header['CounterNo']?.toString() ?? '';
    final cashier = header['CashierName'] ?? header['SalesManID'].toString();
    final supplyType = header['SupplyType'] ?? '';

    List<int> bytes = [];
    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm80, profile);

    bytes += generator.text('Emirates Sea Restaurant L.L.C',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('MW4, Mussafah, Abu Dhabi, U.A.E',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('TL:025506688, Mb:0567137567/0544761636',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('TRN No: 100061566400003',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(generateSeparatorLine(48));

    final dualLangTitle =
        await generateDualLangTitle('Tax Invoice', 'فاتورة ضريبية');
    bytes += generator.imageRaster(dualLangTitle, align: PosAlign.center);
    bytes += generator.text(generateSeparatorLine(48));

    bytes += generator.text('KOT : $supplyType');
    bytes += generator.text(generateSeparatorLine(48));

    final formattedDate =
        billDate != null ? DateFormat('dd/MM/yyyy').format(billDate) : '';
    final formattedTime =
        billTime != null ? DateFormat('hh:mm:ss a').format(billTime) : '';

    bytes += generator.row([
      PosColumn(text: 'Bill No: $billNo', width: 6),
      PosColumn(text: 'Date: $formattedDate $formattedTime', width: 6),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Counter No: $counterNo', width: 6),
      PosColumn(text: 'Cashier: $cashier', width: 6),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Table: ', width: 6),
      PosColumn(text: 'Waiter: ', width: 6),
    ]);

    bytes += generator.text('Comments: ');
    bytes += generator.text(generateSeparatorLine(48));

    bytes += generator.row([
      PosColumn(
          text: 'Description', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Price', width: 2, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Total', width: 2, styles: const PosStyles(bold: true)),
    ]);

    bytes += generator.text(generateSeparatorLine(48));

    double total = 0;
    for (var item in items) {
      final qty = (item["Qty"] ?? 0).toDouble();
      final unitPrice = (item["UnitPrice"] ?? 0).toDouble();
      final taxAmount = (item["Tax1AmountC"] ?? 0).toDouble();
      final lineTotal = (item["LineTotal"] ?? 0).toDouble();

      // Calculate tax per item
      final taxPerUnit = qty > 0 ? taxAmount / qty : 0;
      final priceWithTax = unitPrice + taxPerUnit;

      total += lineTotal;

      bytes += generator.row([
        PosColumn(text: item["ShortDescription"] ?? "-", width: 6),
        PosColumn(
            text: qty.toInt().toString(),
            width: 2,
            styles: const PosStyles(align: PosAlign.right)),
        PosColumn(
            text: priceWithTax.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(align: PosAlign.right)),
        PosColumn(
            text: lineTotal.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.text(generateSeparatorLine(48));

    bytes += generator.row([
      PosColumn(
          text: 'TOTAL:',
          width: 8,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(
          text: total.toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);

    bytes += generator.text('Settlement: CASH');

    bytes += generator.row([
      PosColumn(text: 'Items:', width: 6),
      PosColumn(text: '${items.length}', width: 2),
      PosColumn(text: 'Bill Amount:', width: 2),
      PosColumn(
          text: total.toStringAsFixed(2),
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Qty:', width: 6),
      PosColumn(text: '${items.length}', width: 2),
      PosColumn(text: 'Paid Amount:', width: 2),
      PosColumn(
          text: total.toStringAsFixed(2),
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Bal. Amount:', width: 10),
      PosColumn(
          text: '0.00',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.text(generateSeparatorLine(48));

    bytes += generator.text('Tax Details',
        styles: const PosStyles(bold: true, align: PosAlign.center));
    bytes += generator.row([
      PosColumn(text: 'Taxable Amount', width: 6),
      PosColumn(
          text: 'VAT@5%',
          width: 3,
          styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          text: 'Bill Amount',
          width: 3,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    final taxableAmount =
        double.tryParse(header['TaxableAmount']?.toString() ?? '0') ?? 0;
    final vatAmount =
        double.tryParse(header['Tax1AmountM']?.toString() ?? '0') ?? 0;

    bytes += generator.row([
      PosColumn(text: taxableAmount.toStringAsFixed(2), width: 6),
      PosColumn(
          text: vatAmount.toStringAsFixed(2),
          width: 3,
          styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          text: total.toStringAsFixed(2),
          width: 3,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.text(generateSeparatorLine(48));
    bytes += generator.text('THANK YOU .. VISIT AGAIN',
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

    printerManager.send(type: PrinterType.usb, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Windows USB Thermal Printer')),
      body: Center(
        child: ElevatedButton(
          onPressed: _printReceipt,
          child: const Text('Print Test Receipt'),
        ),
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
