import 'package:flutter/material.dart';

class LeftTotalsRow extends StatelessWidget {
  final List<Map<String, String>> products;
  final double fontSize;
  final String currencyPrecession;
  final bool compact;
  final bool isBaseVersion;
  final bool showDelete;
  final bool showSubtotal;
  final bool showTax;
  final bool showGrandTotal;

  final VoidCallback onDelete;
  final int Function(String? pattern) currencyDecimalsFrom;

  const LeftTotalsRow({
    super.key,
    required this.products,
    this.isBaseVersion = false,
    this.showDelete = true,
    this.showSubtotal = true,
    this.showTax = true,
    this.showGrandTotal = true,
    required this.fontSize,
    required this.currencyPrecession,
    required this.onDelete,
    required this.currencyDecimalsFrom,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    double totalSubTotal = 0.0;
    double totalTax = 0.0;
    double totalLineTotal = 0.0;

    for (var product in products) {
      final unitPrice = double.tryParse(product["UnitPrice"] ?? "0.00") ?? 0.0;
      final quantity = int.tryParse(product["quantity"] ?? "1") ?? 1;
      final subTotal = unitPrice * quantity;
      final taxRate = double.tryParse(product["Tax1Rate"] ?? "0") ?? 0.0;
      final taxAmount = (subTotal * taxRate) / 100;
      final sign = product["isReturn"] == "true" ? -1 : 1;
      totalSubTotal += subTotal * sign;
      totalTax += taxAmount * sign;
      totalLineTotal += (subTotal + taxAmount) * sign;
    }

    final dec = currencyDecimalsFrom(currencyPrecession);
    final pad = compact ? 6.0 : 10.0;
    final fs = compact ? fontSize : fontSize + 0.5;

    return Container(
      padding: EdgeInsets.all(isBaseVersion ? 12 : pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isBaseVersion ? 12 : 8),
        border: Border.all(
            color: isBaseVersion ? Colors.grey.shade200 : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isBaseVersion ? 0.05 : 0.04),
            blurRadius: isBaseVersion ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showDelete)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 14,
                    vertical: compact ? 7 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline,
                          size: fs + 2, color: Colors.red.shade700),
                      const SizedBox(width: 6),
                      Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: fs,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSubtotal) _totLabel("Sub", totalSubTotal, dec, fs),
              if (showSubtotal && showTax) SizedBox(width: compact ? 8 : 12),
              if (showTax) _totLabel("Tax", totalTax, dec, fs),
              if ((showSubtotal || showTax) && showGrandTotal)
                SizedBox(width: compact ? 8 : 12),
              if (showGrandTotal)
                _totLabel("Total", totalLineTotal, dec, fs, bold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totLabel(String label, double value, int dec, double fs,
      {bool bold = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fs - 1,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value.toStringAsFixed(dec),
          style: TextStyle(
            fontSize: fs,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF521C1D),
          ),
        ),
      ],
    );
  }
}
