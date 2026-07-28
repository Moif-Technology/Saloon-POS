import 'package:flutter/material.dart';

class Compliment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Container(
        width: 380,
        height: 510,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF521C1D), // Our discussed background color
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Section
            Text(
              "Compliment Login",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Title in white
              ),
            ),
            const SizedBox(height: 16),

            // Username Field
            _buildInputField("User Name"),
            const SizedBox(height: 16),

            // Password Field
            _buildInputField("Password", isPassword: true),
            const SizedBox(height: 20),

            // Keypad
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.6, // Adjust for better button size
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final keys = [
                    "7",
                    "8",
                    "9",
                    "4",
                    "5",
                    "6",
                    "1",
                    "2",
                    "3",
                    "0",
                    ".",
                    "C",
                  ];
                  return _buildKeypadButton(keys[index]);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Buttons: Login and Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                    "Login", Colors.white, const Color(0xFF521C1D)),
                _buildActionButton("Close", Colors.red, Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Input Field Widget
  Widget _buildInputField(String label, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Label in white
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white, // Input box background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF521C1D), // Border color matches theme
            ),
          ),
          child: TextField(
            obscureText: isPassword,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // Keypad Button Widget
  Widget _buildKeypadButton(String label) {
    return GestureDetector(
      onTap: () {
        // Handle Keypad Button Press
        print("$label pressed");
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white, // White border
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text
            ),
          ),
        ),
      ),
    );
  }

  // Action Button Widget
  Widget _buildActionButton(
      String label, Color textColor, Color backgroundColor) {
    return ElevatedButton(
      onPressed: () {
        // Handle Action Button Press
        print("$label button pressed");
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
