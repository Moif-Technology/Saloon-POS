import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/counter_close_provider.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/services/counter_close_mapper.dart';
import 'package:my_app/widgets/topPanelWidgets/ReportTab/printDialog.dart';
import 'package:my_app/utils/sessionManager.dart';

class CounterCloseDialog extends ConsumerStatefulWidget {
  final String? selectedStaffId;
  /// When true: all pending on this counter (no cashier filter). Same UI.
  final bool isAdmin;

  const CounterCloseDialog({
    Key? key,
    this.selectedStaffId,
    this.isAdmin = false,
  }) : super(key: key);
  @override
  _CounterCloseDialogState createState() => _CounterCloseDialogState();
}

class _CounterCloseDialogState extends ConsumerState<CounterCloseDialog> {
  static const Color primaryColor = Color(0xFF521C1D);

  TextEditingController collectedAmountController = TextEditingController();

  // Track active input field
  TextEditingController? activeController;
  Map<String, TextEditingController> denominationControllers = {};

  // Store values
  double cashToBeCollected = 0.0;
  double cashDifference = 0.0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each denomination
    for (var denomination in [
      '1000',
      '500',
      '200',
      '100',
      '50',
      '20',
      '10',
      '5',
      '1',
      '.50',
      '.25',
      '.10'
    ]) {
      denominationControllers[denomination] = TextEditingController();
    }
    // Set the default active field to Collected Amount
    activeController = collectedAmountController;
  }

  void _onKeypadPress(String value) {
    setState(() {
      String currentValue = activeController?.text ?? "";

      if (value == 'C') {
        activeController?.clear();
        cashDifference = 0.0; // ✅ Reset to 0 when cleared
      } else if (value == '.' && !currentValue.contains('.')) {
        activeController?.text = currentValue + '.';
      } else {
        activeController?.text = currentValue + value;
      }

      // ✅ Ensure cash difference updates live
      double collectedAmount =
          double.tryParse(collectedAmountController.text) ?? 0.0;
      cashDifference =
          collectedAmount == 0.0 ? 0.0 : collectedAmount - cashToBeCollected;
    });
  }

  void _updateCollectedAmount() {
    double totalCollected = 0.0;

    denominationControllers.forEach((denomination, controller) {
      double quantity = double.tryParse(controller.text) ?? 0.0;
      double denomValue = double.tryParse(denomination) ?? 0.0;
      totalCollected += (quantity * denomValue);
    });

    setState(() {
      collectedAmountController.text = totalCollected.toStringAsFixed(2);

      // ✅ Cash Difference updates automatically
      double collectedAmount =
          double.tryParse(collectedAmountController.text) ?? 0.0;
      cashDifference = collectedAmount - cashToBeCollected;
    });
  }

  Future<void> _runReport(String type) async {
    if (_submitting) return;
    final isZ = type == 'Z-Report';
    final collected =
        double.tryParse(collectedAmountController.text.trim()) ?? 0.0;
    if (isZ && collected <= 0) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Missing Value'),
          content: const Text(
              'Please enter the Collected Amount before closing.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ApiService().closeCounter(
        reportType: isZ ? 'Z' : 'X',
        collectedCash: collected,
        allStaff: widget.isAdmin,
      );
      final mapped = mapCounterCloseForUi(
        result,
        session: SessionManager(),
        collectedOverride: collected,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PrintPage(
            Type: type,
            collectedAmount: collected,
            cashDifference: counterCloseNum(mapped['CashDifference']),
            selectedStaffId: widget.selectedStaffId,
            reportData: mapped,
          ),
        ),
      );
      if (!mounted) return;
      ref.invalidate(counterCloseProvider(
          widget.isAdmin ? 'admin' : (widget.selectedStaffId ?? 'null')));
      if (isZ) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffOrReportType =
        widget.isAdmin ? 'admin' : (widget.selectedStaffId ?? "null");
    final counterCloseData = ref.watch(counterCloseProvider(staffOrReportType));

    final currencyPrecession = ref.watch(currencyPrecessionProvider) ?? "0.00";
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine screen size category
    final bool isLargeScreen = screenWidth >= 1920;
    final bool isMediumScreen = screenWidth >= 1366 && screenWidth < 1920;

    // Set dynamic dimensions based on screen size
    final double baseFontSize = isLargeScreen ? 20 : (isMediumScreen ? 18 : 12);
    final double basePadding = isLargeScreen ? 16 : (isMediumScreen ? 12 : 8);
    final double buttonPadding = isLargeScreen ? 16 : (isMediumScreen ? 12 : 8);
    final double dialogHeight = screenHeight * 0.93;
    final double dialogWidth = screenWidth * 0.93;

    // Get decimal places from currencyPrecession
    int decimalPlaces = currencyPrecession.split(".").last.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: counterCloseData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("❌ Error: $err")),
          data: (data) {
            // ✅ Extract Cash To Be Collected from Provider
            cashToBeCollected =
                double.tryParse(data['AmountToBeCollected'].toString()) ?? 0.0;

            // Prefer provider/API data, then active session
            final session = SessionManager();
           final cashierName = _resolveDisplayValue(
  session.staffName,
  data['cashierName']?.toString(),
  fallback: 'Cashier not available',
);
final counterNo = _resolveDisplayValue(
  session.stationId,
  data['CounterNo']?.toString(),
  fallback: 'Counter not assigned',
);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== HEADER =====
                // Layout: Title (left) → Spacer → Cashier|Counter → Close (far right)
                Container(
                  height: 72,
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      // LEFT: title (takes remaining space so right cluster stays far-right)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.point_of_sale_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                widget.isAdmin
                                    ? 'Counter Close - Admin'
                                    : 'Counter Close',
                                style: TextStyle(
                                  fontSize: baseFontSize + 4,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Directly left of Close: Cashier | Counter
                      Text(
                        'Cashier: $cashierName  |  Counter: $counterNo'
                        '${widget.isAdmin ? '  |  ADMIN (all pending)' : ''}',
                        style: TextStyle(
                          fontSize: baseFontSize - 2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(width: 12),
                      // FAR RIGHT: Close ✕ (40×40)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Material(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== BODY =====
               Expanded(
  child: Padding(
    padding: EdgeInsets.fromLTRB(
      basePadding + 4,
      basePadding,
      basePadding + 4,
      basePadding / 2,
    ),
    child: LayoutBuilder(
  builder: (context, constraints) {
    final metricsH =
        (constraints.maxHeight * 0.36).clamp(180.0, 320.0);
    final bottomH =
        (constraints.maxHeight * 0.42).clamp(220.0, 420.0);

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
    // --- Financial Summary (3 columns) ---
                      SizedBox(
  height: metricsH,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
                              Expanded(
                                child: _buildMetricColumn(
                                  baseFontSize,
                                  basePadding,
                                  [
                                    _buildSummaryRow(
                                      'Total Cash',
                                      _getFormattedValue(
                                          data, 'finalTotalCash', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Credits Received',
                                      _getFormattedValue(
                                          data, 'ReceiptAmount', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Refund Amt',
                                      _getFormattedValue(
                                          data, 'RefundAmount', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Advance Received',
                                      _getFormattedValue(data, 'AdvanceReceived',
                                          decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Total Cash IN',
                                      _getFormattedValue(
                                          data, 'CashIN', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Total Cash Out',
                                      _getFormattedValue(
                                          data, 'CashOUt', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Cash To Be Collected',
                                      cashToBeCollected
                                          .toStringAsFixed(decimalPlaces),
                                      baseFontSize,
                                      isBold: true,
                                      highlight: true,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: basePadding),
                              Expanded(
                                child: _buildMetricColumn(
                                  baseFontSize,
                                  basePadding,
                                  [
                                    _buildSummaryRow(
                                      'Credit Amt',
                                      _getFormattedValue(
                                          data, 'CreditAmount', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Credit Card Amt',
                                      _getFormattedValue(data,
                                          'CreditCardAmount', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Online Sale Amt',
                                      _getFormattedValue(
                                          data, 'OnlineAmount', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Voucher Amt',
                                      _getFormattedValue(
                                          data, 'VoucherAmount', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Compliment Amt',
                                      _getFormattedValue(data,
                                          'ComplimentAmount', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Credit Received - C. Card Amt',
                                      _getFormattedValue(data,
                                          'ReceiptAmountCCard', decimalPlaces),
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Total Discount Amount',
                                      _getFormattedValue(
                                          data, 'DiscountAmount', decimalPlaces),
                                      baseFontSize,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: basePadding),
                              Expanded(
                                child: _buildMetricColumn(
                                  baseFontSize,
                                  basePadding,
                                  [
                                    Padding(
                                      padding: EdgeInsets.only(
                                          bottom: basePadding / 4),
                                      child: Text(
                                        'Bill Count: ${data['BillCount'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: baseFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    _buildSummaryRow(
                                      'Cash Bill',
                                      '${data['CashBillCount'] ?? 0}',
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Credit Bill',
                                      '${data['CreditBillCount'] ?? 0}',
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Credit Card Bill',
                                      '${data['CreditCardBillCount'] ?? 0}',
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Compliment Bill',
                                      '${data['ComplimentBillCount'] ?? 0}',
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'Multi Payment Bill',
                                      '${data['MultiBillCount'] ?? 0}',
                                      baseFontSize,
                                    ),
                                    _buildSummaryRow(
                                      'No Of Customers',
                                      '${data['totalCustomers'] ?? 0}',
                                      baseFontSize,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: basePadding),

                        // --- Cash Denominations ---
                        _buildSectionTitle(
                            'Cash Denominations', baseFontSize + 1),
                        SizedBox(height: basePadding / 2),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: basePadding,
                          runSpacing: basePadding / 2,
                          children: [
                            for (var denomination in [
                              '1000',
                              '500',
                              '200',
                              '100',
                              '50',
                              '20',
                              '10',
                              '5',
                              '1',
                              '.50',
                              '.25',
                              '.10'
                            ])
                              _buildDenominationField(
                                  denomination, baseFontSize),
                          ],
                        ),

                        SizedBox(height: basePadding),

                            // --- Collected Amount + Keypad ---
        SizedBox(
          height: bottomH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Collected amount + key totals
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _buildSummaryRow(
                        'Collected Amount',
                        '',
                        baseFontSize,
                        isBold: true,
                      ),
                      SizedBox(height: basePadding / 4),
                      TextField(
                        controller: collectedAmountController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            double collectedAmount =
                                double.tryParse(value) ?? 0.0;
                            cashDifference = collectedAmount -
                                cashToBeCollected;
                          });
                        },
                        style: TextStyle(
                          fontSize: baseFontSize + 2,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          hintText: 'Enter Collected Amount',
                          contentPadding:
                              EdgeInsets.symmetric(
                            vertical: basePadding,
                            horizontal: basePadding,
                          ),
                        ),
                      ),
                      SizedBox(height: basePadding / 2),
                      _buildSummaryRow(
                        'Cash Difference',
                        cashDifference
                            .toStringAsFixed(decimalPlaces),
                        baseFontSize,
                        isBold: true,
                        highlight: true,
                      ),
                      Divider(
                          thickness: 1, height: basePadding),
                      _buildSummaryRow(
                        'Total Sales',
                        _getFormattedValue(data, 'TotalAmount',
                            decimalPlaces),
                        baseFontSize + 1,
                        isBold: true,
                        highlight: true,
                      ),
                      _buildSummaryRow(
                        'Tax Amount',
                        _getFormattedValue(
                            data, 'TaxAmount', decimalPlaces),
                        baseFontSize + 1,
                        isBold: true,
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: basePadding),
              // Keypad docked beside input
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (var row in [
                            ['7', '8', '9'],
                            ['4', '5', '6'],
                            ['1', '2', '3'],
                            ['0', '.', 'C']
                          ])
                            Expanded(
                              child: Row(
                                children: row
                                    .map(
                                      (key) => Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsets.all(
                                                  basePadding /
                                                      4),
                                          child:
                                              _buildKeypadButton(
                                                  key,
                                                  baseFontSize),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: basePadding / 2),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize:
                            const Size(double.infinity, 44),
                        padding: EdgeInsets.symmetric(
                          vertical: buttonPadding / 2,
                          horizontal: basePadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Enter',
                        style: TextStyle(
                          fontSize: baseFontSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
      },
    ),
  ),
),


    // ===== FOOTER: X left / Z right =====
    Padding(
      padding: EdgeInsets.fromLTRB(
        basePadding + 4,
        basePadding / 2,
        basePadding + 4,
        basePadding + 4,
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _submitting ? null : () => _runReport('X-Report'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(
                  color: primaryColor, width: 1.5),
              minimumSize: const Size(160, 52),
              padding: EdgeInsets.symmetric(
                horizontal: buttonPadding,
                vertical: buttonPadding / 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _submitting ? '…' : 'X-Report',
              style: TextStyle(
                fontSize: baseFontSize - 1,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _submitting ? null : () => _runReport('Z-Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              minimumSize: const Size(160, 52),
              padding: EdgeInsets.symmetric(
                horizontal: buttonPadding,
                vertical: buttonPadding / 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _submitting ? 'Saving…' : 'Z-Report',
              style: TextStyle(
                fontSize: baseFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
               ),
      ],
    ),
  ),
            ],
          );
        },
      ),
    ),
  );
}

  /// **🔹 Get the formatted value dynamically using currency precision**
  String _getFormattedValue(
      Map<String, dynamic> data, String key, int decimalPlaces) {
    if (!data.containsKey(key)) {
      return "0.00"; // Default
    }

    double value = double.tryParse(data[key].toString()) ?? 0.0;
    return value.toStringAsFixed(decimalPlaces); // Use dynamic precision
  }

  Widget _buildMetricColumn(
      double fontSize, double padding, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
     child: SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  ),
),
    );
  }

  Widget _buildSectionTitle(String title, double fontSize) {
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String amount,
    double fontSize, {
    bool isBold = false,
    bool highlight = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: fontSize / 10),
      padding: highlight
          ? EdgeInsets.symmetric(
              horizontal: fontSize / 3, vertical: fontSize / 5)
          : EdgeInsets.zero,
      decoration: highlight
          ? BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          if (amount.isNotEmpty)
            Text(
              amount,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: primaryColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDenominationField(String amount, double fontSize) {
    final displayLabel = amount.startsWith('.') ? '₹0$amount' : '₹$amount';
    return SizedBox(
      width: fontSize * 5,
      child: Column(
        children: [
          Text(
            '$displayLabel ×',
            style: TextStyle(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          TextField(
            controller: denominationControllers[amount],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateCollectedAmount();
            },
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: fontSize / 4),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Prefer API value, then session value, then a clear fallback.
  String _resolveDisplayValue(
    String? primary,
    String? secondary, {
    required String fallback,
  }) {
    final p = primary?.trim();
    if (p != null &&
        p.isNotEmpty &&
        p != 'null' &&
        p != 'Unknown' &&
        p != 'N/A') {
      return p;
    }
    final s = secondary?.trim();
    if (s != null &&
        s.isNotEmpty &&
        s != 'null' &&
        s != 'Unknown' &&
        s != 'N/A') {
      return s;
    }
    return fallback;
  }

  Widget _buildKeypadButton(String text, double fontSize) {
    return SizedBox.expand(
      child: ElevatedButton(
        onPressed: () => _onKeypadPress(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF424242),
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, color: Colors.white),
        ),
      ),
    );
  }
}
