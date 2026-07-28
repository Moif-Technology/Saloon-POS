import 'package:flutter/material.dart';

class BarcodePrintUtilityDialog extends StatelessWidget {
  final TextEditingController productController = TextEditingController();
  final TextEditingController text1Controller = TextEditingController();
  final TextEditingController text2Controller = TextEditingController();
  final TextEditingController printCountController =
      TextEditingController(text: "1");

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header with title
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Text(
                  "Barcode Print Utility",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Product and Text fields
            _buildCompactTextField("Product", productController),
            _buildCompactTextField("Text1", text1Controller),
            _buildCompactTextField("Text2", text2Controller),
            SizedBox(height: 12),

            // Date pickers for Production Date and Expiry Date
            _buildDateField(context, "Production Date"),
            _buildDateField(context, "Expiry Date"),
            SizedBox(height: 12),

            // Print Count field
            _buildCompactTextField("Print Count", printCountController),
            SizedBox(height: 16),

            // Bottom action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton("Print", Colors.blue),
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

  // Compact Text Field with label
  Widget _buildCompactTextField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color(0xFF521C1D), fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  // Date Field with label and Date Picker
  // Date Field with label and Date Picker
  Widget _buildDateField(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  color: Color(0xFF521C1D),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              child: TextField(
                readOnly: true,
                onTap: () async {
                  DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    print(selectedDate); // Handle selected date here
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: Icon(Icons.calendar_today,
                      color: Color(0xFF521C1D), size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action Button widget
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
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
