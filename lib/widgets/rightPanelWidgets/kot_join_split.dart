import 'package:flutter/material.dart';

class BillJoinSplitDialog extends StatefulWidget {
  @override
  _BillJoinSplitDialogState createState() => _BillJoinSplitDialogState();
}

class _BillJoinSplitDialogState extends State<BillJoinSplitDialog> {
  String mode = "Join";

  // Join Mode Variables
  List<Map<String, dynamic>> joinKotList1 = [];
  List<Map<String, dynamic>> joinKotList2 = [];
  List<Map<String, dynamic>> joinItems = [];
  double joinTotal = 0.0;

  // Split Mode Variables
  List<Map<String, dynamic>> splitKotList = [];
  List<Map<String, dynamic>> splitSourceItems = [];
  List<Map<String, dynamic>> splitSelectedItems = [];
  double splitSourceTotal = 0.0;
  double splitSelectedTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPendingKOTs();
  }

  Future<void> _loadPendingKOTs() async {
    try {
      List<Map<String, dynamic>> kotData = [];
      setState(() {
        joinKotList1 = kotData.map((kot) {
          return {
            "kotMasterID": int.parse(kot['kotMasterID'].toString()),
            "kotDisplay": "${kot['KotPrefix']}${kot['KotNumber']}"
          };
        }).toList();
        splitKotList = List.from(joinKotList1);
      });
    } catch (e) {
      print("Error fetching pending KOTs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 1200,
        height: 600,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: mode == "Join" ? _buildJoinMode() : _buildSplitMode(),
            ),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton("Join", mode == "Join", Icons.merge_type, () {
          setState(() {
            mode = "Join";
            splitSourceItems.clear();
            splitSelectedItems.clear();
            splitSourceTotal = 0.0;
            splitSelectedTotal = 0.0;
          });
        }),
        const SizedBox(width: 16),
        _buildToggleButton("Split", mode == "Split", Icons.call_split, () {
          setState(() {
            mode = "Split";
            joinKotList2.clear();
            joinItems.clear();
            joinTotal = 0.0;
          });
        }),
      ],
    );
  }

  Widget _buildToggleButton(
      String label, bool isActive, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF521C1D) : Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 2,
      ),
      icon: Icon(
        icon,
        color: isActive ? Colors.white : Colors.black,
        size: 20,
      ),
      onPressed: onPressed,
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildJoinMode() {
    return Row(
      children: [
        Expanded(
          child: _buildDraggableKOTList(
            "KOT 1",
            joinKotList1,
            (item) => _moveItem(item, joinKotList2, joinKotList1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDraggableKOTList(
            "KOT 2",
            joinKotList2,
            (item) => _moveItem(item, joinKotList1, joinKotList2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildTable("Items", joinItems, joinTotal),
        ),
      ],
    );
  }

  double _calculateSubtotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final lineTotal = double.tryParse(item["UnitPrice"].toString()) ?? 0.0;
      return sum + lineTotal;
    });
  }

  double _calculateVatAmount(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final vatAmount = double.tryParse(item["Tax1AmountC"].toString()) ?? 0.0;
      return sum + vatAmount;
    });
  }

  double _calculateTotal(double subtotal, double vatAmount) {
    return subtotal + vatAmount;
  }

  Widget _buildSplitMode() {
    // Calculate values dynamically
    final subtotal = _calculateSubtotal(splitSelectedItems);
    final vatAmount = _calculateVatAmount(splitSelectedItems);
    final total = _calculateTotal(subtotal, vatAmount);

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildKOTListing("KOT Listing", splitKotList),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildTable(
            "KOT Items",
            splitSourceItems,
            splitSourceTotal,
            isSplitMode: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: _buildTable(
                  "Split Items",
                  splitSelectedItems,
                  splitSelectedTotal,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "SubTotal: ${subtotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    "VatAmt: ${vatAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    "Total: ${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKOTListing(String title, List<Map<String, dynamic>> kotList) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF521C1D), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFCEFEF),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF521C1D),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: kotList.length,
              itemBuilder: (context, index) {
                final kot = kotList[index];
                return InkWell(
                  onTap: () async {
                    final items = <Map<String, dynamic>>[];

                    setState(() {
                      splitSourceItems = items;
                      splitSourceTotal = items.fold(
                          0.0,
                          (sum, item) =>
                              sum +
                              (double.tryParse(item["LineTotal"].toString()) ??
                                  0.0));
                    });
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        kot["kotDisplay"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableKOTList(
      String title,
      List<Map<String, dynamic>> kotList,
      Function(Map<String, dynamic>) onDropped) {
    return DragTarget<Map<String, dynamic>>(
      onAccept: onDropped,
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF521C1D), width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFFCEFEF),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF521C1D),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: kotList.length,
                  itemBuilder: (context, index) {
                    return Draggable<Map<String, dynamic>>(
                      data: kotList[index],
                      feedback: Material(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF521C1D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            kotList[index]["kotDisplay"],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                          opacity: 0.5, child: _buildItemCard(kotList[index])),
                      child: _buildItemCard(kotList[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          item["kotDisplay"],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.drag_handle, color: Colors.grey),
      ),
    );
  }

  Widget _buildTable(
      String title, List<Map<String, dynamic>> items, double total,
      {bool isSplitMode = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF521C1D), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFCEFEF),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF521C1D),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowHeight: 40,
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text("SI No.")),
                    DataColumn(label: Text("Short Description")),
                    DataColumn(label: Text("Qty")),
                    DataColumn(label: Text("Price")),
                    DataColumn(label: Text("Total")),
                    DataColumn(label: Text("")),
                  ],
                  rows: List.generate(items.length, (index) {
                    final item = items[index];
                    return DataRow(cells: [
                      DataCell(Text((index + 1).toString())),
                      DataCell(Text(item["ShortDescription"] ?? "N/A")),
                      DataCell(Text(item["Qty"].toString())),
                      DataCell(Text(item["UnitPrice"].toString())),
                      DataCell(Text(item["LineTotal"].toString())),
                      DataCell(
                        isSplitMode
                            ? IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () {
                                  _moveItemToSplit(item);
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                    ]);
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "Total: ${total.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: mode == "Join" ? Colors.green : Colors.deepOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () async {
            if (mode == "Join") {
              _saveJoinedKOT();
            } else {
              if (splitSelectedItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text("Please select at least one item to split.")),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('KOT split saved in mock mode.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(true);
            }
          },
          child: Text(
            mode == "Join" ? "Save Joined KOT" : "Save Split KOT",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            setState(() {
              if (mode == "Join") {
                joinKotList2.clear();
                joinItems.clear();
                joinTotal = 0.0;
              } else {
                splitSourceItems.clear();
                splitSelectedItems.clear();
                splitSourceTotal = 0.0;
                splitSelectedTotal = 0.0;
              }
            });
          },
          child: const Text(
            "Clear",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            "Close",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveJoinedKOT() async {
    if (joinKotList2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select at least one KOT to join.")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KOT join saved in mock mode.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop(true);
  }

  void _moveItemToSplit(Map<String, dynamic> item) {
    // 🚨 Prevent splitting if source KOT has only 1 item
    if (splitSourceItems.length == 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Cannot Split"),
          content: const Text("A KOT with only one item cannot be split."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    if (item['KOTChildID'] == null) {
      print("❌ Error: Selected item has no KotChildID: $item");
      return;
    }

    setState(() {
      splitSourceItems.remove(item);
      splitSourceTotal -= item["LineTotal"] ?? 0.0;
      splitSelectedItems.add(item);
      splitSelectedTotal += item["LineTotal"] ?? 0.0;
    });
  }

  void _moveItem(Map<String, dynamic> item, List<Map<String, dynamic>> fromList,
      List<Map<String, dynamic>> toList) async {
    if (toList == joinKotList2) {
      bool alreadyExists =
          toList.any((kot) => kot["kotMasterID"] == item["kotMasterID"]);
      if (alreadyExists) {
        print("⚠️ KOT already exists in KOT 2");
        return;
      }

      final incomingID = item["kotMasterID"] as int;

      setState(() {
        fromList.removeWhere((kot) => kot["kotMasterID"] == incomingID);
        toList.add(item);
      });
    }
  }
}
