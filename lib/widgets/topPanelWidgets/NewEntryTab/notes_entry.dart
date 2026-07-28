import 'package:flutter/material.dart';

class NotesEntryDialog extends StatefulWidget {
  @override
  _NotesEntryDialogState createState() => _NotesEntryDialogState();
}

class _NotesEntryDialogState extends State<NotesEntryDialog> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 800,
        height: 600,
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
                  "Notes Entry",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Date Range and Description Filter
            Row(
              children: [
                Expanded(
                  child: _buildDateField("From:", fromDateController),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildDateField("To:", toDateController),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactTextField(
                      "Description", descriptionController),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Notes List and Editor
            Expanded(
              child: Row(
                children: [
                  // Notes List
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        children: _generateNotesList(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),

                  // Notes Editor
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(8),
                      child: TextField(
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: "Type your note here...",
                          border: InputBorder.none,
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Date and Created By Information
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  "Date: 07/11/2024    Created By: User",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Bottom Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton("Add New", Colors.brown),
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

  // Compact Date Field with label
  Widget _buildDateField(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Color(0xFF521C1D), fontSize: 13),
          ),
        ),
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                controller.text = "${pickedDate.toLocal()}".split(' ')[0];
              }
            },
            decoration: InputDecoration(
              suffixIcon: Icon(Icons.calendar_today,
                  size: 16, color: Color(0xFF521C1D)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
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

  // Generate sample notes list
  List<Widget> _generateNotesList() {
    final notes = [
      {"date": "07/11/2024 1:57 PM", "description": "Note 1"},
      {"date": "07/11/2024 2:00 PM", "description": "Note 2"},
    ];

    return notes
        .map((note) => ListTile(
              title: Text(note["date"] ?? "", style: TextStyle(fontSize: 12)),
              subtitle: Text(note["description"] ?? "",
                  style: TextStyle(fontSize: 12)),
              tileColor: Colors.white,
              selectedTileColor: Colors.grey[300],
              onTap: () {
                // Handle note selection logic
              },
            ))
        .toList();
  }

  // Helper widget for action buttons
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
