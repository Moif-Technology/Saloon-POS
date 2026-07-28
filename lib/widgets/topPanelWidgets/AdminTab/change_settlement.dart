import 'package:flutter/material.dart';

class ChangeSettlementDialog extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final double dialogWidth = screenWidth > 700 ? 700 : screenWidth * 0.95;

  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Container(
      width: dialogWidth,
      height: screenWidth > 600
          ? 620
          : MediaQuery.of(context).size.height * 0.85,
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
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormSection(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildTableSection()),
                ],
              ),
            ),
          ),
          _buildBottomButton(context),
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
            'Change Settlement',
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
Widget _buildFormSection() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTextField('Bill No')),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDropdownField(
            'Payment Mode',
            ['Cash', 'Card', 'Online'],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildDatePicker('Bill Date')),
      ],
    ),
  );
}

  Widget _buildTextField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D),
              fontSize: 14),
        ),
        const SizedBox(height: 4),
        TextFormField(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF521C1D)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D),
              fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          height: 37, // Adjusted height to match text fields
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF521C1D)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items[0],
              isExpanded: true,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D),
              fontSize: 14),
        ),
        const SizedBox(height: 4),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon:
                Icon(Icons.calendar_today, color: Color(0xFF521C1D), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF521C1D)),
            ),
          ),
          onTap: () {
            // Implement date picker logic
          },
        ),
      ],
    );
  }

Widget _buildTableSection() {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      child: DataTable(
        columnSpacing: 20,
        headingRowHeight: 44,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 48,
        headingRowColor: WidgetStateProperty.all(
          _primaryColor.withOpacity(0.1),
        ),
        columns: [
          DataColumn(label: Text('Bill No', style: _tableHeaderStyle())),
          DataColumn(label: Text('Bill Date', style: _tableHeaderStyle())),
          DataColumn(label: Text('Bill Time', style: _tableHeaderStyle())),
          DataColumn(
            label: Text('Payment Mode', style: _tableHeaderStyle()),
          ),
        ],
        rows: List.generate(
          5,
          (index) => DataRow(
            cells: [
              DataCell(Text('BILL$index')),
              DataCell(Text('11/15/2024')),
              DataCell(Text('12:00 PM')),
              DataCell(Text('Cash')),
            ],
          ),
        ),
      ),
    ),
  );
}

 Widget _buildBottomButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            // Preserve existing Select / settlement selection behavior here.
            // If Select currently only closed the dialog, keep:
            // Navigator.of(context).pop();
            // or whatever selection callback you already use.
            Navigator.of(context).pop();
          },
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
          child: const Text(
            'Select',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
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
