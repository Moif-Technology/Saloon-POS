import 'package:flutter/material.dart';

class SourceEntry extends StatefulWidget {
  @override
  _SourceNameEntryDialogState createState() => _SourceNameEntryDialogState();
}

class _SourceNameEntryDialogState extends State<SourceEntry> {
  final TextEditingController sourceNameController = TextEditingController();
  final TextEditingController sourceNameArabicController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Text(
                  "Source Name Entry",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Source Name and Source Name Arabic fields
            _buildCompactTextField("Source Name", sourceNameController),
            SizedBox(height: 8),
            _buildCompactTextField(
                "Source Name Arabic", sourceNameArabicController),
            SizedBox(height: 16),

            // Bottom action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton("New", Colors.green),
                _buildActionButton("Save", Colors.blue),
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
    return TextField(
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
    );
  }

  // Action buttons for New, Save, and Close
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
