import 'package:flutter/material.dart';

class IncomeExpenseDialog extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final double dialogWidth = screen.width > 1000 ? 900 : screen.width * 0.9;
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
                    _buildInputSection(),
                    const SizedBox(height: 16),
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
              'Income & Expense Entry',
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

  // ── 2. Entry Form ────────────────────────────────────────────────────────
  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTextField('Account Name')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Remarks')),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: _buildDatePicker('Date'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField('Taxable Amount', isNumeric: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField('Tax Rate', ['5%', '10%', '15%']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('Net Amount', isNumeric: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField('Pay Type', ['Cash', 'Credit']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField('Type', ['Income', 'Expense']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {bool isNumeric = false}) {
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
        TextFormField(
          textAlign: isNumeric ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primaryColor),
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

  Widget _buildDatePicker(String label) {
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
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            suffixIcon: const Icon(
              Icons.calendar_today,
              size: 18,
              color: _primaryColor,
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primaryColor),
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
          onTap: () {
            // Implement date picker
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
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
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.first,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. Entry Table & Totals ──────────────────────────────────────────────
  Widget _buildTableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fixed header
                Container(
                  color: _primaryColor.withOpacity(0.1),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12,
                      headingRowHeight: 44,
                      dataRowMinHeight: 0,
                      dataRowMaxHeight: 0,
                      headingRowColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      columns: [
                        DataColumn(
                          label: Text(
                            'Account Name',
                            style: _tableHeaderStyle(),
                          ),
                        ),
                        DataColumn(
                          label: Text('Remarks', style: _tableHeaderStyle()),
                        ),
                        DataColumn(
                          label: Text('Date', style: _tableHeaderStyle()),
                        ),
                        DataColumn(
                          label: Text('Pay Type', style: _tableHeaderStyle()),
                        ),
                        DataColumn(
                          label: Text('Head Type', style: _tableHeaderStyle()),
                        ),
                        DataColumn(
                          label: Text(
                            'Non-Tax Amt',
                            style: _tableHeaderStyle(),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Taxable Amt',
                            style: _tableHeaderStyle(),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text('Tax Amt', style: _tableHeaderStyle()),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text('Income', style: _tableHeaderStyle()),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text('Expense', style: _tableHeaderStyle()),
                          numeric: true,
                        ),
                      ],
                      rows: const [],
                    ),
                  ),
                ),
                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 12,
                        headingRowHeight: 0,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 48,
                        columns: [
                          DataColumn(
                            label: Text(
                              'Account Name',
                              style: _tableHeaderStyle(),
                            ),
                          ),
                          DataColumn(
                            label: Text('Remarks', style: _tableHeaderStyle()),
                          ),
                          DataColumn(
                            label: Text('Date', style: _tableHeaderStyle()),
                          ),
                          DataColumn(
                            label:
                                Text('Pay Type', style: _tableHeaderStyle()),
                          ),
                          DataColumn(
                            label:
                                Text('Head Type', style: _tableHeaderStyle()),
                          ),
                          DataColumn(
                            label: Text(
                              'Non-Tax Amt',
                              style: _tableHeaderStyle(),
                            ),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(
                              'Taxable Amt',
                              style: _tableHeaderStyle(),
                            ),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text('Tax Amt', style: _tableHeaderStyle()),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text('Income', style: _tableHeaderStyle()),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text('Expense', style: _tableHeaderStyle()),
                            numeric: true,
                          ),
                        ],
                        rows: List.generate(
                          5, // Reduced rows to fit better in dialog
                          (index) => DataRow(
                            cells: [
                              DataCell(Text('Account $index')),
                              DataCell(Text('Remarks')),
                              DataCell(Text('11/15/2024')),
                              DataCell(Text('Cash')),
                              DataCell(Text('Type')),
                              DataCell(Text(r'$100')),
                              DataCell(Text(r'$200')),
                              DataCell(Text(r'$30')),
                              DataCell(Text(r'$500')),
                              DataCell(Text(r'$100')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _buildTotalFooter(),
      ],
    );
  }

  Widget _buildTotalFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          Text(
            r'$1000', // Example total amount
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Footer ────────────────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          // Far-left — secondary utility
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              side: const BorderSide(color: _primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Num Pad',
              style: TextStyle(
                color: _primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Far-right — primary action
          ElevatedButton(
            onPressed: () {
              // Save action
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

  TextStyle _tableHeaderStyle() {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      color: _primaryColor,
      fontSize: 13,
    );
  }
}