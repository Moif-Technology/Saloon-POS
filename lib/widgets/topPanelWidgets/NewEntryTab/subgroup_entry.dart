import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/utils/sessionManager.dart';
import 'package:my_app/widgets/common/common_searchable_dropdown.dart';

class SubgroupDetailsDialog extends StatefulWidget {
  final Map<String, dynamic>? subGroupData;

  SubgroupDetailsDialog({this.subGroupData});

  @override
  _SubgroupDetailsDialogState createState() => _SubgroupDetailsDialogState();
}

class _SubgroupDetailsDialogState extends State<SubgroupDetailsDialog> {
  List<Map<String, dynamic>> groupData = [];
  Map<String, dynamic>? selectedGroup; // Stores the exact selected group
  int? selectedGroupId;

  final TextEditingController subGroupCodeController = TextEditingController();
  final TextEditingController subGroupNameController = TextEditingController();
  final TextEditingController subGroupNameArabicController =
      TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Print the initial data passed to the dialog
    print("📢 Initial SubGroupData: ${widget.subGroupData}");

    // Pre-fill the form fields
    subGroupCodeController.text =
        widget.subGroupData?["SubGroupCode"]?.toString() ?? "";
    subGroupNameController.text =
        widget.subGroupData?["SubGroupDescription"] ?? "";
    subGroupNameArabicController.text =
        widget.subGroupData?["SubGroupDescriptionArabic"] ?? "";

    // Parse GroupID as int for consistency
    selectedGroupId =
        int.tryParse(widget.subGroupData?["GroupID"]?.toString() ?? '');

    // Print the selected GroupID
    print("📢 Selected Group (on init): GroupID = $selectedGroupId");

    // Fetch groups data and pre-select the group if possible
    fetchGroupData();
  }

  bool isGroupDataLoading = true;

  Future<void> fetchGroupData() async {
    setState(() {
      isGroupDataLoading = true;
    });

    try {
      final List<dynamic> data = await ApiService().fetchGroups();
      setState(() {
        groupData = data.map((group) {
          return {
            "GroupID": group['GroupID'],
            "GroupDescription": group['GroupDescription'],
          };
        }).toList();

        // Preselect the group based on GroupDescription
        if (widget.subGroupData?["GroupDescription"] != null) {
          selectedGroup = groupData.firstWhere(
            (group) =>
                group["GroupDescription"] ==
                widget.subGroupData?["GroupDescription"],
            orElse: () => {}, // Fallback to empty map
          );

          if (selectedGroup!.isNotEmpty) {
            selectedGroupId =
                int.tryParse(selectedGroup?["GroupID"]?.toString() ?? '');
          } else {
            selectedGroup = null;
          }

          print("📢 Pre-selected Group: $selectedGroup");
        }
      });
    } catch (error) {
      print("Error fetching group data: $error");
    } finally {
      setState(() {
        isGroupDataLoading = false;
      });
    }
  }

  Future<void> saveSubGroup() async {
    // Update is not available on the API yet (POST-only). Edit in the web app.
    if (widget.subGroupData != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Editing a sub-group is only available in the ERP web app (Data entry → Sub group).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final subGroupCode = subGroupCodeController.text.trim();
    if (selectedGroupId == null ||
        subGroupCode.isEmpty ||
        subGroupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Please select a Group, enter a Sub Group code and a Sub Group name."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final branchId = int.tryParse(SessionManager().stationId?.trim() ?? '');
    if (branchId == null || branchId < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session error: branch not set. Please log in again."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final subGroupName = subGroupNameController.text.trim();
    final subGroupNameArabic = subGroupNameArabicController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      await ApiService().createSubGroup({
        "branchId": branchId,
        "groupId": selectedGroupId,
        "subGroupCode": subGroupCode,
        "subGroupDescription": subGroupName.isEmpty ? null : subGroupName,
        "subGroupDescriptionArabic":
            subGroupNameArabic.isEmpty ? null : subGroupNameArabic,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sub Group "$subGroupName" saved.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: isSmallScreen ? screenWidth * 0.9 : 350,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: isGroupDataLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Header
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF521C1D),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_work, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Sub Group Details Entry",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCustomDropdown(),
                  _buildMaterialTextField(
                      "Sub Group Code", Icons.tag, subGroupCodeController),
                  _buildMaterialTextField("Sub Group",
                      Icons.subdirectory_arrow_right, subGroupNameController),
                  _buildMaterialTextField("Arabic Sub Group Name",
                      Icons.category, subGroupNameArabicController),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300], thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(isLoading ? "Saving…" : "Save",
                          Colors.blue, isLoading ? () {} : saveSubGroup),
                      _buildActionButton("Close", Colors.red, () {
                        Navigator.of(context).pop();
                      }),
                    ],
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildCustomDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.flatware, color: const Color(0xFF521C1D)),
          const SizedBox(width: 8),
          Expanded(
            child: CustomSearchableDropdown(
              label: "Select Group",
              items: groupData, // List of available groups
              displayKey: "GroupDescription", // Key to display in dropdown
              initialSelectedItem: selectedGroup, // Prefill item
              onSelected: (selectedItem) {
                setState(() {
                  selectedGroup = selectedItem; // Update selected group
                  selectedGroupId =
                      int.tryParse(selectedItem?["GroupID"]?.toString() ?? '');
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialTextField(
      String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF521C1D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[200],
          labelStyle: const TextStyle(color: Color(0xFF521C1D)),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
