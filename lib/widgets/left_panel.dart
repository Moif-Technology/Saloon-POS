import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/entitlements/pos_features.dart';
import 'package:my_app/services/api_service.dart';

import 'package:my_app/widgets/leftPanelWidgets/add_customer.dart'; // new
import 'package:my_app/widgets/leftPanelWidgets/change_price.dart';
import 'package:my_app/widgets/leftPanelWidgets/change_qty.dart';
import 'package:my_app/widgets/common/supervisor_approval_dialog.dart';

import 'left_panel_components/left_top_bar.dart' as left_top_bar;
import 'left_panel_components/left_items_list.dart';
import 'left_panel_components/left_totals_row.dart';
import 'left_panel_components/left_action_buttons.dart';
import 'left_panel_components/left_qty_amount_bar.dart';
import 'left_panel_components/left_area_buttons.dart';

class PosLeftPanel extends ConsumerStatefulWidget {
  final List<Map<String, String>> selectedProducts;
  String? selectedAreaId;

  final Function(bool, {String? areaId}) onTableSelected;
  final Function(String areaId, String areaName) onAreaSelected;
  final VoidCallback? onKotReset;
  final bool isBaseVersion;

  PosLeftPanel({
    super.key,
    required this.selectedProducts,
    required this.onTableSelected,
    required this.onAreaSelected,
    this.onKotReset,
    this.isBaseVersion = false,
  });

  @override
  _PosLeftPanelState createState() => _PosLeftPanelState();
}

class _PosLeftPanelState extends ConsumerState<PosLeftPanel> {
  bool isKOTActive = false;
  String kotPrefix = "";
  String kotNumber = "NEW";

  String? selectedCustomerId;
  String? selectedCustomerName;
  int? selectedRowIndex;

  List<Map<String, String>> customers = const [
    {'id': '', 'name': 'Select Customer'},
    {'id': '__add__', 'name': 'Add New Customer'},
  ];

  late Future<List<dynamic>> _areas;
  String currencyPrecession = "0.00";

  ProviderSubscription<Map<String, dynamic>>? _kotSub;
  ProviderSubscription<Map<String, dynamic>>? _returnSub;
  bool _loadingKotIntoGrid = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentCurrencyPrecession = ref.read(currencyPrecessionProvider);
      final kotDetails = ref.read(kotDetailsProvider);

      setState(() {
        currencyPrecession = currentCurrencyPrecession ?? "0.00";
        if (kotDetails.isNotEmpty) {
          _updateTableWithKotDetails(kotDetails);
        }
      });
    });

    _areas = _fetchAreas();
    _fetchCustomers();

    // ✅ LISTENERS ONLY ONCE (safe, no duplicates)
    _kotSub = ref.listenManual<Map<String, dynamic>>(kotDetailsProvider,
        (previous, next) {
      if (next.isNotEmpty) {
        _updateTableWithKotDetails(next);
      }
    });

    _returnSub = ref.listenManual<Map<String, dynamic>>(returnBillProvider,
        (previous, next) {
      if (next.isNotEmpty && next['items'] != null) {
        _updateTableWithReturnItems(next);
      }

      final String? customerFromReturn =
          next['header']?['customerName']?.toString();
      if (customerFromReturn != null && customerFromReturn.isNotEmpty) {
        setState(() {
          selectedCustomerName = customerFromReturn;
          final match = customers.firstWhere(
            (c) => c['name'] == customerFromReturn,
            orElse: () => {'id': '', 'name': 'Select Customer'},
          );
          selectedCustomerId = (match['id'] == '__add__') ? '' : match['id'];
        });

        ref.read(selectedCustomerNameProvider.notifier).state =
            selectedCustomerName;
        ref.read(selectedCustomerIdProvider.notifier).state =
            (selectedCustomerId != null && selectedCustomerId!.isNotEmpty)
                ? selectedCustomerId
                : null;
      }
    });
  }

  @override
  void dispose() {
    _kotSub?.close();
    _returnSub?.close();
    super.dispose();
  }

  // ===================== API / DATA =====================

  Future<void> _fetchCustomers() async {
    final list = <Map<String, String>>[
      {'id': '', 'name': 'Select Customer'},
      {'id': '__add__', 'name': 'Add New Customer'},
    ];
    try {
      final rows = await ApiService().fetchCustomers();
      for (final r in rows) {
        if (r is! Map) continue;
        final m = Map<String, dynamic>.from(r);
        final id = m['CustomerID']?.toString().trim() ?? '';
        final name = m['CustomerName']?.toString().trim() ?? '';
        if (id.isEmpty || name.isEmpty) continue;
        list.add({'id': id, 'name': name});
      }
    } catch (_) {
      // Keep placeholder rows; POS still works for walk-in.
    }
    if (!mounted) return;
    setState(() {
      customers = list;
      final syncName = ref.read(selectedCustomerNameProvider);
      final nameToMatch = syncName ?? selectedCustomerName;
      if (nameToMatch != null && nameToMatch.isNotEmpty) {
        final match = customers.firstWhere(
          (x) => x['name'] == nameToMatch,
          orElse: () => {'id': '', 'name': 'Select Customer'},
        );
        selectedCustomerId = (match['id'] == '__add__') ? '' : match['id'];
        selectedCustomerName = nameToMatch;
      }
    });
  }

  Future<List<dynamic>> _fetchAreas({bool fetchAll = false}) async {
    try {
      List<dynamic> fetchedAreas =
          await ApiService().fetchAreas(fetchAll: fetchAll);

      if (!fetchAll) {
        List<dynamic> takeAwayDelivery = [];
        List<dynamic> otherAreas = [];

        for (var area in fetchedAreas) {
          final areaName =
              area['AreaName']?.toString().trim().toUpperCase() ?? '';
          if (areaName == 'TAKE AWAY' ||
              areaName == 'TAKEAWAY' ||
              areaName == 'DELIVERY') {
            takeAwayDelivery.add(area);
          } else {
            otherAreas.add(area);
          }
        }

        takeAwayDelivery.sort((a, b) {
          final aName = a['AreaName']?.toString().trim().toUpperCase() ?? '';
          final bName = b['AreaName']?.toString().trim().toUpperCase() ?? '';
          if (aName == 'TAKE AWAY' || aName == 'TAKEAWAY') return -1;
          if (bName == 'TAKE AWAY' || bName == 'TAKEAWAY') return 1;
          return 0;
        });

        return [...takeAwayDelivery, ...otherAreas];
      }

      return fetchedAreas;
    } catch (_) {
      return [];
    }
  }

  // ===================== KOT / RETURN =====================

  void _resetKOT() {
    widget.onKotReset?.call();

    setState(() {
      widget.selectedProducts.clear();
      kotPrefix = "";
      kotNumber = "NEW";
      isKOTActive = false;
      selectedRowIndex = null;

      selectedCustomerId = null;
      selectedCustomerName = null;
    });

    ref.read(selectedCustomerNameProvider.notifier).state = null;
    ref.read(selectedCustomerIdProvider.notifier).state = null;

    _publishCartSnapshot();
  }

  void _confirmAndResetKOT() async {
    if (widget.selectedProducts.isNotEmpty) {
      bool? confirmClear = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Confirm Reset"),
            content: const Text("Are you sure you want to clear all data?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          );
        },
      );

      if (confirmClear == true) _resetKOT();
    } else {
      _resetKOT();
    }
  }

  void _updateTableWithReturnItems(Map<String, dynamic> returnData) {
    setState(() => widget.selectedProducts.clear());

    final List<dynamic> items = returnData['items'] ?? [];
    for (var item in items) {
      widget.selectedProducts.add({
        "ShortDescription": item["itemName"] ?? "Unknown",
        "quantity": item["qty"].toString(),
        "UnitPrice": item["unitPrice"].toString(),
        "Tax1Rate": item["taxPerc"].toString(),
        "BarCode": item["itemCode"] ?? "",
        "modifiers": item["modifier"] ?? "",
        "isReturn": "true",
      });
    }

    _publishCartSnapshot();
    setState(() {});
  }

  void _updateTableWithKotDetails(Map<String, dynamic> kotDetails) async {
    // Invoice from Job List replaces the grid. Avoid Combine dialog while the
    // Job List popup is closing — that combination froze the till.
    if (_loadingKotIntoGrid) return;
    _loadingKotIntoGrid = true;
    ref.read(isUpdatingFromOrderListProvider.notifier).state = false;

    try {
      ref.read(activeKotProvider.notifier).state = kotDetails;

      if (!mounted) return;

      setState(() => widget.selectedProducts.clear());

      final rawData = kotDetails['data'];
      if (rawData is! List || rawData.isEmpty) {
        _publishCartSnapshot();
        if (mounted) setState(() {});
        return;
      }

      for (final raw in rawData) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final kotChildId = item["KotChildID"] ??
            item["kotChildID"] ??
            item["KOTChildID"] ??
            item["LineID"];
        final productId = item["ProductID"] ?? item["productID"];
        widget.selectedProducts.add({
          "ShortDescription":
              (item["ShortDescription"] ?? "Unknown").toString(),
          "quantity": (item["Qty"] ?? item["qty"] ?? 1).toString(),
          "UnitPrice":
              (item["UnitPrice"] ?? item["unitPrice"] ?? 0).toString(),
          "Tax1Rate":
              (item["Tax1RateC"] ?? item["Tax1Rate"] ?? 0).toString(),
          "BarCode": (item["BarCode"] ?? "").toString(),
          "modifiers":
              (item["Modifier"] ?? item["Remarks"] ?? "").toString(),
          "dgvKOTChildID": kotChildId != null ? kotChildId.toString() : "",
          "LineID": (item["LineID"] ?? kotChildId ?? "").toString(),
          "ProductID": productId != null ? productId.toString() : "",
          "UniqueProductID":
              (item["UniqueProductID"] ?? item["uniqueProductID"] ?? "0")
                  .toString(),
          "GroupID": (item["GroupID"] ?? item["groupID"] ?? "0").toString(),
          "ItemCode":
              (item["DescriptionArabic"] ?? item["BarCode"] ?? "").toString(),
          "AndroidPrint":
              (item["Androidprint"] ?? item["AndroidPrint"] ?? "PENDING")
                  .toString(),
          "KOTDisplayStatus": (item["KOTDisplayStatus"] ??
                  item["kotDisplayStatus"] ??
                  "PENDING")
              .toString(),
          "StylistID":
              (item["StylistID"] ?? item["stylistID"] ?? "").toString(),
          "StylistName":
              (item["StylistName"] ?? item["stylistName"] ?? "").toString(),
          "LineType":
              (item["LineType"] ?? item["lineType"] ?? "PRODUCT").toString(),
          "ProductType":
              (item["ProductType"] ?? item["LineType"] ?? "").toString(),
        });
      }

      final first = Map<String, dynamic>.from(rawData.first as Map);
      kotPrefix = (first["KotPrefix"] ?? first["KOTPrefix"] ?? "").toString();
      kotNumber = (first["JobNo"] ??
              first["KOTNumber"] ??
              first["KotNumber"] ??
              first["kotNumber"] ??
              "")
          .toString();
      isKOTActive = true;

      final areaId = first["AreaID"] ?? first["areaID"];
      if (areaId != null) {
        ref.read(selectedAreaIdProvider.notifier).state = areaId.toString();
        ref.read(selectedAreaNameProvider.notifier).state =
            (first["AreaName"] ?? first["areaName"] ?? "").toString();
      }
      final tableId = first["TableID"] ??
          first["tableID"] ??
          first["ChairID"] ??
          first["chairId"];
      if (tableId != null) {
        ref.read(selectedTableIdProvider.notifier).state = tableId.toString();
      }
      final chairNo = first["ChairNo"] ?? first["chairNo"];
      if (chairNo != null) {
        ref.read(selectedSeatNoProvider.notifier).state = chairNo.toString();
      }
      final custId = first["CustomerID"] ?? first["customerId"];
      if (custId != null && custId.toString().isNotEmpty) {
        selectedCustomerId = custId.toString();
        ref.read(selectedCustomerIdProvider.notifier).state = custId.toString();
      }

      _publishCartSnapshot();
      if (mounted) setState(() {});
    } finally {
      _loadingKotIntoGrid = false;
    }
  }

  // ===================== MODIFIERS / EDITS =====================

  /// Already saved on a job (has a line id from Invoice / Save Job).
  bool _isSavedJobLine(Map<String, String> item) {
    final id = int.tryParse(
            (item['dgvKOTChildID'] ?? item['LineID'] ?? item['lineId'] ?? '0')
                .toString()) ??
        0;
    return id > 0;
  }

  /// Saved lines need supervisor username/password; unsaved lines pass through.
  Future<bool> _approveIfSavedJobLine(
    Map<String, String> item, {
    required String reason,
  }) async {
    if (!_isSavedJobLine(item)) return true;
    final result = await showSupervisorApprovalDialog(
      context,
      title: 'Supervisor Approval',
      reason: reason,
    );
    return result != null;
  }

  Future<void> deleteSelectedRow() async {
    if (selectedRowIndex == null) return;
    final index = selectedRowIndex!;
    if (index < 0 || index >= widget.selectedProducts.length) return;
    final item = widget.selectedProducts[index];
    final ok = await _approveIfSavedJobLine(
      item,
      reason: 'Delete saved job item "${item['ShortDescription'] ?? 'item'}"',
    );
    if (!ok || !mounted) return;
    setState(() {
      widget.selectedProducts.removeAt(index);
      selectedRowIndex = null;
    });
    _publishCartSnapshot();
  }

  Future<void> _removeAt(int index) async {
    if (index < 0 || index >= widget.selectedProducts.length) return;
    final item = widget.selectedProducts[index];
    final ok = await _approveIfSavedJobLine(
      item,
      reason: 'Delete saved job item "${item['ShortDescription'] ?? 'item'}"',
    );
    if (!ok || !mounted) return;
    setState(() {
      widget.selectedProducts.removeAt(index);
      selectedRowIndex = null;
    });
    _publishCartSnapshot();
  }

  Future<void> _showQuantityChangeDialog(int index) async {
    if (index < 0 || index >= widget.selectedProducts.length) return;
    final item = widget.selectedProducts[index];
    final ok = await _approveIfSavedJobLine(
      item,
      reason:
          'Change quantity on saved job item "${item['ShortDescription'] ?? 'item'}"',
    );
    if (!ok || !mounted) return;

    final currentQty = item["quantity"] ?? "1";
    final productName = item["ShortDescription"] ??
        item["label"] ??
        "Unknown Product";

    final newQuantity = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return QuantityChangeDialog(
          currentQty: currentQty,
          productName: productName,
        );
      },
    );

    if (newQuantity != null && newQuantity.isNotEmpty && mounted) {
      setState(() {
        widget.selectedProducts[index]["quantity"] = newQuantity;
      });
      _publishCartSnapshot();
    }
  }

  Future<void> _changeQtyByDelta(int index, int delta) async {
    if (index < 0 || index >= widget.selectedProducts.length) return;
    final item = widget.selectedProducts[index];
    final ok = await _approveIfSavedJobLine(
      item,
      reason:
          'Change quantity on saved job item "${item['ShortDescription'] ?? 'item'}"',
    );
    if (!ok || !mounted) return;

    final qty = int.tryParse(item["quantity"] ?? "1") ?? 1;
    if (qty + delta < 1) {
      setState(() {
        widget.selectedProducts.removeAt(index);
        selectedRowIndex = null;
      });
      _publishCartSnapshot();
      return;
    }
    final newQty = (qty + delta).clamp(1, 999);
    setState(() => widget.selectedProducts[index]["quantity"] = "$newQty");
    _publishCartSnapshot();
  }

  Future<void> _showPriceChangeDialog(int index) async {
    final currentPrice = widget.selectedProducts[index]["UnitPrice"] ?? "0.00";
    final barcode = widget.selectedProducts[index]["BarCode"] ?? "123456789";
    final productName =
        widget.selectedProducts[index]["Description"] ?? "Unknown Product";
    final taxRate = widget.selectedProducts[index]["Tax1Rate"] ?? "0";

    final newPrice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return PriceChangeDialog(
          barcode: barcode,
          currentPrice: currentPrice,
          productName: productName,
          taxRate: taxRate,
        );
      },
    );

    if (newPrice != null && newPrice.isNotEmpty) {
      setState(() {
        widget.selectedProducts[index]["UnitPrice"] = newPrice;
      });
      _publishCartSnapshot();
    }
  }

  void _publishCartSnapshot() {
    ref.read(cartSnapshotProvider.notifier).state =
        List<Map<String, String>>.from(widget.selectedProducts);
  }

  // ===================== HELPERS =====================

  int _currencyDecimalsFrom(String? pattern) {
    if (pattern == null || pattern.isEmpty) return 2;
    if (pattern.contains('.')) return pattern.split('.').last.length;
    return int.tryParse(pattern) ?? 2;
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0.0;
    return 0.0;
  }

  Color _getAreaColor(String supplyType) {
    switch (supplyType) {
      case 'DINE IN':
        return const Color(0xFF20B2AA);
      case 'PARCEL':
        return const Color(0xFF87CEFA);
      case 'DELIVERY':
        return const Color(0xFFE6E6FA);
      default:
        return Colors.grey;
    }
  }

  bool _opensTableSelection(dynamic area) {
    final supplyType = area['SupplyType']?.toString().trim().toUpperCase() ?? '';
    final normalized = supplyType.replaceAll(RegExp(r'[\s_-]+'), '');
    return normalized != 'TAKEAWAY' &&
        normalized != 'PARCEL' &&
        normalized != 'DELIVERY';
  }

  // ===================== CONTEXT MENU =====================

  void _showContextMenuWithOffset(Offset position, int index) async {
    final items = widget.isBaseVersion
        ? const [
            PopupMenuItem<String>(value: 'remove', child: Text('🗑️ Remove')),
          ]
        : const [
            PopupMenuItem<String>(value: 'remove', child: Text('🗑️ Remove')),
            PopupMenuItem<String>(value: 'qty', child: Text('🔢 Change Qty')),
            PopupMenuItem<String>(
                value: 'price', child: Text('💲 Price Change')),
          ];
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    );

    switch (selected) {
      case 'remove':
        await _removeAt(index);
        break;
      case 'qty':
        await _showQuantityChangeDialog(index);
        break;
      case 'price':
        await _showPriceChangeDialog(index);
        break;
    }
  }

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddCustomerDialog();
      },
    ).then((result) {
      _fetchCustomers();
      if (result is Map && mounted) {
        final name = result['CustomerName']?.toString() ?? '';
        final id = result['CustomerID']?.toString() ?? '';
        if (name.isEmpty) return;
        setState(() {
          selectedCustomerName = name;
          selectedCustomerId = id;
        });
        ref.read(selectedCustomerNameProvider.notifier).state = name;
        ref.read(selectedCustomerIdProvider.notifier).state =
            id.isNotEmpty ? id : null;
      }
    });
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // POS compact: finer breakpoints for small screens
    final double fontSize;
    if (screenWidth < 380) {
      fontSize = 8.0;
    } else if (screenWidth < 450) {
      fontSize = 9.0;
    } else if (screenWidth < 520) {
      fontSize = 10.0;
    } else if (screenWidth < 600) {
      fontSize = 11.0;
    } else {
      fontSize = 12.0;
    }
    // Compact for POS: 1024x768, 800x600 etc – use smaller buttons
    final compact = screenWidth < 1200;

    final returnBill = ref.watch(returnBillProvider);
    final String? customerFromReturn =
        returnBill['header']?['customerName']?.toString();

    final selectedQty = ref.watch(selectedQtyProvider);
    final isReturnMode = ref.watch(returnModeProvider);

    final providerCustName = ref.watch(selectedCustomerNameProvider);
    final providerCustId = ref.watch(selectedCustomerIdProvider);
    List<Map<String, String>> customersForBar = customers;
    if (providerCustName != null &&
        providerCustName.isNotEmpty &&
        providerCustId != null &&
        providerCustId.isNotEmpty) {
      final exists = customers.any((c) => c['name'] == providerCustName);
      if (!exists) {
        customersForBar = [
          customers[0],
          customers[1],
          {'id': providerCustId, 'name': providerCustName},
          ...customers.skip(2),
        ];
      }
    }

    // Bill discount from current KOT (so summary bar shows Disc Amt and discounted Amount)
    double billDiscount = 0;
    final kotDetails = ref.watch(kotDetailsProvider);
    final posUi = PosUiFeatures(ref);
    final kotData = kotDetails['data'];
    if (kotData != null && kotData is List && kotData.isNotEmpty) {
      final first = kotData[0];
      if (first is Map<String, dynamic>) {
        final v = first['BillDiscount'] ?? first['billDiscount'];
        if (v != null) {
          billDiscount =
              (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0);
        }
      }
    }

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: widget.isBaseVersion
              ? const Color(0xFFF8FAFC)
              : Colors.grey.shade50,
          border: Border(
            right: BorderSide(
              color: const Color(0xFF521C1D)
                  .withValues(alpha: widget.isBaseVersion ? 0.2 : 1),
              width: widget.isBaseVersion ? 1 : 2,
            ),
          ),
        ),
        padding: EdgeInsets.all(widget.isBaseVersion ? 8 : (compact ? 4 : 8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) TOP BAR
            left_top_bar.LeftTopBar(
              compact: compact,
              showKotLabel: posUi.cartKotLabel,
              showCustomerSelector: posUi.cartCustomerSelector,
              showAddCustomer: posUi.cartAddCustomer,
              isKOTActive: isKOTActive,
              kotPrefix: kotPrefix,
              kotNumber: kotNumber,
              customers: customersForBar,
              selectedCustomerName: providerCustName ?? selectedCustomerName,
              customerFromReturn: customerFromReturn,
              fontSize: fontSize,
              onAddCustomer: () => _showAddCustomerDialog(context),
              onCustomerChanged: (newName) {
                if (newName == null) return;

                if (newName == 'Add New Customer') {
                  _showAddCustomerDialog(context);
                  return;
                }

                final match = customers.firstWhere(
                  (c) => c['name'] == newName,
                  orElse: () => {'id': '', 'name': 'Select Customer'},
                );

                setState(() {
                  selectedCustomerName =
                      newName == 'Select Customer' ? null : newName;
                  selectedCustomerId =
                      (match['id'] == '__add__') ? '' : match['id'];
                });

                ref.read(selectedCustomerNameProvider.notifier).state =
                    selectedCustomerName;
                ref.read(selectedCustomerIdProvider.notifier).state =
                    (selectedCustomerId != null &&
                            selectedCustomerId!.isNotEmpty)
                        ? selectedCustomerId
                        : null;
              },
            ),

            SizedBox(height: compact ? 4 : 8),

            // 2) ITEMS LIST (base: modern scrollable cards)
            Expanded(
              child: LeftItemsList(
                products: widget.selectedProducts,
                selectedRowIndex: selectedRowIndex,
                fontSize: fontSize,
                compact: compact,
                currencyPrecession: currencyPrecession,
                isBaseVersion: widget.isBaseVersion,
                showModifier: false,
                showQtyControls: posUi.cartQtyControls,
                showUnitPrice: posUi.cartUnitPrice,
                showSubtotal: posUi.cartSubtotal,
                showTax: posUi.cartTax,
                showLineTotal: posUi.cartLineTotal,
                allowDelete: posUi.cartDelete,
                onRowTap: (index) {
                  setState(() {
                    selectedRowIndex =
                        (selectedRowIndex == index) ? null : index;
                  });
                },
                onRowContextMenu: (index, globalPos) {
                  setState(() => selectedRowIndex = index);
                  _showContextMenuWithOffset(globalPos, index);
                },
                onModifierTap: (_) {},
                onRemoveItem: widget.isBaseVersion && posUi.cartDelete
                    ? (index) => _removeAt(index)
                    : null,
                onQtyChange: widget.isBaseVersion && posUi.cartQtyControls
                    ? (index, delta) => _changeQtyByDelta(index, delta)
                    : null,
                asDouble: _asDouble,
                currencyDecimalsFrom: _currencyDecimalsFrom,
              ),
            ),

            SizedBox(height: compact ? 4 : 8),

            // Bottom block: totals + actions + qty bar + area buttons (no extra space below)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3) TOTALS ROW (base: modern card style)
                LeftTotalsRow(
                  isBaseVersion: widget.isBaseVersion,
                  products: widget.selectedProducts,
                  fontSize: fontSize,
                  compact: compact,
                  showDelete: posUi.cartDelete,
                  showSubtotal: posUi.totalsSubtotal,
                  showTax: posUi.totalsTax,
                  showGrandTotal: posUi.totalsGrandTotal,
                  currencyPrecession: currencyPrecession,
                  onDelete: deleteSelectedRow,
                  currencyDecimalsFrom: _currencyDecimalsFrom,
                ),

                SizedBox(height: compact ? 4 : 6),

                // 4) ACTION BUTTONS (base: New KOT only)
                LeftActionButtons(
                  compact: compact,
                  isBaseVersion: widget.isBaseVersion,
                  showNewKot: posUi.kotSave && posUi.salonJobs,
                  showQtyChange: posUi.quantityChange,
                  showPriceChange: posUi.priceChange,
                  onNewKot: _confirmAndResetKOT,
                  onQtyChange: () {
                    if (selectedRowIndex != null) {
                      _showQuantityChangeDialog(selectedRowIndex!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Please select a row to change quantity")),
                      );
                    }
                  },
                  onPriceChange: () {
                    if (selectedRowIndex != null) {
                      _showPriceChangeDialog(selectedRowIndex!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Please select a row to change price")),
                      );
                    }
                  },
                ),

                SizedBox(height: compact ? 4 : 6),

                // 5) QTY/AMOUNT BAR
                LeftQtyAmountBar(
                  products: widget.selectedProducts,
                  fontSize: fontSize,
                  compact: compact,
                  currencyPrecession: currencyPrecession,
                  selectedQty: selectedQty,
                  isReturnMode: isReturnMode,
                  currencyDecimalsFrom: _currencyDecimalsFrom,
                  billDiscount: billDiscount,
                ),

                // 6) AREA BUTTONS (hidden in base - area chips in right panel)
                if (!widget.isBaseVersion && posUi.areasPanel)
                  LeftAreaButtons(
                    compact: compact,
                    futureAreas: _areas,
                    getAreaColor: _getAreaColor,
                    onPressed: (area) {
                      if (_opensTableSelection(area)) {
                        widget.onTableSelected(true, areaId: area['AreaID']);
                      } else {
                        widget.onTableSelected(false);
                      }

                      // clear current kot/session data
                      ref.read(kotDetailsProvider.notifier).state = {};
                      ref.read(activeKotProvider.notifier).state = {};
                      ref.read(isUpdatingFromOrderListProvider.notifier).state =
                          false;
                      ref.read(selectedQtyProvider.notifier).state = "1";

                      widget.selectedProducts.clear();
                      _publishCartSnapshot();

                      widget.onAreaSelected(
                        area['AreaID']?.toString() ?? '',
                        area['AreaName']?.toString() ?? '',
                      );

                      setState(() {});
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
