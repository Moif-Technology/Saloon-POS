import 'package:flutter/material.dart';

class RightPanelTakeAwayList extends StatelessWidget {
  final List<Map<String, dynamic>> takeAwayList;
  final VoidCallback onBack;
  final Future<void> Function(Map<String, dynamic> item) onTapItem;

  const RightPanelTakeAwayList({
    super.key,
    required this.takeAwayList,
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
                  backgroundColor: Colors.red.shade700,
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
                  children: takeAwayList.map((item) {
                    return GestureDetector(
                      onTap: () => onTapItem(item),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFA8072), Color(0xFFD32F2F)],
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
