import 'package:flutter/material.dart';

class OnlineSourcesDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Minimal rounded border
      ),
      child: Container(
        width: 420, // Dialog width
        height: 320, // Dialog height
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Title
            Text(
              "Online Sources",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D), // Title color
              ),
            ),
            const SizedBox(height: 20),

            // Buttons for Sources
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.7, // Adjust aspect ratio for button size
                children: [
                  _buildSourceButton("GHAYATHA"),
                  _buildSourceButton("ONLINE"),
                  _buildSourceButton("TALABAT"),
                  _buildSourceButton("TM DONE"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cancel Button
            _buildCancelButton(context),
          ],
        ),
      ),
    );
  }

  // Build Source Button
  Widget _buildSourceButton(String label) {
    return GestureDetector(
      onTap: () {
        print("$label pressed"); // Handle source button press
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF521C1D), // Primary color for buttons
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF521C1D).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color
            ),
          ),
        ),
      ),
    );
  }

  // Build Cancel Button
  Widget _buildCancelButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(); // Close the dialog
      },
      child: Container(
        height: 40,
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF521C1D), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "Cancel",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D), // Cancel button text color
            ),
          ),
        ),
      ),
    );
  }
}
