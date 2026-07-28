import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/widgets/topPanelWidgets/NewEntryTab/area_entry.dart'; // Import your ApiService

class AreaListDialog extends StatefulWidget {
  @override
  _AreaListDialogState createState() => _AreaListDialogState();
}

class _AreaListDialogState extends State<AreaListDialog> {
  List<dynamic> _areas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }

  Future<void> _fetchAreas() async {
    try {
      final apiService = ApiService();
      final areas = await apiService.fetchAreas(fetchAll: true);
      if (mounted) {
        setState(() {
          _areas = areas;
          _isLoading = false;
        });
      }
      print(areas);
    } catch (error) {
      print("Error fetching areas: $error");
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          _isLoading = false;
        });
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
                  "Area List",
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
              child: Container(
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
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
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
                              DataColumn(label: Text("Area Name")),
                              DataColumn(label: Text("Prefix")),
                              DataColumn(label: Text("Price Level")),
                              DataColumn(label: Text("Actions")),
                            ],
                            rows: _generateAreaRows(context),
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

  // Generate rows for DataTable using API data
  List<DataRow> _generateAreaRows(BuildContext context) {
    if (_areas.isEmpty) {
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

    return _areas.map((area) {
      final areaName = area["AreaName"] ?? '';
      final prefix = area["KotPrefix"] ?? '';
      final priceLevel = area["PriceLevel"] ?? '';

      return DataRow(
        cells: [
          DataCell(Text(areaName, style: const TextStyle(fontSize: 14))),
          DataCell(Text(prefix, style: const TextStyle(fontSize: 14))),
          DataCell(Text(priceLevel, style: const TextStyle(fontSize: 14))),
          DataCell(
            Row(
              children: [
                _buildTableActionButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onTap: () => _editArea(context, area),
                ),
                SizedBox(width: 8),
                _buildTableActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: () => _deleteArea(context, area),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  // Edit area functionality (placeholder)
  void _editArea(BuildContext context, Map<String, dynamic> area) {
    print("Editing area with details: $area");

    // // Close the current dialog before opening a new one
    // Navigator.of(context).pop();

    // Open AreaDetailsEntryDialog as a dialog
    showDialog(
      context: context,
      builder: (context) => AreaDetailsEntryDialog(
        task: "Edit",
        existingArea: area,
      ),
    ).then((_) {
      _fetchAreas(); // Reload the areas after returning
    });
  }

  // Delete area functionality
  void _deleteArea(BuildContext context, Map<String, dynamic> area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete the area "${area['AreaName']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Area "${area['AreaName']}" deleted in mock mode.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _areas.removeWhere(
            (a) => a['AreaID']?.toString() == area['AreaID']?.toString(),
          );
        });
      }
    });
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
