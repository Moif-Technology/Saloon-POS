import 'package:flutter/material.dart';

class MessMasterEntryDialog extends StatefulWidget {
  @override
  _MessMasterEntryDialogState createState() => _MessMasterEntryDialogState();
}

class _MessMasterEntryDialogState extends State<MessMasterEntryDialog> {
  final TextEditingController messNameController = TextEditingController();
  final TextEditingController messAmountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedNoOfTime;
  String? selectedDropdownOption;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 500,
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
                  "Mess Master Entry",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Mess Name field
            _buildCompactTextField("Mess Name", messNameController),
            SizedBox(height: 8),

            // No Of Time Dropdown
            _buildCompactDropdownField("No Of Time", ["1", "2", "3", "4"]),
            SizedBox(height: 8),

            // Mess Amount field
            _buildCompactTextField("Mess Amount", messAmountController),
            SizedBox(height: 12),

            // Dropdown and Add to Table button
            Row(
              children: [
                Expanded(
                  child: _buildCompactDropdownField(
                      "Select Option", ["Option 1", "Option 2", "Option 3"]),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Add to table logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF521C1D),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text("Add To Table", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Description Text Area
            _buildCompactTextArea("Description", descriptionController),
            SizedBox(height: 16),

            // Bottom action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
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

  // Compact Dropdown Field
  Widget _buildCompactDropdownField(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF521C1D), fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedNoOfTime = value;
        });
      },
    );
  }

  // Compact Text Area for Description
  Widget _buildCompactTextArea(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 4,
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

  // Action button styling for Save and Close
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
