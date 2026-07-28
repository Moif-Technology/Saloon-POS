import 'package:flutter/material.dart';
import 'package:my_app/widgets/common/common_searchable_dropdown.dart';

class RecipeDetailsEntryDialog extends StatefulWidget {
  @override
  _RecipeEntryDialogState createState() => _RecipeEntryDialogState();
}

class _RecipeEntryDialogState extends State<RecipeDetailsEntryDialog> {
  // Controllers
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController productCodeController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController packDetailsController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController packQtyController = TextEditingController();
  final TextEditingController costController = TextEditingController();

  final FocusNode productNameFocusNode = FocusNode();
  String? selectedUnit;

  List<Map<String, dynamic>> rawMaterialList = [];

  //Finished Product Data
  List<Map<String, dynamic>> finishedProductList = [];
  int itemsPerPage = 20;
  int currentItemCount = 0; // Currently displayed item count
  bool isLoadingMore = false;
  ScrollController _scrollController = ScrollController();

  //Ingredients Table Data
  final List<Map<String, dynamic>> ingredientList = [];

  Map<String, dynamic>? selectedFinishedProduct;

  @override
  void initState() {
    super.initState();
    _fetchProducts(
        type:
            "recipe"); // Fetch all finished products // Fetch products when dialog initializes
    _fetchProducts(type: "raw_material");

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreItems(); // Load more items when scrolling near the bottom
      }
    });
  }

  @override
  void dispose() {
    productNameFocusNode.dispose(); // Dispose of the FocusNode
    _scrollController.dispose(); // Clean up the scroll controller
    super.dispose();
  }

  Future<void> _fetchProducts({required String type}) async {
    try {
      setState(() {
        isLoadingMore = true;
      });

      final products = <dynamic>[];

      setState(() {
        if (type == "raw_material") {
          rawMaterialList = products.map<Map<String, dynamic>>((product) {
            return {
              "id": product["ProductID"],
              "name": product["ShortDescription"],
              "details": product,
            };
          }).toList();
        } else if (type == "recipe") {
          finishedProductList = products.map<Map<String, dynamic>>((product) {
            return {
              "id": product["ProductID"],
              "name": product["ShortDescription"],
              "details": product,
            };
          }).toList();
        }
      });
    } catch (e) {
      print("Error fetching products: $e");
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _loadMoreItems() {
    if (currentItemCount >= finishedProductList.length)
      return; // No more items to load

    setState(() {
      final remainingItems = finishedProductList.length - currentItemCount;
      final itemsToLoad =
          remainingItems >= itemsPerPage ? itemsPerPage : remainingItems;

      // Append the next set of items to the displayed list
      finishedProductList.addAll(
        finishedProductList.sublist(
            currentItemCount, currentItemCount + itemsToLoad),
      );

      currentItemCount += itemsToLoad;
    });
  }

  void _onFinishedProductSelected(Map<String, dynamic>? selectedItem) {
    if (selectedItem == null) {
      // Handle the case where selectedItem is null
      setState(() {
        productCodeController.clear();
        productNameController.clear();
      });
      return;
    }

    setState(() {
      productCodeController.text = selectedItem["id"]?.toString() ?? "";
      productNameController.text = selectedItem["name"] ?? "";

      productNameFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: screenWidth * 0.7,
        height: screenHeight * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recipe Entry",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Form Fields
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Form (Unchanged)
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Finished Product",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF521C1D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 250,
                            height: 42,
                            child: CustomSearchableDropdown(
                              label: "Search Finished Product",
                              items: finishedProductList,
                              displayKey: "name",
                              onSelected: (selectedItem) {
                                _onFinishedProductSelected(
                                    selectedItem?["details"]);
                              },
                              onScrollEnd: () {
                                _loadMoreItems(); // Load more items when the user scrolls to the end
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Add Ingredients",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF521C1D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildLabeledField(
                                  "Product Code",
                                  _buildModernField(
                                    "Enter product code",
                                    controller: productCodeController,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildLabeledField(
                                  "Product Name",
                                  SizedBox(
                                    width: 250,
                                    height:
                                        40, // Adjust height to match your UI
                                    child:
                                        _buildProductNameDropdown(), // Replace with dropdown
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildLabeledField(
                                  "Pack Details",
                                  _buildModernField(
                                    "Pack",
                                    controller: packDetailsController,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildLabeledField(
                                  "Pack Qty",
                                  _buildModernField(
                                    "Pack Qty",
                                    controller: packQtyController,
                                    isNumeric: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildLabeledField(
                                  "Cost",
                                  _buildModernField(
                                    "Cost",
                                    controller:
                                        costController, // Add a new controller for cost
                                    isNumeric: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildLabeledField(
                                  "Qty",
                                  _buildModernField(
                                    "Qty",
                                    controller: qtyController,
                                    isNumeric: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildLabeledField(
                                  "Unit",
                                  _buildDropdownField(
                                    [
                                      {"id": "gm", "name": "GM"},
                                      {"id": "kg", "name": "KG"},
                                      {"id": "ml", "name": "ML"},
                                      {"id": "lt", "name": "LT"},
                                      {"id": "pcs", "name": "PCS"},
                                    ],
                                    selectedValue: selectedUnit,
                                    displayKey: "name",
                                    hintText: "Unit",
                                    onChanged: (value) {
                                      setState(() {
                                        selectedUnit = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _addIngredient,
                              icon: const Icon(Icons.add, size: 15),
                              label: const Text("Add Ingredient"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF521C1D),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLabeledField(
                            "Remarks",
                            _buildModernField(
                              "Add remarks...",
                              controller: remarksController,
                              maxLines: 3,
                              width: 400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  VerticalDivider(
                    color: Colors.grey.shade400,
                    thickness: 1,
                    width: 16,
                  ),

                  // Right Side: Ingredient List Table with Unit Cost
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                headingRowColor:
                                    MaterialStateProperty.all(Colors.grey[300]),
                                columnSpacing: 12,
                                columns: const [
                                  DataColumn(label: Text("Product Code")),
                                  DataColumn(label: Text("Product Name")),
                                  DataColumn(label: Text("Pack Details")),
                                  DataColumn(label: Text("Pack Qty")),
                                  DataColumn(label: Text("Qty")),
                                  DataColumn(label: Text("Unit")),
                                  DataColumn(label: Text("Cost")),
                                  DataColumn(label: Text("Line Cost")),
                                ],
                                rows: ingredientList.map((ingredient) {
                                  return DataRow(cells: [
                                    DataCell(Text(ingredient["productCode"])),
                                    DataCell(Text(ingredient["productName"])),
                                    DataCell(Text(ingredient["packDetails"])),
                                    DataCell(Text(ingredient["packQty"])),
                                    DataCell(Text(ingredient["qty"])),
                                    DataCell(Text(ingredient["unit"])),
                                    DataCell(Text(ingredient["cost"])),
                                    DataCell(Text(ingredient["lineCost"])),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Unit Cost in Bottom-Right
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF521C1D),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Unit Cost: \$275.00",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                    onPressed: () {}, child: const Text("Save Recipe")),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addIngredient() {
    if (productCodeController.text.isEmpty ||
        productNameController.text.isEmpty ||
        qtyController.text.isEmpty ||
        costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields before adding."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse cost and quantity
    final double cost = double.tryParse(costController.text) ?? 0.0;
    final double qty = double.tryParse(qtyController.text) ?? 0.0;
    final double packQty = double.tryParse(packQtyController.text) ??
        1.0; // Default to 1 if empty or invalid
    double unitCost = cost;
    double lineCost = cost * qty;

    // Adjust calculations based on selected unit
    if (selectedUnit != null) {
      switch (selectedUnit?.toLowerCase()) {
        case "kg":
        case "lt":
          unitCost = cost / 1000;
          lineCost = unitCost * qty * 1000;
          break;
        case "gm":
        case "ml":
          unitCost = cost / 1000;
          lineCost = unitCost * qty;
          break;
        case "pcs":
        default:
          // Use cost directly for PCS or other units
          unitCost = cost;
          lineCost = cost * qty;
          break;
      }
    }

    // Create new ingredient entry
    final newIngredient = {
      "productCode": productCodeController.text,
      "productName": productNameController.text,
      "packDetails": packDetailsController.text,
      "packQty": packQty.toString(),
      "qty": qty.toString(),
      "unit": selectedUnit ?? "",
      "cost": unitCost.toStringAsFixed(2),
      "lineCost": lineCost.toStringAsFixed(2),
    };

    // Update the table and clear fields
    setState(() {
      ingredientList.add(newIngredient);
    });

    // Clear fields after adding
    productCodeController.clear();
    productNameController.clear();
    packDetailsController.clear();
    qtyController.clear();
    packQtyController.clear();
    costController.clear();
    selectedUnit = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ingredient added successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildModernField(String hintText,
      {TextEditingController? controller,
      FocusNode? focusNode,
      int maxLines = 1,
      bool isNumeric = false,
      double? width}) {
    return SizedBox(
      width: width ?? 250,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    List<Map<String, dynamic>> items, {
    required String displayKey,
    String? selectedValue,
    String? hintText,
    ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item[displayKey],
                child: Text(item[displayKey]),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildProductNameDropdown() {
    return GestureDetector(
      onTap: () async {
        // Fetch raw materials dynamically when the dropdown is tapped
        if (rawMaterialList.isEmpty) {
          await _fetchProducts(type: "raw_material");
        }
      },
      child: CustomSearchableDropdown(
        label: "Product Name",
        items: rawMaterialList, // Use rawMaterialList
        displayKey: "name",
        onSelected: (selectedItem) {
          if (selectedItem != null) {
            final productDetails = selectedItem["details"];
            setState(() {
              productNameController.text = selectedItem["name"] ?? "";
              productCodeController.text = selectedItem["id"]?.toString() ?? "";
              packDetailsController.text =
                  productDetails["PacketDescription"] ?? "";
              costController.text =
                  productDetails["LastPurchaseCost"]?.toString() ??
                      ""; // Convert int/double to String
              packQtyController.text =
                  productDetails["PackQty"]?.toString() ?? "";
            });
          }
        },
      ),
    );
  }

  Widget _buildLabeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(height: 5),
        field,
      ],
    );
  }
}
