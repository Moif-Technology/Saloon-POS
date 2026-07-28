import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/utils/sessionManager.dart';

class GroupDetailsDialog extends StatefulWidget {
  final Map<String, dynamic>? groupData; // Pass group data for editing

  GroupDetailsDialog({this.groupData});

  @override
  _GroupDetailsDialogState createState() => _GroupDetailsDialogState();
}

class _GroupDetailsDialogState extends State<GroupDetailsDialog> {
  final TextEditingController _groupCodeController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupNameArabicController =
      TextEditingController();
  bool showOnBackOffice = false;
  bool isLoading = false;
  late String dialogTitle;
  late String actionButtonText;

  @override
  void initState() {
    super.initState();

    if (widget.groupData != null) {
      // Editing case
      _groupCodeController.text =
          widget.groupData?['GroupCode']?.toString() ?? '';
      _groupNameController.text = widget.groupData?['GroupDescription'] ?? '';
      _groupNameArabicController.text =
          widget.groupData?['GroupDescriptionArabic'] ?? '';
      showOnBackOffice = (widget.groupData?['KeyShift'] ?? 1) == 0;
      dialogTitle = "Group Details Update";
      actionButtonText = "Update";
    } else {
      // New entry case
      dialogTitle = "Group Details Entry";
      actionButtonText = "Save";
    }
  }

  @override
  void dispose() {
    _groupCodeController.dispose();
    _groupNameController.dispose();
    _groupNameArabicController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    // Update is not available on the API yet (POST-only). Edit in the web app.
    if (widget.groupData != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Editing a group is only available in the ERP web app (Data entry → Group entry).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final groupCode = _groupCodeController.text.trim();
    final groupName = _groupNameController.text.trim();
    final groupNameArabic = _groupNameArabicController.text.trim();

    if (groupCode.isEmpty) {
      _showSnackBar("Please enter a group code");
      return;
    }
    if (groupName.isEmpty && groupNameArabic.isEmpty) {
      _showSnackBar("Please enter a group name or group name Arabic");
      return;
    }

    final branchId = int.tryParse(SessionManager().stationId?.trim() ?? '');
    if (branchId == null || branchId < 1) {
      _showSnackBar("Session error: branch not set. Please log in again.");
      return;
    }

    setState(() => isLoading = true);
    try {
      await ApiService().createGroup({
        "branchId": branchId,
        "groupCode": groupCode,
        "groupDescription": groupName.isEmpty ? null : groupName,
        "groupDescriptionArabic":
            groupNameArabic.isEmpty ? null : groupNameArabic,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "${groupName.isEmpty ? groupCode : groupName}" saved.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header with icon and title
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF521C1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    dialogTitle,
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

            // Material input fields
            _buildMaterialTextField(
              "Group Code",
              Icons.tag,
              _groupCodeController,
            ),
            _buildMaterialTextField(
              "Group Name",
              Icons.group,
              _groupNameController,
            ),
            _buildMaterialTextField(
              "Group Name Arabic",
              Icons.language,
              _groupNameArabicController,
            ),

            SizedBox(height: 16),

            // Checkbox for Show only on BackOffice
            Row(
              children: [
                Checkbox(
                  value: showOnBackOffice,
                  onChanged: (value) {
                    setState(() {
                      showOnBackOffice = value!;
                    });
                  },
                  activeColor: Color(0xFF521C1D),
                ),
                Text(
                  "Show only on BackOffice",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF521C1D),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),
            Divider(color: Colors.grey[300], thickness: 1),

            // Bottom action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.groupData == null) // Only show "New" if adding
                  _buildActionButton("New", Colors.green, () {
                    _groupCodeController.clear();
                    _groupNameController.clear();
                    _groupNameArabicController.clear();
                    setState(() {
                      showOnBackOffice = false;
                    });
                  }),
                _buildActionButton(isLoading ? "Saving…" : actionButtonText,
                    Colors.blue, isLoading ? () {} : _saveGroup),
                _buildActionButton("Close", Colors.red, () {
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Material Text Field
  Widget _buildMaterialTextField(
      String label, IconData icon, TextEditingController controller) {
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
      ),
    );
  }

  // Helper widget for action buttons
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
