import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/utils/sessionManager.dart';

class AreaDetailsEntryDialog extends StatefulWidget {
  final String task; // "New" or "Edit"
  final Map<String, dynamic>? existingArea; // For editing existing area

  AreaDetailsEntryDialog({required this.task, this.existingArea});

  @override
  _AreaDetailsEntryDialogState createState() => _AreaDetailsEntryDialogState();
}

class _AreaDetailsEntryDialogState extends State<AreaDetailsEntryDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form inputs
  final TextEditingController _areaNameController = TextEditingController();
  final TextEditingController _areaNameArabicController =
      TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  String? _supplyType;
  String? _priceLevel;
  bool isManualSelected = true;
  bool showOnTablet = true;

  @override
  void initState() {
    super.initState();

    // Pre-fill fields if editing
    if (widget.task == "Edit" && widget.existingArea != null) {
      final area = widget.existingArea!;
      _areaNameController.text = area['AreaName'] ?? '';
      _areaNameArabicController.text = area['AreaNameArabic'] ?? '';
      _prefixController.text = area['KotPrefix'] ?? '';
      _supplyType = area['SupplyType'];
      _priceLevel = area['PriceLevel']
          ?.toUpperCase(); // Convert to uppercase if necessary
      isManualSelected = (area['TableCreationType'] ?? 1) == 0;
      showOnTablet = area['isTabletShow'] ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine if we are on a small screen
    final bool isSmallScreen = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: isSmallScreen ? screenWidth * 0.9 : 400,
        height: isSmallScreen ? screenHeight * 0.8 : 600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            SizedBox(height: 16),

            // Form fields inside an Expanded widget to allow scrolling if needed
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMaterialTextField(
                        "Area Name", _areaNameController, Icons.location_city),
                    _buildMaterialTextField("Area Name Arabic",
                        _areaNameArabicController, Icons.language),
                    _buildDropdownField(
                        "Supply Type", Icons.local_shipping, _supplyType,
                        (value) {
                      setState(() {
                        _supplyType = value;
                      });
                    }, ["GENERAL", "DINE_IN", "PARCEL", "DELIVERY", "TAKEAWAY"]),

                    _buildMaterialTextField(
                        "Prefix", _prefixController, Icons.short_text),
                    _buildDropdownField(
                        "Price Type", Icons.attach_money, _priceLevel, (value) {
                      setState(() {
                        _priceLevel = value;
                      });
                    }, ["NORMAL", "PRICE LEVEL 1", "PRICE LEVEL 2"]),

                    SizedBox(height: 12),
                    Divider(color: Colors.grey[300], thickness: 1),

                    // Table Creation Type
                    _buildTableCreationType(),

                    // Show on Tablet
                    _buildShowOnTablet(),

                    SizedBox(height: 12),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                ),
              ),
            ),

            // Action buttons fixed at the bottom
            SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF521C1D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            widget.task == "New" ? "New Area Entry" : "Edit Area Details",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialTextField(
      String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        validator: (value) => value!.isEmpty ? "$label is required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF521C1D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, IconData icon, String? value,
      void Function(String?) onChanged, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF521C1D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        items: items
            .map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTableCreationType() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _customRadioButton("Manual", isManualSelected, () {
          setState(() {
            isManualSelected = true;
          });
        }),
        SizedBox(width: 16),
        _customRadioButton("Automatic", !isManualSelected, () {
          setState(() {
            isManualSelected = false;
          });
        }),
      ],
    );
  }

  Widget _buildShowOnTablet() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Switch(
          value: showOnTablet,
          onChanged: (value) {
            setState(() {
              showOnTablet = value;
            });
          },
          activeColor: Color(0xFF521C1D),
        ),
        Text(
          "Show on Tablet",
          style: TextStyle(fontSize: 14, color: Color(0xFF521C1D)),
        ),
      ],
    );
  }

  Widget _customRadioButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF521C1D), width: 2),
              color: isSelected ? Color(0xFF521C1D) : Colors.transparent,
            ),
            child: isSelected
                ? Center(
                    child: Icon(Icons.circle, color: Colors.white, size: 10),
                  )
                : Container(),
          ),
          SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 14, color: Color(0xFF521C1D))),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton("Save", Colors.blue, _saveArea),
        _buildActionButton("Close", Colors.red, () {
          Navigator.of(context).pop();
        }),
      ],
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _saveArea() async {
    if (_areaNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Area Name is required"),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_supplyType == null || _supplyType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Supply Type is required"),
            backgroundColor: Colors.red),
      );
      return;
    }

    final branchId = int.tryParse(SessionManager().stationId?.trim() ?? '');
    if (branchId == null || branchId < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Session error: branch not set. Please log in again."),
            backgroundColor: Colors.red),
      );
      return;
    }

    final payload = {
      "branchId": branchId,
      "areaName": _areaNameController.text.trim(),
      "areaNameArabic": _areaNameArabicController.text.trim().isEmpty
          ? null
          : _areaNameArabicController.text.trim(),
      "supplyType": _supplyType,
      "kotPrefix": _prefixController.text.trim().isEmpty
          ? null
          : _prefixController.text.trim(),
      "isTabletShow": showOnTablet,
      "tableCreationType": isManualSelected ? 0 : 1,
    };

    try {
      await ApiService().createArea(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Area "${_areaNameController.text.trim()}" saved.'),
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
  void dispose() {
    // Dispose of controllers to free up resources
    _areaNameController.dispose();
    _areaNameArabicController.dispose();
    _prefixController.dispose();
    super.dispose();
  }
}
