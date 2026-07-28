import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/widgets/topPanelWidgets/NewEntryTab/table_entry.dart';

class TableListDialog extends StatefulWidget {
  @override
  _TableListDialogState createState() => _TableListDialogState();
}

class _TableListDialogState extends State<TableListDialog> {
  List<dynamic> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.fetchAreas(fetchAll: true),
        api.fetchTables(),
      ]);
      final areas = results[0];
      final tables = results[1];

      final areaMap = {
        for (final a in areas) a['AreaID'].toString(): a['AreaName'] ?? '',
      };

      final annotated = tables.map((t) {
        final m = Map<String, dynamic>.from(t as Map);
        m['AreaName'] = areaMap[m['AreaID']?.toString()] ?? '';
        return m;
      }).toList();

      if (mounted) {
        setState(() {
          _tables = annotated;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tables: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 550,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Text(
                  "Table List",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Scrollable DataTable Container
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                                const Color(0xFF521C1D)),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            dataRowColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.hovered)
                                  ? Colors.grey[100]
                                  : Colors.white,
                            ),
                            dataRowHeight: 50,
                            columnSpacing: 24,
                            columns: const [
                              DataColumn(label: Text("Table No")),
                              DataColumn(label: Text("Table Name")),
                              DataColumn(label: Text("Area Name")),
                              DataColumn(label: Text("Actions")),
                            ],
                            rows: _generateTableRows(context),
                          ),
                        ),
                      ),
                    ),
            ),

            // Bottom action buttons (Icon + Text buttons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIconButton(Icons.check_circle, "Select", Colors.green,
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Select action performed')),
                    );
                  }),
                  _buildIconButton(Icons.close, "Close", Colors.red, () {
                    Navigator.of(context).pop();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate rows dynamically from API data
  List<DataRow> _generateTableRows(BuildContext context) {
    if (_tables.isEmpty) {
      return [
        DataRow(
          cells: [
            DataCell(Text('No data available')),
            DataCell(Text('')),
            DataCell(Text('')),
            DataCell(Text('')),
          ],
        ),
      ];
    }

    return _tables.map((table) {
      return DataRow(
        cells: [
          DataCell(Text(table["TableNO"]?.toString() ?? "",
              style: const TextStyle(fontSize: 14))),
          DataCell(Text(table["TableName"] ?? "",
              style: const TextStyle(fontSize: 14))),
          DataCell(Text(table["AreaName"] ?? "",
              style: const TextStyle(fontSize: 14))),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => TableDetailsDialog(tableData: table),
                    ).then((result) {
                      if (result == true) _fetchTables();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  // Helper widget for bottom icon buttons (Icon + Text)
  Widget _buildIconButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(icon, size: 20, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper widget for table action buttons (Background + Icon Only)
  Widget _buildTableActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
        tooltip: icon == Icons.edit ? 'Edit' : 'Delete',
      ),
    );
  }
}
