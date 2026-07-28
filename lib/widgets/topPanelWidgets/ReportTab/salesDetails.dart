import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/services/printService/sales_viewer_receipt.dart';
import 'package:my_app/services/printService/windows_native_settlement_printer.dart';

class SalesDetailsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> salesData;

  const SalesDetailsDialog({
    Key? key,
    required this.salesData,
  }) : super(key: key);

  @override
  _SalesDetailsDialogState createState() => _SalesDetailsDialogState();
}

class _SalesDetailsDialogState extends ConsumerState<SalesDetailsDialog> {
  Map<String, dynamic>? fetchedDetails;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSalesDetails();
  }

  Future<void> _fetchSalesDetails() async {
    try {
      final details = <String, dynamic>{};
      setState(() {
        fetchedDetails = details;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to fetch sales details: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(salesData);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 800; // Check screen size
          return Container(
            width: MediaQuery.of(context).size.width * 0.99,
            height: constraints.maxHeight > 768 ? 768 : constraints.maxHeight,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 16),

                // Details Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopDetails(isSmallScreen),
                      const SizedBox(height: 16),
                      _buildTableHeader(),
                      const SizedBox(height: 8),
                      Expanded(child: _buildTable()),
                    ],
                  ),
                ),

                // Footer Section
                const SizedBox(height: 16),
                _buildFooter(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF521C1D), // Header background color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          "Sales Details",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white, // Header text color
          ),
        ),
      ),
    );
  }

  Widget _buildTopDetails(bool isSmallScreen) {
    final salesMaster = fetchedDetails?['salesMaster'] ?? {};
    final formattedBillDate = salesMaster['BillDate'] != null
        ? DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(salesMaster['BillDate']))
        : "N/A";

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailField(
                  "Bill No:", salesMaster['BillNo']?.toString() ?? "N/A"),
            ),
            if (!isSmallScreen)
              Expanded(
                child: _buildDetailField(
                    "Payment Mode:", salesMaster['PaymentMode'] ?? "N/A"),
              ),
            if (!isSmallScreen)
              Expanded(
                child: _buildDetailField(
                    "Customer Name:", salesMaster['CustomerName'] ?? "N/A"),
              ),
            if (!isSmallScreen)
              Expanded(
                child: _buildDetailField(
                    "Cashier Name:", salesMaster['SalesManName'] ?? "N/A"),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDetailField("Bill Date:", formattedBillDate),
            ),
            if (!isSmallScreen)
              Expanded(
                child: _buildDetailField("CreditCard No.:", "N/A"),
              ),
            if (!isSmallScreen)
              Expanded(
                child: _buildDetailField("CreditCard Type:", "N/A"),
              ),
            if (!isSmallScreen)
              Expanded(
                child: _buildDetailField("Counter No:",
                    salesMaster['CounterNo']?.toString() ?? "N/A"),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          constraints: const BoxConstraints(
            minWidth: 100, // Minimum width
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFF521C1D), // Matching color for table header
      child: Row(
        children: const [
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                "SI No",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Item Code",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                "Short Description",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                "Qty",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Selling Price",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Taxable Amount",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                "VAT(%)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Total",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final salesItems = fetchedDetails?['salesItems'] ?? [];

    // Use Riverpod to fetch the currency precession
    final currencyPrecession = ref.read(currencyPrecessionProvider) ?? "0.00";
    // Helper function for formatting with currency precession
    String formatPrice(dynamic value) {
      if (value == null) return "N/A";
      final double? parsedValue = double.tryParse(value.toString());
      if (parsedValue == null) return "N/A";
      return parsedValue.toStringAsFixed(
          int.parse(currencyPrecession.split('.')[1].length.toString()));
    }

    if (salesItems.isEmpty) {
      return const Center(
        child: Text(
          "No items available",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.separated(
      itemCount: salesItems.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300),
      itemBuilder: (context, index) {
        final item = salesItems[index];
        return Container(
          color: index % 2 == 0
              ? const Color(0xFFF8E1E1)
              : Colors.white, // Alternate row colors
          child: Row(
            children: [
              Expanded(
                  flex: 1, child: Center(child: Text("${index + 1}"))), // SI No
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text(
                          item["BarCode"]?.toString() ?? "N/A"))), // Item Code
              Expanded(
                  flex: 3,
                  child: Center(
                      child: Text(
                          item["ShortDescription"] ?? "N/A"))), // Description
              Expanded(
                  flex: 1,
                  child: Center(
                      child:
                          Text(item["Qty"]?.toString() ?? "N/A"))), // Quantity
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text(formatPrice(item["UnitPrice"])))), // Price
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text(
                          formatPrice(item["SubTotalC"])))), // Taxable Amount
              Expanded(
                  flex: 1,
                  child: Center(
                      child: Text(formatPrice(item["Tax1AmountC"])))), // VAT
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text(formatPrice(item["LineTotal"])))), // Total
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final salesMaster = fetchedDetails?['salesMaster'] ?? {};

    // Use Riverpod to fetch the currency precession
    final currencyPrecession = ref.read(currencyPrecessionProvider) ?? "0.00";
    // Helper function for formatting with currency precession
    String formatPrice(dynamic value) {
      if (value == null) return "N/A";
      final double? parsedValue = double.tryParse(value.toString());
      if (parsedValue == null) return "N/A";
      return parsedValue.toStringAsFixed(
          int.parse(currencyPrecession.split('.')[1].length.toString()));
    }

    // Extract relevant fields with formatting
    final taxableAmount = formatPrice(salesMaster['TaxableAmount']);
    final discountAmount = formatPrice(salesMaster['DiscountAmount']);
    final taxAmount = formatPrice(salesMaster['Tax1AmountM']);
    final netAmount = formatPrice(salesMaster['Amount']);
    final roundAdj = formatPrice(salesMaster['RoundOffAdj']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: Colors.grey),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFooterField("Amount:", taxableAmount),
            _buildFooterField("Discount:", discountAmount),
            _buildFooterField("VAT:", taxAmount),
            _buildFooterField("Net Amount:", netAmount),
            _buildFooterField("RoundAdj:", roundAdj, color: Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () async {
                final salesId = salesMaster['SalesID'].toString();
                final decParts = currencyPrecession.split('.');
                final decimals =
                    decParts.length > 1 ? decParts[1].length : 2;

                try {
                  final receiptData = <String, dynamic>{};

                  // Windows native (physical thermal or Microsoft Print to PDF)
                  if (!kIsWeb &&
                      Platform.isWindows &&
                      useWindowsNativeSalesReceiptPrint &&
                      WindowsNativeSettlementPrinter.isSalesReceiptAvailable) {
                    WindowsNativeSettlementPrinter.printSalesReceipt(
                      receiptData: receiptData,
                      currencyDecimals: decimals,
                      onError: (msg) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Receipt sent to printer (or Print to PDF).'),
                        ),
                      );
                    }
                    return;
                  }

                  // Fallback: ESC/POS (SalesViewerPrinting)
                  ref.read(salesViewerPrintDataProvider.notifier).state =
                      receiptData;
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SalesViewerPrinting(),
                      ),
                    );
                  }
                } catch (e) {
                  print("❌ Error fetching receipt data: $e");
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Error"),
                        content: Text("Failed to fetch receipt data: $e"),
                        actions: [
                          TextButton(
                            child: const Text("Close"),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002868),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "Print Receipt",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF521C1D),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterField(String label, String value,
      {Color color = Colors.black}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
