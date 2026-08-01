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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF780829).withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFF780829).withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text('Item Name',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF521C1D))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Price',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF521C1D))),
                  ),
                  SizedBox(width: 8),
                  Text('Tap to add',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.black54)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: results.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final product = results[index];
                  final name = (product['ShortDescription'] ??
                          product['ProductName'] ??
                          'Unknown')
                      .toString();
                  final code = (product['ProductCode'] ??
                          product['Barcode'] ??
                          '')
                      .toString();
                  final price = double.tryParse(
                          (product['UnitPrice'] ?? '0').toString()) ??
                      0.0;
                  final selected = index == selectedIndex;

                  return Material(
                    color: selected
                        ? const Color(0xFF780829).withValues(alpha: 0.12)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelect(product),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (code.isNotEmpty)
                                    Text(
                                      code,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                price.toStringAsFixed(2),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? const Color(0xFF780829)
                                      : const Color(0xFF521C1D),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.add_circle_outline,
                              size: 20,
                              color: selected
                                  ? const Color(0xFF780829)
                                  : Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
