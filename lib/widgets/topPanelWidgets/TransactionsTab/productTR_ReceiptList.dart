import 'package:flutter/material.dart';

class ProductReceiptListDialog extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final double dialogWidth = screen.width > 1100 ? 1000 : screen.width * 0.95;
    final double dialogHeight = screen.height > 720 ? 680 : screen.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
                    _buildFilterSection(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildTableSection()),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ── 1. Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.only(left: 20, right: 8),
      decoration: const BoxDecoration(color: _primaryColor),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Product Receipt List',
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
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: 'Close',
              icon: const Icon(Icons.close, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Search & Filter Section ─────────────────────────────────────────
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  // Search action logic here
                },
                icon: const Icon(Icons.search, color: Colors.white, size: 18),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _primaryColor,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildDateField('From')),
              const SizedBox(width: 10),
              Expanded(child: _buildDateField('To')),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Receipt List Table ────────────────────────────────────────────────
  Widget _buildTableSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(_primaryColor),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          dataRowMinHeight: 44,
          dataRowMaxHeight: 50,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Transfer No')),
            DataColumn(label: Text('Transfer From')),
            DataColumn(label: Text('Transfer To')),
            DataColumn(label: Text('Transfer Date')),
            DataColumn(label: Text('Total Amount')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _generateDummyRows(),
        ),
      ),
    );
  }

  // ── 4. Footer ────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBFB),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // Select action logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Select',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  List<DataRow> _generateDummyRows() {
    final data = [
      {
        'transferNo': 'TR001',
        'from': 'Warehouse A',
        'to': 'Warehouse B',
        'date': '01/11/2024',
        'amount': '500.00',
        'status': 'Completed',
      },
      {
        'transferNo': 'TR002',
        'from': 'Warehouse B',
        'to': 'Warehouse A',
        'date': '02/11/2024',
        'amount': '300.00',
        'status': 'Pending',
      },
    ];

    return data.map((row) {
      return DataRow(
        cells: [
          DataCell(Text(row['transferNo'] ?? '')),
          DataCell(Text(row['from'] ?? '')),
          DataCell(Text(row['to'] ?? '')),
          DataCell(Text(row['date'] ?? '')),
          DataCell(Text(row['amount'] ?? '')),
          DataCell(Text(row['status'] ?? '')),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                  onPressed: () {
                    // Edit action logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () {
                    // Delete action logic
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildDateField(String label) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 0,
        ),
      ),
      onTap: () {
        // Date picker logic goes here
      },
    );
  }
}