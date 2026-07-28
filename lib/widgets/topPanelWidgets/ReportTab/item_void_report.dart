import 'package:flutter/material.dart';


class ItemVoidReportDialog extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);
  @override
  Widget build(BuildContext context) {
   final screenWidth = MediaQuery.of(context).size.width;
final dialogWidth = screenWidth < 480 ? screenWidth * 0.92 : 440.0;

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
        // Brand header — title left, close top-right
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.only(left: 20, right: 8),
          decoration: const BoxDecoration(
            color: _primaryColor,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Item Void Report',
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

        // Content
Padding(
  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Cashier Name Dropdown
      _buildDropdownField('Cashier Name:', ['Select Cashier']),
      const SizedBox(height: 16),

      // Report Date From Field
      _buildDateField('Report Date From:'),
      const SizedBox(height: 16),

      // Report Date To Field
      _buildDateField('Report Date To:'),
    ],
  ),
),

            // Footer — Print as primary action (bottom-right)
Padding(
  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ElevatedButton(
        onPressed: () {},
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
          'Print',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D), // Dark red for labels
          ),
        ),
        SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: items.first,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: (value) {},
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D), // Dark red for labels
          ),
        ),
        SizedBox(height: 4),
        TextField(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: Icon(
              Icons.calendar_today,
              size: 18,
              color: Color(0xFF521C1D), // Dark red for icon
            ),
          ),
        ),
      ],
    );
  }

 
}
