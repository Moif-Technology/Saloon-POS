import 'package:flutter/material.dart';

class PurchaseReturnListDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 800,
        height: 800,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Text(
                  "Purchase Return List",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search and Filter Section
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField("Search"), // Search Field
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDropdownField(
                      "Post Status", ['All', 'Completed', 'Pending']),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildDropdownField(
                      "Payment Mode", ['Credit', 'Debit', 'Cash']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDropdownField(
                      "Supplier", ['All', 'Supplier 1', 'Supplier 2']),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateField("From"),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateField("To"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.search, size: 16),
                  label: Text("Search", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF521C1D),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Table Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFF521C1D)),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      dataRowHeight: 40,
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text("Return No")),
                        DataColumn(label: Text("Return Date")),
                        DataColumn(label: Text("Purchase No")),
                        DataColumn(label: Text("Supplier Inv No")),
                        DataColumn(label: Text("Supplier Name")),
                        DataColumn(label: Text("Amount")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: _generateDummyRows(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Footer Section

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildFooterButton("Select", Colors.green),
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

  // Compact Text Field for Search
  Widget _buildTextField(String label) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  // Compact Dropdown Field
  Widget _buildDropdownField(String label, List<String> options) {
    return DropdownButtonFormField<String>(
      value: options[0],
      items: options.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: TextStyle(fontSize: 12)),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (String? newValue) {},
    );
  }

  // Compact Date Field
  Widget _buildDateField(String label) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white,
      ),
      onTap: () {
        // Implement date picker logic
      },
    );
  }

  // Sample Data Rows for DataTable with Edit and Delete actions
  List<DataRow> _generateDummyRows() {
    return [
      DataRow(
          cells: _buildDataRow("123", "06/11/2024", "Supplier 1", "INV123",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("124", "07/11/2024", "Supplier 2", "INV124",
              "2000.00", "Debit", "Pending")),
      DataRow(
          cells: _buildDataRow("125", "08/11/2024", "Supplier 3", "INV125",
              "1500.00", "Cash", "Completed")),
      DataRow(
          cells: _buildDataRow("126", "09/11/2024", "Supplier 4", "INV126",
              "500.00", "Credit", "Pending")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
      DataRow(
          cells: _buildDataRow("127", "10/11/2024", "Supplier 5", "INV127",
              "1000.00", "Credit", "Completed")),
    ];
  }

  // Function to build each row
  List<DataCell> _buildDataRow(String purchaseNo, String date, String supplier,
      String invNo, String amount, String mode, String status) {
    return [
      DataCell(Text(purchaseNo, style: TextStyle(fontSize: 12))),
      DataCell(Text(date, style: TextStyle(fontSize: 12))),
      DataCell(Text(supplier, style: TextStyle(fontSize: 12))),
      DataCell(Text(invNo, style: TextStyle(fontSize: 12))),
      DataCell(Text(amount, style: TextStyle(fontSize: 12))),
      DataCell(Text(mode, style: TextStyle(fontSize: 12))),
      DataCell(Text(status, style: TextStyle(fontSize: 12))),
      DataCell(Row(
        children: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red, size: 18),
            onPressed: () {
              // Delete action
            },
          ),
        ],
      )),
    ];
  }

  // Footer Button
  Widget _buildFooterButton(String label, Color color,
      {VoidCallback? onClose}) {
    return ElevatedButton(
      onPressed: onClose ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
