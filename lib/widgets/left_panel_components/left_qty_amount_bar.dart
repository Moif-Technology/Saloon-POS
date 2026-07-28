import 'package:flutter/material.dart';

class LeftQtyAmountBar extends StatelessWidget {
  final List<Map<String, String>> products;
  final double fontSize;
  final String currencyPrecession;
  final bool compact;

  /// Bill-level discount (from KOTMaster.BillDiscount). When set, Amount = sum(line totals) - billDiscount.
  final double billDiscount;

  final String selectedQty;
  final bool isReturnMode;

  final int Function(String? pattern) currencyDecimalsFrom;

  const LeftQtyAmountBar({
    super.key,
    required this.products,
    required this.fontSize,
    required this.currencyPrecession,
    required this.selectedQty,
    required this.isReturnMode,
    required this.currencyDecimalsFrom,
    this.compact = false,
    this.billDiscount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final dec = currencyDecimalsFrom(currencyPrecession);

    int totalQuantity = 0;
    double totalLineTotal = 0.0;

    for (var product in products) {
      final quantity = int.tryParse(product["quantity"] ?? "1") ?? 1;
      final unitPrice = double.tryParse(product["UnitPrice"] ?? "0.00") ?? 0.0;
      final subTotal = unitPrice * quantity;
      final taxRate = double.tryParse(product["Tax1Rate"] ?? "0") ?? 0.0;
      final taxAmount = (subTotal * taxRate) / 100;
      final lineTotal = subTotal + taxAmount;
      final isReturn = product["isReturn"] == "true";
      final sign = isReturn ? -1 : 1;
      totalQuantity += quantity * sign;
      totalLineTotal += lineTotal * sign;
    }

    final qtyValue = selectedQty.isEmpty ? "0" : selectedQty;
    final displayQty = isReturnMode ? "-$qtyValue" : qtyValue;
    final padV = compact ? 6.0 : 10.0;
    final padH = compact ? 8.0 : 12.0;
    final fs = compact ? fontSize : fontSize + 0.5;

    final discAmt = billDiscount.clamp(0.0, double.infinity);
    final amountAfterDisc = (totalLineTotal - discAmt).clamp(0.0, double.infinity);

    // Old color combination: dark red gradient bar
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(52, 5, 15, 1),
            Color.fromRGBO(128, 0, 0, 1),
            Color.fromRGBO(52, 5, 15, 1),
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Qty: $totalQuantity   Disc Amt: ${discAmt.toStringAsFixed(dec)}   Amount: ${amountAfterDisc.toStringAsFixed(dec)}",
              style: TextStyle(
                color: Colors.white,
                fontSize: fs,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10.0 : 16.0,
              vertical: compact ? 4.0 : 6.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              "Qty: $displayQty",
              style: TextStyle(
                color: const Color(0xFF521C1D),
                fontSize: compact ? fs + 2 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
