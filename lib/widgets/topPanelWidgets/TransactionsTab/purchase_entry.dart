import 'package:flutter/material.dart';

class PurchaseEntryDialog extends StatefulWidget {
  @override
  _PurchaseEntryDialogState createState() => _PurchaseEntryDialogState();
}

class _PurchaseEntryDialogState extends State<PurchaseEntryDialog> {
  final TextEditingController _purchaseController = TextEditingController();
  final TextEditingController _supInvController = TextEditingController();
  final TextEditingController _lpoController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _invoiceAmtController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _roundOffController = TextEditingController();

  bool _fromLpo = false;
  List<DataRow> _tableRows = [];

  @override
  void initState() {
    super.initState();
    _tableRows = List.generate(
      21,
      (index) => DataRow(cells: [
        DataCell(Text("${index + 1}", style: TextStyle(fontSize: 12))),
        DataCell(Text("12345$index", style: TextStyle(fontSize: 12))),
        DataCell(Text("Item $index", style: TextStyle(fontSize: 12))),
        DataCell(Text("5", style: TextStyle(fontSize: 12))),
        DataCell(Text("Details $index", style: TextStyle(fontSize: 12))),
        DataCell(Text("43 $index", style: TextStyle(fontSize: 12))),
        DataCell(Text("10", style: TextStyle(fontSize: 12))),
        DataCell(Text("2", style: TextStyle(fontSize: 12))),
        DataCell(Text("50.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("60.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("5.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("550.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("18%", style: TextStyle(fontSize: 12))),
        DataCell(Text("99.00", style: TextStyle(fontSize: 12))),
        DataCell(Text("649.00", style: TextStyle(fontSize: 12))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;

        // Adjusting width, height, and scale based on screen resolutions
        double dialogWidth;
        double dialogHeight;
        double scale;

        if (screenWidth >= 1920 && screenHeight >= 1080) {
          dialogWidth = screenWidth * 1020;
          dialogHeight = screenHeight * 0.80;
          scale = 1.0;
        } else if (screenWidth >= 1366 && screenHeight >= 768) {
          dialogWidth = screenWidth * 0.5;
          dialogHeight = screenHeight * 0.80;
          scale = 0.85;
        } else {
          dialogWidth = screenWidth * 0.7;
          dialogHeight = screenHeight * 0.9;
          scale = 0.75;
        }

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Dialog Title
                Text(
                  "NEW PURCHASE",
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),

                // Purchase Information Section
                _buildPurchaseInfoSection(scale),
                const SizedBox(height: 16),

                // Add Items Section
                _buildAddItemsSection(scale),
                const SizedBox(height: 16),

                // Table Section (Scrollable)
                Expanded(child: _buildScrollableTableSection(scale)),

                const SizedBox(height: 16),

                // Footer Section with Remarks, Totals, and Round-Off
                _buildFooterSection(scale),
              ],
            ),
          ),
        );
      },
    );
  }

  // Purchase Information Section
  Widget _buildPurchaseInfoSection(double scale) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildBoundedTextField(
                    "Purchase #", _purchaseController, scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildBoundedTextField(
                    "Sup Inv #", _supInvController, scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildBoundedTextField("LPO No", _lpoController, scale)),
            Checkbox(
              value: _fromLpo,
              onChanged: (value) {
                setState(() {
                  _fromLpo = value!;
                });
              },
            ),
            Text("From LPO", style: TextStyle(fontSize: 12 * scale)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _buildBoundedTextField(
                    "Supplier Name", _supplierNameController, scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildBoundedDateField(
                    "Purchase Date", DateTime.now().toString(), scale)),
            const SizedBox(width: 8),
            Expanded(
                child:
                    _buildDropdownField("Pay Mode", ["Credit", "Cash"], scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildBoundedDateField(
                    "Entered Date", DateTime.now().toString(), scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildBoundedTextField(
                    "Invoice Amt", _invoiceAmtController, scale)),
          ],
        ),
      ],
    );
  }

  // Add Items Section
  Widget _buildAddItemsSection(double scale) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildCompactTextField(
                    "Barcode", TextEditingController(), scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildCompactTextField(
                    "Short Description", TextEditingController(), scale)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _buildCompactTextField(
                    "Pack Qty", TextEditingController(), scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildCompactTextField(
                    "Packet Details", TextEditingController(), scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildCompactTextField(
                    "Qty", TextEditingController(), scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildCompactTextField(
                    "FOC Qty", TextEditingController(), scale)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _buildCompactTextField(
                    "Unit Cost", TextEditingController(), scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildCompactTextField(
                    "Selling Price", TextEditingController(), scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildCompactTextField(
                    "Discount", TextEditingController(), scale)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildCompactTextField(
                    "Total", TextEditingController(), scale)),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              // Add logic for adding items to table here
            },
            icon: Icon(Icons.add, size: 16 * scale),
            label: Text("Add to Table", style: TextStyle(fontSize: 14 * scale)),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueGrey,
              padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale, vertical: 10 * scale),
            ),
          ),
        ),
      ],
    );
  }

  // Scrollable Table Section
  Widget _buildScrollableTableSection(double scale) {
    return Container(
      height: 300 * scale,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
            columnSpacing: 8 * scale,
            columns: [
              DataColumn(
                  label: Text("Sl No", style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label:
                      Text("Barcode", style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label: Text("Short Description",
                      style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label:
                      Text("Pack Qty", style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label: Text("Pack Details",
                      style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label: Text("Last Purch Cost",
                      style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label: Text("Qty", style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label:
                      Text("FOC Qty", style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label: Text("Unit Cost",
                      style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label: Text("Selling Price",
                      style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label:
                      Text("Discount", style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label: Text("Total", style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label: Text("VAT %", style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label:
                      Text("VAT Amt", style: TextStyle(fontSize: 12 * scale))),
              DataColumn(
                  label: Text("Line Total",
                      style: TextStyle(fontSize: 12 * scale))),
            ],
            rows: _tableRows,
          ),
        ),
      ),
    );
  }

  // Footer Section with Remarks, Total, Round-Off Adjustment, and Net Amount
  Widget _buildFooterSection(double scale) {
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
                Text("Total",
                    style: TextStyle(
                        fontSize: 14 * scale, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text("0",
                        style: TextStyle(
                            fontSize: 14 * scale, color: Colors.black)),
                    const SizedBox(width: 8),
                    Text("0",
                        style: TextStyle(
                            fontSize: 14 * scale, color: Colors.black)),
                    const SizedBox(width: 8),
                    Text("0",
                        style: TextStyle(
                            fontSize: 14 * scale, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBoundedTextField(
                    "Round Off Adjustment", _roundOffController, scale),
                const SizedBox(height: 8),
                Text(
                  "Net Amount: 0.00",
                  style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFooterButton("Edit", Colors.red, scale),
            _buildFooterButton("Post", Colors.blue, scale),
            _buildFooterButton("Acc Post Temp", Colors.purple, scale),
            _buildFooterButton("Print", Colors.blue, scale),
            _buildFooterButton("Save", Colors.green, scale),
            _buildFooterButton("Close", Colors.grey, scale),
          ],
        ),
      ],
    );
  }

  Widget _buildBoundedTextField(
      String label, TextEditingController controller, double scale) {
    return SizedBox(
      width: 150 * scale,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 15 * scale),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 8, vertical: 8 * scale),
        ),
      ),
    );
  }

  Widget _buildCompactTextField(
      String label, TextEditingController controller, double scale) {
    return SizedBox(
      height: 36 * scale,
      width: 150 * scale,
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

  Widget _buildBoundedDateField(String label, String value, double scale) {
    return SizedBox(
      width: 150 * scale,
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(Icons.calendar_today, size: 16 * scale),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 8, vertical: 8 * scale),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, double scale) {
    return SizedBox(
      width: 150 * scale,
      child: DropdownButtonFormField<String>(
        value: items[0],
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: TextStyle(fontSize: 12 * scale)),
                ))
            .toList(),
        onChanged: (newValue) {},
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 8, vertical: 8 * scale),
        ),
      ),
    );
  }

  Widget _buildFooterButton(String label, Color color, double scale) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding:
            EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 12 * scale),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12 * scale, color: Colors.white),
      ),
    );
  }
}
