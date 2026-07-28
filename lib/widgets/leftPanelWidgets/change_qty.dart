import 'package:flutter/material.dart';

class QuantityChangeDialog extends StatelessWidget {
  final TextEditingController currentQtyController;
  final TextEditingController newQtyController = TextEditingController();
  final String productName;

  QuantityChangeDialog({required String currentQty, required this.productName})
      : currentQtyController = TextEditingController(text: currentQty);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500, // Increased width for a more spacious layout
        height: 550,
        padding: const EdgeInsets.all(24), // Increased padding for aesthetics
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header text with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, color: Color(0xFF521C1D), size: 24),
                SizedBox(width: 8),
                Text(
                  'Quantity Change',
                  style: TextStyle(
                    color: Color(0xFF521C1D),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Product name
            Text(
              productName,
              style: TextStyle(
                color: Color(0xFF521C1D),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildQtyField('Current Qty', currentQtyController,
                        isEnabled: false),
                    SizedBox(height: 16),
                    buildQtyField('New Qty', newQtyController),
                  ],
                ),
                SizedBox(width: 30), // More space between fields and keypad
                buildKeypad(context),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildActionButton(context, 'Done', Colors.green, () {
                  Navigator.of(context).pop(newQtyController.text);
                }),
                buildActionButton(context, 'Cancel', Colors.red, () {
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQtyField(String label, TextEditingController controller,
      {bool isEnabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF521C1D),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 80,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey[100],
            border: Border.all(color: Color(0xFF521C1D)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
            enabled: isEnabled,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildKeypad(BuildContext context) {
    return Container(
      width: 240, // Increased width for more spacious keypad buttons
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          ...List.generate(9, (index) {
            return buildKeypadButton((index + 1).toString());
          }),
          buildKeypadButton('0'),
          buildKeypadButton('.'),
          buildKeypadButton('C', isClear: true),
        ],
      ),
    );
  }

  Widget buildKeypadButton(String label, {bool isClear = false}) {
    return ElevatedButton(
      onPressed: () {
        if (isClear) {
          newQtyController.clear();
        } else {
          newQtyController.text += label;
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        elevation: 1,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isClear ? Colors.red : Color(0xFF521C1D),
        ),
      ),
    );
  }

  Widget buildActionButton(
      BuildContext context, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
