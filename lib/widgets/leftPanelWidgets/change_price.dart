import 'package:flutter/material.dart';

class PriceChangeDialog extends StatelessWidget {
  final TextEditingController barcodeController;
  final TextEditingController currentPriceController;
  final TextEditingController newPriceController = TextEditingController();
  final TextEditingController vatPercentageController = TextEditingController();
  final TextEditingController vatAmountController = TextEditingController();
  final TextEditingController priceWithVatController = TextEditingController();

  final String productName;
  final String taxRate;

  PriceChangeDialog({
    required String barcode,
    required String currentPrice,
    required this.productName,
    required this.taxRate, // Accept Tax Rate as a parameter
  })  : barcodeController = TextEditingController(text: barcode),
        currentPriceController = TextEditingController(text: currentPrice) {
    // Initialize the VAT Percentage field with the tax rate
    vatPercentageController.text = taxRate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.price_change, color: Color(0xFF521C1D), size: 24),
                SizedBox(width: 8),
                Text(
                  'Price Change',
                  style: TextStyle(
                    color: Color(0xFF521C1D),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column with form fields
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLabeledTextField('BarCode', barcodeController,
                          isEnabled: false),
                      buildLabeledTextField(
                          'Current Price', currentPriceController,
                          isEnabled: false),
                      buildLabeledTextField('New Price', newPriceController),
                      Row(
                        children: [
                          Expanded(
                            child: buildLabeledTextField(
                              'VAT %',
                              vatPercentageController,
                              isEnabled: false, // VAT percentage is fixed
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: buildLabeledTextField(
                              'VAT Amount',
                              vatAmountController,
                              isEnabled: false,
                            ),
                          ),
                        ],
                      ),
                      buildLabeledTextField(
                        'Price With VAT',
                        priceWithVatController,
                        isEnabled: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 24), // Space between fields and keypad
                // Right column with keypad
                buildKeypad(),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton(context, 'Done', Colors.green, () {
                  Navigator.of(context).pop(newPriceController.text);
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

  Widget buildLabeledTextField(String label, TextEditingController controller,
      {bool isEnabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
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
          SizedBox(height: 4),
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white : Colors.grey[200],
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
      ),
    );
  }

  Widget buildKeypad() {
    return Container(
      width: 300,
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
          newPriceController.clear();
          vatAmountController.clear();
          priceWithVatController.clear();
        } else {
          newPriceController.text += label;
          _calculateVAT();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        elevation: 1,
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
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _calculateVAT() {
    double newPrice = double.tryParse(newPriceController.text) ?? 0.0;
    double vatPercentage = double.tryParse(vatPercentageController.text) ?? 0.0;
    double vatAmount = newPrice * vatPercentage / 100;
    double priceWithVat = newPrice + vatAmount;

    vatAmountController.text = vatAmount.toStringAsFixed(2);
    priceWithVatController.text = priceWithVat.toStringAsFixed(2);
  }
}
