import 'package:flutter/material.dart';

class OutstandingBillsDialog extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

  // Column flexes: keep header / rows / totals in sync
  static const int _flexSlNo = 1;
  static const int _flexCustomer = 3;
  static const int _flexBillCount = 2;
  static const int _flexOsAmount = 2;
  static const int _flex030 = 2;
  static const int _flex3060 = 2;
  static const int _flex60120 = 2;
  static const int _flex120Plus = 2;

  // Label span under Sl No + Customer + Bill Count (totals start at O/S Amount)
  static const int _flexLabelSpan =
      _flexSlNo + _flexCustomer + _flexBillCount; // 6

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
                      'Outstanding Bills',
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
                    _buildFooterTotals(),
                  ],
                ),
              ),
            ),

            // ── Footer — Print bottom-right ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Existing Print behavior preserved (stub)
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filter:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Radio(
                    value: 'All',
                    groupValue: 'Filter',
                    onChanged: (_) {},
                    activeColor: _primaryColor,
                  ),
                  const Text('All', style: TextStyle(color: _primaryColor)),
                ],
              ),
              Row(
                children: [
                  Radio(
                    value: 'Filter',
                    groupValue: 'Filter',
                    onChanged: (_) {},
                    activeColor: _primaryColor,
                  ),
                  const Text('Filter', style: TextStyle(color: _primaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDatePickerField('From')),
              const SizedBox(width: 12),
              Expanded(child: _buildDatePickerField('To')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Customer Name')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(String label) {
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
            hintText: 'MM/DD/YYYY',
            hintStyle: TextStyle(color: Colors.grey.shade400),
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
          ),
          readOnly: true,
          onTap: () {
            // Implement date picker logic here
          },
        ),
      ],
    );
  }

  Widget _buildTextField(String label) {
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 14,
            ),
          ),
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
          _buildHeaderCell('Customer Name', flex: _flexCustomer),
          _buildHeaderCell('Bill Count', flex: _flexBillCount),
          _buildHeaderCell('O/S Amount', flex: _flexOsAmount),
          _buildHeaderCell('0-30', flex: _flex030),
          _buildHeaderCell('30-60', flex: _flex3060),
          _buildHeaderCell('60-120', flex: _flex60120),
          _buildHeaderCell('120+', flex: _flex120Plus),
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
          _buildTableCell('Customer $index', flex: _flexCustomer),
          _buildTableCell('2', flex: _flexBillCount),
          _buildTableCell('\$100', flex: _flexOsAmount),
          _buildTableCell('\$20', flex: _flex030),
          _buildTableCell('\$30', flex: _flex3060),
          _buildTableCell('\$40', flex: _flex60120),
          _buildTableCell('\$10', flex: _flex120Plus),
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

  Widget _buildFooterTotals() {
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
              'Totals',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _buildTotalCell('Total O/S Amount', '\$0.00', flex: _flexOsAmount),
          _buildTotalCell('Total 0-30', '\$0.00', flex: _flex030),
          _buildTotalCell('Total 30-60', '\$0.00', flex: _flex3060),
          _buildTotalCell('Total 60-120', '\$0.00', flex: _flex60120),
          _buildTotalCell('Total 120+', '\$0.00', flex: _flex120Plus),
        ],
      ),
    );
  }

  Widget _buildTotalCell(String label, String amount, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: _primaryColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}