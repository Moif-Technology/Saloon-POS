import 'package:flutter/material.dart';

class MessListDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Text(
                  "Mess List",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // DataTable with scroll and border
            Container(
              height: 300, // Fixed height for table with scroll
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), // Table border
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFF521C1D)),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  dataRowHeight: 40,
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text("Mess Description")),
                    DataColumn(label: Text("No Of Times")),
                    DataColumn(label: Text("Mess Amount")),
                    DataColumn(label: Text("Active Status")),
                  ],
                  rows: _generateMessRows(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton("Select", Colors.grey[800]!),
                const SizedBox(width: 8),
                _buildActionButton("Close", Colors.red, onClose: () {
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Generate sample rows for DataTable
  List<DataRow> _generateMessRows() {
    final messItems = [
      {
        "description": "Breakfast",
        "noOfTimes": "1",
        "amount": "20.00",
        "status": "Active"
      },
      {
        "description": "Lunch",
        "noOfTimes": "1",
        "amount": "30.00",
        "status": "Active"
      },
      {
        "description": "Dinner",
        "noOfTimes": "1",
        "amount": "25.00",
        "status": "Inactive"
      },
      {
        "description": "Snacks",
        "noOfTimes": "2",
        "amount": "15.00",
        "status": "Active"
      },
      // Add more rows as needed
    ];

    return messItems.map((mess) {
      return DataRow(
        cells: [
          DataCell(
              Text(mess["description"] ?? "", style: TextStyle(fontSize: 14))),
          DataCell(
              Text(mess["noOfTimes"] ?? "", style: TextStyle(fontSize: 14))),
          DataCell(Text(mess["amount"] ?? "", style: TextStyle(fontSize: 14))),
          DataCell(Text(mess["status"] ?? "", style: TextStyle(fontSize: 14))),
        ],
      );
    }).toList();
  }

  // Helper widget for bottom action buttons
  Widget _buildActionButton(String label, Color color,
      {VoidCallback? onClose}) {
    return Container(
      height: 36,
      child: ElevatedButton(
        onPressed: onClose ?? () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
