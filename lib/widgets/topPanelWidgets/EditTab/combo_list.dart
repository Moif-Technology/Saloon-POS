import 'package:flutter/material.dart';

class ComboListDialog extends StatelessWidget {
  final TextEditingController comboNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
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
                  "Combo List",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Combo Name Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: comboNameController,
                    decoration: InputDecoration(
                      labelText: "Combo Name",
                      labelStyle:
                          TextStyle(color: Color(0xFF521C1D), fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // DataTable for Combo Items with scroll and border
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
                    DataColumn(label: Text("Item Name")),
                    DataColumn(label: Text("Price")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: _generateComboRows(),
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
  List<DataRow> _generateComboRows() {
    final combos = [
      {"itemName": "Combo Item 1", "price": "10.00"},
      {"itemName": "Combo Item 2", "price": "12.50"},
      {"itemName": "Combo Item 3", "price": "15.00"},
      {"itemName": "Combo Item 4", "price": "9.99"},
      {"itemName": "Combo Item 5", "price": "8.99"},
      {"itemName": "Combo Item 6", "price": "14.00"},
    ];

    return combos.map((combo) {
      return DataRow(
        cells: [
          DataCell(
              Text(combo["itemName"] ?? "", style: TextStyle(fontSize: 14))),
          DataCell(Text(combo["price"] ?? "", style: TextStyle(fontSize: 14))),
          DataCell(Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue, size: 18),
                onPressed: () {
                  // Edit action here
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {
                  // Delete action here
                },
              ),
            ],
          )),
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
