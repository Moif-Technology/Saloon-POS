import 'package:flutter/material.dart';

class SupplierMasterListDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 800, // Reduced width
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF521C1D), // Dark red color for header
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Text(
                  "Supplier Master List",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100], // Light grey for search background
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Search",
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Search action logic here
                        },
                        icon: Icon(Icons.search, color: Colors.white),
                        label: Text("Search"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xFF521C1D),
                          side: BorderSide(color: Color(0xFF521C1D)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data Table Section
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 350, // Adjusted height for a balanced layout
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFF521C1D)),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  dataRowHeight: 50,
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text("SupplierCode")),
                    DataColumn(label: Text("SupplierName")),
                    DataColumn(label: Text("Telephone")),
                    DataColumn(label: Text("MobileNo")),
                    DataColumn(label: Text("ContactPerson")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: _generateSupplierRows(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildFooterButton("New", Colors.green),
                const SizedBox(width: 8),
                _buildFooterButton("Select", Colors.grey[800]!),
                const SizedBox(width: 8),
                _buildFooterButton("Close", Colors.red, onClose: () {
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Generate dummy rows for DataTable
  List<DataRow> _generateSupplierRows() {
    final data = [
      {
        "supplierCode": "Supp2",
        "supplierName": "AL BAHIJ DRAWING MATE...",
        "telephone": "0",
        "mobileNo": "0553752551",
        "contactPerson": "SHAMSU"
      },
      {
        "supplierCode": "Supp1",
        "supplierName": "CASH SUPPLIER",
        "telephone": "0",
        "mobileNo": "0553752551",
        "contactPerson": "SHAMSU"
      },
      {
        "supplierCode": "001",
        "supplierName": "COCA COLA",
        "telephone": "0502272920",
        "mobileNo": "0553752551",
        "contactPerson": "JOHN DOE"
      },
      {
        "supplierCode": "002",
        "supplierName": "LULU",
        "telephone": "024437500",
        "mobileNo": "0553752551",
        "contactPerson": "JANE DOE"
      },
    ];

    return data.map((row) {
      return DataRow(cells: [
        DataCell(Text(row["supplierCode"] ?? "")),
        DataCell(Text(row["supplierName"] ?? "")),
        DataCell(Text(row["telephone"] ?? "")),
        DataCell(Text(row["mobileNo"] ?? "")),
        DataCell(Text(row["contactPerson"] ?? "")),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue, size: 18),
                onPressed: () {
                  // Edit action logic
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {
                  // Delete action logic
                },
              ),
            ],
          ),
        ),
      ]);
    }).toList();
  }

  // Helper function for the date field
  Widget _buildDateField(String label) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today, size: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onTap: () {
        // Date picker logic goes here
      },
    );
  }

  // Helper function for bottom footer buttons
  Widget _buildFooterButton(String label, Color color,
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
