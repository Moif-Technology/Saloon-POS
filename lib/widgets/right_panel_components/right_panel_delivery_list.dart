import 'package:flutter/material.dart';

class RightPanelDeliveryList extends StatelessWidget {
  final List<Map<String, dynamic>> deliveryList;
  final VoidCallback onBack;
  final Future<void> Function(Map<String, dynamic> item) onTapItem;

  const RightPanelDeliveryList({
    super.key,
    required this.deliveryList,
    required this.onBack,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text("Back",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: deliveryList.map((item) {
                    return GestureDetector(
                      onTap: () => onTapItem(item),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "${item['KotPrefix']}${item['KotNumber']}",
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
