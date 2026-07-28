import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:my_app/core/providers/counter_close_provider.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:thermal_printer/thermal_printer.dart';

class PrintPage extends ConsumerStatefulWidget {
  final String Type; // ✅ Determine X-Report or Z-Report
  final double collectedAmount;
  final double cashDifference;
  final String? selectedStaffId;
  const PrintPage({
    Key? key,
    required this.Type,
    required this.collectedAmount,
    this.cashDifference = 0.0,
    this.selectedStaffId,
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

  Future<void> _printReceipt() async {
    _selectDefaultPrinter(); // Ensure a printer is selected

    if (selectedPrinter == null) {
      log('No printers available.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No USB printers detected. Please connect a printer.')),
      );
      return;
    }

    if (selectedPrinter == null) {
      log('No printers available.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No USB printers detected. Please connect a printer.')),
      );
      return;
    }

    // ✅ Fetch Provider Data Only When Printing
    try {
      final counterCloseData = await ref
          .read(counterCloseProvider(widget.selectedStaffId ?? "null").future);

      final pendingKotCheck = ref.read(pendingKotCheckProvider);
      counterCloseData['pendingKotCheck'] = pendingKotCheck;
      print(counterCloseData);
      if (widget.Type == 'Z-Report') {
        counterCloseData['CollectedAmount'] = widget.collectedAmount;
        counterCloseData['CashDifference'] = widget.collectedAmount -
            (double.tryParse(
                    counterCloseData['AmountToBeCollected'].toString()) ??
                0.0);

      }

      if (counterCloseData.isEmpty) {
        log('No counter close data available.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available to print.')),
        );
        return;
      }
      // ✅ Use provider data directly when printing
      List<int> bytes = [];
      final profile = await CapabilityProfile.load(name: 'XP-N160I');
      final generator = Generator(PaperSize.mm80, profile);

      // // ✅ Extract data from provider dynamically
      // final counterNo = data['CounterNo']?.toString() ?? 'N/A';
      // final cashierName = data['cashierName'] ?? 'Unknown';
      // final billCount = data['BillCount']?.toString() ?? '0';

      // ✅ Get Current Date & Time
      DateTime now = DateTime.now();
      String formattedDate = "${now.day}/${now.month}/${now.year}";
      String formattedTime =
          "${now.hour}:${now.minute}:${now.second} ${now.hour >= 12 ? 'PM' : 'AM'}";

      // ✅ Business Header
      bytes += generator.text('Emirates Sea Restaurant L.L.C',
          styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('MW4, Mussafah, Abu Dhabi, U.A.E',
          styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('TL:025506688, Mb:0567137567/0544761636',
          styles: PosStyles(align: PosAlign.center));

      // ✅ Full-width separator line
      bytes += generator.text('-' * 48);

      // ✅ Print "X-Report" or "Z-Report" based on `widget.Type`
      bytes += generator.text('${widget.Type}',
          styles: PosStyles(align: PosAlign.center, bold: true));

      // ✅ Full-width separator line
      bytes += generator.text('-' * 48);

      // ✅ Date & Time (Left & Right)
      bytes += generator.row([
        PosColumn(text: 'Date: $formattedDate', width: 6),
        PosColumn(
            text: 'Time: $formattedTime',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      // ✅ Counter Close & Counter No (Side-by-side)
      bytes += generator.row([
        PosColumn(text: 'Counter Close#:', width: 6),
        PosColumn(
            text:
                'Counter:${counterCloseData['CounterNo']?.toString() ?? 'N/A'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
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
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);

      // ✅ Full-width separator line
      bytes += generator.text('-' * 48);
// ✅ Table Header (Description | Amount)
      bytes += generator.row([
        PosColumn(text: 'Description', width: 6, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'Amount',
            width: 6,
            styles: PosStyles(align: PosAlign.right, bold: true)),
      ]);

// ✅ Full-width separator line
      bytes += generator.text(generateSeparatorLine(48)); // 48 dashes

// ✅ Table Rows - Fetching values from Provider dynamically
      bytes += generator.row([
        PosColumn(text: 'Cash Sales:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['totalCash']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Credit Received:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['ReceiptAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Advance Received:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['AdvanceReceived']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Total Cash IN:', width: 6),
        PosColumn(
            text: '${counterCloseData['CashIN']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Total Cash Out:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['CashOUt']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

// ✅ Full-width separator for total
      bytes += generator.text(generateSeparatorLine(48));

      bytes += generator.row([
        PosColumn(
            text:
                '${counterCloseData['totalCash']?.toStringAsFixed(2) ?? '0.00'}',
            width: 12,
            styles: PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.feed(2); // Feeds 1 blank line
// ✅ Refund Row
      bytes += generator.row([
        PosColumn(text: 'Refund:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['RefundAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

// ✅ Full-width separator for clarity
      bytes += generator.text(generateSeparatorLine(48));
      bytes += generator.feed(1); // Feeds 1 blank line
// ✅ Cash To Be Collected
      bytes += generator.row([
        PosColumn(
            text: 'Cash To Be Collected:',
            width: 6,
            styles: PosStyles(bold: true)),
        PosColumn(
            text:
                '${counterCloseData['AmountToBeCollected']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right, bold: true)),
      ]);

// ✅ Collected Cash & Cash Difference
      bytes += generator.row([
        PosColumn(text: 'Collected Cash:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['CollectedAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Cash Difference:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['CashDifference']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

// ✅ Final separator
      bytes += generator.text(generateSeparatorLine(48));
      bytes += generator.feed(1); // Feeds 1 blank line
// ✅ Table Rows - Fetching values from Provider dynamically
      bytes += generator.row([
        PosColumn(text: 'Credit Sales:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['CreditAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Credit Card Sales:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['CreditCardAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Online Sales:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['OnlineAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Receipt Credit Card:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['ReceiptAmountCCard']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Voucher Sales:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['VoucherAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Compliment Sales:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['ComplimentAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Cash Sales (Less Refund):', width: 6),
        PosColumn(
            text:
                '${counterCloseData['finalTotalCash']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Total Discount Amount:', width: 6),
        PosColumn(
            text:
                '${counterCloseData['DiscountAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

// ✅ Full-width separator line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ Total Sales - Bold & Important
      bytes += generator.row([
        PosColumn(
            text: 'Total Sales:', width: 6, styles: PosStyles(bold: true)),
        PosColumn(
            text:
                '${counterCloseData['TotalAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right, bold: true)),
      ]);

// ✅ Full-width separator line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ Taxable Amount & Tax Amount
      bytes += generator.row([
        PosColumn(
            text: 'Taxable Amount:', width: 6, styles: PosStyles(bold: true)),
        PosColumn(
            text:
                '${counterCloseData['TaxableAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right, bold: true)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Tax Amount:', width: 6, styles: PosStyles(bold: true)),
        PosColumn(
            text:
                '${counterCloseData['TaxAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right, bold: true)),
      ]);

// ✅ Final separator
      bytes += generator.text(generateSeparatorLine(48));

      bytes += generator.feed(3); // Feeds 1 blank line
// ✅ Bill Cancel Details Section
      bytes += generator.text('Bill Cancel Details',
          styles: PosStyles(bold: true, align: PosAlign.left));
// ✅ Final separator
      bytes += generator.text(generateSeparatorLine(48));
      bytes += generator.feed(1); // Feeds 1 blank line
// ✅ Table Header (Cancel Type | Amount)
      bytes += generator.row([
        PosColumn(text: 'Cancel Type', width: 6, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'Amount',
            width: 6,
            styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);

// ✅ Separator Line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ Bill Cancelled & Item Cancelled Data
      bytes += generator.row([
        PosColumn(text: 'Bill Cancelled', width: 6),
        PosColumn(
            text:
                '${counterCloseData['billCancelledAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Item Cancelled', width: 6),
        PosColumn(
            text:
                '${counterCloseData['itemCancelledAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

// ✅ Full-width separator line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ KOT Status Row
      bytes += generator.row([
        PosColumn(
            text: 'KOT Status:',
            width: 6,
            styles: PosStyles(bold: true, align: PosAlign.left)),
        PosColumn(
            text: 'PENDING',
            width: 6,
            styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);

// ✅ Separator Line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ KOT Table Header
      bytes += generator.row([
        PosColumn(text: 'KOT Number', width: 6, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'Amount',
            width: 6,
            styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);

      bytes += generator.text(generateSeparatorLine(48));

// ✅ Fetch KOT List from Provider
      List<dynamic> kotList =
          counterCloseData['kotList'] ?? []; // Default empty list if null

// ✅ Check if KOT List is Empty
      if (kotList.isEmpty) {
        bytes += generator.text('No KOT Data Available',
            styles: PosStyles(align: PosAlign.center));
      } else {
        // ✅ Print KOT Numbers & Amounts (Using Actual Data)
        // ✅ Print KOT Numbers & Amounts (Using Actual Data)
        for (var kot in kotList) {
          bytes += generator.row([
            PosColumn(text: kot["kotNumber"].toString(), width: 6),
            PosColumn(
                text: double.tryParse(kot["amount"].toString())
                        ?.toStringAsFixed(2) ??
                    '0.00',
                width: 6,
                styles: PosStyles(align: PosAlign.right)),
          ]);
        }
      }

// ✅ Final Separator
      bytes += generator.text(generateSeparatorLine(48));

      // ✅ Bill Count Section
      bytes += generator.text('Bill Count:', styles: PosStyles(bold: true));

// ✅ Three-column layout (Width: 4+4+4 = 12)
      bytes += generator.row([
        PosColumn(
            text: 'Cash Bill: ${counterCloseData['CashBillCount'] ?? 0}',
            width: 4),
        PosColumn(
            text:
                'Credit Card: ${counterCloseData['CreditCardBillCount'] ?? 0}',
            width: 4,
            styles: PosStyles(align: PosAlign.center)),
        PosColumn(
            text: 'Multi Pay: ${counterCloseData['MultiBillCount'] ?? 0}',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(
            text: 'Credit Bill: ${counterCloseData['CreditBillCount'] ?? 0}',
            width: 6),
        PosColumn(
            text: 'Compliment: ${counterCloseData['ComplimentBillCount'] ?? 0}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]);

// ✅ Full-width separator line
      bytes += generator.text(generateSeparatorLine(48));
// ✅ CARD Sales Details Section
      bytes += generator.text('CARD Sales Details',
          styles: PosStyles(bold: true, align: PosAlign.center));

// ✅ Separator Line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ Card Sales Table Header (3-column layout)
      bytes += generator.row([
        PosColumn(text: 'CARD', width: 4, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'BillCount',
            width: 4,
            styles: PosStyles(bold: true, align: PosAlign.center)),
        PosColumn(
            text: 'Amount',
            width: 4,
            styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);

// ✅ Separator Line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ Fetch Card Sales Data from Provider
      List<dynamic> creditCardSales = counterCloseData['creditCardSales'] ?? [];

// ✅ Check if data is available
      if (creditCardSales.isEmpty) {
        bytes += generator.row([
          PosColumn(
              text: 'No Card Sales Data',
              width: 12,
              styles: PosStyles(align: PosAlign.center)),
        ]);
      } else {
        // ✅ Print Each Card Entry
        for (var card in creditCardSales) {
          bytes += generator.row([
            PosColumn(text: card["creditCardName"], width: 4),
            PosColumn(
                text: '${card["ccCount"]}',
                width: 4,
                styles: PosStyles(align: PosAlign.center)),
            PosColumn(
                text: double.tryParse(card["creditCardAmount"].toString())
                        ?.toStringAsFixed(2) ??
                    '0.00',
                width: 4,
                styles: PosStyles(align: PosAlign.right)),
          ]);
        }
      }

// ✅ Full-width separator line
      bytes += generator.text(generateSeparatorLine(48));
// ✅ ONLINE SALES DETAILS SECTION
      bytes += generator.text('Online Sales Details',
          styles: PosStyles(bold: true, align: PosAlign.center));

// ✅ Separator Line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ Online Sales Table Header
      bytes += generator.row([
        PosColumn(
            text: 'OnlineSource', width: 6, styles: PosStyles(bold: true)),
        PosColumn(
            text: 'BillCount',
            width: 3,
            styles: PosStyles(bold: true, align: PosAlign.center)),
        PosColumn(
            text: 'Amount',
            width: 3,
            styles: PosStyles(bold: true, align: PosAlign.right)),
      ]);

// ✅ Separator Line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ Dummy Online Sales Data (Replace this with actual data later)
      List<dynamic> onlineSalesData =
          counterCloseData['onlineSalesDetails'] ?? [];

// ✅ Print Each Online Sales Entry
      for (var sale in onlineSalesData) {
        bytes += generator.row([
          PosColumn(text: sale["onlineSourceName"], width: 6),
          PosColumn(
              text: '${sale["billCount"]}', // Bill Count as String
              width: 3,
              styles: PosStyles(align: PosAlign.center)),
          PosColumn(
              text: double.tryParse(sale["onlineAmount"].toString())
                      ?.toStringAsFixed(2) ??
                  '0.00',
              width: 3,
              styles: PosStyles(align: PosAlign.right)),
        ]);
      }

// ✅ Separator Line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ Number of Customers
      bytes += generator.row([
        PosColumn(
            text: 'No Of Customers:', width: 8, styles: PosStyles(bold: true)),
        PosColumn(
            text: '${counterCloseData['totalCustomers'] ?? 0}',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
      ]);

// ✅ Separator Line
      bytes += generator.text(generateSeparatorLine(48));

// ✅ Return Amount & Return Bill Count
      bytes += generator.row([
        PosColumn(text: 'Return Amount:', width: 8),
        PosColumn(
            text:
                '${counterCloseData['ReturnAmount']?.toStringAsFixed(2) ?? '0.00'}',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Return Bill Count:', width: 8),
        PosColumn(
            text: '${counterCloseData['ReturnBillCount'] ?? 0}',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
      ]);

// ✅ Refund Amount & Refund Bill Count
      bytes += generator.row([
        PosColumn(text: 'Refund Amount:', width: 8),
        PosColumn(
            text:
                '${counterCloseData['RefundAmount2ndOne']?.toStringAsFixed(2) ?? '0.00'}',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Refund Bill Count:', width: 8),
        PosColumn(
            text: '${counterCloseData['Refund2ndBillCount'] ?? 0}',
            width: 4,
            styles: PosStyles(align: PosAlign.right)),
      ]);

// ✅ Full-width separator line
      bytes += generator.text(generateSeparatorLine(48));

      bytes += generator.row([
        PosColumn(
            text: 'Cashier',
            width: 6,
            styles: PosStyles(align: PosAlign.center)),
        PosColumn(
            text: 'Supervisor',
            width: 6,
            styles: PosStyles(align: PosAlign.center)),
      ]);

      // ✅ Cashier & Supervisor Section
      bytes += generator.row([
        PosColumn(
            text: '----------------------',
            width: 6,
            styles: PosStyles(align: PosAlign.center)),
        PosColumn(
            text: '----------------------',
            width: 6,
            styles: PosStyles(align: PosAlign.center)),
      ]);

// ✅ Remarks Section
      bytes += generator.text('Remarks:', styles: PosStyles(bold: true));

// ✅ Full-width separator line
      bytes += generator.text(generateSeparatorLine(48));
      // ✅ Auto Feed & Cut
      bytes += generator.feed(3); // Feeds 3 blank lines before cutting
      bytes += generator.cut(); // Auto-cut the receipt

      // ✅ Send to Printer
      await printerManager.connect(
        type: selectedPrinter!.typePrinter,
        model: UsbPrinterInput(
          name: selectedPrinter!.deviceName,
          productId: selectedPrinter!.productId,
          vendorId: selectedPrinter!.vendorId,
        ),
      );

      printerManager.send(type: PrinterType.usb, bytes: bytes);
    } catch (e) {
      log('Error printing receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing receipt: $e')),
      );
    }
    ;
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
