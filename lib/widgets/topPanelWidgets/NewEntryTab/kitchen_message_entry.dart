import 'package:flutter/material.dart';

class KitchenMessageEntryDialog extends StatefulWidget {
  @override
  _KitchenMessageEntryDialogState createState() =>
      _KitchenMessageEntryDialogState();
}

class _KitchenMessageEntryDialogState extends State<KitchenMessageEntryDialog> {
  final TextEditingController englishMessageController =
      TextEditingController();
  final TextEditingController arabicMessageController = TextEditingController();

  List<dynamic> _modifiers = [];
  bool _isLoading = true;
  int? _selectedModifierID;

  @override
  void initState() {
    super.initState();
    _fetchModifiers();
  }

  Future<void> _fetchModifiers() async {
    setState(() {
      _modifiers = [
        {
          'ModifierID': 1,
          'EnglishMessage': 'No onion',
          'ArabicMessage': '',
        },
        {
          'ModifierID': 2,
          'EnglishMessage': 'Extra spicy',
          'ArabicMessage': '',
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _saveModifier() async {
    if (englishMessageController.text.isEmpty &&
        arabicMessageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Please enter both English and Arabic messages")),
      );
      return;
    }

    setState(() {
      _modifiers.add({
        'ModifierID': DateTime.now().millisecondsSinceEpoch,
        'EnglishMessage': englishMessageController.text.trim(),
        'ArabicMessage': arabicMessageController.text.trim(),
      });
      englishMessageController.clear();
      arabicMessageController.clear();
    });
    await _showSuccessDialog('Kitchen message saved in mock mode.');
  }

  Future<void> _updateModifier() async {
    if (_selectedModifierID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No modifier selected for update")),
      );
      return;
    }

    if (englishMessageController.text.isEmpty &&
        arabicMessageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Please enter both English and Arabic messages")),
      );
      return;
    }

    setState(() {
      final index =
          _modifiers.indexWhere((m) => m['ModifierID'] == _selectedModifierID);
      if (index >= 0) {
        _modifiers[index] = {
          'ModifierID': _selectedModifierID,
          'EnglishMessage': englishMessageController.text.trim(),
          'ArabicMessage': arabicMessageController.text.trim(),
        };
      }
    });
    await _showSuccessDialog('Kitchen message updated in mock mode.');
  }

  Future<void> _deleteModifier(int modifierID) async {
    final isConfirmed = await _showConfirmationDialog();
    if (!isConfirmed) return;

    setState(() {
      _modifiers.removeWhere((m) => m['ModifierID'] == modifierID);
      if (_selectedModifierID == modifierID) _selectedModifierID = null;
    });
    await _showSuccessDialog('Kitchen message deleted in mock mode.');
  }

  Future<void> _showSuccessDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade100,
                  Colors.green.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 80,
                ),
                SizedBox(height: 20),

                // Title
                Text(
                  'Success',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 15),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 25),

                // OK Button with modern design
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.orange, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Confirm Delete',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to delete this item?',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _clearForm() {
    englishMessageController.clear();
    arabicMessageController.clear();
    _selectedModifierID = null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        height: 600,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "Kitchen Message Entry",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMessageTextField(
                        "Kitchen Message", englishMessageController),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMessageTextField(
                      "رسالة للمطبخ",
                      arabicMessageController,
                      isRightToLeft: true,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child:
                  _isLoading ? _buildLoadingIndicator() : _buildMessageTable(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                      "Save", Icons.save, Colors.blue, _saveModifier),
                  _buildActionButton(
                      "Update", Icons.update, Colors.green, _updateModifier),
                  _buildActionButton("Close", Icons.close, Colors.red, () {
                    Navigator.of(context).pop();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildMessageTextField(String label, TextEditingController controller,
      {bool isRightToLeft = false}) {
    return TextField(
      controller: controller,
      textDirection: isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMessageTable() {
    return SingleChildScrollView(
      child: DataTable(
        columns: [
          DataColumn(label: Text("Message")),
          DataColumn(label: Text("Message Arabic")),
          DataColumn(label: Text("Actions")),
        ],
        rows: _modifiers.map((modifier) {
          final modifierID = modifier["ModifierID"];
          final modifierName = modifier["Modifier"];
          final modifierArabic = modifier["ModifierArabic"];

          return DataRow(
            cells: [
              DataCell(Text(modifierName)),
              DataCell(Text(modifierArabic)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        englishMessageController.text = modifierName;
                        arabicMessageController.text = modifierArabic;
                        _selectedModifierID = modifierID;
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteModifier(modifierID);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

Widget _buildActionButton(
    String label, IconData icon, Color color, VoidCallback onPressed) {
  return ElevatedButton.icon(
    icon: Icon(icon, color: Colors.white),
    label: Text(label),
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
    ),
  );
}
