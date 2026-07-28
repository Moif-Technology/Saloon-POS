import 'package:flutter/material.dart';

class PurchaseReturnDialog extends StatefulWidget {
  @override
  _PurchaseReturnDialogState createState() => _PurchaseReturnDialogState();
}

class _PurchaseReturnDialogState extends State<PurchaseReturnDialog> {
  final TextEditingController _returnController = TextEditingController();
  final TextEditingController _purchaseController = TextEditingController();
  final TextEditingController _supInvController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _roundOffController = TextEditingController();

  bool _itemWithSupplier = false;
  List<DataRow> _tableRows = [];

  @override
  void initState() {
    super.initState();
    // Dummy data for table rows
    _tableRows = List.generate(
      21,
      (index) => DataRow(cells: [
        DataCell(Text("${index + 1}", style: TextStyle(fontSize: 12))),
        DataCell(Text("12345$index", style: TextStyle(fontSize: 12))),
        DataCell(Text("Item $index", style: TextStyle(fontSize: 12))),
        DataCell(Text("Details $index", style: TextStyle(fontSize: 12))),
        DataCell(Text("43", style: TextStyle(fontSize: 12))),
        DataCell(Text("10", style: TextStyle(fontSize: 12))),
        DataCell(Text("50.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("60.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("5.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("550.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("18%", style: TextStyle(fontSize: 12))),
        DataCell(Text("99.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("649.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("649.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("649.00", style: TextStyle(fontSize: 12))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 1020,
        height: 780,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dialog Title
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Text(
                  "PURCHASE RETURN",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Return Info Section
            _buildReturnInfoSection(),
            const SizedBox(height: 16),

            // Table Section (Scrollable)
            Expanded(child: _buildScrollableTableSection()),

            const SizedBox(height: 16),

            // Footer Section with Remarks, Totals, and Round-Off
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField("Return No", _returnController)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildTextField("Purchase No", _purchaseController)),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField("Sup Inv No", _supInvController)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child:
                    _buildTextField("Supplier Name", _supplierNameController)),
            const SizedBox(width: 8),
            Expanded(child: _buildDateField("Return Date")),
            const SizedBox(width: 8),
            Expanded(
                child: _buildDropdownField(
                    "Return Type", ["With GRN", "Without GRN"])),
            const SizedBox(width: 8),
            Expanded(
                child: _buildDropdownField("Payment Mode", ["Credit", "Cash"])),
            const SizedBox(width: 8),
            Expanded(child: _buildDateField("Entered Date")),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _itemWithSupplier,
                onChanged: (value) {
                  setState(() {
                    _itemWithSupplier = value!;
                  });
                },
              ),
              Text("Item With Supplier"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableTableSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF521C1D)),
          headingTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          columns: [
            DataColumn(label: Text("Sl No")),
            DataColumn(label: Text("Barcode")),
            DataColumn(label: Text("Short Desc")),
            DataColumn(label: Text("Packet Details")),
            DataColumn(label: Text("Last Cost")),
            DataColumn(label: Text("Qty")),
            DataColumn(label: Text("Return Qty")),
            DataColumn(label: Text("Actual Cost")),
            DataColumn(label: Text("Selling Price")),
            DataColumn(label: Text("Disc")),
            DataColumn(label: Text("Total")),
            DataColumn(label: Text("VAT%")),
            DataColumn(label: Text("VAT Amt")),
            DataColumn(label: Text("Return Total")),
            DataColumn(label: Text("Line Total")),
          ],
          rows: _tableRows,
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Remark",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Purchase Bill Total:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                _buildTextField("Round Off Adjustment", _roundOffController),
                const SizedBox(height: 8),
                Text(
                  "Total Amount: 0.00",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFooterButton("Post", Colors.blue),
            _buildFooterButton("Acc Post Temp", Colors.purple),
            _buildFooterButton("Print", Colors.blue),
            _buildFooterButton("Save", Colors.green),
            _buildFooterButton("Close", Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildDateField(String label) {
    return SizedBox(
      width: 150,
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: DateTime.now().toString()),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(Icons.calendar_today, size: 16),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
        onTap: () {
          // Date picker implementation here
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        value: items[0],
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (newValue) {},
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildFooterButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label, style: TextStyle(color: Colors.white)),
    );
  }
}
