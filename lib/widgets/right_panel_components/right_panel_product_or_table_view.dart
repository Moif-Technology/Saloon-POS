import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/widgets/topPanelWidgets/NewEntryTab/product_entry.dart';

class RightPanelProductOrTableView extends StatelessWidget {
  final bool showTables;
  final bool isBaseVersion;
  final bool isSearching;
  final List<Map<String, dynamic>> searchResults;

  final List<Map<String, dynamic>> tableData;
  final Map<String, List<String>> tableChairs;
  final String? selectedTable;
  final int selectedSearchIndex;

  final void Function(String tableName, String chairCountStr) onSelectTable;

  final void Function(Map<String, dynamic> product) onSelectSearchItem;
  final void Function(Map<String, String> product) onSelectProductGridItem;

  final int? selectedGroupId;

  const RightPanelProductOrTableView({
    super.key,
    required this.showTables,
    this.isBaseVersion = false,
    required this.isSearching,
    required this.searchResults,
    required this.tableData,
    required this.tableChairs,
    required this.selectedTable,
    required this.selectedSearchIndex,
    required this.onSelectTable,
    required this.onSelectSearchItem,
    required this.onSelectProductGridItem,
    required this.selectedGroupId,
  });

  @override
  Widget build(BuildContext context) {
    if (showTables) {
      return _buildTablesAndChairs();
    }

    if (isSearching || searchResults.isNotEmpty) {
      // Search list stays in RightPanelSearchResults widget (we will call that from right_panel.dart)
      // Here just return empty; RightPanel decides.
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, child) {
        final products = ref.watch(productProvider);
        final isLoading = ref.watch(isLoadingProvider);

        if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF521C1D)));
        if (products.isEmpty)
          return Center(child: Text("No products available", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)));

        const accent = Color(0xFF521C1D);
        final isBase = isBaseVersion;
        final maxExtent = isBase ? 100.0 : 90.0;
        final spacing = isBase ? 8.0 : 4.0;
        final aspectRatio = isBase ? 1.25 : 1.3;

        return GridView.builder(
          padding: isBase ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8) : EdgeInsets.zero,
          physics: isBase ? const BouncingScrollPhysics() : null,
          itemCount: products.length + 1,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            if (index == products.length) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => ProductMasterDetailsDialog(
                      uniqueMultiProductID: "",
                      groupId: selectedGroupId,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(isBase ? 12 : 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isBase ? const LinearGradient(colors: [Color(0xFF6B2737), Color(0xFF521C1D)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                      color: isBase ? null : accent,
                      borderRadius: BorderRadius.circular(isBase ? 12 : 8),
                      boxShadow: isBase ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: Colors.white, size: isBase ? 24 : 20),
                          SizedBox(height: isBase ? 4 : 2),
                          Text("Add Item", style: TextStyle(color: Colors.white, fontSize: isBase ? 11 : 9, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final product = products[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (product is Map) {
                    final converted = product.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
                    onSelectProductGridItem(Map<String, String>.from(converted));
                  }
                },
                borderRadius: BorderRadius.circular(isBase ? 12 : 8),
                child: Container(
                  padding: EdgeInsets.all(isBase ? 10 : 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isBase ? 12 : 8),
                    border: Border.all(color: isBase ? Colors.grey.shade200 : accent.withValues(alpha: 0.35), width: isBase ? 1 : 1),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isBase ? 0.06 : 0.05), blurRadius: isBase ? 8 : 4, offset: Offset(0, isBase ? 2 : 1))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          product["ShortDescription"] ?? "Unknown",
                          style: TextStyle(fontSize: isBase ? 12 : 11, fontWeight: FontWeight.w600, color: Colors.grey.shade900, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: isBase ? 6 : 4),
                      Text(
                        "${product["UnitPrice"] ?? "0"}",
                        style: TextStyle(fontSize: isBase ? 13 : 12, fontWeight: FontWeight.w700, color: accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTablesAndChairs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 10,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tableData.map((table) {
                final tableName = table['TableName'] ?? 'T?';
                final kotPrefix = table['KOTPrefix'];
                final kotNumber = table['KOTNumber'];

                final isOccupied = kotPrefix != null &&
                    kotPrefix.isNotEmpty &&
                    kotNumber != null;
                final isSelected = selectedTable == tableName;

                return GestureDetector(
                  onTap: () =>
                      onSelectTable(tableName, table['NoOfChairs'] ?? '0'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? Colors.red.shade100
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.brown.shade700
                            : Colors.grey.shade300,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant,
                            size: 20,
                            color: isOccupied
                                ? Colors.red.shade700
                                : Colors.brown.shade700),
                        const SizedBox(height: 4),
                        Text(
                          tableName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOccupied
                                ? Colors.red.shade900
                                : Colors.brown.shade900,
                          ),
                        ),
                        if (isOccupied)
                          Text(
                            '$kotPrefix$kotNumber',
                            style: TextStyle(
                                fontSize: 8,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (selectedTable != null)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.0),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chairs for $selectedTable',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown.shade800),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: tableChairs[selectedTable]?.length ?? 0,
                      itemBuilder: (context, chairIndex) {
                        final currentTableData = tableData.firstWhere(
                          (t) => t["TableName"] == selectedTable,
                          orElse: () => <String, Object>{},
                        );
                        final occupiedChairs = List<String>.from(
                            currentTableData['occupiedChairs'] ?? []);
                        final currentChair = (chairIndex + 1).toString();
                        final isThisChairOccupied =
                            occupiedChairs.contains(currentChair);

                        return Container(
                          decoration: BoxDecoration(
                            color: isThisChairOccupied
                                ? Colors.red.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isThisChairOccupied
                                  ? Colors.red.shade300
                                  : Colors.grey.shade300,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chair,
                                  size: 20,
                                  color: isThisChairOccupied
                                      ? Colors.red.shade700
                                      : Colors.brown.shade700),
                              const SizedBox(height: 4),
                              Text(
                                'Chair ${chairIndex + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isThisChairOccupied
                                      ? Colors.red.shade900
                                      : Colors.brown.shade900,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
