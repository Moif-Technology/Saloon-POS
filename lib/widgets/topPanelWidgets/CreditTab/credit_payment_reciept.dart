import 'package:flutter/material.dart';

class CustomerLookupDialog extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth > 1200 ? 900 : screenWidth * 0.95;
    final double tableHeight = screenWidth > 600 ? 140.0 : 110.0;
    final double listTableHeight = screenWidth > 600 ? 320.0 : 240.0;
    final double columnWidth = dialogWidth * 0.45;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: dialogWidth,
        height:
            screenWidth > 600 ? 720 : MediaQuery.of(context).size.height * 0.9,
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
            // ── Header ──────────────────────────────────────────────
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.only(left: 20, right: 8),
              decoration: const BoxDecoration(color: _primaryColor),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Customer Lookup',
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Customer Details'),
                                Expanded(
                                  child: _buildLastBillsTable(
                                    tableHeight,
                                    columnWidth,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _buildLastTransactionsTable(
                                    tableHeight,
                                    columnWidth,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Customer List'),
                                Expanded(
                                  child: _buildCustomerListTable(
                                    listTableHeight,
                                    columnWidth * 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterSection(),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────
            _buildButtonRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
        ),
      ),
    );
  }

  Widget _buildLastBillsTable(double height, double width) {
    return _buildTableContainer(
      height: height,
      width: width,
      columns: ['Date', 'Bill No', 'Amount', 'OS Balance'],
      rows: List.generate(8, (index) => ['11/14', 'B$index', '\$100', '\$50']),
    );
  }

  Widget _buildLastTransactionsTable(double height, double width) {
    return _buildTableContainer(
      height: height,
      width: width,
      columns: ['Date', 'Type', 'Amount'],
      rows: List.generate(5, (index) => ['11/14', 'Payment', '\$50']),
    );
  }

  Widget _buildCustomerListTable(double height, double width) {
    return _buildTableContainer(
      height: height,
      width: width,
      columns: ['Code', 'Name'],
      rows: List.generate(10, (index) => ['C$index', 'Customer $index']),
    );
  }

  Widget _buildTableContainer({
    required double height,
    double? width,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: height,
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(
            _primaryColor.withOpacity(0.1),
          ),
          columns: columns
              .map((col) => DataColumn(
                    label: Center(
                      child: Text(
                        col,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ))
              .toList(),
          rows: rows
              .map((row) => DataRow(
                    cells: row
                        .map((cell) => DataCell(Center(child: Text(cell))))
                        .toList(),
                  ))
              .toList(),
          dividerThickness: 1,
          dataRowHeight: 28,
          headingRowHeight: 32,
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
          Expanded(child: _buildInputField('Customer Code')),
          const SizedBox(width: 12),
          Expanded(child: _buildInputField('Customer Name')),
        ],
      ),
     );
}

Widget _buildInputField(String label) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ],
  );
}

Widget _buildButtonRow() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    decoration: const BoxDecoration(
      color: Color(0xFFF8F9FA),
      border: Border(
        top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Far left — report / utility group
        Flexible(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSecondaryButton(
                'Print Outstanding',
                icon: Icons.print,
                onPressed: () {},
              ),
              _buildSecondaryButton(
                'Receipt Summary',
                icon: Icons.description_outlined,
                onPressed: () {},
              ),
              _buildSecondaryButton(
                'Receipt Details',
                icon: Icons.receipt_long,
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Far right — workflow group (Clear left of Select)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNeutralButton(
              'Clear',
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            _buildPrimaryButton(
              'Select',
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildNeutralButton(String label, {VoidCallback? onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6B7280),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        backgroundColor: const Color(0xFFE5E7EB),
        minimumSize: const Size(100, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, {VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(100, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSecondaryButton(
    String label, {
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}