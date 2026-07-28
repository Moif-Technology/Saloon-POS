import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductMovementReportDialog extends StatefulWidget {
  @override
  _ProductMovementReportDialogState createState() =>
      _ProductMovementReportDialogState();
}

class _ProductMovementReportDialogState
    extends State<ProductMovementReportDialog> {
        static const Color _primaryColor = Color(0xFF521C1D);

  DateTime selectedFromDate = DateTime.now();
  DateTime selectedToDate = DateTime.now();
  final TextEditingController itemNameController = TextEditingController();

  List<String> groupNames = [
    "APPETIZER",
    "BREAKFAST",
    "CAKE",
    "COLD COFFEE",
    "COOL DRINKS",
    "DRINKS",
    "EXTRA",
    "HOT COFFEE",
    "MAIN COURSE",
    "SALAD",
    "SODA",
    "V60"
  ];
  Map<String, bool> groupSelection = {};
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    groupSelection = {for (var group in groupNames) group: false};
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? selectedFromDate : selectedToDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null &&
        picked != (isFromDate ? selectedFromDate : selectedToDate)) {
      setState(() {
        if (isFromDate) {
          selectedFromDate = picked;
        } else {
          selectedToDate = picked;
        }
      });
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      groupSelection.updateAll((key, value) => selectAll);
    });
  }

  void _toggleIndividualCheckbox(String group, bool? value) {
    setState(() {
      groupSelection[group] = value ?? false;
      selectAll = groupSelection.values.every((isSelected) => isSelected);
    });
  }

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final dialogWidth = screenWidth < 900 ? screenWidth * 0.95 : 860.0;

  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Container(
      width: dialogWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.only(left: 20, right: 8),
            decoration: const BoxDecoration(color: _primaryColor),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Product Movement Report',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    tooltip: 'Close',
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Two-column body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: SizedBox(
              height: 420,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildGroupSelection()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildDetailsSection()),
                ],
              ),
            ),
          ),

          // ── Footer ──
          _buildFooter(),
        ],
      ),
    ),
  );
}

  // Group Selection (left side) with Select All option
 Widget _buildGroupSelection() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Group Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _primaryColor,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select All',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                Checkbox(
                  value: selectAll,
                  onChanged: _toggleSelectAll,
                  activeColor: _primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
        Divider(color: Colors.grey.shade300, height: 16),
        Expanded(
          child: ListView(
            children: groupNames.map((group) {
              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                value: groupSelection[group],
                activeColor: _primaryColor,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  group,
                  style: const TextStyle(fontSize: 13),
                ),
                onChanged: (value) =>
                    _toggleIndividualCheckbox(group, value),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

  // Details Section (right side)
 Widget _buildDetailsSection() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item search
        const Text(
          'Item Name',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: itemNameController,
                decoration: InputDecoration(
                  hintText: 'Search item',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: _primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                icon: const Icon(Icons.search, color: _primaryColor),
                onPressed: () {
                  // Search item logic
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                tooltip: 'Search',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Invoice date range
        const Text(
          'Invoice Date',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDateField('From', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildDateField('To', false)),
          ],
        ),
      ],
    ),
  );
}

Widget _buildDateField(String label, bool isFromDate) {
  final date = isFromDate ? selectedFromDate : selectedToDate;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF424242),
        ),
      ),
      const SizedBox(height: 6),
      InkWell(
        onTap: () => _selectDate(context, isFromDate),
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          child: Text(
            DateFormat('dd/MM/yyyy').format(date),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    ],
  );
}
Widget _buildFooter() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            // Show report logic
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 44),
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Show',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

}
