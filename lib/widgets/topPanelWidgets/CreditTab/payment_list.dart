import 'package:flutter/material.dart';

class PaymentList extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth > 600 ? 650 : screenWidth * 0.92;
    final double inputFontSize = screenWidth > 600 ? 14 : 12;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: screenWidth > 600 ? 640 : MediaQuery.of(context).size.height * 0.85,
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
                      'Payment List',
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
                    // Filter section
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField('Customer Code', inputFontSize),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField('Customer Name', inputFontSize),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Table
                    Expanded(
                      child: _buildScrollableTable(),
                    ),
                    const SizedBox(height: 16),

                    // Display information (unchanged)
                    _buildDisplayText('Customer Name', 'John Doe', inputFontSize),
                    const SizedBox(height: 8),
                    _buildDisplayText('Advance Amount', '\$500', inputFontSize),
                    const SizedBox(height: 8),
                    _buildDisplayText('Payment Date', '11/14/2024', inputFontSize),
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
                  ElevatedButton(
                    // Preserves existing Print behavior (defaulted to pop)
                    onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildInputField(String label, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: TextStyle(fontSize: fontSize),
        ),
      ],
    );
  }

  Widget _buildDisplayText(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : 600,
                ),
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(
                    _primaryColor.withOpacity(0.1),
                  ),
                  columns: [
                    DataColumn(
                      label: Text('Customer Code', style: _columnHeaderStyle()),
                    ),
                    DataColumn(
                      label: Text('Customer Name', style: _columnHeaderStyle()),
                    ),
                    DataColumn(
                      label: Text('Advance Amount', style: _columnHeaderStyle()),
                    ),
                    DataColumn(
                      label: Text('Payment Date', style: _columnHeaderStyle()),
                    ),
                  ],
                  rows: List.generate(
                    20,
                    (index) => DataRow(
                      cells: [
                        DataCell(Text('C$index')),
                        DataCell(Text('Customer $index')),
                        DataCell(Text('\$100')),
                        DataCell(Text('11/14')),
                      ],
                    ),
                  ),
                  dividerThickness: 1,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 48,
                  headingRowHeight: 40,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  TextStyle _columnHeaderStyle() {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      color: _primaryColor,
    );
  }
}