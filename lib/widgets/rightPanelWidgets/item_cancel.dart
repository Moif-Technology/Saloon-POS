import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/providers.dart';

class ItemRemoveDialog extends ConsumerStatefulWidget {
  @override
  ItemRemoveDialogState createState() => ItemRemoveDialogState();
}

class ItemRemoveDialogState extends ConsumerState<ItemRemoveDialog> {
  List<bool> selectedItems = [];

  @override
  void initState() {
    super.initState();
    final kotDetails = ref.read(activeKotProvider);
    final items = kotDetails['data'] as List<dynamic>? ?? [];
    selectedItems = List.generate(items.length, (index) => false);
  }

  void showQtyDialog(int index) {
    final kotDetails = ref.read(activeKotProvider);
    final items = kotDetails['data'] as List<dynamic>? ?? [];
    final item = items[index];
    String newQty = "";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              width: 300,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: Color(0xFF582424),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    width: double.infinity,
                    child: Text(
                      item['ShortDescription'] ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Current Qty: ${item['Qty'] ?? '0'}",
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "New Qty:",
                        style: TextStyle(fontSize: 14),
                      ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          newQty.isEmpty ? "_" : newQty,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (var row in [
                          ["7", "8", "9", "C"],
                          ["4", "5", "6", "."],
                          ["1", "2", "3", "0"],
                        ])
                          Row(
                            children: row.map((btn) {
                              return Expanded(
                                child: Container(
                                  height: 45,
                                  margin: EdgeInsets.all(4),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setDialogState(() {
                                        if (btn == "C") {
                                          newQty = "";
                                        } else if (btn == "." &&
                                            newQty.contains(".")) {
                                          return;
                                        } else {
                                          newQty += btn;
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: btn == "C"
                                          ? Colors.red[400]
                                          : Colors.brown[700],
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      elevation: 2,
                                    ),
                                    child: Text(btn,
                                        style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (newQty.isNotEmpty) {
                              final updatedKotDetails =
                                  Map<String, dynamic>.from(kotDetails);
                              final updatedQty = double.tryParse(newQty) ?? 0.0;

                              (updatedKotDetails['data'] as List)[index]
                                      ['Qty'] =
                                  updatedQty % 1 == 0
                                      ? updatedQty.toInt()
                                      : updatedQty;

                              ref.read(activeKotProvider.notifier).state =
                                  updatedKotDetails;
                              ref.read(kotDetailsProvider.notifier).state =
                                  updatedKotDetails;
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: Text("Done"),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.brown[700],
                          ),
                          child: Text("Cancel"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void removeSelectedItems() async {
    final kotDetails = ref.read(activeKotProvider);
    if (kotDetails['data'] == null) return;

    final items = kotDetails['data'] as List<dynamic>? ?? [];

    print("🟡 Total items: ${items.length}");
    print("🟡 Selected flags: $selectedItems");

    if (items.length <= 1) {
      _showCustomDialog(
        title: "Cannot Remove",
        message: "Only one item remains in KOT. You have to make BILL CANCEL.",
        icon: Icons.error_outline,
        iconColor: Colors.red[700]!,
      );
      return;
    }

    int selected = selectedItems.where((e) => e).length;
    int unselected = selectedItems.length - selected;

    if (selected == 0) {
      _showCustomDialog(
        title: "Selection Required",
        message: "Please select at least one item to remove.",
        icon: Icons.info_outline,
        iconColor: Colors.amber[700]!,
      );
      return;
    }

    if (unselected == 0) {
      _showCustomDialog(
        title: "Cannot Remove All",
        message:
            "All items cannot be removed. Please make a Bill Cancel instead.",
        icon: Icons.error_outline,
        iconColor: Colors.red[700]!,
      );
      return;
    }

    final itemsToRemove = <Map<String, dynamic>>[];
    double newAmount = 0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      print("🔍 Item $i: $item");

      if (selectedItems[i]) {
        itemsToRemove.add({
          "KOTChildID": int.tryParse(item["KOTChildID"].toString()) ?? 0,
          "ProductID": int.tryParse(item["ProductID"].toString()) ?? 0,
          "ItemName": item["ShortDescription"] ?? '',
          "Qty": double.tryParse(item["Qty"].toString()) ?? 0.0,
          "UnitCost": double.tryParse(item["UnitCost"].toString()) ?? 0.0,
          "UnitPrice": double.tryParse(item["UnitPrice"].toString()) ?? 0.0,
          "LineTotal": double.tryParse(item["LineTotal"].toString()) ?? 0.0,
          "GroupID": int.tryParse(item["GroupID"].toString()) ?? 0,
        });
      } else {
        double lineTotal = double.tryParse(item["LineTotal"].toString()) ?? 0.0;
        newAmount += lineTotal;
      }
    }

    final kotMasterID =
        int.tryParse(items.first["KotMasterID"].toString()) ?? 0;

    print("🟢 Items to remove: $itemsToRemove");
    print("🟢 New KOT Amount: $newAmount");
    print("🟢 KOT Master ID: $kotMasterID");

    final result = <String, dynamic>{'success': true};

    try {
      print("✅ API Response: $result");

      if (result['success'] == true) {
        _showCustomDialog(
          title: "Items Removed",
          message: "Selected items have been removed successfully.",
          icon: Icons.check_circle_outline,
          iconColor: Colors.green[700]!,
        );

        // Update UI
        final updatedKotDetails = Map<String, dynamic>.from(kotDetails);
        final updatedItems = List.from(items);
        for (int i = selectedItems.length - 1; i >= 0; i--) {
          if (selectedItems[i]) {
            updatedItems.removeAt(i);
            selectedItems.removeAt(i);
          }
        }
        updatedKotDetails['data'] = updatedItems;
        ref.read(activeKotProvider.notifier).state = updatedKotDetails;
        ref.read(kotDetailsProvider.notifier).state =
            updatedKotDetails; // ✅ Add this

        setState(() {});
      } else {
        throw Exception(result['message'] ?? 'Failed to remove items.');
      }
    } catch (e, stackTrace) {
      print("❌ Exception caught: $e");
      print("🔍 Stack Trace:\n$stackTrace");

      _showCustomDialog(
        title: "Error",
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  // Update this method for showing more compact custom dialogs
  void _showCustomDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          width: 350, // Reduced width
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(52, 5, 15, 1),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(52, 5, 15, 1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kotDetails = ref.watch(activeKotProvider);
    final items = kotDetails['data'] as List<dynamic>? ?? [];
    print(items);
    return Dialog(
      child: Container(
        width: 1000,
        height: 600,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(52, 5, 15, 1),
                    Color.fromRGBO(128, 0, 0, 1),
                    Color.fromRGBO(52, 5, 15, 1),
                  ],
                  stops: [0.0, 0.5, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Stack(
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            color: Colors.white, size: 22),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Icon(Icons.remove_circle,
                              color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Remove Items from Order",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Select items to remove or adjust quantities",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 20, color: Colors.white),
                      padding: EdgeInsets.all(8),
                      splashRadius: 24,
                      tooltip: 'Close',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Color.fromRGBO(52, 5, 15, 0.05),
                border: Border(
                  bottom: BorderSide(color: Color.fromRGBO(52, 5, 15, 0.1)),
                ),
              ),
              child: Row(
                children: [
                  _buildHeaderCell("No.", 1,
                      icon: Icons.format_list_numbered,
                      align: TextAlign.center),
                  _buildHeaderCell("KOT", 2,
                      icon: Icons.receipt_long, align: TextAlign.center),
                  _buildHeaderCell("Item Name", 4,
                      icon: Icons.restaurant_menu, align: TextAlign.left),
                  _buildHeaderCell("Quantity", 2,
                      icon: Icons.shopping_cart, align: TextAlign.center),
                  _buildHeaderCell("Price  ", 2,
                      align: TextAlign.right), // Removed icon here
                  _buildHeaderCell("Total", 2,
                      icon: Icons.calculate, align: TextAlign.right),
                  SizedBox(width: 50),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];
                  return InkWell(
                    onTap: () => setState(
                        () => selectedItems[index] = !selectedItems[index]),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      height: 32,
                      decoration: BoxDecoration(
                        color: selectedItems[index]
                            ? Color.fromRGBO(52, 5, 15, 0.02)
                            : Colors.white,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[100]!)),
                      ),
                      child: Row(
                        children: [
                          ItemCell("${index + 1}", 1, align: TextAlign.center),
                          ItemCell(item['KOTNumber'] ?? "", 2,
                              align: TextAlign.center),
                          ItemCell(item['ShortDescription'] ?? '', 4,
                              align: TextAlign.left),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => showQtyDialog(index),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                padding: EdgeInsets.symmetric(vertical: 2),
                                height: 24,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[200]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${item['Qty'] ?? '0'}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                          ItemCell(item['UnitPrice']?.toString() ?? '0.00', 2,
                              align: TextAlign.right),
                          ItemCell(
                              ((double.tryParse(
                                              item['Qty']?.toString() ?? '0') ??
                                          0.0) *
                                      (double.tryParse(
                                              item['UnitPrice']?.toString() ??
                                                  '0') ??
                                          0.0))
                                  .toStringAsFixed(2),
                              2,
                              align: TextAlign.right),
                          Container(
                            width: 50,
                            alignment: Alignment.center,
                            child: Checkbox(
                              value: selectedItems[index],
                              onChanged: (value) =>
                                  setState(() => selectedItems[index] = value!),
                              activeColor: Color.fromRGBO(52, 5, 15, 1),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromRGBO(52, 5, 15, 0.02),
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: removeSelectedItems,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color.fromRGBO(128, 0, 0, 1),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      side: BorderSide(color: Color.fromRGBO(128, 0, 0, 0.5)),
                    ),
                    child:
                        Text("Remove Selected", style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(52, 5, 15, 1),
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text("Close", style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, int flex,
      {IconData? icon, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: align == TextAlign.center
              ? MainAxisAlignment.center
              : align == TextAlign.right
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            if (icon != null && align != TextAlign.right) ...[
              Icon(icon, size: 14, color: Color.fromRGBO(52, 5, 15, 0.4)),
              SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(52, 5, 15, 0.6),
                letterSpacing: 0.3,
              ),
            ),
            if (icon != null && align == TextAlign.right) ...[
              SizedBox(width: 4),
              Icon(icon, size: 14, color: Color.fromRGBO(52, 5, 15, 0.4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget ItemCell(String text, int flex, {TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          text,
          style: TextStyle(fontSize: 11),
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
