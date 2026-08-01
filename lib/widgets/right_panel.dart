import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/entitlements/pos_features.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/services/printService/pos_print.dart';
import 'package:my_app/utils/privilege_utils.dart';
import 'package:my_app/utils/kot_reset_utils.dart';
import 'package:my_app/widgets/rightPanelWidgets/item_cancel.dart';
import 'package:my_app/widgets/topPanelWidgets/NewEntryTab/product_entry.dart';
import 'package:my_app/core/providers/parameterProviders.dart';

import '../utils/sessionManager.dart';
import '../utils/empty_kot_response.dart';
import 'rightPanelWidgets/right_panels_widgets_import.dart';
import 'table_selection_dialog.dart';

// ✅ NEW COMPONENT IMPORTS
import 'right_panel_components/right_panel_compact_actions.dart';
import 'right_panel_components/right_panel_search_bar.dart';
import 'right_panel_components/right_panel_keypad_actions.dart';
import 'right_panel_components/right_panel_search_results.dart';
import 'right_panel_components/right_panel_product_or_table_view.dart';
import 'right_panel_components/right_panel_takeaway_list.dart';
import 'right_panel_components/right_panel_delivery_list.dart';

class RightPanel extends ConsumerStatefulWidget {
  final Function(Map<String, String>) onProductSelected;
  final VoidCallback onResetProducts;
  final VoidCallback? onKotReset;
  bool showTables;
  final String? areaId;
  final String? areaName;
  final bool isBaseVersion;
  final void Function(String areaId, String areaName)? onAreaSelected;
  final void Function(bool isSelected, {String? areaId})? onTableSelected;
  final String? selectedTableId;
  final String? selectedSeatNo;

  RightPanel({
    super.key,
    required this.onProductSelected,
    required this.onResetProducts,
    required this.showTables,
    this.onKotReset,
    this.areaId,
    this.areaName,
    this.isBaseVersion = false,
    this.onAreaSelected,
    this.onTableSelected,
    this.selectedTableId,
    this.selectedSeatNo,
  });

  @override
  _RightPanelState createState() => _RightPanelState();
}

class _RightPanelState extends ConsumerState<RightPanel> {
  String enteredQty = "";
  List<Map<String, dynamic>> tableData = [];

  List<Map<String, dynamic>> takeAwayList = [];
  List<Map<String, dynamic>> deliveryList = [];

  String? selectedTable;
  bool isLoading = true;
  bool isSearchingByName = true;
  bool isTakeAwayView = false;
  bool isDeliveryListView = false;
  int selectedTableChairs = 0;
  int selectedSearchIndex = -1;
  Timer? _searchDebounce;

  String selectedOrderType = 'Walk-In';
  final Map<String, List<String>> tableChairs = {};
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  int? get selectedGroupId => ref.watch(selectedGroupIdProvider);

  String? selectedKotMasterID;

  // Base version: groups + areas for chips
  List<dynamic> baseGroups = [];
  List<dynamic> baseAreas = [];

  @override
  void initState() {
    super.initState();
    searchFocusNode.onKeyEvent = (node, event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      if (!isSearchingByName || searchResults.isEmpty) {
        return KeyEventResult.ignored;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (selectedSearchIndex < 0) {
            selectedSearchIndex = 0;
          } else if (selectedSearchIndex < searchResults.length - 1) {
            selectedSearchIndex++;
          }
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (selectedSearchIndex > 0) {
            selectedSearchIndex--;
          } else {
            selectedSearchIndex = 0;
          }
        });
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
    Future.microtask(() {
      fetchTakeAwayList();
      fetchDeliveryList();
      if (widget.areaId != null && widget.areaId!.isNotEmpty) {
        fetchTables(widget.areaId!);
      }

      if (widget.areaName != null) {
        setState(() {
          selectedOrderType = widget.areaName!;
        });
      }

      if (widget.isBaseVersion) {
        _fetchBaseGroups();
        _fetchBaseAreas();
      }
    });
  }

  Future<void> _fetchBaseGroups() async {
    try {
      final groups = await ApiService().fetchGroups();
      if (mounted) {
        setState(() => baseGroups = groups);
        if (groups.isNotEmpty) {
          final firstId = groups[0]['GroupID'].toString();
          ref.read(selectedGroupIdProvider.notifier).state =
              int.tryParse(firstId);
          await _fetchProductsForGroup(firstId);
        }
      }
    } catch (e) {
      if (mounted) setState(() => baseGroups = []);
    }
  }

  Future<void> _fetchProductsForGroup(String groupId,
      {String? subGroupId}) async {
    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorProvider.notifier).state = null;
    try {
      final products = await ApiService().fetchProducts(
        groupId: groupId,
        subGroupId: subGroupId,
      );
      if (!mounted) return;
      ref.read(productProvider.notifier).state = products;
    } catch (e) {
      if (mounted) {
        ref.read(errorProvider.notifier).state = 'Failed to load products.';
        ref.read(productProvider.notifier).state = <dynamic>[];
      }
    } finally {
      if (mounted) ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _fetchBaseAreas() async {
    try {
      final areas = await ApiService().fetchAreas(fetchAll: false);
      if (mounted) {
        setState(() => baseAreas = areas);
        if (areas.isNotEmpty && widget.areaId == null) {
          final first = areas[0];
          widget.onAreaSelected?.call(
            first['AreaID']?.toString() ?? '',
            first['AreaName']?.toString() ?? '',
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => baseAreas = []);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId &&
        widget.areaId != null &&
        widget.areaId!.isNotEmpty) {
      fetchTables(widget.areaId!);
    }
    if (oldWidget.areaName != widget.areaName && widget.areaName != null) {
      setState(() {
        selectedOrderType = widget.areaName!;
      });
    }
  }

  void _selectSearchItem(Map<String, dynamic> product) {
    final converted = product
        .map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));

    final isReturnMode = ref.read(returnModeProvider);
    final selectedQty = ref.read(selectedQtyProvider);
    final qty = selectedQty.isEmpty ? 1 : int.tryParse(selectedQty) ?? 1;

    final actualQty = isReturnMode ? -qty : qty;
    final modified = Map<String, String>.from(converted);
    modified['Qty'] = actualQty.toString();

    widget.onProductSelected(modified);

    ref.read(returnModeProvider.notifier).state = false;
    ref.read(selectedQtyProvider.notifier).state = '1';

    setState(() {
      searchController.clear();
      searchResults.clear();
      isSearching = false;
      selectedSearchIndex = -1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
  }

  Future<void> fetchTables(String areaId) async {
    try {
      setState(() => isLoading = true);
      final combinedData = await ApiService()
          .fetchTables(areaId: areaId.isEmpty ? null : areaId);

      if (!mounted) return;
      setState(() {
        selectedTable = null;
        selectedTableChairs = 0;

        tableData = List<Map<String, dynamic>>.from(combinedData).map((table) {
          return {
            "TableID": table["TableID"]?.toString() ?? '',
            "TableNO": (table["TableNO"] ?? table["TableNo"])?.toString() ?? '',
            "TableName": table["TableName"]?.toString() ?? '',
            "TableNameArabic": table["TableNameArabic"]?.toString() ?? '',
            "NoOfChairs": table["NoOfChairs"]?.toString() ?? '4',
            "KOTPrefix": table["KOTPrefix"]?.toString() ?? '',
            "KOTNumber": table["KOTNumber"]?.toString() ?? '',
            "KOTStatus": table["KOTStatus"]?.toString() ?? '',
            "Remarks": table["Remarks"]?.toString() ?? '',
            "occupiedChairs": List<String>.from(table["occupiedChairs"] ?? []),
            "kotDetails":
                List<Map<String, dynamic>>.from(table["kotDetails"] ?? []),
          };
        }).toList();

        tableChairs.clear();
        for (var table in tableData) {
          final tableName = table["TableName"] ?? "Unknown";
          final chairsCount = int.tryParse(table["NoOfChairs"] ?? "0") ?? 0;
          tableChairs[tableName] =
              List.generate(chairsCount, (index) => "Chair ${index + 1}");
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchTakeAwayList() async {
    try {
      setState(() => isLoading = true);
      List<Map<String, dynamic>> responseList = [
        {
          'kotMasterID': 'MK-TA-001',
          'KotPrefix': 'TA',
          'KotNumber': '001',
          'TableId': '0',
          'ChairNo': '1',
          'KOTStatus': 'OPEN',
          'Remarks': 'Mock takeaway order',
        },
        {
          'kotMasterID': 'MK-TA-002',
          'KotPrefix': 'TA',
          'KotNumber': '002',
          'TableId': '0',
          'ChairNo': '1',
          'KOTStatus': 'HOLD',
          'Remarks': 'Pickup in 10 minutes',
        },
      ];

      setState(() {
        takeAwayList = responseList.map((item) {
          return {
            "kotMasterID": item['kotMasterID']?.toString() ?? '',
            "KotPrefix": item['KotPrefix']?.toString() ?? '',
            "KotNumber": item['KotNumber']?.toString() ?? '',
            "TableId": item['TableId']?.toString() ?? '',
            "ChairNo": item['ChairNo']?.toString() ?? '',
            "KOTStatus": item['KOTStatus']?.toString() ?? '',
            "Remarks": item['Remarks']?.toString() ?? '',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchDeliveryList() async {
    try {
      setState(() => isLoading = true);
      List<Map<String, dynamic>> responseList = [
        {
          'kotMasterID': 'MK-DL-001',
          'KotPrefix': 'DL',
          'KotNumber': '001',
          'TableId': '0',
          'ChairNo': '1',
          'KOTStatus': 'OPEN',
          'Remarks': 'Mock delivery - Dubai Marina',
        },
        {
          'kotMasterID': 'MK-DL-002',
          'KotPrefix': 'DL',
          'KotNumber': '002',
          'TableId': '0',
          'ChairNo': '1',
          'KOTStatus': 'OUT',
          'Remarks': 'Rider assigned',
        },
      ];

      setState(() {
        deliveryList = responseList.map((item) {
          return {
            "kotMasterID": item['kotMasterID']?.toString() ?? '',
            "KotPrefix": item['KotPrefix']?.toString() ?? '',
            "KotNumber": item['KotNumber']?.toString() ?? '',
            "TableId": item['TableId']?.toString() ?? '',
            "ChairNo": item['ChairNo']?.toString() ?? '',
            "KOTStatus": item['KOTStatus']?.toString() ?? '',
            "Remarks": item['Remarks']?.toString() ?? '',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
        selectedSearchIndex = -1;
      });
      return;
    }

    // Item Code mode: do not live-search; wait for Enter (scan behaviour).
    if (!isSearchingByName) {
      setState(() {
        isSearching = false;
        searchResults = [];
        selectedSearchIndex = -1;
      });
      return;
    }

    setState(() => isSearching = true);
    try {
      final results = await ApiService().fetchProducts(search: q, limit: 80);
      if (!mounted) return;
      // Ignore stale responses when the query has already changed.
      if (searchController.text.trim() != q) return;
      setState(() {
        searchResults = results
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        isSearching = false;
        selectedSearchIndex = searchResults.isEmpty ? -1 : 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSearching = false;
        searchResults = [];
        selectedSearchIndex = -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  /// Item Code / barcode scan: type code + Enter → add first exact match to grid.
  Future<void> _lookupCodeAndAdd(String code) async {
    final q = code.trim();
    if (q.isEmpty) return;

    setState(() => isSearching = true);
    try {
      var results = await ApiService().fetchProducts(barcode: q, limit: 5);
      if (results.isEmpty) {
        results = await ApiService().fetchProducts(productCode: q, limit: 5);
      }
      if (results.isEmpty) {
        // Fallback: search then prefer exact barcode/code match
        final loose = await ApiService().fetchProducts(search: q, limit: 20);
        results = loose.where((e) {
          if (e is! Map) return false;
          final bar = (e['Barcode'] ?? e['barcode'] ?? '').toString();
          final pc = (e['ProductCode'] ?? e['productCode'] ?? '').toString();
          return bar == q || pc.toLowerCase() == q.toLowerCase();
        }).toList();
        if (results.isEmpty && loose.isNotEmpty) {
          results = [loose.first];
        }
      }
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No item found for code "$q"')),
        );
        return;
      }
      final product = Map<String, dynamic>.from(results.first as Map);
      _selectSearchItem(product);
    } catch (e) {
      if (!mounted) return;
      setState(() => isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lookup failed: $e')),
      );
    }
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0.0;
    return 0.0;
  }

  /// Base version: area selector row + table dropdown — redesigned
  /// Returns the area map for a given supply type keyword from baseAreas.
  Map<String, dynamic>? _areaByType(String typeKeyword) {
    try {
      return baseAreas.firstWhere((a) =>
          (a['SupplyType']?.toString().toUpperCase() ?? '')
              .contains(typeKeyword.toUpperCase()));
    } catch (_) {
      return null;
    }
  }

  Widget _buildBaseAreaRow(BoxConstraints constraints) {
    const accent = Color(0xFF521C1D);
    final selectedId = widget.areaId?.toString();

    final takeAwayArea = _areaByType('PARCEL') ??
        _areaByType('TAKEAWAY') ??
        _areaByType('DELIVERY');
    final dineInArea = _areaByType('DINE');

    // Resolve which button is currently active
    final takeAwayId = takeAwayArea?['AreaID']?.toString();
    final dineInId = dineInArea?['AreaID']?.toString();
    final isTakeAwaySelected = selectedId != null && selectedId == takeAwayId;
    final isDineInSelected = selectedId != null && selectedId == dineInId;

    // Loading state
    if (baseAreas.isEmpty) {
      return Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF521C1D)),
        ),
      );
    }

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          // Walk-In button (parcel / counter area)
          if (takeAwayArea != null)
            Expanded(
              child: _buildOrderTypeBtn(
                label: 'Walk-In',
                icon: Icons.person_outline_rounded,
                isSelected: isTakeAwaySelected,
                onTap: () => widget.onAreaSelected?.call(
                  takeAwayId ?? '',
                  takeAwayArea['AreaName']?.toString() ?? 'Walk-In',
                ),
                accent: accent,
              ),
            ),

          if (takeAwayArea != null && dineInArea != null)
            const SizedBox(width: 6),

          // Chair / floor button
          if (dineInArea != null)
            Expanded(
              child: _buildOrderTypeBtn(
                label: 'Chair',
                icon: Icons.event_seat_rounded,
                isSelected: isDineInSelected,
                onTap: () => widget.onAreaSelected?.call(
                  dineInId ?? '',
                  dineInArea['AreaName']?.toString() ?? 'Chair',
                ),
                accent: accent,
              ),
            ),

          // Chair dropdown when Chair section is active
          if (isDineInSelected && tableData.isNotEmpty) ...[
            const SizedBox(width: 6),
            SizedBox(width: 130, child: _buildBaseTableDropdown()),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderTypeBtn({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF7B1C1C), Color(0xFF521C1D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 22,
                color: isSelected ? Colors.white : Colors.grey.shade500),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseTableDropdown() {
    if (tableData.isEmpty) return const SizedBox.shrink();
    const accent = Color(0xFF521C1D);
    final selectedTid = widget.selectedTableId;

    return Container(
      decoration: BoxDecoration(
        color:
            selectedTid != null ? const Color(0xFFFFF5F5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selectedTid != null
              ? accent.withValues(alpha: 0.35)
              : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTid,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.event_seat_outlined,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('Table',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          icon: Icon(Icons.expand_more,
              size: 16,
              color: selectedTid != null ? accent : Colors.grey.shade500),
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: accent),
          dropdownColor: Colors.white,
          items: [
            const DropdownMenuItem(
                value: null,
                child: Text('— None',
                    style: TextStyle(fontSize: 12, color: Colors.grey))),
            ...tableData.map((t) {
              final tid = t['TableID']?.toString();
              final name =
                  t['TableName']?.toString() ?? t['TableNO']?.toString() ?? '?';
              return DropdownMenuItem(
                value: tid,
                child: Row(
                  children: [
                    Icon(Icons.chair_outlined, size: 13, color: accent),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12))),
                  ],
                ),
              );
            }),
          ],
          onChanged: (v) {
            if (v == null) return;
            final t = tableData.firstWhere((x) => x['TableID']?.toString() == v,
                orElse: () => {});
            final tableId = t['TableID']?.toString();
            final chairNo = t['NoOfChairs']?.toString() ?? '1';
            ref.read(selectedTableIdProvider.notifier).state = tableId;
            ref.read(selectedSeatNoProvider.notifier).state = chairNo;
            setState(() => selectedTable = t['TableName']?.toString());
          },
        ),
      ),
    );
  }

  /// Base version: groups as horizontal scrollable tabs - modern style
  Widget _buildBaseGroupsTabs() {
    if (baseGroups.isEmpty) return const SizedBox(height: 44);
    const accent = Color(0xFF521C1D);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // "All" pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: GestureDetector(
              onTap: () {
                ref.read(selectedGroupIdProvider.notifier).state = null;
                _fetchProductsForGroup('');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: selectedGroupId == null
                      ? accent
                      : const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selectedGroupId == null
                        ? Colors.white
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
          // Divider
          Container(
              width: 1,
              height: 24,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(vertical: 10)),

          // Category tabs
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              itemCount: baseGroups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 5),
              itemBuilder: (_, i) {
                final g = baseGroups[i];
                final id = g['GroupID'].toString();
                final label = g['GroupDescription']?.toString() ?? '?';
                final isSel = selectedGroupId == int.tryParse(id);

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedGroupIdProvider.notifier).state =
                        int.tryParse(id);
                    _fetchProductsForGroup(id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: isSel
                          ? const LinearGradient(
                              colors: [Color(0xFF7B1C1C), Color(0xFF521C1D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight)
                          : null,
                      color: isSel ? null : const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSel ? Colors.transparent : Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                  color: accent.withValues(alpha: 0.28),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white : Colors.grey.shade700,
                        letterSpacing: 0.1,
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

  /// Decimal places from login-fetched currency pattern (e.g. "0.00" -> 2).
  int _currencyDecimalsFrom(String? pattern) {
    if (pattern == null || pattern.isEmpty) return 2;
    if (pattern.contains('.')) return pattern.split('.').last.length;
    return int.tryParse(pattern) ?? 2;
  }

  void showTakeAwayList() => setState(() => isTakeAwayView = true);
  void showDeliveryList() => setState(() {
        isTakeAwayView = false;
        isDeliveryListView = true;
      });
  void showDefaultGrid() => setState(() {
        isTakeAwayView = false;
        isDeliveryListView = false;
      });

  // ✅ Keypad actions (same behavior)
  void _keypadAppend(String t) {
    setState(() {
      enteredQty += t;
      searchController.text = enteredQty;
      performSearch(enteredQty);
    });
  }

  void _keypadDot() {
    setState(() {
      if (!enteredQty.contains(".")) enteredQty += '.';
      searchController.text = enteredQty;
      performSearch(enteredQty);
    });
  }

  void _keypadBackspace() {
    setState(() {
      if (enteredQty.isNotEmpty) {
        enteredQty = enteredQty.substring(0, enteredQty.length - 1);
      }
      searchController.text = enteredQty;
      performSearch(enteredQty);
    });
  }

  void _commitQty() {
    if (enteredQty.isNotEmpty) {
      ref.read(selectedQtyProvider.notifier).state = enteredQty;
      setState(() {
        enteredQty = "";
        searchController.clear();
        searchResults.clear();
        isSearching = false;
      });
    }
  }

  Future<void> _performSettlement() async {
    final posUi = PosUiFeatures(ref);
    final canSettleUnsavedCart = posUi.settlementUnsavedCart;
    final canSaveKotWithoutArea = posUi.kotSaveWithoutArea;
    var kotDetailsLocal = ref.read(kotDetailsProvider);
    final activeKotLocal = ref.read(activeKotProvider);
    var kotDataSrc = kotDetailsLocal['data'] ?? activeKotLocal['data'];
    var firstRow = (kotDataSrc is List && kotDataSrc.isNotEmpty)
        ? kotDataSrc[0] as Map<String, dynamic>?
        : null;
    var kotId = firstRow != null
        ? (int.tryParse(
                (firstRow['KotMasterID'] ?? firstRow['kotMasterID'] ?? 0)
                    .toString()) ??
            0)
        : 0;

    if (!canSettleUnsavedCart && kotId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Settlement needs a saved job. Load a job or tap Save Job first.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (canSettleUnsavedCart && kotId <= 0) {
      final areaId = ref.read(selectedAreaIdProvider);
      final tableId = ref.read(selectedTableIdProvider);
      final seatNo = ref.read(selectedSeatNoProvider);
      final custId = ref.read(selectedCustomerIdProvider);
      final isWaiterMandatory = ref.read(ISWaiterMandotoryProvider);
      final cart = ref.read(cartSnapshotProvider);
      if (!canSaveKotWithoutArea && (areaId == null || areaId.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a section')));
        return;
      }
      if (cart.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add at least one item')));
        return;
      }
      double saveSub = 0, saveTax = 0, saveGrand = 0;
      final itemsPayload = cart.map((p) {
        final qty = double.tryParse(p['quantity'] ?? '1') ?? 1.0;
        final rate = double.tryParse(p['UnitPrice'] ?? '0') ?? 0.0;
        final taxP =
            double.tryParse(p['Tax1Rate'] ?? p['TaxPerc'] ?? '0') ?? 0.0;
        final st = qty * rate;
        final taxA = st * taxP / 100.0;
        final lt = st + taxA;
        saveSub += st;
        saveTax += taxA;
        saveGrand += lt;
        final name = p['ShortDescription'] ?? p['Description'] ?? '';
        return {
          'ProductID': p['ProductID'],
          'BarCode': p['BarCode'] ?? p['Barcode'] ?? '',
          'UniqueProductID': p['UniqueProductID'] ?? '0',
          'ItemName': name,
          'ShortDescription': name,
          'ItemCode': p['ItemCode'] ?? '',
          'Qty': qty.toString(),
          'PackQty': p['PackQty'] ?? '0',
          'UnitCost': p['UnitCost'] ?? '0',
          'UnitPrice': rate.toString(),
          'SubTotal': st.toString(),
          'TaxPerc': taxP.toString(),
          'Tax1Rate': taxP.toString(),
          'Tax1RateC': taxP.toString(),
          'TaxAmount': taxA.toString(),
          'Tax1AmountC': taxA.toString(),
          'ItemDisc': p['ItemDisc'] ?? '0',
          'ItemDiscount': p['ItemDisc'] ?? '0',
          'LineTotal': lt.toString(),
          'dgvGrpID': p['GroupID'] ?? p['dgvGrpID'] ?? '0',
          'GroupID': p['GroupID'] ?? p['dgvGrpID'] ?? '0',
          'Modifir': p['modifiers'] ?? '',
          'AndroidPrint': p['AndroidPrint'] ?? 'PENDING',
          'KOTDisplayStatus': p['KOTDisplayStatus'] ?? 'PENDING',
          'qtyadd': p['qtyadd'] ?? '',
          'StylistID': p['StylistID'] ?? SessionManager().staffID ?? '',
          'LineType': p['LineType'] ?? p['ProductType'] ?? 'PRODUCT',
          'ProductType': p['ProductType'] ?? p['LineType'] ?? '',
        };
      }).toList();
      final sm = SessionManager();
      final stationId = int.tryParse(sm.stationId ?? '0') ?? 0;
      final staffName = sm.staffName ?? '';
      final staffId = int.tryParse(sm.staffID ?? '0') ?? 0;
      final payload = {
        'StationID': stationId,
        'stationId': stationId,
        'mfAreaId': int.tryParse(areaId ?? '0') ?? 0,
        'AreaID': int.tryParse(areaId ?? '0') ?? 0,
        'mfTableID': (tableId == null || tableId.isEmpty)
            ? 0
            : int.tryParse(tableId) ?? 0,
        'ChairID': (tableId == null || tableId.isEmpty)
            ? 0
            : int.tryParse(tableId) ?? 0,
        'TableID': (tableId == null || tableId.isEmpty)
            ? 0
            : int.tryParse(tableId) ?? 0,
        'mfChairNo':
            (seatNo == null || seatNo.isEmpty) ? 0 : int.tryParse(seatNo) ?? 0,
        'ISWaiterMandatory': isWaiterMandatory,
        'mfCustomerID':
            (custId == null || custId.isEmpty) ? 0 : int.tryParse(custId) ?? 0,
        'CustomerID':
            (custId == null || custId.isEmpty) ? 0 : int.tryParse(custId) ?? 0,
        'PrimaryStylistID': staffId,
        'gvCounterNo': stationId.toString(),
        'gvUserName': staffName,
        'gvCashierID': staffId,
        'txtDiscount': 0,
        'lblSubTotalAmt': saveSub,
        'lblTax1Total': saveTax,
        'lblRound': 0,
        'lblBillTotal': saveGrand,
        'txtNoofCustomer': 0,
        'txtRemarks': '',
        'btnname': 'JobSave',
        'Items': itemsPayload,
      };
      try {
        final result =
            await ApiService().saveKot(Map<String, dynamic>.from(payload));
        if (!mounted) return;
        if (result['ok'] != true && result['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['msg']?.toString() ??
                    result['message']?.toString() ??
                    'Failed to save job')),
          );
          return;
        }
        final currentKotId = result['CurrentKOTID'] ??
            result['currentJobId'] ??
            result['jobId'] ??
            result['kotMasterId'];
        final newKotId = currentKotId != null &&
                int.tryParse(currentKotId.toString()) != null
            ? (int.tryParse(currentKotId.toString()) ?? 0)
            : 0;
        if (newKotId > 0) {
          try {
            Map<String, dynamic> kotDetails;
            final kd = result['kotDetails'];
            if (kd is Map) {
              kotDetails = Map<String, dynamic>.from(kd as Map);
            } else {
              kotDetails = await ApiService().fetchKotDetails('$newKotId');
            }
            ref.read(kotDetailsProvider.notifier).state = kotDetails;
            ref.read(activeKotProvider.notifier).state = kotDetails;
            kotDetailsLocal = kotDetails;
            kotDataSrc = kotDetails['data'];
            firstRow = (kotDataSrc is List && kotDataSrc.isNotEmpty)
                ? kotDataSrc[0] as Map<String, dynamic>?
                : null;
            kotId = newKotId;
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Job saved but failed to load details. Try opening settlement again.')),
            );
            return;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Save Job did not return a valid job ID.')),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Save Job failed: $e'),
              backgroundColor: Colors.red),
        );
        return;
      }
    }

    double subTotal = 0, taxTotal = 0, grandTotal = 0;
    List<Map<String, dynamic>> items;

    if (kotDataSrc != null && kotDataSrc is List && kotDataSrc.isNotEmpty) {
      items = kotDataSrc.map<Map<String, dynamic>>((p) {
        final qty = _asDouble(p['Qty'] ?? p['qty'] ?? 1);
        final rate = _asDouble(p['UnitPrice'] ?? p['unitPrice'] ?? 0);
        final tax1Rate = _asDouble(p['Tax1RateC'] ?? p['tax1RateC'] ?? 0);
        final tax1Amt = _asDouble(p['Tax1AmountC'] ?? p['tax1AmountC'] ?? 0);
        final disc = _asDouble(p['ItemDiscount'] ?? p['discount'] ?? 0);
        final st = (qty * rate) - disc;
        subTotal += st;
        taxTotal += tax1Amt;
        grandTotal +=
            _asDouble(p['LineTotal'] ?? p['lineTotal'] ?? st + tax1Amt);
        return {
          'productId': int.tryParse(
                  (p['ProductID'] ?? p['productId'] ?? 0).toString()) ??
              0,
          'kotChildID': int.tryParse(
                  (p['KotChildID'] ?? p['kotChildID'] ?? 0).toString()) ??
              0,
          'uniqueMultiProductId': int.tryParse(
                  (p['UniqueProductID'] ?? p['uniqueProductID'] ?? 0)
                      .toString()) ??
              0,
          'shortDescription':
              (p['ShortDescription'] ?? p['shortDescription'] ?? '') as String,
          'arabicDescription': (p['DescriptionArabic'] ??
              p['arabicDescription'] ??
              '') as String,
          'groupId':
              int.tryParse((p['GroupID'] ?? p['groupId'] ?? 0).toString()) ?? 0,
          'qty': qty,
          'unitPrice': rate,
          'unitCost': _asDouble(p['UnitCost'] ?? p['unitCost'] ?? 0),
          'packQty': _asDouble(p['PackQty'] ?? p['packQty'] ?? 1),
          'discount': disc,
          'subTotalC': st,
          'tax1RateC': tax1Rate,
          'tax1AmountC': tax1Amt,
          'tax2RateC': _asDouble(p['Tax2RateC'] ?? p['tax2RateC'] ?? 0),
          'tax2AmountC': _asDouble(p['Tax2AmountC'] ?? p['tax2AmountC'] ?? 0),
          'tax3RateC': _asDouble(p['Tax3RateC'] ?? p['tax3RateC'] ?? 0),
          'tax3AmountC': _asDouble(p['Tax3AmountC'] ?? p['tax3AmountC'] ?? 0),
          // Salon: settlement writes stylist_id and line_type onto every bill
          // line, which is what per-stylist commission is computed from. These
          // rows come back from the saved job, so they already carry both —
          // lineId lets the server match the bill line to its job line exactly
          // instead of guessing by product id.
          'lineId': int.tryParse(
                  (p['LineID'] ?? p['lineID'] ?? p['KotChildID'] ?? 0)
                      .toString()) ??
              0,
          'stylistId': int.tryParse(
                  (p['StylistID'] ?? p['stylistID'] ?? 0).toString()) ??
              0,
          'lineType': (p['LineType'] ?? p['lineType'] ?? '').toString(),
        };
      }).toList();
    } else {
      final cart = ref.read(cartSnapshotProvider);
      if (cart.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No items to settle. Load a job or add items and tap Save Job first.'),
              backgroundColor: Colors.red),
        );
        return;
      }
      items = cart.map<Map<String, dynamic>>((p) {
        final qty = double.tryParse(p['quantity'] ?? '1') ?? 1.0;
        final rate = double.tryParse(p['UnitPrice'] ?? '0') ?? 0.0;
        final taxP =
            double.tryParse(p['Tax1Rate'] ?? p['TaxPerc'] ?? '0') ?? 0.0;
        final st = qty * rate;
        final taxA = st * taxP / 100.0;
        subTotal += st;
        taxTotal += taxA;
        grandTotal += st + taxA;
        return {
          'productId': int.tryParse(p['ProductID'] ?? '0') ?? 0,
          'uniqueMultiProductId': int.tryParse(
                  p['UniqueProductID'] ?? p['UniqueProductID'] ?? '0') ??
              0,
          'shortDescription': p['ShortDescription'] ?? p['Description'] ?? '',
          'arabicDescription': p['ArabicDescription'] ?? '',
          'groupId': int.tryParse(p['GroupID'] ?? p['dgvGrpID'] ?? '0') ?? 0,
          'qty': qty,
          'unitPrice': rate,
          'unitCost': double.tryParse(p['UnitCost'] ?? '0') ?? 0,
          'packQty': double.tryParse(p['PackQty'] ?? '1') ?? 1,
          'discount': double.tryParse(p['ItemDisc'] ?? '0') ?? 0,
          'subTotalC': st,
          'tax1RateC': taxP,
          'tax1AmountC': taxA,
          'tax2RateC': 0.0,
          'tax2AmountC': 0.0,
          'tax3RateC': 0.0,
          'tax3AmountC': 0.0,
          // Salon: unsaved-cart path. No job line exists yet, so there is no
          // lineId to send — the stylist and line type come straight off the
          // cart row, stamped when the product was added.
          'stylistId': int.tryParse(p['StylistID'] ?? '0') ?? 0,
          'lineType': p['LineType'] ?? 'PRODUCT',
        };
      }).toList();
    }

    double billDiscount = 0;
    if (firstRow != null && firstRow is Map<String, dynamic>) {
      final v = firstRow['BillDiscount'] ?? firstRow['billDiscount'];
      if (v != null) {
        billDiscount =
            (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0);
      }
    }
    final netAmountForSettlement =
        (grandTotal - billDiscount).clamp(0.0, double.infinity);

    final sm = SessionManager();
    final stationId = int.tryParse(sm.stationId ?? '0') ?? 0;
    final areaId = ref.read(selectedAreaIdProvider);
    final tableId = ref.read(selectedTableIdProvider);
    final custId = ref.read(selectedCustomerIdProvider);
    final custName = ref.read(selectedCustomerNameProvider);
    String customerCode = '';
    String customerMobile = (firstRow?['MobileNo'] ??
            firstRow?['mobileNo'] ??
            '')
        .toString()
        .trim();
    String customerAddress = '';
    String customerTrn = '';
    final custIdStr = (custId ?? '').trim();
    if (custIdStr.isNotEmpty && custIdStr != '0') {
      try {
        final rows = await ApiService().fetchCustomers(
          search: (custName ?? '').trim().isNotEmpty ? custName!.trim() : null,
          limit: 50,
        );
        Map<String, dynamic>? match;
        for (final r in rows) {
          if (r is! Map) continue;
          final m = Map<String, dynamic>.from(r);
          final id = (m['CustomerID'] ?? m['customerId'] ?? '').toString();
          if (id == custIdStr) {
            match = m;
            break;
          }
        }
        if (match == null) {
          final nameKey = (custName ?? '').trim().toLowerCase();
          if (nameKey.isNotEmpty) {
            for (final r in rows) {
              if (r is! Map) continue;
              final m = Map<String, dynamic>.from(r);
              final n = (m['CustomerName'] ?? m['customerName'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              if (n == nameKey) {
                match = m;
                break;
              }
            }
          }
        }
        if (match != null) {
          customerCode =
              (match['CustomerCode'] ?? match['customerCode'] ?? '')
                  .toString()
                  .trim();
          final mob = (match['MobileNo'] ?? match['mobileNo'] ?? '')
              .toString()
              .trim();
          final tel = (match['Telephone'] ?? match['telephone'] ?? '')
              .toString()
              .trim();
          if (mob.isNotEmpty || tel.isNotEmpty) {
            customerMobile = [mob, tel]
                .where((e) => e.isNotEmpty)
                .join(' / ');
          }
          customerAddress =
              (match['Address'] ?? match['address'] ?? '').toString().trim();
          customerTrn =
              (match['CustTRN'] ?? match['taxRegNo'] ?? '').toString().trim();
        }
      } catch (_) {}
    }
    final firstRowWaiter = firstRow != null
        ? int.tryParse((firstRow['WaiterID'] ?? firstRow['waiterId'] ?? 0)
                .toString()) ??
            0
        : 0;
    final orderData = {
      'kotId': kotId,
      'counterNo': stationId,
      'stationId': stationId,
      'customerId': (custId == null || custId.isEmpty)
          ? (firstRow != null
              ? int.tryParse(
                      (firstRow['CustomerID'] ?? firstRow['customerId'] ?? 0)
                          .toString()) ??
                  0
              : 0)
          : int.tryParse(custId) ?? 0,
      'waiterId': firstRowWaiter,
      'tableId': (tableId == null || tableId.isEmpty)
          ? (firstRow != null
              ? int.tryParse((firstRow['TableID'] ?? firstRow['tableId'] ?? 0)
                      .toString()) ??
                  0
              : 0)
          : int.tryParse(tableId) ?? 0,
      'areaId': (areaId == null || areaId.isEmpty)
          ? (firstRow != null
              ? int.tryParse((firstRow['AreaID'] ?? firstRow['areaId'] ?? 0)
                      .toString()) ??
                  0
              : 0)
          : int.tryParse(areaId) ?? 0,
      'noOfCustomer': 0,
      'subTotal': subTotal,
      'subTotalM': subTotal,
      'discountAmount': billDiscount,
      'taxableAmount': subTotal,
      'tax1Amount': taxTotal,
      'tax1AmountM': taxTotal,
      'tax1Rate':
          (taxTotal > 0 && subTotal > 0) ? (taxTotal / subTotal) * 100 : 0,
      'tax1RateM':
          (taxTotal > 0 && subTotal > 0) ? (taxTotal / subTotal) * 100 : 0,
      'tax2AmountM': 0,
      'tax2RateM': 0,
      'tax3AmountM': 0,
      'tax3RateM': 0,
      'roundOffAdj': 0,
      'netAmount': netAmountForSettlement,
      'paidCurrency': 'AED',
      'dbLocation': 'LOCAL',
      'items': items,
      'kotPrefix': firstRow?['KotPrefix'] ??
          firstRow?['KOTPrefix'] ??
          (items.isNotEmpty
              ? (items.first['KotPrefix'] ?? items.first['KOTPrefix'])
              : null),
      'kotNumber': firstRow?['KotNumber'] ??
          firstRow?['KOTNumber'] ??
          firstRow?['JobNo'] ??
          firstRow?['jobNo'] ??
          (items.isNotEmpty
              ? (items.first['KotNumber'] ??
                  items.first['KOTNumber'] ??
                  items.first['JobNo'])
              : null),
      'jobNo': firstRow?['JobNo'] ??
          firstRow?['jobNo'] ??
          firstRow?['KotNumber'] ??
          firstRow?['KOTNumber'],
      'tableName': firstRow?['ChairName'] ??
          firstRow?['TableName'] ??
          selectedTable ??
          tableId?.toString(),
      'chairName': firstRow?['ChairName'] ?? firstRow?['TableName'],
      'waiterName': firstRow?['PrimaryStylistName'] ??
          firstRow?['WaiterName'] ??
          firstRow?['waiterName'] ??
          firstRow?['stylistName'],
      'stylistName': firstRow?['PrimaryStylistName'] ??
          firstRow?['WaiterName'] ??
          firstRow?['stylistName'],
      'cashierName': SessionManager().staffName,
      'orderType': 'WALK-IN',
      'comments': '',
      'customerName': custName ?? '',
      'customerCode': customerCode,
      'mobileNo': customerMobile,
      'address': customerAddress,
      'taxRegNo': customerTrn,
    };
    final currencyPrecession = ref.read(currencyPrecessionProvider) ?? '0.00';
    final int currencyDecimals = _currencyDecimalsFrom(currencyPrecession);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SettlementDialog(
        netTotal: netAmountForSettlement,
        currencyDecimals: currencyDecimals,
        customerName: custName ?? 'Cash Customer',
        startTime: '--',
        elapsed: '--',
        orderData: orderData,
      ),
    );
    if (result != null && mounted) {
      final orderDataOut = result['orderData'] as Map<String, dynamic>?;
      if (orderDataOut != null && orderDataOut.isNotEmpty) {
        final onError = (String msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.orange),
            );
          }
        };
        final customerName =
            result['customerName']?.toString() ?? custName ?? 'Cash Customer';
        await PosPrint.printSettlement(
          result: result,
          orderData: orderDataOut,
          customerName: customerName,
          currencyDecimals: currencyDecimals,
          onError: onError,
        );
      }
      final container = ProviderScope.containerOf(context);
      clearKotStateForNewOrder(container);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onKotReset?.call();
      });
    }
  }

  Future<void> _onTapTakeAwayItem(Map<String, dynamic> item) async {
    final kotMasterID = item['kotMasterID']?.toString();
    if (kotMasterID == null || kotMasterID.isEmpty) return;

    try {
      var kotDetails = await emptyKotDetails();
      ref.read(kotDetailsProvider.notifier).state = kotDetails;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to fetch job details."),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _onTapDeliveryItem(Map<String, dynamic> item) async {
    final id = item['kotMasterID']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() => selectedKotMasterID = id);

    try {
      var kotDetails = await emptyKotDetails();
      ref.read(kotDetailsProvider.notifier).state = kotDetails;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to fetch job details."),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kotDetails = ref.watch(kotDetailsProvider);
    final kotData = kotDetails['data'];
    final bool hasActiveKOT = kotData != null && kotData.isNotEmpty;

    final returnBill = ref.watch(returnBillProvider);
    final returnHeader = returnBill['header'];
    final isReturnBillAvailable =
        returnHeader != null && returnHeader.isNotEmpty;
    final posUi = PosUiFeatures(ref);
    final canUseTables = posUi.tablesPanel;
    final canUseAreas = posUi.areasPanel;
    final canUseSettlement = posUi.settlement;
    final canUseDelivery = posUi.delivery;
    final canUseCashInOut = posUi.cashInOut;
    final canUseDiscount = posUi.discount;
    final canUseItemCancel = posUi.itemCancel;
    final canUseKotJoinSplit = posUi.kotJoinSplit;
    final canUseReturnBill = posUi.returnBill;
    final canUseVoidBill = posUi.voidBill;

    final mq = MediaQuery.of(context);

    return MediaQuery(
      data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;

          // ✅ Responsive spacings based on available height
          final bool shortH = h < 720; // small height windows
          final bool veryShortH = h < 640; // extreme cases
          final double vGap = veryShortH ? 2 : (shortH ? 4 : 6);

          return Scaffold(
            backgroundColor: widget.isBaseVersion
                ? const Color(0xFFF1F5F9)
                : Colors.grey.shade100,
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: w < 520 ? 4 : 6),
              child: Column(
                children: [
                  // Base: area chips + table dropdown
                  if (widget.isBaseVersion && canUseAreas)
                    _buildBaseAreaRow(constraints),
                  if (widget.isBaseVersion) SizedBox(height: vGap),
                  // Base: groups as horizontal tabs
                  if (widget.isBaseVersion && posUi.groupsPanel)
                    _buildBaseGroupsTabs(),
                  if (widget.isBaseVersion) SizedBox(height: vGap),
                  // ✅ Top area always takes remaining space
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: veryShortH ? 2 : 4),
                      child: isTakeAwayView
                          ? RightPanelTakeAwayList(
                              takeAwayList: takeAwayList,
                              onBack: () =>
                                  setState(() => isTakeAwayView = false),
                              onTapItem: _onTapTakeAwayItem,
                            )
                          : isDeliveryListView
                              ? RightPanelDeliveryList(
                                  deliveryList: deliveryList,
                                  onBack: () => setState(
                                      () => isDeliveryListView = false),
                                  onTapItem: _onTapDeliveryItem,
                                )
                              : (isSearching || searchResults.isNotEmpty)
                                  ? RightPanelSearchResults(
                                      results: searchResults,
                                      selectedIndex: selectedSearchIndex,
                                      onSelect: _selectSearchItem,
                                    )
                                  : RightPanelProductOrTableView(
                                      showTables:
                                          widget.isBaseVersion || !canUseTables
                                              ? false
                                              : widget.showTables,
                                      isBaseVersion: widget.isBaseVersion,
                                      isSearching: isSearching,
                                      searchResults: searchResults,
                                      tableData: tableData,
                                      tableChairs: tableChairs,
                                      selectedTable: selectedTable,
                                      selectedSearchIndex: selectedSearchIndex,
                                      selectedGroupId: selectedGroupId,
                                      onSelectTable:
                                          (tableName, chairCountStr) {
                                        setState(() {
                                          selectedTable = tableName;
                                          selectedTableChairs =
                                              int.tryParse(chairCountStr) ?? 0;
                                        });
                                      },
                                      onSelectSearchItem: _selectSearchItem,
                                      onSelectProductGridItem: (m) =>
                                          widget.onProductSelected(m),
                                    ),
                    ),
                  ),

                  // ✅ Compact actions (now Wrap-based + responsive)
                  // Base version: returns SizedBox.shrink() — no gap needed
                  if (!widget.isBaseVersion) SizedBox(height: vGap),
                  RightPanelCompactActions(
                    isBaseVersion: widget.isBaseVersion,
                    showCancelBill: canUseVoidBill &&
                        isControlEnabled(ref, 'btnBillCancel'),
                    showPrintKot:
                        posUi.kotPrint && isControlEnabled(ref, 'btnPrintKOT'),
                    showReprintKot: posUi.kotReprint &&
                        isControlEnabled(ref, 'btnKOTReprint'),
                    showSaveKot:
                        posUi.kotSave && isControlEnabled(ref, 'btnSaveKOT'),
                    showDiscount:
                        canUseDiscount && isControlEnabled(ref, 'btnDiscount'),
                    showDummyBill: posUi.kotDummyBill &&
                        isControlEnabled(ref, 'btnDummyBill'),
                    showComments: posUi.kotComments &&
                        isControlEnabled(ref, 'btnComments'),
                    showKotJoin: canUseKotJoinSplit,
                    showCashInOut: canUseCashInOut,
                    showBillPrint: posUi.directSettlement,
                    onCancelBill: () {
                      final kotDetailsLocal = ref.read(activeKotProvider);
                      if (kotDetailsLocal.isEmpty) return;

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            child: Container(
                              width: 400,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF521C1D)
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.warning_rounded,
                                        color: Color(0xFF521C1D), size: 40),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    "Cancel Job",
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF521C1D)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Are you sure you want to cancel this job?",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                        height: 1.5),
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          foregroundColor: Colors.black87,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                        ),
                                        child: const Text("No, Keep it",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();

                                          final kotMasterIDString =
                                              kotDetailsLocal['data']?[0]
                                                  ?['KotMasterID'];
                                          final kotMasterID = int.tryParse(
                                              kotMasterIDString.toString());

                                          if (kotMasterID == null) return;

                                          try {
                                            final response = <String, dynamic>{
                                              'success': false,
                                            };

                                            if (!mounted) return;

                                            if (response['success'] == true) {
                                              widget.onResetProducts();

                                              await showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20)),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              24),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                              size: 48),
                                                          const SizedBox(
                                                              height: 16),
                                                          const Text("Success!",
                                                              style: TextStyle(
                                                                  fontSize: 24,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          const SizedBox(
                                                              height: 8),
                                                          const Text(
                                                              "Job cancelled successfully",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      16)),
                                                          const SizedBox(
                                                              height: 24),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(),
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFF521C1D),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          32,
                                                                      vertical:
                                                                          12),
                                                            ),
                                                            child: const Text(
                                                                "OK",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            } else {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text("Error"),
                                                  content: Text(
                                                      "Failed: ${response['message']}"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                        child:
                                                            const Text("OK")),
                                                  ],
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (!mounted) return;
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text("Error"),
                                                content: Text("Error: $e"),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child: const Text("OK")),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF521C1D),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                        ),
                                        child: const Text("Yes, Cancel it",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    onKotJoin: canUseKotJoinSplit
                        ? () => showDialog(
                            context: context,
                            builder: (_) => BillJoinSplitDialog())
                        : () {},
                    onCashInOut: canUseCashInOut
                        ? () => showDialog(
                              context: context,
                              builder: (_) => CashInOutDialog(),
                            )
                        : () {},
                    onPrintKot: () async {
                      final kotD = ref.read(kotDetailsProvider);
                      final actD = ref.read(activeKotProvider);
                      final src = kotD['data'] ?? actD['data'];
                      if (src == null || (src is List && src.isEmpty)) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No job to print')));
                        }
                        return;
                      }
                      final rawList = src is List ? src : [src];
                      final first = rawList.isNotEmpty ? rawList[0] : null;
                      final firstRow = first is Map ? first : null;
                      final kotMasterId = firstRow != null
                          ? (int.tryParse((firstRow['KotMasterID'] ??
                                      firstRow['kotMasterID'] ??
                                      0)
                                  .toString()) ??
                              0)
                          : 0;
                      if (kotMasterId <= 0) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No job to print')));
                        }
                        return;
                      }
                      // Fetch fresh data from server to get correct Androidprint status
                      final fresh = await emptyKotDetails();
                      final freshData = fresh['data'];
                      final freshList = freshData is List
                          ? freshData
                          : (freshData != null ? [freshData] : <dynamic>[]);
                      // Type 1: Print KOT – only items with AndroidPrint='PENDING'
                      final pending = freshList.where((r) {
                        if (r is! Map) return false;
                        final ap = (r['AndroidPrint'] ??
                                r['Androidprint'] ??
                                r['androidprint'] ??
                                'PENDING')
                            .toString()
                            .toUpperCase();
                        return ap == 'PENDING';
                      }).toList();
                      if (pending.isEmpty) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (BuildContext ctx) => Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Container(
                                width: 400,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6)),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Center(
                                      child: Text(
                                        "Print Job",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF521C1D)),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No new items to print.\nAll items have already been printed.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF521C1D),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12)),
                                        child: const Text("OK",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      final supplyType = isTakeAwayView
                          ? 'PARCEL'
                          : (isDeliveryListView ? 'DELIVERY' : 'DINE IN');
                      await PosPrint.printKOT(
                        kotDetails: {'data': pending},
                        supplyType: supplyType,
                        title: 'JOB TICKET',
                        onError: (m) {
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(m)));
                          }
                        },
                      );
                      if (kotMasterId > 0) {
                        try {
                          final updated = await emptyKotDetails();
                          ref.read(kotDetailsProvider.notifier).state = updated;
                          ref.read(activeKotProvider.notifier).state = updated;
                        } catch (e) {
                          debugPrint('⚠️ markKotPrinted failed: $e');
                        }
                      }
                    },
                    onKotReprint: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              width: 400,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6)),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Center(
                                    child: Text(
                                      "Reprint Job",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF521C1D)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Are you sure you want to Reprint Job?",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 8)),
                                        child: const Text("No",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          debugPrint(
                                              'KOT reprint: YES pressed');
                                          Navigator.of(context).pop();
                                          final kotD =
                                              ref.read(kotDetailsProvider);
                                          final actD =
                                              ref.read(activeKotProvider);
                                          final src =
                                              kotD['data'] ?? actD['data'];
                                          if (src == null ||
                                              (src is List && src.isEmpty)) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'No job to reprint')));
                                            }
                                            return;
                                          }
                                          final supplyType = isTakeAwayView
                                              ? 'PARCEL'
                                              : (isDeliveryListView
                                                  ? 'DELIVERY'
                                                  : 'DINE IN');
                                          await PosPrint.printKOT(
                                            kotDetails:
                                                kotD.isNotEmpty ? kotD : actD,
                                            supplyType: supplyType,
                                            title: 'Duplicate Job',
                                            onError: (m) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(m)));
                                              }
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF521C1D),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 8)),
                                        child: const Text("Yes",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    onSaveKot: () async {
                      try {
                        final activeKot = ref.read(activeKotProvider);
                        final kotDataSrc = activeKot['data'];
                        final kotList = kotDataSrc is List ? kotDataSrc : null;
                        final firstRow = (kotList != null && kotList.isNotEmpty)
                            ? kotList[0] as Map<String, dynamic>?
                            : null;
                        final loadedKotMasterId = firstRow != null
                            ? (int.tryParse((firstRow['KotMasterID'] ??
                                        firstRow['kotMasterID'] ??
                                        0)
                                    .toString()) ??
                                0)
                            : 0;
                        final hasLoadedKot = loadedKotMasterId > 0;

                        final cart = ref.read(cartSnapshotProvider);
                        if (cart.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Add at least one item')));
                          return;
                        }

                        // Area/Chair: use loaded job context when we have one
                        String? areaId = ref.read(selectedAreaIdProvider);
                        String? tableId = ref.read(selectedTableIdProvider);
                        String? seatNo = ref.read(selectedSeatNoProvider);
                        if (hasLoadedKot && firstRow != null) {
                          areaId ??= (firstRow['AreaID'] ?? firstRow['areaID'])
                              ?.toString();
                          tableId ??=
                              (firstRow['TableID'] ?? firstRow['tableID'] ??
                                      firstRow['ChairID'])
                                  ?.toString();
                          seatNo ??=
                              (firstRow['ChairNo'] ?? firstRow['chairNo'])
                                  ?.toString();
                        }

                        if (!posUi.kotSaveWithoutArea &&
                            (areaId == null || areaId.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a section')));
                          return;
                        }

                        final custId = ref.read(selectedCustomerIdProvider);
                        final isWaiterMandatory =
                            ref.read(ISWaiterMandotoryProvider);

                        // When appending to a loaded job, only send NEW lines so
                        // existing ones are not duplicated on Save Job.
                        bool isNewCartLine(Map<String, String> p) {
                          final lineId = int.tryParse(
                                  (p['dgvKOTChildID'] ??
                                          p['LineID'] ??
                                          p['lineId'] ??
                                          '0')
                                      .toString()) ??
                              0;
                          return lineId <= 0;
                        }
                        final newLines = hasLoadedKot
                            ? cart.where(isNewCartLine).toList()
                            : cart;

                        // Loaded job + no new lines: treat as successful update
                        // of the same job (no API insert, no error).
                        if (hasLoadedKot && newLines.isEmpty) {
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.white,
                                title: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade700, size: 28),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Updated',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF521C1D),
                                      ),
                                    ),
                                  ],
                                ),
                                content: const Text(
                                  'Job updated. No new items to add.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF521C1D),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('OK',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }
                          // Refresh job details so grid/line ids stay in sync
                          try {
                            final refreshed = await ApiService()
                                .fetchKotDetails('$loadedKotMasterId');
                            if (mounted &&
                                refreshed['data'] is List &&
                                (refreshed['data'] as List).isNotEmpty) {
                              ref.read(kotDetailsProvider.notifier).state =
                                  refreshed;
                              ref.read(activeKotProvider.notifier).state =
                                  refreshed;
                            }
                          } catch (_) {}
                          return;
                        }

                        if (newLines.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Add at least one item')),
                          );
                          return;
                        }

                        final linesToSave = newLines;

                        double subTotal = 0, taxTotal = 0, grandTotal = 0;
                        final itemsPayload = linesToSave.map((p) {
                          final qty =
                              double.tryParse(p['quantity'] ?? '1') ?? 1.0;
                          final rate =
                              double.tryParse(p['UnitPrice'] ?? '0') ?? 0.0;
                          final taxP = double.tryParse(
                                  p['Tax1Rate'] ?? p['TaxPerc'] ?? '0') ??
                              0.0;
                          final st = qty * rate;
                          final taxA = st * taxP / 100.0;
                          final lt = st + taxA;

                          subTotal += st;
                          taxTotal += taxA;
                          grandTotal += lt;

                          return {
                            'ProductID': p['ProductID'],
                            'BarCode': p['BarCode'] ?? p['Barcode'] ?? '',
                            'UniqueProductID': p['UniqueProductID'] ?? '0',
                            'ItemName':
                                p['ShortDescription'] ?? p['Description'] ?? '',
                            'ShortDescription':
                                p['ShortDescription'] ?? p['Description'] ?? '',
                            'ItemCode': p['ItemCode'] ?? '',
                            'Qty': qty.toString(),
                            'PackQty': p['PackQty'] ?? '0',
                            'UnitCost': p['UnitCost'] ?? '0',
                            'UnitPrice': rate.toString(),
                            'SubTotal': st.toString(),
                            'TaxPerc': taxP.toString(),
                            'Tax1Rate': taxP.toString(),
                            'Tax1RateC': taxP.toString(),
                            'TaxAmount': taxA.toString(),
                            'Tax1AmountC': taxA.toString(),
                            'ItemDisc': p['ItemDisc'] ?? '0',
                            'ItemDiscount': p['ItemDisc'] ?? '0',
                            'LineTotal': lt.toString(),
                            'dgvGrpID': p['GroupID'] ?? p['dgvGrpID'] ?? '0',
                            'GroupID': p['GroupID'] ?? p['dgvGrpID'] ?? '0',
                            'Modifir': p['modifiers'] ?? '',
                            'AndroidPrint': p['AndroidPrint'] ?? 'PENDING',
                            'KOTDisplayStatus':
                                p['KOTDisplayStatus'] ?? 'PENDING',
                            'qtyadd': p['qtyadd'] ?? '',
                            'dgvKOTChildID': p['dgvKOTChildID'] ?? '0',
                            'StylistID': p['StylistID'] ??
                                SessionManager().staffID ??
                                '',
                            'LineType': p['LineType'] ??
                                p['ProductType'] ??
                                'PRODUCT',
                            'ProductType': p['ProductType'] ?? p['LineType'] ?? '',
                          };
                        }).toList();

                        final sm = SessionManager();
                        final stationId =
                            int.tryParse(sm.stationId ?? '0') ?? 0;
                        final staffName = sm.staffName ?? '';
                        final staffId = int.tryParse(sm.staffID ?? '0') ?? 0;

                        final payload = {
                          'StationID': stationId,
                          'stationId': stationId,
                          'mfAreaId': int.tryParse(areaId ?? '0') ?? 0,
                          'AreaID': int.tryParse(areaId ?? '0') ?? 0,
                          'mfTableID': (tableId == null || tableId.isEmpty)
                              ? 0
                              : int.tryParse(tableId) ?? 0,
                          'ChairID': (tableId == null || tableId.isEmpty)
                              ? 0
                              : int.tryParse(tableId) ?? 0,
                          'TableID': (tableId == null || tableId.isEmpty)
                              ? 0
                              : int.tryParse(tableId) ?? 0,
                          'mfChairNo': (seatNo == null || seatNo.isEmpty)
                              ? 0
                              : int.tryParse(seatNo) ?? 0,
                          'ISWaiterMandatory': isWaiterMandatory,
                          'mfCustomerID': (custId == null || custId.isEmpty)
                              ? 0
                              : int.tryParse(custId) ?? 0,
                          'CustomerID': (custId == null || custId.isEmpty)
                              ? 0
                              : int.tryParse(custId) ?? 0,
                          'PrimaryStylistID': staffId,
                          'gvCounterNo': stationId.toString(),
                          'gvUserName': staffName,
                          'gvCashierID': staffId,
                          'txtDiscount': 0,
                          'lblSubTotalAmt': subTotal,
                          'lblTax1Total': taxTotal,
                          'lblRound': 0,
                          'lblBillTotal': grandTotal,
                          'txtNoofCustomer': 0,
                          'txtRemarks': '',
                          'btnname': 'JobSave',
                          'Items': itemsPayload,
                        };

                        // Append to existing open job when one is already loaded
                        if (hasLoadedKot && firstRow != null) {
                          payload['CurrentJobID'] = loadedKotMasterId;
                          payload['CurrentKOTID'] = loadedKotMasterId;
                          payload['mfKotPrefix'] = (firstRow['KotPrefix'] ??
                                  firstRow['KOTPrefix'] ??
                                  firstRow['kotPrefix'] ??
                                  firstRow['JobNo'] ??
                                  '')
                              .toString();
                          payload['mfKotNo'] = (firstRow['KotNumber'] ??
                                  firstRow['KOTNumber'] ??
                                  firstRow['kotNumber'] ??
                                  firstRow['JobNo'] ??
                                  '')
                              .toString();
                        }

                        final result = await ApiService()
                            .saveKot(Map<String, dynamic>.from(payload));

                        if (!mounted) return;

                        final saveOk = result['ok'] == true ||
                            result['success'] == true;
                        if (saveOk) {
                          // Show success dialog immediately
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.white,
                                title: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade700, size: 28),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Success',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF521C1D),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  result['msg'] ??
                                      result['message'] ??
                                      'Job saved successfully.',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF521C1D),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('OK',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }

                          final currentKotId = result['CurrentKOTID'] ??
                              result['currentJobId'] ??
                              result['jobId'] ??
                              result['currentKotId'];
                          Map<String, dynamic>? savedKotDetails;
                          if (currentKotId != null &&
                              int.tryParse(currentKotId.toString()) != null &&
                              (int.tryParse(currentKotId.toString()) ?? 0) >
                                  0) {
                            try {
                              final kd = result['kotDetails'];
                              Map<String, dynamic> kotDetails;
                              if (kd is Map) {
                                kotDetails =
                                    Map<String, dynamic>.from(kd as Map);
                              } else if (result['data'] is List) {
                                kotDetails = {
                                  'success': true,
                                  'data': result['data'],
                                };
                              } else {
                                kotDetails = await ApiService()
                                    .fetchKotDetails(currentKotId.toString());
                              }
                              ref.read(kotDetailsProvider.notifier).state =
                                  kotDetails;
                              ref.read(activeKotProvider.notifier).state =
                                  kotDetails;
                              savedKotDetails = kotDetails;
                            } catch (_) {
                              // Keep previous job details if fetch fails
                            }
                          }

                          // Salon: no auto-print on Save Job (unlike restaurant KOT).
                          // Use Print Job / Job Reprint when a ticket is needed.

                          final clearAfter =
                              ref.read(ClearAfterKOTSaveProvider) == 1;
                          if (clearAfter) {
                            ref.read(cartSnapshotProvider.notifier).state =
                                const [];
                            widget.onKotReset?.call();
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(result['msg'] ??
                                    result['message'] ??
                                    'Failed to save job'),
                                backgroundColor: Colors.red),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        final msg =
                            e.toString().replaceFirst('Exception: ', '');
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            title: const Text('Save Job failed',
                                style: TextStyle(
                                    color: Color(0xFF521C1D),
                                    fontWeight: FontWeight.bold)),
                            content: Text(msg),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF780829)),
                                child: const Text('OK',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    onDiscount: () async {
                      var kotDetailsLocal = ref.read(kotDetailsProvider);
                      final activeKotLocal = ref.read(activeKotProvider);
                      var kotDataSrc =
                          kotDetailsLocal['data'] ?? activeKotLocal['data'];
                      if (kotDataSrc == null ||
                          kotDataSrc is! List ||
                          kotDataSrc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Select or load a job first (or tap Save Job).'),
                              backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      final firstRow = kotDataSrc[0] as Map<String, dynamic>;
                      final kotId = int.tryParse((firstRow['KotMasterID'] ??
                              firstRow['kotMasterID'] ??
                              0)
                          .toString());
                      if (kotId == null || kotId <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Invalid job. Load a saved job first.'),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }
                      double subTotal = 0;
                      double taxPerc = 0;
                      for (var p in kotDataSrc) {
                        final qty = _asDouble(p['Qty'] ?? p['qty'] ?? 1);
                        final rate =
                            _asDouble(p['UnitPrice'] ?? p['unitPrice'] ?? 0);
                        final disc = _asDouble(
                            p['ItemDiscount'] ?? p['itemDiscount'] ?? 0);
                        subTotal += (qty * rate) - disc;
                        if (taxPerc == 0)
                          taxPerc =
                              _asDouble(p['Tax1RateC'] ?? p['tax1RateC'] ?? 0);
                      }
                      final currentDisc = _asDouble(firstRow['BillDiscount'] ??
                          firstRow['billDiscount'] ??
                          0);
                      final tax1 = ref.read(tax1Provider);
                      if (tax1 != null && tax1 > 0) taxPerc = tax1;

                      if (!mounted) return;
                      final result = await showDialog<double>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => DiscountDialog(
                          kotId: kotId,
                          totalAmount: subTotal,
                          currentDiscount: currentDisc,
                          taxPercentage: taxPerc,
                        ),
                      );
                      if (!mounted || result == null) return;
                      try {
                        final kotDetails = await emptyKotDetails();
                        ref.read(kotDetailsProvider.notifier).state =
                            kotDetails;
                        ref.read(activeKotProvider.notifier).state = kotDetails;
                        if (mounted) setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Discount applied: ${result.toStringAsFixed(2)}'),
                            backgroundColor: const Color(0xFF521C1D),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Discount saved but failed to refresh job: $e'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                    onDummyBill: () {},
                    onBillPrint: () {},
                    onComments: () => showDialog(
                        context: context, builder: (_) => CommentsDialog()),
                    onSettlement: canUseSettlement
                        ? () {
                            _performSettlement();
                          }
                        : null,
                  ),

                  SizedBox(height: vGap),

                  // ✅ Search bar (keep same)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: veryShortH ? 1 : 2),
                    child: RightPanelSearchBar(
                      isSearchingByName: isSearchingByName,
                      isSearching: isSearching,
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onToggleNameCode: () {
                        _searchDebounce?.cancel();
                        setState(() {
                          isSearchingByName = !isSearchingByName;
                          searchController.clear();
                          searchResults = [];
                          isSearching = false;
                          selectedSearchIndex = -1;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          searchFocusNode.requestFocus();
                        });
                      },
                      onChanged: (query) {
                        selectedSearchIndex = -1;
                        if (!isSearchingByName) {
                          // Code mode: wait for Enter (barcode scan style)
                          setState(() {
                            searchResults = [];
                            isSearching = false;
                          });
                          return;
                        }
                        _searchDebounce?.cancel();
                        _searchDebounce =
                            Timer(const Duration(milliseconds: 280), () {
                          performSearch(query);
                        });
                      },
                      onSubmitted: (query) {
                        if (!isSearchingByName) {
                          _lookupCodeAndAdd(query);
                        } else if (selectedSearchIndex >= 0 &&
                            selectedSearchIndex < searchResults.length) {
                          _selectSearchItem(
                              searchResults[selectedSearchIndex]);
                        } else if (searchResults.length == 1) {
                          _selectSearchItem(searchResults.first);
                        } else if (searchResults.isNotEmpty) {
                          _selectSearchItem(searchResults.first);
                        } else {
                          performSearch(query);
                        }
                      },
                      onClear: () {
                        _searchDebounce?.cancel();
                        searchController.clear();
                        performSearch("");
                      },
                      hasActiveKOT: hasActiveKOT,
                      kotRow: hasActiveKOT ? kotData[0] : null,
                      isReturnBillAvailable: isReturnBillAvailable,
                      returnHeader: isReturnBillAvailable ? returnHeader : null,
                      areaLabelFallback: widget.areaName ?? selectedOrderType,
                      selectedSearchIndex: selectedSearchIndex,
                      searchResultsCount: searchResults.length,
                      onArrowDown: () {
                        if (searchResults.isEmpty) return;
                        setState(() {
                          if (selectedSearchIndex < 0) {
                            selectedSearchIndex = 0;
                          } else if (selectedSearchIndex <
                              searchResults.length - 1) {
                            selectedSearchIndex++;
                          }
                        });
                      },
                      onArrowUp: () {
                        if (searchResults.isEmpty) return;
                        setState(() {
                          if (selectedSearchIndex > 0) {
                            selectedSearchIndex--;
                          } else {
                            selectedSearchIndex = 0;
                          }
                        });
                      },
                      onEnterSelect: () {
                        if (selectedSearchIndex >= 0 &&
                            selectedSearchIndex < searchResults.length) {
                          _selectSearchItem(
                              searchResults[selectedSearchIndex]);
                        }
                      },
                    ),
                  ),

                  SizedBox(height: vGap),

                  // ✅ Keypad + actions (your same logic)
                  RightPanelKeypadActions(
                    isBaseVersion: widget.isBaseVersion,
                    enteredQty: enteredQty,
                    onKeypadAppend: _keypadAppend,
                    onKeypadDot: _keypadDot,
                    onKeypadBackspace: _keypadBackspace,
                    onTakeAwayList: showTakeAwayList,
                    onAreaChange: canUseAreas
                        ? () async {
                            final result =
                                await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (_) => AreaChangeDialog(),
                            );
                            if (!mounted || result == null) return;
                            final kotId = result['kotId']?.toString();
                            final areaId = result['areaId']?.toString();
                            final areaName = result['area']?.toString();
                            final tableId = result['tableId']?.toString();
                            final seatNo = result['seatNo']?.toString();
                            if (kotId == null || kotId == '0' || areaId == null)
                              return;
                            try {
                              final kotDetails = await emptyKotDetails();
                              ref.read(kotDetailsProvider.notifier).state =
                                  kotDetails;
                              ref.read(activeKotProvider.notifier).state =
                                  kotDetails;
                              ref.read(selectedAreaIdProvider.notifier).state =
                                  areaId;
                              ref
                                      .read(selectedAreaNameProvider.notifier)
                                      .state =
                                  areaName ?? result['area']?.toString();
                              ref.read(selectedTableIdProvider.notifier).state =
                                  tableId;
                              ref.read(selectedSeatNoProvider.notifier).state =
                                  seatNo;
                              if (mounted) setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Job moved to ${areaName ?? "new section"}${(tableId != null && tableId != "0") ? " · Chair $tableId" : ""}'),
                                  backgroundColor: const Color(0xFF521C1D),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Area updated but failed to refresh: $e'),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    onNoSale: () {},
                    onDeliveryList: canUseDelivery ? showDeliveryList : null,
                    onOrderList: () {
                      showJobListDialog(context);
                    },
                    onQtyCommit: _commitQty,
                    onReturn1: canUseReturnBill
                        ? () async {
                            final input = searchController.text.trim();

                            if (input.isNotEmpty &&
                                RegExp(r'^\d{6,}$').hasMatch(input)) {
                              try {
                                final billDetails = <String, dynamic>{};

                                if (billDetails.isNotEmpty) {
                                  ref.read(returnBillProvider.notifier).state =
                                      billDetails;
                                  setState(() {
                                    searchController.clear();
                                    enteredQty = "";
                                    isSearching = false;
                                    searchResults.clear();
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "No bill found for number $input"),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              ref.read(returnModeProvider.notifier).state =
                                  true;
                              setState(() {
                                searchController.clear();
                                enteredQty = "";
                                searchResults.clear();
                                isSearching = false;
                              });
                            }
                          }
                        : () {},
                    onDelivery: canUseDelivery
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DeliveryManagementDesktopPage(),
                              ),
                            );
                          }
                        : null,
                    onDirectSettlement: posUi.directSettlement
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DirectSettlement()),
                            );
                          }
                        : () {},
                    onItemCancel: canUseItemCancel
                        ? () {
                            final kotDetailsLocal = ref.read(activeKotProvider);
                            if (kotDetailsLocal.isNotEmpty) {
                              showDialog(
                                  context: context,
                                  builder: (_) => ItemRemoveDialog());
                            }
                          }
                        : () {},
                    onReceipts: () => showCreditSettlementDialog(context),
                    onSelectTable: canUseTables
                        ? () async {
                            final result = await showDialog<TableSeatSelection>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const TableSelectionDialog(),
                            );

                            if (result != null) {
                              // TODO: use result.areaId/tableId/seatNo
                            }
                          }
                        : null,
                    onSettlement: widget.isBaseVersion && canUseSettlement
                        ? () {
                            _performSettlement();
                          }
                        : null,
                    showNoSale: posUi.noSale,
                    showOrderList: posUi.orderList,
                    showQtyCommit: posUi.cartQtyControls,
                    showReturn: posUi.returnBill,
                    showDirectSettlement: posUi.directSettlement,
                    showReceipts: posUi.reprintBill,
                    showTakeAwayList: posUi.has(PosFeature.takeaway),
                    showItemCancel: canUseItemCancel,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
