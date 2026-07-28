import 'package:flutter/material.dart';

class ProductReceiptDialog extends StatelessWidget {
  // Simulating data fetched from the backend
  final String barcodeData = "123456";
  final String availableStock = "50";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 950,
        height: 650, // Fixed height for the dialog
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Receipt Fields
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabelledTextField(
                                  "Receipt No", Colors.yellow[100]),
                              const SizedBox(height: 8),
                              _buildDateField("Receipt Date"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownField("Receipt From", "AUH"),
                              const SizedBox(height: 8),
                              _buildDropdownField("Receipt To", "AUH"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildBarcodeInfo(),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Barcode and Short Description Input Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildCompactTextField(
                              "Barcode", Colors.yellow[100]),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _buildCompactTextField(
                              "Short Description", Colors.yellow[100]),
                        ),
                        const SizedBox(width: 8),
                        _buildSmallInputField("Qty", 50),
                        const SizedBox(width: 8),
                        _buildSmallInputField("Unit Cost", 50),
                        const SizedBox(width: 8),
                        _buildSmallInputField("Unit Price", 50),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            // Add item logic
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Table Section
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      height: 310,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(Color(0xFF521C1D)),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          columns: _buildTableColumns(),
                          rows: _buildTableRows(), // Example rows
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Remarks and Total Amount Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildRemarksField(),
                        ),
                        const SizedBox(width: 8),
                        _buildTotalAmountField(),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Footer Buttons fixed at the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildFooterButton("Print", Icons.print, Colors.blue),
                const SizedBox(width: 8),
                _buildFooterButton("Save", Icons.save, Colors.green),
                const SizedBox(width: 8),
                _buildFooterButton("Close", Icons.close, Colors.grey,
                    onClose: () {
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelledTextField(String label, Color? fillColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          child: TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              suffixIcon: Icon(Icons.calendar_today, size: 16),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onTap: () {
              // Show date picker logic
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          child: DropdownButtonFormField<String>(
            value: initialValue.isEmpty ? null : initialValue,
            items: ["AUH", "DXB", "SHJ"]
                .map((location) =>
                    DropdownMenuItem(value: location, child: Text(location)))
                .toList(),
            onChanged: (value) {},
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeInfo() {
    return Container(
      width: 200,
      height: 140,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        border: Border.all(color: Colors.pink),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Barcode: $barcodeData",
              style: TextStyle(color: Colors.purple, fontSize: 16)),
          const SizedBox(height: 4),
          Text("Available Stock: $availableStock",
              style: TextStyle(color: Colors.purple, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCompactTextField(String label, Color? fillColor) {
    return SizedBox(
      height: 30,
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildSmallInputField(String label, double width) {
    return SizedBox(
      width: width,
      height: 30,
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  List<DataColumn> _buildTableColumns() {
    return [
      DataColumn(label: Text("Sl No")),
      DataColumn(label: Text("Barcode")),
      DataColumn(label: Text("Short Description")),
      DataColumn(label: Text("Qty")),
      DataColumn(label: Text("Unit")),
      DataColumn(label: Text("Pack Qty")),
      DataColumn(label: Text("Packet Details")),
      DataColumn(label: Text("Unit Cost")),
      DataColumn(label: Text("Unit Price")),
      DataColumn(label: Text("Line Total")),
      DataColumn(label: Text("Delete")),
    ];
  }

  List<DataRow> _buildTableRows() {
    return [
      DataRow(cells: [
        DataCell(Text("1")),
        DataCell(Text("123456")),
        DataCell(Text("Sample Item")),
        DataCell(Text("2")),
        DataCell(Text("Unit")),
        DataCell(Text("5")),
        DataCell(Text("Details")),
        DataCell(Text("10.00")),
        DataCell(Text("12.00")),
        DataCell(Text("24.00")),
        DataCell(IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            // Delete action
          },
        )),
      ]),
    ];
  }

  Widget _buildRemarksField() {
    return TextField(
      maxLines: 2,
      decoration: InputDecoration(
        labelText: "Remarks",
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildTotalAmountField() {
    return Column(
      children: [
        const Text("Total Amount",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            border: Border.all(color: Colors.purple),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            "0",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButton(String label, IconData icon, Color color,
      {VoidCallback? onClose}) {
    return ElevatedButton.icon(
      onPressed: onClose ?? () {},
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
