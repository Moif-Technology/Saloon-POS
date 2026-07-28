import 'package:flutter/material.dart';

class UsersListDialog extends StatelessWidget {
    static const Color _primaryColor = Color(0xFF521C1D);

 @override
Widget build(BuildContext context) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Container(
      width: 600,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildTableSection(),
          ),
          _buildActionButtons(context),
        ],
      ),
    ),
  );
}

 Widget _buildHeader(BuildContext context) {
  return Container(
    constraints: const BoxConstraints(minHeight: 56),
    padding: const EdgeInsets.only(left: 20, right: 8),
    decoration: const BoxDecoration(
      color: _primaryColor,
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Users List',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
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
 Widget _buildTableSection() {
  return Container(
    height: 320,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 24,
        horizontalMargin: 16,
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: [
          DataColumn(label: Text('User Code', style: _tableHeaderStyle())),
          DataColumn(label: Text('User Name', style: _tableHeaderStyle())),
          DataColumn(label: Text('User Role', style: _tableHeaderStyle())),
          DataColumn(label: Text('Login Name', style: _tableHeaderStyle())),
        ],
        rows: [
  DataRow(
    cells: [
      DataCell(Text('ADMIN')),
      DataCell(Text('ADMIN')),
      DataCell(Text('ADMIN')),
      DataCell(Text('944')),
    ],
  ),
  DataRow(
    cells: [
      DataCell(Text('WAITER')),
      DataCell(Text('RAKESH')),
      DataCell(Text('WAITER')),
      DataCell(Text('1')),
    ],
  ),
  DataRow(
    cells: [
      DataCell(Text('CASHIER1')),
      DataCell(Text('CASHIER1')),
      DataCell(Text('CHIEF CASHIER')),
      DataCell(Text('101')),
    ],
  ),
  DataRow(
    cells: [
      DataCell(Text('invent')),
      DataCell(Text('Invent')),
      DataCell(Text('ADMIN')),
      DataCell(Text('0')),
    ],
  ),
  DataRow(
    cells: [
      DataCell(Text('CASHIER2')),
      DataCell(Text('CASHIER2')),
      DataCell(Text('CASHIER')),
      DataCell(Text('102')),
    ],
  ),
  DataRow(
    cells: [
      DataCell(Text('7987')),
      DataCell(Text('DELIVERY BOY')),
      DataCell(Text('DELIVERY BOY')),
      DataCell(Text('44')),
    ],
  ),
  DataRow(
    cells: [
      DataCell(Text('CHIEF CASHIER')),
      DataCell(Text('CHIEF CASHIER')),
      DataCell(Text('CHIEF CASHIER')),
      DataCell(Text('6600')),
    ],
  ),
],
        dividerThickness: 1,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 48,
        headingRowHeight: 40,
      ),
    ),
  );
}

Widget _buildActionButtons(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    child: Row(
      children: [
        // Left — destructive
        ElevatedButton.icon(
          onPressed: () {
            // Delete action logic
          },
          icon: const Icon(Icons.delete, color: Colors.white, size: 20),
          label: const Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
        const Spacer(),
        // Right — workflow actions
        ElevatedButton.icon(
          onPressed: () {
            // New action logic
          },
          icon: const Icon(Icons.add, color: Colors.white, size: 20),
          label: const Text(
            ' New',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            // Select action logic
          },
          icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
          label: const Text(
            'Select',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 44),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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

  TextStyle _tableHeaderStyle() {
    return TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFF521C1D),
    );
  }
}
