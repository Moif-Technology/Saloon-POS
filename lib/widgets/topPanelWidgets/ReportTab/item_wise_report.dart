import 'package:flutter/material.dart';

class ItemWiseReportDialog extends StatelessWidget {
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
          'Item Wise Report',
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
      // Report With Section
      const Text(
        'Report with :',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF424242),
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Radio(
                  value: 'Date',
                  groupValue: 'reportWith',
                  onChanged: (value) {},
                  activeColor: _primaryColor,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                const Text(
                  'Date',
                  style: TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Radio(
                  value: 'Counter Close No.',
                  groupValue: 'reportWith',
                  onChanged: (value) {},
                  activeColor: _primaryColor,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                const Flexible(
                  child: Text(
                    'Counter Close No.',
                    style: TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Counter Close No. and Counter No. Fields
      Row(
        children: [
          Expanded(
            child: _buildDropdownField(
              'Counter Close No:',
              ['S1-'],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField('Counter No:')),
        ],
      ),
      const SizedBox(height: 16),

      // Group Section
      Row(
        children: [
          Expanded(child: _buildTextField('Group:')),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: _primaryColor,
              size: 18,
            ),
            onPressed: () {},
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Date Fields
      _buildTextField('Report Date From:', isDateField: true),
      const SizedBox(height: 16),
      _buildTextField('Report Date To:', isDateField: true),
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

  Widget _buildTextField(String label, {bool isDateField = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12)),
        SizedBox(height: 4),
        TextField(
          decoration: InputDecoration(
            isDense: true, // reduces the overall height
            contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8), // controls the padding inside the TextField
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon:
                isDateField ? Icon(Icons.calendar_today, size: 18) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12)),
        SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: items.first,
          items: items
              .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: TextStyle(fontSize: 12))))
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

  
}
