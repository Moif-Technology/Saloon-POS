import 'package:flutter/material.dart';

class ProductionEntryDialog extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

  // Keep table header / body columns in sync
  static const int _flexItemCode = 2;
  static const int _flexItemName = 3;
  static const int _flexPresentQty = 2;
  static const int _flexQty = 2;
  static const double _actionsColWidth = 96;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final double dialogWidth = screen.width > 900 ? 750 : screen.width * 0.92;
    final double dialogHeight =
        screen.height > 720 ? 700 : screen.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProductionInfoSection(),
                    const SizedBox(height: 12),
                    _buildItemEntrySection(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildTableSection()),
                  ],
                ),
              ),
            ),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  // ── 1. Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.only(left: 20, right: 8),
      decoration: const BoxDecoration(
        color: _primaryColor,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Production Entry',
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
    );
  }

  // ── 2. Production Information Section ────────────────────────────────────
  Widget _buildProductionInfoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactTextField('Production No.'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCompactDateField('Production Date'),
          ),
        ],
      ),
    );
  }

  // ── 3. Item Entry Section ────────────────────────────────────────────────
  Widget _buildItemEntrySection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: _buildCompactTextField('Barcode'),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _buildCompactTextField('Short Description'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactTextField('Qty'),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                // Add logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Production Items Table ────────────────────────────────────────────
  Widget _buildTableSection() {
    final rows = _productionItems();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  rows.length,
                  (index) => _buildTableRow(rows[index], index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: _primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          _buildHeaderCell('Item Code', flex: _flexItemCode),
          _buildHeaderCell('Item Name', flex: _flexItemName),
          _buildHeaderCell('Present Qty', flex: _flexPresentQty),
          _buildHeaderCell('Qty', flex: _flexQty),
          const SizedBox(
            width: _actionsColWidth,
            child: Text(
              'Actions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(Map<String, String> item, int index) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: index.isEven ? Colors.white : Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        children: [
          _buildTableCell(item['itemCode'] ?? '', flex: _flexItemCode),
          _buildTableCell(item['itemName'] ?? '', flex: _flexItemName),
          _buildTableCell(item['presentQty'] ?? '', flex: _flexPresentQty),
          _buildTableCell(item['qty'] ?? '', flex: _flexQty),
          SizedBox(
            width: _actionsColWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onPressed: () {
                    // Edit action
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onPressed: () {
                    // Delete action
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ── 5. Footer ────────────────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBFB),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          const Spacer(),
          // Far-right — primary Save (Close handled by header ✕)
          ElevatedButton(
            onPressed: () {
              // Save logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save',
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

  // ── Shared field helpers (same behavior as before) ───────────────────────
  Widget _buildCompactTextField(String label) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildCompactDateField(String label) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
      readOnly: true,
      onTap: () {
        // Implement date picker logic
      },
    );
  }

  List<Map<String, String>> _productionItems() {
    return [
      {
        'itemCode': '1001',
        'itemName': 'Sample Item',
        'presentQty': '50',
        'qty': '10',
      },
      // Add more rows as needed
    ];
  }
}