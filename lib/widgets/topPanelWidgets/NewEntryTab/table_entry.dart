import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/utils/sessionManager.dart';

class TableDetailsDialog extends StatefulWidget {
  final Map<String, dynamic>? tableData;

  TableDetailsDialog({this.tableData});
  @override
  _TableDetailsDialogState createState() => _TableDetailsDialogState();
}

class _TableDetailsDialogState extends State<TableDetailsDialog> {
  List<dynamic> areaList = [];
  List<dynamic> waiterList = [];
  List<dynamic> _existingTables = [];
  String? selectedArea;
  String? selectedWaiter;
  String? tableId;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController tableNoController = TextEditingController();
  final TextEditingController tableNameController = TextEditingController();
  final TextEditingController tableNameArabicController =
      TextEditingController();
  final TextEditingController noOfChairsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _loadWaiters();
    if (widget.tableData != null) {
      tableId = widget.tableData!['TableID']?.toString();
      tableNoController.text = widget.tableData!['TableNO']?.toString() ?? '';
      tableNameController.text = widget.tableData!['TableName'] ?? '';
      tableNameArabicController.text =
          widget.tableData!['TableNameArabic'] ?? '';
      noOfChairsController.text =
          widget.tableData!['NoOfChairs']?.toString() ?? '';
      selectedArea = widget.tableData!['AreaId']?.toString();
      selectedWaiter = widget.tableData!['WaiterID']?.toString();
      if (selectedArea != null) _loadTablesForArea(selectedArea!);
    }
  }

  Future<void> _loadTablesForArea(String areaId) async {
    try {
      final tables = await ApiService().fetchTables(areaId: areaId);
      if (mounted) setState(() => _existingTables = tables);
    } catch (_) {
      if (mounted) setState(() => _existingTables = []);
    }
  }

  Future<void> _loadAreas() async {
    try {
      final areas = await ApiService().fetchAreas(fetchAll: true);
      // Edit mode: show all areas so existing area pre-fills correctly.
      // New entry: only manual (TableCreationType==0) areas need manual tables.
      final filteredAreas = widget.tableData != null
          ? areas
          : areas
              .where((a) => a['TableCreationType'].toString() == "0")
              .toList();
      setState(() {
        areaList = filteredAreas;
      });
    } catch (e) {
      print("Error fetching areas: $e");
    }
  }

  Future<void> _loadWaiters() async {
    try {
      final staff = await ApiService().fetchStaff();
      final waiters = staff
          .where((s) =>
              (s['roleName'] ?? '').toString().toLowerCase().contains('waiter'))
          .toList();
      if (mounted) setState(() => waiterList = waiters);
    } catch (_) {
      if (mounted) setState(() => waiterList = []);
    }
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) return;

    final branchId = int.tryParse(SessionManager().stationId?.trim() ?? '');
    if (branchId == null || branchId < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Session error: branch not set. Please log in again."),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select an area."),
            backgroundColor: Colors.red),
      );
      return;
    }

    final enteredNo   = tableNoController.text.trim();
    final enteredName = tableNameController.text.trim().toLowerCase();

    for (final t in _existingTables) {
      final sameTable = t['TableID']?.toString() == tableId; // skip self in edit
      if (sameTable) continue;
      if (t['TableNO']?.toString() == enteredNo) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Table No. $enteredNo already exists in this area.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if ((t['TableName'] ?? '').toString().toLowerCase() == enteredName) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Table name "${tableNameController.text.trim()}" already exists in this area.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final payload = {
      "branchId": branchId,
      "areaId": int.parse(selectedArea!),
      "tableNo": int.tryParse(tableNoController.text.trim()) ?? 0,
      "tableName": tableNameController.text.trim(),
      "tableNameArabic": tableNameArabicController.text.trim().isEmpty
          ? null
          : tableNameArabicController.text.trim(),
      "noOfChairs": int.tryParse(noOfChairsController.text.trim()) ?? 4,
    };

    try {
      await ApiService().createTable(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Table "${tableNameController.text.trim()}" saved.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool isSmallScreen = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: isSmallScreen ? screenWidth * 0.9 : 400,
        height: isSmallScreen ? screenHeight * 0.8 : 650,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Header with icon and title
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF521C1D),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_chart, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Table Details Entry",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Area Name Dropdown
                _buildAreaDropdown(),

                // Material input fields
                _buildMaterialTextField("Table No", Icons.format_list_numbered,
                    controller: tableNoController),
                _buildMaterialTextField("Table Name", Icons.table_bar,
                    controller: tableNameController),
                _buildMaterialTextField("Table Name Arabic", Icons.language,
                    controller: tableNameArabicController, optional: true),
                _buildMaterialTextField("No. of chairs", Icons.chair,
                    controller: noOfChairsController),

                // Waiter Dropdown
                _buildWaiterDropdown(),

                SizedBox(height: 16),
                Divider(color: Colors.grey[300], thickness: 1),

                // Bottom action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton("New", Colors.green, () {
                      tableNoController.clear();
                      tableNameController.clear();
                      tableNameArabicController.clear();
                      noOfChairsController.clear();
                      setState(() {
                        selectedArea = null;
                        selectedWaiter = null;
                      });
                    }),
                    _buildActionButton("Save", Colors.blue, _saveTable),
                    _buildActionButton("Close", Colors.red, () {
                      Navigator.of(context).pop();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Area Name Dropdown
  Widget _buildAreaDropdown() {
    final validSelectedArea =
        areaList.any((area) => area['AreaID'].toString() == selectedArea)
            ? selectedArea
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: validSelectedArea, // only assign if it's valid
        decoration: InputDecoration(
          labelText: "Area Name",
          prefixIcon: Icon(Icons.location_city, color: Color(0xFF521C1D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[200],
          labelStyle: TextStyle(color: Color(0xFF521C1D)),
        ),
        items: areaList.map((area) {
          return DropdownMenuItem<String>(
            value: area['AreaID'].toString(),
            child: Text(area['AreaName']),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedArea = value;
            _existingTables = [];
          });
          if (value != null) _loadTablesForArea(value);
        },
        validator: (value) => value == null ? "Please select an area" : null,
      ),
    );
  }

  // Waiter Dropdown — optional selection, always visible
  Widget _buildWaiterDropdown() {
    final validSelectedWaiter = waiterList.any(
            (w) => w['staffId']?.toString() == selectedWaiter)
        ? selectedWaiter
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: validSelectedWaiter,
        decoration: InputDecoration(
          labelText: "Waiter (optional)",
          prefixIcon: Icon(Icons.person, color: Color(0xFF521C1D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[200],
          labelStyle: TextStyle(color: Color(0xFF521C1D)),
        ),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('— none —')),
          ...waiterList.map((w) => DropdownMenuItem<String>(
                value: w['staffId']?.toString(),
                child: Text(w['staffName']?.toString() ?? ''),
              )),
        ],
        onChanged: (value) => setState(() => selectedWaiter = value),
      ),
    );
  }

  // Material Text Field
  Widget _buildMaterialTextField(String label, IconData icon,
      {TextEditingController? controller, bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF521C1D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[200],
          labelStyle: TextStyle(color: Color(0xFF521C1D)),
        ),
        validator: optional
            ? null
            : (value) =>
                value == null || value.isEmpty ? "Please enter $label" : null,
      ),
    );
  }

  // Action Button
  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
