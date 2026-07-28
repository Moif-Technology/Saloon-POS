import 'package:flutter/material.dart';

class RightPanelSearchResults extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final int selectedIndex;
  final void Function(Map<String, dynamic>) onSelect;

  const RightPanelSearchResults({
    super.key,
    required this.results,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF521C1D).withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final product = results[index];
            final name = product["ShortDescription"] ?? "Unknown";
            final price = product["UnitPrice"] != null
                ? double.tryParse(product["UnitPrice"].toString())
                    ?.toStringAsFixed(2)
                : "0.00";

            return GestureDetector(
              onTap: () => onSelect(product),
              child: Container(
                decoration: BoxDecoration(
                  color: index == selectedIndex
                      ? const Color(0xFF521C1D).withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  "$name  (\$$price)",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Courier",
                    color: Colors.black,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
