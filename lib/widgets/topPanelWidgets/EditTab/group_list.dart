import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/widgets/topPanelWidgets/NewEntryTab/group_entry.dart';

class GroupListDialog extends StatefulWidget {
  @override
  _GroupListDialogState createState() => _GroupListDialogState();
}

class _GroupListDialogState extends State<GroupListDialog> {
  final ApiService _apiService = ApiService();
  List<dynamic> _groups = [];
  List<dynamic> _filteredGroups = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Print when dialog opens
    debugPrint('[GroupListDialog] initState -> Dialog opened');

    _fetchGroups();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isKeyShiftOne(dynamic v) {
    if (v == null) return false;
    final s = v.toString().trim();
    return s == '1';
  }

  void _printSample(String stage, List list, {int sample = 10}) {
    debugPrint('[$stage] count=${list.length}');
    for (int i = 0; i < list.length && i < sample; i++) {
      final g = list[i];
      if (g is Map) {
        debugPrint(
          '[$stage][$i] '
          'GroupID=${g['GroupID']}, '
          'GroupDescription=${g['GroupDescription']}, '
          'KeyShift=${g['KeyShift']}',
        );
      } else {
        debugPrint('[$stage][$i] $g');
      }
    }
    if (list.length > sample) {
      debugPrint('[$stage] …and ${list.length - sample} more');
    }
  }

  Future<void> _fetchGroups() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      debugPrint('[GroupListDialog] _fetchGroups -> start');

      final groups = await _apiService.fetchGroups();
      if (groups == null) {
        debugPrint('[GroupListDialog] _fetchGroups -> API returned null');
      } else {
        debugPrint(
            '[GroupListDialog] _fetchGroups -> API returned list of length ${(groups as List).length}');
      }
      _printSample('RAW_FROM_API', (groups as List? ?? const []));

      // robust filter: KeyShift can be int or string
      final filteredGroups = (groups as List? ?? const []).where((group) {
        try {
          final keyShift = (group as Map?)?['KeyShift'];
          return _isKeyShiftOne(keyShift);
        } catch (_) {
          return false;
        }
      }).toList();

      _printSample('AFTER_FILTER(KeyShift==1)', filteredGroups);

      if (!mounted) return;
      setState(() {
        _groups = filteredGroups;
        _filteredGroups = List.from(_groups);
        _isLoading = false;
      });

      debugPrint('[GroupListDialog] _fetchGroups -> done, '
          '_groups=${_groups.length}, _filteredGroups=${_filteredGroups.length}, _isLoading=$_isLoading');
    } catch (error) {
      debugPrint('[GroupListDialog] _fetchGroups -> ERROR: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load groups: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSearchChanged() {
    final searchTerm = _searchController.text.toLowerCase().trim();
    if (!mounted) return;
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredGroups = List.from(_groups);
        debugPrint(
            '[GroupListDialog] SEARCH: empty -> show all (${_filteredGroups.length})');
      } else {
        _filteredGroups = _groups.where((group) {
          final groupDescription =
              (group['GroupDescription'] ?? '').toString().toLowerCase();
          return groupDescription.contains(searchTerm);
        }).toList();
        debugPrint(
            '[GroupListDialog] SEARCH: "$searchTerm" -> matched ${_filteredGroups.length}');
      }
    });
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
                  "Group List",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: "Search Group Name",
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF521C1D)),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // DataTable
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                                const Color(0xFF521C1D)),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            columns: const [
                              DataColumn(label: Text("Group Name")),
                              DataColumn(label: Text("Order By")),
                              DataColumn(label: Text("Actions")),
                            ],
                            rows: _generateGroupRows(context),
                          ),
                        ),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIconButton(
                      Icons.check_circle, "Select", Colors.green, () {}),
                  _buildIconButton(Icons.update, "Update", Colors.blue, () {}),
                  _buildIconButton(
                      Icons.refresh, "Reset", Colors.orange, () {}),
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

  List<DataRow> _generateGroupRows(BuildContext context) {
    if (_filteredGroups.isEmpty) {
      debugPrint('[GroupListDialog] BUILD_ROWS -> No data to show');
      return const [
        DataRow(
          cells: [
            DataCell(Text('No data available')),
            DataCell(Text('')),
            DataCell(Text('')),
          ],
        ),
      ];
    }

    // print each row we actually render
    for (final group in _filteredGroups) {
      debugPrint('[GroupListDialog] BUILD_ROWS -> '
          'GroupDescription=${group["GroupDescription"]} | KeyShift=${group["KeyShift"]}');
    }

    return _filteredGroups.map((group) {
      return DataRow(
        cells: [
          DataCell(Text(group["GroupDescription"]?.toString() ?? "")),
          DataCell(Text(group["KeyShift"]?.toString() ?? "")),
          DataCell(
            Row(
              children: [
                _buildTableActionButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onTap: () => _editGroup(Map<String, dynamic>.from(group)),
                ),
                const SizedBox(width: 8),
                _buildTableActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  void _editGroup(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => GroupDetailsDialog(
        groupData: group,
      ),
    ).then((_) => _fetchGroups());
  }

  Widget _buildIconButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(icon, size: 20, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

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
      ),
    );
  }
}
