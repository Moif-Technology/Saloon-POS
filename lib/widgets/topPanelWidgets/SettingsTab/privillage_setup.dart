import 'package:flutter/material.dart';

class PrivilegeSettingsTabbedDialog extends StatefulWidget {
  @override
  _PrivilegeSettingsTabbedDialogState createState() =>
      _PrivilegeSettingsTabbedDialogState();
}

class _PrivilegeSettingsTabbedDialogState
    extends State<PrivilegeSettingsTabbedDialog> {
  static const Color _primaryColor = Color(0xFF521C1D);
  static const Color _primaryLight = Color(0xFF6B2A2C);
  static const Color _primaryDeep = Color(0xFF3F1415);

  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> functionList = [];
  List<Map<String, dynamic>> childFunctions = [];

  String? selectedUser;
  int? selectedFunctionId;
  Map<int, bool> accessMap = {};

  @override
  void initState() {
    super.initState();
    _loadStaffsAndFunctions();
  }

  Future<void> _loadStaffsAndFunctions({String? selectedStaffId}) async {
    setState(() {
      staffList = [
        {'StaffID': '1', 'StaffName': 'Admin'},
        {'StaffID': '2', 'StaffName': 'Sarah'},
        {'StaffID': '3', 'StaffName': 'Ahmed'},
      ];
      functionList = [
        {'FunctionID': 1, 'FunctionDescription': 'POS'},
        {'FunctionID': 2, 'FunctionDescription': 'Reports'},
        {'FunctionID': 3, 'FunctionDescription': 'Masters'},
        {'FunctionID': 4, 'FunctionDescription': 'Settings'},
      ];
      selectedUser = selectedStaffId ?? staffList.first['StaffID'].toString();
      selectedFunctionId = null;
      childFunctions = [];
      accessMap.clear();
    });
  }

  Future<void> _fetchChildFunctions(int functionId) async {
    final names = switch (functionId) {
      1 => ['Settlement', 'Save Job', 'Print Job', 'Discount', 'Item Cancel'],
      2 => ['Bill Reprint', 'Sales Viewer', 'Counter Close Reports'],
      3 => ['Area Master', 'Table Master', 'Group Master', 'Product Master'],
      _ => ['Control Panel', 'Printer Setup', 'Privilege Setup'],
    };
    setState(() {
      childFunctions = [
        for (var i = 0; i < names.length; i++)
          {
            'FunctionID': functionId * 100 + i,
            'FunctionDescription': names[i],
          }
      ];
      for (final func in childFunctions) {
        final id = int.tryParse(func['FunctionID'].toString()) ?? 0;
        accessMap[id] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 880,
        height: 560,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 248,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _primaryLight,
            _primaryColor,
            _primaryDeep,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 26, 18, 8),
            child: Text(
              'Privilege\nSettings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildUserDropdown(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: Text(
              'MODULES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              itemCount: functionList.length,
              itemBuilder: (context, index) {
                final func = functionList[index];
                final int id = int.tryParse(func['FunctionID'].toString()) ?? 0;
                final String desc = func['FunctionDescription'] ?? '';
                final bool isSelected = id == selectedFunctionId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          selectedFunctionId = id;
                        });
                        _fetchChildFunctions(id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.16)
                                    : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.22),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _getFunctionIcon(desc),
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: Colors.white.withOpacity(
                                    isSelected ? 1.0 : 0.88,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
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

  Widget _buildUserDropdown() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: staffList.isEmpty
          ? Text(
              'No mock staff loaded.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedUser,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 22,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    dropdownColor: _primaryColor,
                    items: staffList.map((staff) {
                      return DropdownMenuItem<String>(
                        value: staff['StaffID'].toString(),
                        child: Text(
                          staff['StaffName'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _loadStaffsAndFunctions(selectedStaffId: value);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (childFunctions.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _toggleSelectAll(!_areAllSelected()),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _areAllSelected()
                                ? _primaryColor
                                : Colors.transparent,
                            border: Border.all(
                              color: _primaryColor,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _areAllSelected()
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Select All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (childFunctions.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        selectedFunctionId == null
                            ? 'Select a function'
                            : 'No sub functions found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              constraints.maxWidth >= 480 ? 3 : 2;
                          const spacing = 10.0;
                          final itemWidth = (constraints.maxWidth -
                                  (spacing * (crossAxisCount - 1))) /
                              crossAxisCount;

                          return SingleChildScrollView(
                            child: Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: childFunctions.map((func) {
                                final int id = int.tryParse(
                                        func['FunctionID'].toString()) ??
                                    0;
                                final String fullName =
                                    func['FunctionDescription'] ?? '';
                                final String name = fullName.contains('-')
                                    ? fullName.split('-').last.trim()
                                    : fullName;
                                final bool isChecked = accessMap[id] ?? false;

                                return SizedBox(
                                  width: itemWidth,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        accessMap[id] = !isChecked;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isChecked
                                            ? _primaryColor
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _primaryColor,
                                          width: 1,
                                        ),
                                        boxShadow: isChecked
                                            ? [
                                                BoxShadow(
                                                  color: _primaryColor
                                                      .withOpacity(0.18),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isChecked
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: isChecked
                                                ? Colors.white
                                                : _primaryColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              name,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isChecked
                                                    ? Colors.white
                                                    : _primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.only(left: 20, right: 8, top: 10, bottom: 10),
      decoration: const BoxDecoration(
        color: _primaryColor,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Privilege ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      TextSpan(
                        text: 'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Role & Access Management',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              tooltip: 'Close',
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: _savePrivileges,
            icon: const Icon(Icons.save, size: 20, color: Colors.white),
            label: const Text(
              'Save',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFunctionIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('master')) return Icons.dashboard_outlined;
    if (desc.contains('pos')) return Icons.point_of_sale_outlined;
    if (desc.contains('amendment')) return Icons.edit_note_outlined;
    if (desc.contains('transaction')) return Icons.receipt_long_outlined;
    if (desc.contains('reprint')) return Icons.print_outlined;
    if (desc.contains('report')) return Icons.bar_chart_outlined;
    if (desc.contains('admin')) return Icons.admin_panel_settings_outlined;
    if (desc.contains('setting')) return Icons.settings_outlined;
    if (desc.contains('purchase')) return Icons.shopping_cart_outlined;
    return Icons.menu_outlined;
  }

  bool _areAllSelected() {
    if (childFunctions.isEmpty) return false;
    return childFunctions.every((func) {
      final id = int.tryParse(func['FunctionID'].toString()) ?? 0;
      return accessMap[id] == true;
    });
  }

  void _toggleSelectAll(bool enable) {
    setState(() {
      for (var func in childFunctions) {
        final id = int.tryParse(func['FunctionID'].toString()) ?? 0;
        accessMap[id] = enable;
      }
    });
  }

  Future<void> _savePrivileges() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privileges saved in mock mode.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}