import 'package:flutter/material.dart';

/// Left panel top bar: KOT label + customer dropdown + add customer.
/// API unchanged for [PosLeftPanel].
class LeftTopBar extends StatelessWidget {
  final bool isKOTActive;
  final String kotPrefix;
  final String kotNumber;

  final List<Map<String, String>> customers;
  final String? selectedCustomerName;
  final String? customerFromReturn;

  final double fontSize;
  final bool compact;
  final bool showKotLabel;
  final bool showCustomerSelector;
  final bool showAddCustomer;

  final ValueChanged<String?> onCustomerChanged;
  final VoidCallback onAddCustomer;

  const LeftTopBar({
    super.key,
    required this.isKOTActive,
    required this.kotPrefix,
    required this.kotNumber,
    required this.customers,
    required this.selectedCustomerName,
    required this.customerFromReturn,
    required this.fontSize,
    required this.onCustomerChanged,
    required this.onAddCustomer,
    this.compact = false,
    this.showKotLabel = true,
    this.showCustomerSelector = true,
    this.showAddCustomer = true,
  });

  @override
  Widget build(BuildContext context) {
    final names = customers.map((c) => c['name'] ?? '').toList();
    final String dropdownValue = () {
      final candidate = customerFromReturn ?? selectedCustomerName;
      if (candidate != null &&
          candidate.isNotEmpty &&
          names.contains(candidate)) {
        return candidate;
      }
      return 'Select Customer';
    }();

    final fs = compact ? 11.0 : 12.0;
    final padding = compact ? 6.0 : 8.0;

    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        height: compact ? 40 : 44,
        padding: EdgeInsets.symmetric(horizontal: padding),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showKotLabel)
              _KotSection(
                isKOTActive: isKOTActive,
                kotPrefix: kotPrefix,
                kotNumber: kotNumber,
                fontSize: fs,
              ),
            if (showKotLabel && showCustomerSelector)
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey.shade300,
              ),
            if (showCustomerSelector)
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: dropdownValue,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down,
                        color: Colors.grey.shade700),
                    style: TextStyle(
                      fontSize: fs,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: Colors.white,
                    items: names
                        .toSet()
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(n,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: fs)),
                            ))
                        .toList(),
                    onChanged: onCustomerChanged,
                  ),
                ),
              )
            else
              const Spacer(),
            if (showAddCustomer)
              IconButton(
                onPressed: onAddCustomer,
                icon: Icon(Icons.add_circle_outline,
                    size: compact ? 20 : 22, color: const Color(0xFF521C1D)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }
}

class _KotSection extends StatelessWidget {
  final bool isKOTActive;
  final String kotPrefix;
  final String kotNumber;
  final double fontSize;

  const _KotSection({
    required this.isKOTActive,
    required this.kotPrefix,
    required this.kotNumber,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF521C1D);
    final hasKot =
        isKOTActive && (kotPrefix.isNotEmpty || kotNumber.isNotEmpty);

    String value = 'NEW';
    if (hasKot) {
      final p = kotPrefix.toUpperCase().trim();
      final n = kotNumber.trim();
      value = p.isNotEmpty && n.isNotEmpty ? '$p$n' : (p.isNotEmpty ? p : n);
      if (value.isEmpty) value = '—';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'KOT ',
          style: TextStyle(
            fontSize: fontSize - 1,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: hasKot ? maroon : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
