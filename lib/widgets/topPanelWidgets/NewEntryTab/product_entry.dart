import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/utils/sessionManager.dart';
import 'package:my_app/widgets/common/common_searchable_dropdown.dart';
import 'package:my_app/widgets/common/common_table.dart';
import 'package:quickalert/quickalert.dart';
import 'package:window_size/window_size.dart';

class ProductMasterDetailsDialog extends ConsumerStatefulWidget {
  final String uniqueMultiProductID;
  final int? groupId;
  final bool fromTopBar;

  ProductMasterDetailsDialog({
    Key? key,
    required this.uniqueMultiProductID,
    this.groupId,
    this.fromTopBar = false,
  }) : super(key: key);
  @override
  _ProductMasterDetailsDialogState createState() =>
      _ProductMasterDetailsDialogState();
}

class _ProductMasterDetailsDialogState
    extends ConsumerState<ProductMasterDetailsDialog> {
  Timer? _debounce;
  List<Map<String, dynamic>> productDataTable = [];

  final TextEditingController itemCodeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController arabicDescriptionController =
      TextEditingController();
  final TextEditingController unitCostController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController qtyOnHandController = TextEditingController();
  final TextEditingController reorderLevelController = TextEditingController();
  final TextEditingController reorderQtyController = TextEditingController();
  final TextEditingController costWithTaxController = TextEditingController();
  final TextEditingController taxFieldController = TextEditingController();
  final TextEditingController priceWithTaxController = TextEditingController();
  final TextEditingController packQtyController = TextEditingController();
  final TextEditingController outTaxFieldController = TextEditingController();
  final TextEditingController InTaxFieldController = TextEditingController();
  final TextEditingController InvatAmountController = TextEditingController();
  final TextEditingController OutvatAmountController = TextEditingController();

  TextEditingController priceLevel1Controller = TextEditingController();
  TextEditingController priceLevel2Controller = TextEditingController();
  TextEditingController priceLevel3Controller = TextEditingController();
  TextEditingController priceLevel4Controller = TextEditingController();
  TextEditingController priceLevel5Controller = TextEditingController();
  TextEditingController displayOrderController = TextEditingController();
  TextEditingController cookingTimeController = TextEditingController();

  Map<String, dynamic> comboDetails = {
    'itemCode': '',
    'itemName': '',
    'arabicDescription': '',
    'unitCost': 0.0,
    'price': 0.0,
    'packQty': 0,
    'vat': 0.0, // Add VAT percentage
    'vatAmount': 0.0, // Add VAT Amount
    'priceWithVat': 0.0, // Add Price With VAT
  };

  List<Map<String, dynamic>> groupData = [];
  String? selectedGroupDescription;
  int? selectedGroupId;
  List<Map<String, dynamic>> subGroupData = [];
  String? selectedSubGroupDescription;
  int? selectedSubGroupID;
  String? selectedUnit;
  String? selectedProductType;
  String? _productID; // Internal variable to store ProductID
  late int? effectiveGroupId;

  bool isDailyTransactionItem = false;

  @override
  void initState() {
    super.initState();

    print('VAT ${ref.read(tax1Provider)}%');

    priceController.addListener(_updatePriceWithTax);
    outTaxFieldController.addListener(_updatePriceWithTax);
    unitCostController.addListener(_updateCostWithTax);
    InTaxFieldController.addListener(_updateCostWithTax);

    final providerGroupId = ref.read(selectedGroupIdProvider); // ✅ already int?
    effectiveGroupId =
        widget.fromTopBar ? null : (widget.groupId ?? providerGroupId);

    fetchGroupData().then((_) {
      if (effectiveGroupId != null) {
        print("📦 Using Group ID: $effectiveGroupId");

        final matchedGroup = groupData.firstWhere(
          (group) => group['GroupID'].toString() == effectiveGroupId.toString(),
          orElse: () => {},
        );

        if (matchedGroup.isNotEmpty) {
          selectedGroupId = effectiveGroupId as int?;
          selectedGroupDescription = matchedGroup['GroupDescription'];
          print("✅ Matched group for ID $effectiveGroupId: $matchedGroup");
        } else {
          print("❌ Group ID $effectiveGroupId not found in groupData");
        }
      }

      fetchSubGroupData().then((_) {
        if (widget.uniqueMultiProductID.isNotEmpty) {
          _fetchProductDetails().then((_) {
            setState(() {
              selectedGroupDescription = _getGroupDescription(selectedGroupId);
            });
          });
        } else if (effectiveGroupId == null) {
          outTaxFieldController.text =
              ref.read(tax1Provider)?.toString() ?? '0.00';

          InTaxFieldController.text =
              ref.read(tax1Provider)?.toString() ?? '0.00';

          print("Adding new product - No ID provided");

          setState(() {
            itemCodeController.text = "";
            descriptionController.text = "";
            arabicDescriptionController.text = "";
            unitCostController.text = "";
            costWithTaxController.text = "";
            priceController.text = "";
            priceWithTaxController.text = "";
            packQtyController.text = "";
            qtyOnHandController.text = "";
            reorderLevelController.text = "";
            reorderQtyController.text = "";
            taxFieldController.text = "0.000";

            priceLevel1Controller.text = "";
            priceLevel2Controller.text = "";
            priceLevel3Controller.text = "";
            priceLevel4Controller.text = "";
            priceLevel5Controller.text = "";

            selectedGroupId = null;
            selectedGroupDescription = null;
            selectedSubGroupID = null;
            selectedSubGroupDescription = null;
            selectedUnit = null;
            selectedProductType = null;

            isDailyTransactionItem = false;
          });
        }
      });
    });

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setWindowMinSize(const Size(1024, 768));
    }
  }

  void _updateProductTable() {
    // Create a new product entry
    final newProduct = {
      'itemCode': itemCodeController.text, // BarCode
      'itemName': descriptionController.text.toString(), // Description
      'itemNameArabic': arabicDescriptionController.text, // Arabic Description
      'packQty': int.tryParse(packQtyController.text) ?? 0, // Pack Qty
      'unitCost': double.tryParse(unitCostController.text) ?? 0.0, // Item Cost
      'price': double.tryParse(priceController.text) ?? 0.0, // Item Price
      'level1':
          double.tryParse(priceLevel1Controller.text) ?? 0.0, // Price Level 1
      'level2':
          double.tryParse(priceLevel2Controller.text) ?? 0.0, // Price Level 2
      'level3':
          double.tryParse(priceLevel3Controller.text) ?? 0.0, // Price Level 3
      'level4':
          double.tryParse(priceLevel4Controller.text) ?? 0.0, // Price Level 4
      'level5':
          double.tryParse(priceLevel5Controller.text) ?? 0.0, // Price Level 5
      'isMaster': true, // Default value for isMaster
      'vat': double.tryParse(outTaxFieldController.text) ?? 0.0, // OutTax
      'vatAmount':
          double.tryParse(OutvatAmountController.text) ?? 0.0, // OutvatAmount
      'priceWithVat': double.tryParse(priceWithTaxController.text) ?? 0.0,
    };

    // Update the productDataTable
    setState(() {
      // Clear the previous entry and add the new one
      productDataTable.clear();
      productDataTable.add(newProduct);
    });
  }

  void _addOrUpdateProduct() {
    // Get the VAT percentage from the session
    comboDetails['vat'] = ref.read(tax1Provider) ?? 0.0;

    // Calculate VAT Amount and Price With VAT

    comboDetails['vatAmount'] =
        comboDetails['price'] * (comboDetails['vat'] / 100);
    comboDetails['priceWithVat'] =
        comboDetails['price'] + comboDetails['vatAmount'];
    // Use the map directly
    setState(() {
      productDataTable.add({
        'itemCode': comboDetails['itemCode'],
        'itemName': comboDetails['itemName'],
        'itemNameArabic': comboDetails['arabicDescription'],
        'packQty': comboDetails['packQty'],
        'unitCost': comboDetails['unitCost'],
        'price': comboDetails['price'],
        'vat': comboDetails['vat'], // VAT percentage
        'vatAmount': comboDetails['vatAmount'], // VAT Amount
        'priceWithVat': comboDetails['priceWithVat'], // Price With VAT
        'isMaster': false, // Set isMaster to false for Combo Details
      });
    });

    // Clear the input fields after adding/updating
    _clearComboInputFields();
  }

  void _clearComboInputFields() {
    comboDetails['itemCode'] = '';
    comboDetails['itemName'] = '';
    comboDetails['arabicDescription'] = '';
    comboDetails['unitCost'] = 0.0;
    comboDetails['price'] = 0.0;
    comboDetails['packQty'] = 0;
  }

  void _updatePriceWithTax() {
    // Parse the input values safely
    final unitPrice =
        double.tryParse(priceController.text) ?? 0.0; // Base price
    final outTaxRate =
        double.tryParse(outTaxFieldController.text) ?? 0.0; // Out Tax Rate as %

    // Validate tax rate input
    if (outTaxRate < 0 || outTaxRate > 100) {
      print("Invalid Tax Rate: $outTaxRate. Must be between 0 and 100.");
      return;
    }

    // Calculate VAT Amount
    final vatAmount = (unitPrice * outTaxRate) / 100;

    // Calculate Price With Tax
    final priceWithTax = unitPrice + vatAmount;

    // Debugging information
    print("Unit Price: $unitPrice");
    print("Out Tax Rate: $outTaxRate");
    print("VAT Amount: $vatAmount");
    print("Price With Tax: $priceWithTax");

    // Update the respective fields in the UI
    setState(() {
      OutvatAmountController.text = vatAmount.toStringAsFixed(2); // VAT Amount
      priceWithTaxController.text =
          priceWithTax.toStringAsFixed(2); // Price With Tax
    });
  }

  void _updateCostWithTax() {
    final unitCost = double.tryParse(unitCostController.text) ?? 0.0;
    final inTaxRate =
        double.tryParse(InTaxFieldController.text) ?? 0.0; // Use InTax here

    // Calculate Cost With Tax
    final costWithTax = unitCost + (unitCost * (inTaxRate / 100));

    // Calculate VAT Amount for Cost
    final vatAmountForCost = unitCost * (inTaxRate / 100);

    // Debugging output
    print(
        "Unit Cost: $unitCost, In Tax Rate: $inTaxRate, Cost With Tax: $costWithTax, VAT Amount for Cost: $vatAmountForCost");

    setState(() {
      costWithTaxController.text =
          costWithTax.toStringAsFixed(2); // Set cost with tax
      InvatAmountController.text =
          vatAmountForCost.toStringAsFixed(2); // Set VAT amount for cost
    });
  }

  Future<void> _fetchProductDetails() async {
    if (widget.uniqueMultiProductID.isEmpty) return;
    setState(() {
      itemCodeController.text = 'MOCK-${widget.uniqueMultiProductID}';
      descriptionController.text = 'Mock editable product';
      priceController.text = '25.00';
      unitCostController.text = '10.00';
      packQtyController.text = '1';
      qtyOnHandController.text = '100';
      selectedGroupId ??= 1;
    });
  }

  double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0.0;

  String? _getGroupDescription(int? groupId) {
    print("Requested Group ID: $groupId"); // Log input GroupID

    final group = groupData.firstWhere(
      (group) => group['GroupID'].toString() == groupId.toString(),
      orElse: () => {}, // Return empty map if no match found
    );

    print("Found Group: $group"); // Log the found group
    return group['GroupDescription']; // Return the GroupDescription
  }

  Future<void> fetchGroupData() async {
    try {
      final List<dynamic> data = await ApiService().fetchGroups();
      setState(() {
        groupData = data.map((group) {
          return {
            "GroupID": group['GroupID'],
            "GroupDescription": group['GroupDescription'],
          };
        }).toList();
      });
      print("Fetched group data: $groupData"); // Log fetched group data
    } catch (error) {
      print("Error fetching group data: $error");
    }
  }

  String? _getSubGroupDescription(int? subGroupId) {
    final subGroup = subGroupData.firstWhere(
        (subGroup) => subGroup['SubGroupID'] == subGroupId,
        orElse: () => {});
    return subGroup['SubGroupCode'];
  }

  Future<void> fetchSubGroupData() async {
    try {
      final List<dynamic> data = await ApiService().fetchSubGroups();
      setState(() {
        subGroupData = data.map((subGroup) {
          return {
            "SubGroupID": subGroup['SubGroupID'],
            "SubGroupCode": subGroup['SubGroupCode'],
          };
        }).toList();
      });
    } catch (error) {
      print("Error Fetching SubGroups: $error");
    }
  }

  bool _savingProduct = false;

  void _saveProduct() async {
    if (_savingProduct) return;

    // Edit is not wired from POS yet (basic create only). Edit in the web app.
    if (false && widget.uniqueMultiProductID.isNotEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Mock edit',
        text:
            'Editing a product is only available in the ERP web app (Backoffice → Product entry).',
        width: 300,
        confirmBtnText: 'OK',
        confirmBtnColor: Colors.orange,
      );
      return;
    }

    final productCode = itemCodeController.text.trim();
    final description = descriptionController.text.trim();
    if (productCode.isEmpty || description.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Missing fields',
        text: 'Enter a product code and a description.',
        width: 300,
        confirmBtnText: 'OK',
        confirmBtnColor: Colors.orange,
      );
      return;
    }

    final branchId = int.tryParse(SessionManager().stationId?.trim() ?? '');
    if (branchId == null || branchId < 1) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Session error',
        text: 'Branch not set. Please log in again.',
        width: 300,
        confirmBtnText: 'OK',
      );
      return;
    }

    final payload = <String, dynamic>{
      'branchId': branchId,
      'productCode': productCode,
      'description': description,
      'descriptionArabic': arabicDescriptionController.text.trim(),
      if (selectedGroupId != null) 'groupId': selectedGroupId,
      if (selectedSubGroupID != null) 'subGroupId': selectedSubGroupID,
      if (selectedUnit != null && selectedUnit!.isNotEmpty)
        'unit': selectedUnit,
      if (selectedProductType != null && selectedProductType!.isNotEmpty)
        'productType': selectedProductType,
      'unitPrice': priceController.text.trim(),
      'minUnitPrice': priceController.text.trim(),
      'baseCost': unitCostController.text.trim(),
      'packQty': packQtyController.text.trim(),
      'qtyOnHand': qtyOnHandController.text.trim(),
      'reorderLevel': reorderLevelController.text.trim(),
      'reorderQty': reorderQtyController.text.trim(),
      'vatInPct': InTaxFieldController.text.trim(),
      'vatOutPct': outTaxFieldController.text.trim(),
      'priceLevel1': priceLevel1Controller.text.trim(),
    };

    setState(() => _savingProduct = true);
    try {
      await ApiService().createProduct(payload);
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Saved',
        text: 'Product "$description" saved.',
        width: 300,
        confirmBtnText: 'OK',
        confirmBtnColor: Colors.green,
        onConfirmBtnTap: () {
          Navigator.of(context).pop(); // close alert
          Navigator.of(context).pop(true); // close product dialog
        },
      );
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Save failed',
        text: e.toString().replaceFirst('Exception: ', ''),
        width: 300,
        confirmBtnText: 'OK',
      );
    } finally {
      if (mounted) setState(() => _savingProduct = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double dialogWidth = screenSize.width > 1366
        ? screenSize.width * 0.75
        : screenSize.width * 0.95;
    final double dialogHeight = screenSize.height > 768
        ? screenSize.height * 0.95
        : screenSize.height * 1.1;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildDialogHeader(),
           Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: const TabBar(
    labelColor: Color(0xFF521C1D),
    indicatorColor: Color(0xFF521C1D),
    dividerColor: Colors.transparent,
    dividerHeight: 0,
    unselectedLabelColor: Colors.grey,
    labelStyle: TextStyle(fontWeight: FontWeight.w600),
    tabs: [
      Tab(text: "Basic Details"),
      Tab(text: "Combo & Pricing"),
    ],
  ),
),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBasicDetailsTab(screenSize),
                    _buildComboAndPricingTab(screenSize),
                  ],
                ),
              ),
              _buildButtonBar(),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildDialogHeader() {
  return Container(
    constraints: const BoxConstraints(minHeight: 56),
    decoration: const BoxDecoration(
      color: Color(0xFF521C1D),
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    padding: const EdgeInsets.only(left: 20, right: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            widget.uniqueMultiProductID.isNotEmpty
                ? "Edit Product Details"
                : "Add New Product",
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (widget.uniqueMultiProductID.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Product ID: ${widget.uniqueMultiProductID}",
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
        ),
      ],
    ),
  );
}

 Widget _buildButtonBar() {
  return Container(
    decoration: const BoxDecoration(
      color: Color(0xFFFCFBFB),
      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
    ),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
    child: Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text("Delete"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            _saveProduct();
          },
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text("Save"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF521C1D),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(120, 44),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildBasicDetailsTab(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 800,
                child: _buildSectionCard(
                  screenSize,
                  "Items Details",
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernFieldCode(
                            widget.uniqueMultiProductID.isNotEmpty
                                ? "BarCode (Editing)"
                                : "ProductID (Adding)",
                            screenSize,
                            controller: itemCodeController,
                            onChanged: (value) {
                              // Cancel the previous timer if it exists
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();

                              // Start a new timer
                              _debounce =
                                  Timer(const Duration(milliseconds: 300), () {
                                _updateProductTable(); // Call the update function after the delay
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            final newCode =
                                DateTime.now().millisecondsSinceEpoch % 1000000;
                            itemCodeController.text = newCode.toString();
                          },
                          iconSize: 24,
                          color: Colors.blueAccent,
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.barcode),
                              SizedBox(width: 4),
                              Text("New Code"),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildModernField(
                            "Description",
                            screenSize,
                            controller: descriptionController,
                            onChanged: (value) {
                              // Cancel the previous timer if it exists
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();

                              // Start a new timer
                              _debounce =
                                  Timer(const Duration(milliseconds: 300), () {
                                _updateProductTable(); // Call the update function after the delay
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernField(
                            "Arabic Description",
                            screenSize,
                            controller: arabicDescriptionController,
                            onChanged: (value) {
                              // Cancel the previous timer if it exists
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();

                              // Start a new timer
                              _debounce =
                                  Timer(const Duration(milliseconds: 300), () {
                                _updateProductTable(); // Call the update function after the delay
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildSearchableGroupDropdown(
                              "Group", screenSize),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSearchableSubGroupDropdown(
                              "SubGroup", screenSize),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child:
                              _buildModernField("Item Description", screenSize),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Container(
                width: 800,
                child: _buildSectionCard(
                  screenSize,
                  "Pricing Information",
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernField(
                            "Item Cost",
                            screenSize,
                            controller: unitCostController,
                            onChanged: (value) {
                              // Cancel the previous timer if it exists
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();

                              // Start a new timer
                              _debounce =
                                  Timer(const Duration(milliseconds: 300), () {
                                _updateProductTable(); // Call the update function after the delay
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildModernField(
                            "Item Price",
                            screenSize,
                            controller: priceController,
                            onChanged: (value) {
                              // Cancel the previous timer if it exists
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();

                              // Start a new timer
                              _debounce =
                                  Timer(const Duration(milliseconds: 300), () {
                                _updateProductTable(); // Call the update function after the delay
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTaxField("InTax", screenSize,
                              controller: InTaxFieldController),
                        ),
                        Expanded(
                          child: _buildModernField("VAT Amount 1", screenSize,
                              controller: InvatAmountController,
                              labelFontSize: 14),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildTaxField(
                            "OutTax",
                            screenSize,
                            controller: outTaxFieldController,
                            onChanged: (value) {
                              // Cancel the previous timer if it exists
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();

                              // Start a new timer
                              _debounce =
                                  Timer(const Duration(milliseconds: 300), () {
                                _updateProductTable(); // Call the update function after the delay
                              });
                            },
                          ),
                        ),
                        // SizedBox(width: 10),
                        // New VAT Amount Field
                        Expanded(
                          child: _buildModernField("VAT Amount 2", screenSize,
                              controller: OutvatAmountController,
                              labelFontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernField("Cost With Tax", screenSize,
                              controller: costWithTaxController),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildModernField(
                            "Price With Tax",
                            screenSize,
                            controller: priceWithTaxController,
                            onChanged: (value) {
                              // Cancel the previous timer if it exists
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();

                              // Start a new timer
                              _debounce =
                                  Timer(const Duration(milliseconds: 300), () {
                                _updateProductTable(); // Call the update function after the delay
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Container(
                width: 800,
                child: _buildSectionCard(
                  screenSize,
                  "Stock Information",
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernField(
                            "Pack Qty",
                            screenSize,
                            controller: packQtyController,
                            onChanged: (value) {
                              // Cancel the previous timer if it exists
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();

                              // Start a new timer
                              _debounce =
                                  Timer(const Duration(milliseconds: 300), () {
                                _updateProductTable(); // Call the update function after the delay
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildModernField("Qty On Hand", screenSize,
                              controller: qtyOnHandController),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            "Unit",
                            ["PCS", "KG", "LTR"], // List of units
                            screenSize,
                            initialValue:
                                selectedUnit, // Pre-fill with the selected unit
                            onChanged: (value) {
                              setState(() {
                                selectedUnit = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdownField(
                            "Product Type",
                            ["NORMAL", "SPECIAL"], // List of product types
                            screenSize,
                            initialValue:
                                selectedProductType, // Pre-fill with the selected type
                            onChanged: (value) {
                              setState(() {
                                selectedProductType = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleIsMaster(int index, bool isMaster) {
    setState(() {
      productDataTable[index]['isMaster'] = isMaster; // Update the value
    });
  }

  Widget _buildComboAndPricingTab(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 650,
              child: Row(
                children: [
                  Expanded(
                    child: _buildSectionCard(
                      screenSize,
                      "Price Levels",
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                "Price Level 1 With Tax",
                                screenSize,
                                controller: priceLevel1Controller,
                                onChanged: (value) {
                                  // Cancel the previous timer if it exists
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();

                                  // Start a new timer
                                  _debounce = Timer(
                                      const Duration(milliseconds: 300), () {
                                    _updateProductTable(); // Call the update function after the delay
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                "Price Level 2 With Tax",
                                screenSize,
                                controller: priceLevel2Controller,
                                onChanged: (value) {
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();
                                  _debounce = Timer(
                                      const Duration(milliseconds: 300), () {
                                    _updateProductTable();
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                "Price Level 3 With Tax",
                                screenSize,
                                controller: priceLevel3Controller,
                                onChanged: (value) {
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();
                                  _debounce = Timer(
                                      const Duration(milliseconds: 300), () {
                                    _updateProductTable();
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                "Price Level 4 With Tax",
                                screenSize,
                                controller: priceLevel4Controller,
                                onChanged: (value) {
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();
                                  _debounce = Timer(
                                      const Duration(milliseconds: 300), () {
                                    _updateProductTable();
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                "Price Level 5 With Tax",
                                screenSize,
                                controller: priceLevel5Controller,
                                onChanged: (value) {
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();
                                  _debounce = Timer(
                                      const Duration(milliseconds: 300), () {
                                    _updateProductTable();
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildSectionCard(
                      screenSize,
                      "Other Details",
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                  "ReOrder Level", screenSize,
                                  controller: reorderLevelController),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                  "ReOrder Qty", screenSize,
                                  controller: reorderQtyController),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                  "Display Order", screenSize,
                                  controller: displayOrderController),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                  "Cooking Time", screenSize,
                                  controller: cookingTimeController),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                        SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "Daily Transaction Item",
                            style: TextStyle(fontSize: 14),
                          ),
                          value: isDailyTransactionItem,
                          onChanged: (value) {
                            setState(() {
                              isDailyTransactionItem = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
         Expanded(
  child: Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _buildSectionCard(
    screenSize,
    "Combo Details",
              [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(labelText: "Item Code"),
                        onChanged: (value) {
                          comboDetails['itemCode'] = value; // Update the map
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(labelText: "Item Name"),
                        onChanged: (value) {
                          comboDetails['itemName'] = value; // Update the map
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 220,
                      child: TextField(
                        decoration:
                            InputDecoration(labelText: "Arabic Description"),
                        onChanged: (value) {
                          comboDetails['arabicDescription'] =
                              value; // Update the map
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(labelText: "Unit Cost"),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          comboDetails['unitCost'] =
                              double.tryParse(value) ?? 0.0; // Update the map
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(labelText: "Price"),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          comboDetails['price'] =
                              double.tryParse(value) ?? 0.0; // Update the map
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(labelText: "Pack Qty"),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          comboDetails['packQty'] =
                              int.tryParse(value) ?? 0; // Update the map
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed:
                          _addOrUpdateProduct, // Call the method to add/update the product
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text("Add"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF521C1D),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
                SizedBox(height: 5),
                Expanded(
                  child: ResizableTable(
                    headers: [
                      'Item Code',
                      'Item Name',
                      'Name Arabic',
                      'Pack Qty',
                      'Unit Cost',
                      'Unit Price',
                      'Price Level 1',
                      'Price Level 2',
                      'Price Level 3',
                      'Price Level 4',
                      'Price Level 5',
                      'Is Master',
                      'VAT %',
                      'VAT Amount',
                      'Price With VAT',
                    ],
                    data: productDataTable.map((product) {
                      return [
                        product['itemCode'] ?? '', // Item Code
                        product['itemName'] ?? '', // Item Name
                        product['itemNameArabic'] ?? '', // Name Arabic
                        product['packQty']?.toString() ?? '0', // Pack Qty
                        _toDouble(product['unitCost'])
                            .toStringAsFixed(2), // Unit Cost
                        _toDouble(product['price'])
                            .toStringAsFixed(2), // Unit Price
                        _toDouble(product['level1'])
                            .toStringAsFixed(2), // Price Level 1
                        _toDouble(product['level2'])
                            .toStringAsFixed(2), // Price Level 2
                        _toDouble(product['level3'])
                            .toStringAsFixed(2), // Price Level 3
                        _toDouble(product['level4'])
                            .toStringAsFixed(2), // Price Level 4
                        _toDouble(product['level5'])
                            .toStringAsFixed(2), // Price Level 5
                        Checkbox(
                          value: product['isMaster'] ??
                              false, // Use false if isMaster is null
                          onChanged: (value) {
                            if (value != null) {
                              _toggleIsMaster(
                                  productDataTable.indexOf(product), value);
                            }
                          },
                        ),

                        _toDouble(product['vat']).toStringAsFixed(2), // VAT %
                        _toDouble(product['vatAmount'])
                            .toStringAsFixed(2), // VAT Amount
                        _toDouble(product['priceWithVat'])
                            .toStringAsFixed(2), // Price With VAT
                      ];
                    }).toList(),
                    columnWidths: [
                      130, // Custom width for 'Item Code'
                      130, // Custom width for 'Item Name'
                      130, // Custom width for 'Name Arabic'
                      55, // Custom width for 'Pack Qty'
                      80, // Custom width for 'Unit Cost'
                      80, // Custom width for 'Unit Price'
                      80, // Custom width for 'Price Level 1'
                      80, // Custom width for 'Price Level 2'
                      80, // Custom width for 'Price Level 3'
                      80, // Custom width for 'Price Level 4'
                      80, // Custom width for 'Price Level 5'
                      70, // Custom width for 'Is Master'
                      80, // Custom width for 'VAT %'
                      80, // Custom width for 'VAT Amount'
                      80, // Custom width for 'Price With VAT'
                    ],
                                ),
              ),
            ],
          ), // closes _buildSectionCard
          ), // closes Padding
        ), // closes Expanded
      ],
    ),
  );
}

  
  

  Widget _buildSectionCard(Size screenSize, String title, List<Widget> fields) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildModernField(String label, Size screenSize,
      {TextEditingController? controller,
      Function(String)? onChanged,
      double labelFontSize = 14}) {
    return Container(
      width: 180,
      height: 43,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildModernFieldCode(String label, Size screenSize,
      {TextEditingController? controller,
      Function(String)? onChanged,
      double labelFontSize = 14}) {
    return Container(
      width: 180,
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        style: TextStyle(fontSize: 14),
      ),
    );
  }

Widget _buildTaxField(
  String label,
  Size screenSize, {
  required TextEditingController controller,
  Function(String)? onChanged,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: _buildModernField(
          label,
          screenSize,
          controller: controller,
          onChanged: onChanged,
        ),
      ),
      const SizedBox(width: 6),
      const SizedBox(
        width: 18,
        child: Text(
          "%",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

  Widget _buildDropdownField(String label, List<String> items, Size screenSize,
      {String? initialValue, ValueChanged<String?>? onChanged}) {
    final String? safeValue = (initialValue != null &&
            initialValue.trim().isNotEmpty &&
            items.contains(initialValue.trim()))
        ? initialValue.trim()
        : null;

    return Container(
      key: ValueKey('$label-$safeValue'),
      height: 43,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton<String>(
        value: safeValue,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSearchableGroupDropdown(String label, Size screenSize) {
    // ✅ Wait until groupData is fetched before showing the dropdown
    if (groupData.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    final initialGroup = groupData.firstWhere(
      (group) => group['GroupID'].toString() == selectedGroupId?.toString(),
      orElse: () => groupData.first, // fallback to first actual group
    );

    print(
        "Dropdown Rebuild -> initialGroup: $initialGroup, selectedGroupId: $selectedGroupId");

    return CustomSearchableDropdown(
      key: ValueKey(selectedGroupId), // Important: force rebuild
      label: label,
      items: groupData,
      displayKey: "GroupDescription",
      initialSelectedItem: initialGroup,
      onSelected: (group) {
        if (group != null) {
          setState(() {
            selectedGroupDescription = group['GroupDescription'];
            selectedGroupId = int.tryParse(group['GroupID'].toString());
          });
          print(
              "✅ Group Selected Manually: $selectedGroupDescription (ID: $selectedGroupId)");
        } else {
          setState(() {
            selectedGroupDescription = null;
            selectedGroupId = null;
          });
        }
      },
    );
  }

  Widget _buildSearchableSubGroupDropdown(String label, Size screenSize) {
    return CustomSearchableDropdown(
      label: label,
      items: subGroupData,
      displayKey: "SubGroupCode",
      selectedItem: selectedSubGroupID != null
          ? subGroupData.firstWhere(
              (subGroup) => subGroup['SubGroupID'] == selectedSubGroupID,
              orElse: () => {})
          : null,
      onSelected: (subGroup) {
        if (subGroup != null) {
          setState(() {
            selectedSubGroupDescription = subGroup['SubGroupCode'];
            selectedSubGroupID = subGroup['SubGroupID'] is String
                ? int.tryParse(subGroup['SubGroupID'])
                : subGroup['SubGroupID'];
          });
          print(
              "Selected SubGroup: $selectedSubGroupDescription (ID: $selectedSubGroupID)");
        } else {
          setState(() {
            selectedSubGroupDescription = null;
            selectedSubGroupID = null;
          });
        }
      },
    );
  }
}
