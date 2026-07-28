import 'package:flutter/material.dart';

class ComboDetailsEntryDialog extends StatefulWidget {
  @override
  _ComboDetailsEntryDialogState createState() =>
      _ComboDetailsEntryDialogState();
}

class _ComboDetailsEntryDialogState extends State<ComboDetailsEntryDialog> {
  final TextEditingController comboNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController itemCodeController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  String? selectedDisplayNumber;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              "Combo Details Entry",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D), // Original header color
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Combo Name and Price
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField("Combo Name", comboNameController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    "Price",
                    priceController,
                    inputType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Details
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField("Item Code", itemCodeController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildTextField("Item Name", itemNameController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    "Quantity",
                    quantityController,
                    inputType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildDropdownField(
                    "Display Number",
                    ["1", "2", "3"],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Add item logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF521C1D), // Original button color
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text("Add", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.resolveWith(
                    (states) => Color(0xFF521C1D), // Original header color
                  ),
                  headingTextStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  dataRowHeight: 36,
                  headingRowHeight: 36,
                  columns: const [
                    DataColumn(label: Text("Item Code")),
                    DataColumn(label: Text("Item Name")),
                    DataColumn(label: Text("Quantity")),
                    DataColumn(label: Text("Display No.")),
                  ],
                  rows: _generateItemRows(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Remove logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    "Remove from list",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Save logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TextField Builder
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Color(0xFF521C1D), // Original label color
        ),
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  // DropdownField Builder
  Widget _buildDropdownField(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Color(0xFF521C1D), // Original label color
        ),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedDisplayNumber = value;
        });
      },
    );
  }

  // Generate Item Rows
  List<DataRow> _generateItemRows() {
    final items = [
      {"itemCode": "1001", "itemName": "Item A", "qty": "2", "displayNo": "1"},
      {"itemCode": "1002", "itemName": "Item B", "qty": "1", "displayNo": "2"},
    ];

    return items
        .map(
          (item) => DataRow(
            cells: [
              DataCell(Text(item["itemCode"]!)),
              DataCell(Text(item["itemName"]!)),
              DataCell(Text(item["qty"]!)),
              DataCell(Text(item["displayNo"]!)),
            ],
          ),
        )
        .toList();
  }
}
