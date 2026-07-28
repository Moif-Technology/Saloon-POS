import 'package:flutter/material.dart';

/// Uses app theme: primary Color(0xFF521C1D), background 0xfff8f8ff
class AreaChangeDialog extends StatefulWidget {
  @override
  State<AreaChangeDialog> createState() => _AreaChangeDialogState();
}

class _AreaChangeDialogState extends State<AreaChangeDialog> {
  static const Color _primary = Color(0xFF521C1D);
  static const Color _appBackground = Color(0xfff8f8ff);

  // Data
  List<Map<String, String>> kots = [];
  List<String> areas = [];
  Map<String, Color> areaColors = {
    'TAKE AWAY': const Color(0xFF2196F3),
    'DELIVERY': const Color(0xFF4CAF50),
    'FAMILY': const Color(0xFFFF9800),
    'HALL': const Color(0xFF9C27B0),
    'DINE IN': const Color(0xFFE53935),
  };
  Map<String, List<String>> areaTables = {};
  Map<String, String> tableMap = {};
  Map<String, String> areaMap = {};
  Map<String, List<String>> tableChairs = {};
  Map<String, List<String>> chairMapping = {};

  // Selection (tap only – no drag)
  String? selectedKot;
  String? selectedKotId;
  String? selectedArea;
  String? selectedTable;
  List<String> selectedChairs = [];

  List<Map<String, String>> displayedKots = [];
  bool _loading = true;
  String? _loadError;

  static const double _cardRadius = 12.0;
  static const double _buttonRadius = 10.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final responseData = <String, dynamic>{
        'kotList': <dynamic>[],
        'areaList': <dynamic>[],
        'tableList': <dynamic>[],
      };
      if (!mounted) return;
      setState(() {
        kots = (responseData["kotList"] as List<dynamic>).map((kot) {
          final raw = kot as Map<String, dynamic>;
          // Support both KotMasterID and kotMasterID (driver/DB casing may vary)
          final id = (raw["KotMasterID"] ?? raw["kotMasterID"])?.toString();
          return {
            "id": (id != null && id != "" && id != "0") ? id : "0",
            "name": "${raw["KotPrefix"] ?? ''}${raw["KotNumber"] ?? ''}",
            "area": raw["AreaName"]?.toString() ?? raw["areaName"]?.toString() ?? "Unknown",
            "table": raw["TableName"]?.toString() ?? raw["tableName"]?.toString() ?? "No Table",
            "chairs": raw["ChairNo"] != null ? raw["ChairNo"].toString() : "None",
          };
        }).toList();

        areas = (responseData["areaList"] as List<dynamic>).map((area) {
          areaMap[area["AreaName"].toString()] = area["AreaID"].toString();
          return area["AreaName"].toString();
        }).toList();

        areaTables = {};
        tableChairs = {};
        chairMapping = {};
        tableMap = {};

        for (var table in responseData["tableList"]) {
          String areaName = responseData["areaList"].firstWhere(
            (area) => area["AreaID"] == table["AreaID"],
            orElse: () => {"AreaName": "Unknown"},
          )["AreaName"];

          String tableName = table["TableName"].toString();
          String tableID = table["TableID"].toString();
          int noOfChairs = table["NoOfChairs"] is int
              ? table["NoOfChairs"]
              : int.tryParse(table["NoOfChairs"].toString()) ?? 0;

          if (!areaTables.containsKey(areaName)) {
            areaTables[areaName] = [];
          }
          areaTables[areaName]!.add(tableName);
          tableMap[tableName] = tableID;
          tableChairs[tableName] = noOfChairs > 0
              ? List.generate(noOfChairs, (i) => "Chair ${i + 1}")
              : [];

          if (table["KotMasterID"] != null) {
            chairMapping[tableName] ??= [];
            chairMapping[tableName]!.add(table["ChairNo"].toString());
          }
        }

        displayedKots = List.from(kots);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  bool get _areaHasTables =>
      selectedArea != null &&
      areaTables.containsKey(selectedArea) &&
      areaTables[selectedArea]!.isNotEmpty;

  bool get _canSubmit {
    if (selectedKot == null || selectedArea == null) return false;
    if (_areaHasTables && (selectedTable == null || selectedTable!.isEmpty)) return false;
    return true;
  }

  void _clearSelection() {
    setState(() {
      selectedKot = null;
      selectedArea = null;
      selectedTable = null;
      selectedChairs.clear();
      displayedKots = List.from(kots);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: _appBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildHeader(),
              if (_loading) _buildLoading(),
              if (_loadError != null) _buildError(),
              if (!_loading && _loadError == null) ...[
                _buildStepSummary(),
                Expanded(child: _buildContent()),
                _buildFooter(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
            child: const Icon(Icons.swap_horiz, color: _primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Change Area",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Move a KOT to a different area, table or chair",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.grey[600]),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _stepChip("1", "KOT", selectedKot ?? "—", Icons.receipt_long),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 18, color: Colors.grey[400]),
          ),
          _stepChip("2", "Area", selectedArea ?? "—", Icons.place),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 18, color: Colors.grey[400]),
          ),
          _stepChip("3", "Table", selectedTable ?? (_areaHasTables ? "—" : "N/A"), Icons.table_restaurant),
          if (selectedTable != null && tableChairs.containsKey(selectedTable)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 18, color: Colors.grey[400]),
            ),
            _stepChip("4", "Chair", selectedChairs.isNotEmpty ? selectedChairs.join(", ") : "—", Icons.chair),
          ],
          const Spacer(),
          TextButton.icon(
            onPressed: (selectedKot != null || selectedArea != null) ? _clearSelection : null,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Clear"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepChip(String step, String label, String value, IconData icon) {
    final hasValue = value != "—" && value != "N/A";
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue ? _primary.withOpacity(0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasValue ? _primary.withOpacity(0.3) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              step,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasValue ? _primary : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: hasValue ? _primary : Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? Colors.grey[800] : Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: KOT list + filter
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.22,
            child: _buildKotSection(),
          ),
          const SizedBox(width: 20),
          Expanded(child: _buildDestinationSection()),
        ],
      ),
    );
  }

  Widget _buildKotSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                "Select KOT",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip("All", displayedKots.length == kots.length, () {
                  setState(() => displayedKots = List.from(kots));
                }),
                ...areas.map((a) => _filterChip(a, displayedKots.length != kots.length && displayedKots.every((k) => k['area'] == a), () {
                  setState(() => displayedKots = kots.where((k) => k['area'] == a).toList());
                })),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: displayedKots.length,
              itemBuilder: (context, i) {
                final kot = displayedKots[i];
                final isSelected = selectedKot == kot["name"];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedKot = kot["name"];
                          selectedKotId = kot["id"];
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (areaColors[kot['area']] ?? Colors.grey).withOpacity(0.2)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? (areaColors[kot['area']] ?? Colors.grey)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (areaColors[kot['area']] ?? Colors.grey).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.receipt, color: areaColors[kot['area']] ?? Colors.grey, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    kot["name"] ?? "",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    "${kot["area"]} · ${kot["table"]}",
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected) Icon(Icons.check_circle, color: _primary, size: 20),
                          ],
                        ),
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

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: active,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade100,
        selectedColor: _primary.withOpacity(0.2),
        checkmarkColor: _primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDestinationSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Areas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.place, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      "New area",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: areas.map((area) {
                    final isSelected = selectedArea == area;
                    final color = areaColors[area] ?? Colors.grey;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedArea = area;
                            selectedTable = null;
                            selectedChairs.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(_buttonRadius),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(_buttonRadius),
                            border: Border.all(
                              color: isSelected ? color : color.withOpacity(0.4),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                size: 18,
                                color: isSelected ? Colors.white : color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                area,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (_areaHasTables) ...[
            const SizedBox(height: 16),
            _buildTablesAndChairs(),
          ],
        ],
      ),
    );
  }

  Widget _buildTablesAndChairs() {
    final tables = areaTables[selectedArea]!.toSet().toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_restaurant, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                "Table & chair",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tables.map((table) {
              final isSelected = selectedTable == table;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedTable = table;
                      selectedChairs.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? _primary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.table_bar,
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          table,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedTable != null && tableChairs.containsKey(selectedTable)) ...[
            const SizedBox(height: 16),
            Text(
              "Chair",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tableChairs[selectedTable]!.map((chair) {
                final chairNum = chair.split(' ')[1];
                final occupied = chairMapping[selectedTable]?.contains(chairNum) ?? false;
                final isSelected = selectedChairs.contains(chair);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (occupied) {
                        _showValidationErrorDialog();
                        return;
                      }
                      setState(() {
                        selectedChairs.clear();
                        selectedChairs.add(chair);
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: occupied
                            ? Colors.red.shade50
                            : isSelected
                                ? _primary
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: occupied
                              ? Colors.red.shade200
                              : isSelected
                                  ? _primary
                                  : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chair_outlined,
                            size: 16,
                            color: occupied
                                ? Colors.red
                                : isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            chairNum,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: occupied
                                  ? Colors.red
                                  : isSelected
                                      ? Colors.white
                                      : Colors.grey[800],
                            ),
                          ),
                          if (occupied) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.lock, size: 14, color: Colors.red[700]),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Text(
            _canSubmit
                ? "Ready to move KOT to $selectedArea${selectedTable != null ? " · $selectedTable" : ""}"
                : "Select KOT, then new area${_areaHasTables ? ", table and optional chair" : ""}",
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _canSubmit ? _submit : null,
            icon: const Icon(Icons.swap_horiz, size: 20),
            label: const Text("Move KOT"),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    String? kotId = selectedKotId;
    // If ID is missing or "0" but user has selected a KOT by name, resolve from list
    if ((kotId == null || kotId == "0") && selectedKot != null) {
      final matches = kots.where((k) => k["name"] == selectedKot).toList();
      if (matches.isNotEmpty) {
        final id = matches.first["id"];
        if (id != null && id != "0") kotId = id;
      }
    }

    String? areaId = areaMap[selectedArea];
    String? tableId = tableMap[selectedTable] ?? "0";
    List<String> chairNumbers = selectedChairs.map((c) => c.split(' ')[1]).toList();

    if (kotId == null || areaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a KOT and area")),
      );
      return;
    }
    if (kotId == "0") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid KOT selection. Please select a KOT from the list.")),
      );
      return;
    }

    final areaRequiresTable = _areaHasTables;
    if (areaRequiresTable && (tableId == "0" || selectedTable == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a table for this area")),
      );
      return;
    }

    var response = <String, dynamic>{'success': true};

    if (!mounted) return;
    if (response["success"] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed to move KOT"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Success: pop with result; right panel will show friendly message with area/table names
    final kotIdForResult = kotId;
    final areaIdForResult = areaMap[selectedArea];
    Navigator.pop(context, {
        'kotId': kotIdForResult,
        'kot': selectedKot,
        'areaId': areaIdForResult,
        'area': selectedArea,
        'tableId': tableId,
        'chairs': selectedChairs,
        'seatNo': selectedChairs.isNotEmpty ? selectedChairs.first.split(' ')[1] : null,
      });
  }

  Widget _buildLoading() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _primary),
            SizedBox(height: 16),
            Text("Loading KOTs and areas...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                "Could not load data",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError ?? "Unknown error",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showValidationErrorDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: _primary),
            SizedBox(width: 12),
            Text("Chair in use"),
          ],
        ),
        content: const Text("This chair already has a KOT. Please choose another chair."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
