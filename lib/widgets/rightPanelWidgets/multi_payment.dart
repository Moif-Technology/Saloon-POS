import 'package:flutter/material.dart';

class MultiPayDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500, // Adjusted dialog width for compactness
        height: 450, // Dialog height (increased to include heading)
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            // Heading Section
            Text(
              "Multi Payment Options", // Title Text
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D), // Highlight color for the heading
              ),
            ),
            const SizedBox(height: 16), // Spacing below heading

            // Main Content Section
            Expanded(
              child: Row(
                children: [
                  // Left Section: Input Fields
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInputField("Bill Amount", "27.6",
                            isReadOnly: true),
                        const SizedBox(height: 12),
                        _buildInputField("Gift Voucher", ""),
                        const SizedBox(height: 12),
                        _buildInputField("Credit Card", ""),
                        const SizedBox(height: 12),
                        _buildInputField("Cash Paid", ""),
                        const SizedBox(height: 12),
                        _buildInputField("Balance Amount", "",
                            isReadOnly: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right Section: Keypad and Buttons
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
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
                                "Back"
                              ];
                              return _buildKeypadButton(keys[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                                "Enter", const Color(0xFF521C1D)),
                            _buildActionButton("Cancel", Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input Field with label
  Widget _buildInputField(String label, String placeholder,
      {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          width: 200,
          child: TextField(
            readOnly: isReadOnly,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              hintText: placeholder,
              hintStyle: const TextStyle(color: Colors.grey),
              fillColor: isReadOnly ? Colors.grey.shade200 : Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF521C1D)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Keypad Button
  Widget _buildKeypadButton(String key) {
    return GestureDetector(
      onTap: () {
        // Handle Keypad Input
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF521C1D), // Highlight border color
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: key == "Back"
              ? const Icon(Icons.backspace, color: Colors.black)
              : Text(
                  key,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () {
        // Handle Actions
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadowColor: color.withOpacity(0.3),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
