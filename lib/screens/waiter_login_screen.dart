// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';

// class WaiterLoginScreen extends ConsumerStatefulWidget {
//   @override
//   _WaiterLoginScreenState createState() => _WaiterLoginScreenState();
// }

// class _WaiterLoginScreenState extends ConsumerState<WaiterLoginScreen> {
//   final TextEditingController _pinController = TextEditingController();
//   bool _isLoading = false;
//   String? _errorMessage;
//   bool _showPin = false;

//   @override
//   void dispose() {
//     _pinController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleLogin() async {
//     if (_pinController.text.length != 4) {
//       setState(() => _errorMessage = "Enter 4-digit staff code");
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     await Future.delayed(Duration(seconds: 1));

//     if (_pinController.text == "2024") {
//       _showSuccessFeedback();
//     } else {
//       setState(() {
//         _errorMessage = "Invalid access code";
//         _pinController.clear();
//       });
//     }

//     setState(() => _isLoading = false);
//   }

//   void _showSuccessFeedback() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Welcome, Server #${_pinController.text}"),
//         backgroundColor: Color(0xFF5E132A),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _handleKeypress(String value) {
//     if (value == "⌫" && _pinController.text.isNotEmpty) {
//       _pinController.text =
//           _pinController.text.substring(0, _pinController.text.length - 1);
//     } else if (_pinController.text.length < 4 && value != "⌫") {
//       _pinController.text += value;
//     }
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       body: Row(
//         children: [
//           // LEFT PANEL
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 40),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF5E132A), Color(0xFF3A0D1E)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.restaurant_menu, size: 80, color: Colors.white),
//                     SizedBox(height: 20),
//                     Text(
//                       "MOIF RESTAURANT",
//                       style: GoogleFonts.playfairDisplay(
//                         fontSize: 36,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     Text(
//                       "POS Login",
//                       style: GoogleFonts.nunito(
//                         color: Colors.white70,
//                         fontSize: 18,
//                         letterSpacing: 2,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // RIGHT PANEL
//           Container(
//             width: size.width * 0.5,
//             color: Colors.white,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 50),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Title
//                   Text(
//                     "Enter Staff Code",
//                     style: GoogleFonts.nunito(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF5E132A),
//                     ),
//                   ),
//                   SizedBox(height: 30),

//                   // PIN Display
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: List.generate(4, (index) {
//                       final hasValue = index < _pinController.text.length;
//                       return Container(
//                         width: 60,
//                         height: 70,
//                         margin: EdgeInsets.symmetric(horizontal: 10),
//                         decoration: BoxDecoration(
//                           border: Border(
//                             bottom: BorderSide(
//                               color: hasValue
//                                   ? Color(0xFF5E132A)
//                                   : Colors.grey.shade400,
//                               width: 3,
//                             ),
//                           ),
//                         ),
//                         child: Center(
//                           child: Text(
//                             hasValue
//                                 ? (_showPin ? _pinController.text[index] : "•")
//                                 : "",
//                             style: TextStyle(
//                               fontSize: 32,
//                               color: Color(0xFF5E132A),
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       );
//                     }),
//                   ),
//                   if (_errorMessage != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 20),
//                       child: Text(
//                         _errorMessage!,
//                         style: TextStyle(color: Colors.red[700]),
//                       ),
//                     ),
//                   TextButton(
//                     onPressed: () => setState(() => _showPin = !_showPin),
//                     child: Text(
//                       _showPin ? "Hide PIN" : "Show PIN",
//                       style: TextStyle(color: Color(0xFF5E132A)),
//                     ),
//                   ),

//                   SizedBox(height: 100),

//                   // FULL HEIGHT KEYPAD
//                   Expanded(
//                     child: GridView.count(
//                       crossAxisCount: 3,
//                       mainAxisSpacing: 20,
//                       crossAxisSpacing: 20,
//                       childAspectRatio: 2,
//                       physics: NeverScrollableScrollPhysics(),
//                       children: [
//                         for (int i = 1; i <= 9; i++)
//                           _BigKeypadButton(
//                             value: "$i",
//                             onPressed: () => _handleKeypress("$i"),
//                           ),
//                         _BigKeypadButton(
//                           value: "⌫",
//                           onPressed: () => _handleKeypress("⌫"),
//                           icon: Icons.backspace_outlined,
//                         ),
//                         _BigKeypadButton(
//                           value: "0",
//                           onPressed: () => _handleKeypress("0"),
//                         ),
//                         _BigKeypadButton(
//                           value: "GO",
//                           onPressed: _handleLogin,
//                           isPrimary: true,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _BigKeypadButton extends StatelessWidget {
//   final String value;
//   final VoidCallback onPressed;
//   final bool isPrimary;
//   final IconData? icon;

//   const _BigKeypadButton({
//     required this.value,
//     required this.onPressed,
//     this.isPrimary = false,
//     this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isPrimary ? Color(0xFF5E132A) : Colors.grey.shade100,
//         foregroundColor: isPrimary ? Colors.white : Color(0xFF5E132A),
//         elevation: 6,
//         padding: EdgeInsets.symmetric(vertical: 24),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         textStyle: GoogleFonts.nunito(
//           fontSize: 32,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       child: icon != null ? Icon(icon, size: 36) : Text(value),
//     );
//   }
// }

import 'package:flutter/material.dart';

class WaiterLoginScreen extends StatefulWidget {
  const WaiterLoginScreen({super.key});

  @override
  State<WaiterLoginScreen> createState() => _WaiterLoginScreenState();
}

class _WaiterLoginScreenState extends State<WaiterLoginScreen> {
  final List<Map<String, String>> waiters = [
    {"name": "John", "role": "Waiter 1"},
    {"name": "Sarah", "role": "Waiter 2"},
    {"name": "Ahmed", "role": "Waiter 3"},
    {"name": "Aisha", "role": "Waiter 4"},
    {"name": "Ali", "role": "Waiter 5"},
    {"name": "Zara", "role": "Waiter 6"},
    {"name": "David", "role": "Waiter 7"},
    {"name": "Noor", "role": "Waiter 8"},
  ];

  String? selectedWaiter;
  String pin = "";

  void _onKeyTap(String value) {
    setState(() {
      if (value == 'C') {
        pin = "";
      } else if (value == '←') {
        if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
      } else if (value == '✔') {
        _validatePin();
      } else if (pin.length < 4) {
        pin += value;
      }
    });
  }

  void _validatePin() {
    if (pin == '1234') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $selectedWaiter logged in')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Incorrect PIN')),
      );
      setState(() => pin = "");
    }
  }

  Widget _buildWaiterCard(String name, String role) {
    final isSelected = selectedWaiter == name;

    return GestureDetector(
      onTap: () => setState(() {
        selectedWaiter = name;
        pin = "";
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDEAEA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF800000) : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: isSelected
                  ? const Color(0xFF800000).withOpacity(0.1)
                  : Colors.grey.shade200,
              child: Icon(Icons.person,
                  size: 30,
                  color: isSelected ? const Color(0xFF800000) : Colors.black54),
              radius: 28,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              role,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    const List<List<String>> keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['←', '0', '✔'],
      ['C']
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          selectedWaiter != null
              ? "Welcome, $selectedWaiter"
              : "Select a waiter",
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D)),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: pin.length > index
                    ? const Color(0xFF800000)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF800000)),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        for (var row in keys)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              return Padding(
                padding: const EdgeInsets.all(6.0),
                child: ElevatedButton(
                  onPressed: () => _onKeyTap(key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: key == '✔'
                        ? Colors.green.shade700
                        : key == 'C'
                            ? Colors.grey.shade600
                            : const Color(0xFF800000),
                    foregroundColor: Colors.white,
                    fixedSize: const Size(100, 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    key,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Row(
          children: [
            // Waiter Grid
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: waiters
                      .map((w) => _buildWaiterCard(w['name']!, w['role']!))
                      .toList(),
                ),
              ),
            ),

            // PIN Pad
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEFEFEF),
                  border: Border(
                    left: BorderSide(color: Color(0xFFDDDDDD), width: 1),
                  ),
                ),
                child: selectedWaiter == null
                    ? const Center(
                        child: Text(
                          "← Select a waiter",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500),
                        ),
                      )
                    : _buildPinPad(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
