import 'package:flutter/material.dart';

class CustomerDisplayScreen extends StatelessWidget {
  final List<Map<String, dynamic>> readyOrders = [
    {'kot': '1032', 'area': 'DINE-IN', 'time': '12:45 PM'},
    {'kot': '1035', 'area': 'TAKEAWAY', 'time': '12:46 PM'},
  ];

  final List<Map<String, dynamic>> preparingOrders = [
    {'kot': '1040', 'area': 'DINE-IN', 'time': '12:50 PM'},
    {'kot': '1042', 'area': 'TAKEAWAY', 'time': '12:52 PM'},
    {'kot': '1043', 'area': 'DINE-IN', 'time': '12:54 PM'},
  ];

  Widget buildKotCard(Map<String, dynamic> order, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("KOT #${order['kot']}",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              )),
          const SizedBox(height: 6),
          Text(order['area'],
              style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(order['time'],
              style: const TextStyle(fontSize: 16, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget buildSection(String title, List<Map<String, dynamic>> orders, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: orders.map((order) => buildKotCard(order, color)).toList(),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(52, 5, 15, 1),   // deep maroon
              Color.fromRGBO(128, 0, 0, 1),   // red center
              Color.fromRGBO(52, 5, 15, 1),   // deep maroon again
            ],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("CUSTOMER ORDER DISPLAY",
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2)),
            ),
            const SizedBox(height: 30),
            buildSection("Now Serving", readyOrders, Colors.greenAccent),
            buildSection("Preparing", preparingOrders, Colors.orangeAccent),
            const Spacer(),
            Center(
              child: Text("Please collect your food when it’s READY!",
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
