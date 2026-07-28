import 'package:flutter/material.dart';
import 'package:my_app/widgets/topPanelWidgets/top_panel_widgets_imports.dart';

class CounterCloseAdminDialog extends StatefulWidget {
  @override
  _CounterCloseAdminDialogState createState() =>
      _CounterCloseAdminDialogState();
}

class _CounterCloseAdminDialogState extends State<CounterCloseAdminDialog> {
  List<Map<String, dynamic>> staffList = [];
  String? selectedStaff; // ✅ Store StaffID, not StaffName
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffList();
  }

  Future<void> _loadStaffList() async {
    try {
      final data = <Map<String, dynamic>>[];
      print("Fetched Staff List:");
      print(data);
      setState(() {
        staffList = data;
        if (data.isNotEmpty) selectedStaff = data.first['StaffID'].toString(); // ✅ StaffID
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching staff list: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDropdownSection(),
                  const SizedBox(height: 30),
                  _buildBottomButtons(context),
                ],
              ),
      ),
    );
  }

  Widget _buildDropdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cashier Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFF521C1D), width: 1.5),
          ),
          child: DropdownButton<String>(
            value: selectedStaff,
            isExpanded: true,
            underline: SizedBox(),
            onChanged: (String? newValue) {
              setState(() => selectedStaff = newValue);
            },
            items: staffList.map<DropdownMenuItem<String>>((staff) {
              return DropdownMenuItem<String>(
                value: staff['StaffID'].toString(), // ✅ Use StaffID
                child: Text(
                  staff['StaffName'], // ✅ Show StaffName
                  style: TextStyle(color: Color(0xFF521C1D)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            if (selectedStaff == null) return;
            showDialog(
              context: context,
              useRootNavigator: true,
              builder: (BuildContext context) {
                return CounterCloseDialog(
                  selectedStaffId: selectedStaff, // ✅ Send StaffID
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Color(0xFF521C1D),
            backgroundColor: Colors.white,
            side: BorderSide(color: Color(0xFF521C1D)),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Counter Close',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF521C1D),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Close',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
