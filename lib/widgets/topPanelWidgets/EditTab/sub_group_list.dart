import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/widgets/common/common_searchable_dropdown.dart';
import 'package:my_app/widgets/topPanelWidgets/NewEntryTab/subgroup_entry.dart';

class SubGroupListDialog extends StatefulWidget {
  @override
  _SubGroupListDialogState createState() => _SubGroupListDialogState();
}

class _SubGroupListDialogState extends State<SubGroupListDialog> {
  final TextEditingController subGroupNameController = TextEditingController();
  String? selectedGroupDescription;
  String? selectedGroupId;
  List<Map<String, dynamic>> groupData = [];
  List<Map<String, dynamic>> subGroupData = [];

  @override
  void initState() {
    super.initState();
    fetchGroupData();
  }

  Future<void> fetchGroupData() async {
    try {
      final List<dynamic> data = await ApiService().fetchGroups();
      setState(() {
        groupData = data.map((group) {
          return {
            "GroupID": group['GroupID'],
            "GroupDescription": group['GroupDescription'] ?? "No Description",
          };
        }).toList();
      });
    } catch (error) {
      print("Error fetching group data: $error");
    }
  }

  Future<void> fetchSubGroupData(String? groupId) async {
    if (groupId == null) return;
    try {
      final List<dynamic> data = await ApiService().fetchSubGroups();
      setState(() {
        subGroupData = data
            .where((subGroup) => subGroup['GroupID'].toString() == groupId)
            .map((subGroup) {
          // Find the GroupDescription from groupData
          final group = groupData.firstWhere(
            (group) => group["GroupID"].toString() == groupId,
            orElse: () => {"GroupDescription": "No Description"},
          );

          return {
            "SubGroupID": subGroup['SubGroupID'],
            "SubGroupDescription": subGroup['SubGroupDescription'],
            "SubGroupDescriptionArabic": subGroup['SubGroupDescriptionArabic'],
            "GroupID": subGroup['GroupID'],
            "GroupDescription":
                group["GroupDescription"], // Add GroupDescription
          };
        }).toList();
      });
    } catch (error) {
      print("Error Fetching SubGroups: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: const Center(
                child: Text(
                  "Sub Group List",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // CustomSearchableDropdown for Group Description
            SizedBox(
              width: double.infinity,
              child: CustomSearchableDropdown(
                label: "Select Group",
                items: groupData,
                displayKey: "GroupDescription",
                onSelected: (selectedItem) {
                  setState(() {
                    selectedGroupId = selectedItem?['GroupID'].toString();
                    selectedGroupDescription =
                        selectedItem?['GroupDescription'];
                    fetchSubGroupData(selectedGroupId);
                  });
                },
              ),
            ),
            const SizedBox(height: 8),

            // Sub Group Name Text Field
            SizedBox(
              width: double.infinity,
              child:
                  _buildTextField("Search Sub Group", subGroupNameController),
            ),
            const SizedBox(height: 12),

            // DataTable for Sub Group List with edit and delete actions
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFF521C1D)),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  dataRowHeight: 40,
                  columns: const [
                    DataColumn(label: Text("Sub Group Name")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: _generateSubGroupRows(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton("Close", Colors.red, onClose: () {
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      style: TextStyle(fontSize: 14),
    );
  }

  List<DataRow> _generateSubGroupRows() {
    if (subGroupData.isEmpty) {
      return [
        DataRow(
          cells: [
            DataCell(Text("No Sub Groups Available")),
            DataCell(Row()),
          ],
        ),
      ];
    }

    return subGroupData.map((subGroup) {
      return DataRow(
        cells: [
          DataCell(Text(subGroup["SubGroupDescription"] ?? "",
              style: const TextStyle(fontSize: 14))),
          DataCell(
            Row(
              children: [
                _buildTableActionButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onTap: () {
                    // Open the SubgroupDetailsDialog with pre-filled data
                    print("📢 Data Sent to SubgroupDetailsDialog: $subGroup");
                    showDialog(
                      context: context,
                      builder: (_) => SubgroupDetailsDialog(
                        subGroupData: subGroup,
                      ),
                    );
                  },
                ),
                SizedBox(width: 8),
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

  Widget _buildTableActionButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
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

  Widget _buildActionButton(String label, Color color,
      {VoidCallback? onClose}) {
    return ElevatedButton(
      onPressed: onClose ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
