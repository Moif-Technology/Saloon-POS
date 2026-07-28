import 'package:flutter/material.dart';

class DiscountListingDialog extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

  // Keep header / search / body columns in sync
  static const int _flexSlNo = 1;
  static const int _flexBarcode = 2;
  static const int _flexShortDesc = 3;
  static const int _flexPackQty = 1;
  static const int _flexPackDetails = 2;
  static const int _flexSellingPrice = 2;
  static const int _flexDisAmt = 2;
  static const int _flexDisSellPrice = 2;
  static const int _flexDiscPct = 1;
  static const double _checkboxColWidth = 40;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final double dialogWidth = screen.width > 1100 ? 1100 : screen.width * 0.95;
    final double dialogHeight =
        screen.height > 720 ? 720 : screen.height * 0.9;

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
                    _buildTopSection(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTableSection()),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context),
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
              'Discount Listing',
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

  // ── 2. Filter & Search Panel ─────────────────────────────────────────────
  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabelFieldRow('Supplier', 'Edit'),
                const SizedBox(height: 10),
                _buildLabelFieldRow('Product Brand', 'Edit'),
                const SizedBox(height: 10),
                _buildLabelFieldRow('Group', 'Edit'),
                const SizedBox(height: 10),
                _buildLabelFieldRow('SubGroup', 'Edit'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField('Discount Percentage'),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
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
                      'Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelFieldRow(String label, String buttonText) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            icon: const Icon(Icons.edit, color: _primaryColor, size: 20),
            tooltip: buttonText,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _primaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
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
          ),
        ),
      ],
    );
  }

  // ── 3–4. Column search + table ───────────────────────────────────────────
  Widget _buildTableSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildSearchSection(),
          _buildTableHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  5,
                  (index) => _buildTableRow(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Spacer under Sl No (no search field)
          const Expanded(flex: _flexSlNo, child: SizedBox.shrink()),
          Expanded(
            flex: _flexBarcode,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildSmallTextField('Barcode'),
            ),
          ),
          Expanded(
            flex: _flexShortDesc,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildSmallTextField('Short Description'),
            ),
          ),
          Expanded(
            flex: _flexPackQty,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildSmallTextField('Pack Qty'),
            ),
          ),
          Expanded(
            flex: _flexPackDetails,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildSmallTextField('Pack Details'),
            ),
          ),
          Expanded(
            flex: _flexSellingPrice,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildSmallTextField('Selling Price'),
            ),
          ),
          Expanded(
            flex: _flexDisAmt,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildSmallTextField('Dis. Amt'),
            ),
          ),
          Expanded(
            flex: _flexDisSellPrice,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildSmallTextField('Dis. Sell Price'),
            ),
          ),
          Expanded(
            flex: _flexDiscPct,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildSmallTextField('Disc. %'),
            ),
          ),
          SizedBox(
            width: _checkboxColWidth,
            child: Checkbox(value: false, onChanged: (value) {}),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTextField(String label) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: _primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          _buildHeaderCell('Sl No', flex: _flexSlNo),
          _buildHeaderCell('Barcode', flex: _flexBarcode),
          _buildHeaderCell('Short Description', flex: _flexShortDesc),
          _buildHeaderCell('Pack Qty', flex: _flexPackQty),
          _buildHeaderCell('Pack Details', flex: _flexPackDetails),
          _buildHeaderCell('Selling Price', flex: _flexSellingPrice),
          _buildHeaderCell('Dis. Amt', flex: _flexDisAmt),
          _buildHeaderCell('Dis. Sell Price', flex: _flexDisSellPrice),
          _buildHeaderCell('Disc. %', flex: _flexDiscPct),
          const SizedBox(width: _checkboxColWidth),
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
            color: _primaryColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(int index) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: index.isEven ? Colors.white : Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          _buildTableCell((index + 1).toString(), flex: _flexSlNo),
          _buildTableCell('Barcode $index', flex: _flexBarcode),
          _buildTableCell('Description $index', flex: _flexShortDesc),
          _buildTableCell('Qty $index', flex: _flexPackQty),
          _buildTableCell('Details $index', flex: _flexPackDetails),
          _buildTableCell(r'$50', flex: _flexSellingPrice),
          _buildTableCell(r'$5', flex: _flexDisAmt),
          _buildTableCell(r'$45', flex: _flexDisSellPrice),
          _buildTableCell('10%', flex: _flexDiscPct),
          const SizedBox(width: _checkboxColWidth),
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
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ── 5. Footer ────────────────────────────────────────────────────────────
  Widget _buildBottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          // Far-left — destructive
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Remove Discount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Right side left clean (Close handled by header ✕)
        ],
      ),
    );
  }
}