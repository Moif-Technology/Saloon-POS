import 'package:flutter/material.dart';

class AdvanceViewer extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

  // Column flexes: keep header / rows / total in sync
  static const int _flexSlNo = 1;
  static const int _flexDate = 2;
  static const int _flexCode = 2;
  static const int _flexName = 2;
  static const int _flexPayMode = 2;
  static const int _flexEnteredBy = 2;
  static const int _flexAmount = 2;

  static const int _flexLabelSpan =
      _flexSlNo +
      _flexDate +
      _flexCode +
      _flexName +
      _flexPayMode +
      _flexEnteredBy; // 11 — sits under all cols except Amount

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth > 900 ? 900 : screenWidth * 0.95;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: dialogWidth,
        height:
            screenWidth > 600 ? 700 : MediaQuery.of(context).size.height * 0.88,
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
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────
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
                      'Advance Viewer',
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

            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilterSection(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildTableContainer(),
                    ),
                    const SizedBox(height: 12),
                    _buildTotalRow(),
                  ],
                ),
              ),
            ),

            // ── Footer — Close left, Print right ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: const BorderSide(color: _primaryColor),
                      minimumSize: const Size(120, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Implement print logic here
                    },
                    icon: const Icon(Icons.print, color: Colors.white, size: 20),
                    label: const Text(
                      'Print',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(child: _buildDatePicker('From')),
          const SizedBox(width: 12),
          Expanded(child: _buildDatePicker('To')),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label) {
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
            isDense: true,
            suffixIcon: const Icon(
              Icons.calendar_today,
              size: 18,
              color: Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 14,
            ),
            hintText: 'MM/DD/YYYY',
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          readOnly: true,
          onTap: () {
            // Implement date picker logic here
          },
        ),
      ],
    );
  }

  Widget _buildTableContainer() {
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
                  10,
                  (index) => _buildTableRow(index + 1),
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
      color: _primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          _buildHeaderCell('Sl No', flex: _flexSlNo),
          _buildHeaderCell('Transaction Date', flex: _flexDate),
          _buildHeaderCell('Customer Code', flex: _flexCode),
          _buildHeaderCell('Customer Name', flex: _flexName),
          _buildHeaderCell('Customer Pay Mode', flex: _flexPayMode),
          _buildHeaderCell('Entered By', flex: _flexEnteredBy),
          _buildHeaderCell('Amount', flex: _flexAmount),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
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
      constraints: const BoxConstraints(minHeight: 40),
      color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          _buildTableCell(index.toString(), flex: _flexSlNo),
          _buildTableCell('11/14/2024', flex: _flexDate),
          _buildTableCell('C$index', flex: _flexCode),
          _buildTableCell('Customer $index', flex: _flexName),
          _buildTableCell('Cash', flex: _flexPayMode),
          _buildTableCell('Staff $index', flex: _flexEnteredBy),
          _buildTableCell('\$500', flex: _flexAmount),
        ],
      ),
    );
  }

  Widget _buildTableCell(String content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          content,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTotalRow() {
    // Label spans first 6 columns; Amount total aligns under Amount column
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: _flexLabelSpan,
            child: Text(
              'Total:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: _flexAmount,
            child: Center(
              child: Text(
                '\$5000',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}