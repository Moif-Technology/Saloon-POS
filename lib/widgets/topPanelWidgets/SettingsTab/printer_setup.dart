import 'package:flutter/material.dart';

class CounterPrinterSetupDialog extends StatelessWidget {
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTableSection(),
                const SizedBox(height: 16),
                _buildFooterNotes(),
              ],
            ),
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
            'Counter Printer Setup',
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
    height: 220,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          columns: [
            DataColumn(label: Text('Counter No', style: _tableHeaderStyle())),
            DataColumn(label: Text('Kitchen Loc Name', style: _tableHeaderStyle())),
            DataColumn(label: Text('Printer Name', style: _tableHeaderStyle())),
          ],
          rows: [
            DataRow(
              cells: [
                DataCell(Text('1')),
                DataCell(Text('MAIN KITCHEN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF521C1D)))),
                DataCell(Text('KITCHEN')),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('1')),
                DataCell(Text('COFFEE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                DataCell(Text('COUNTER', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
          dataRowMinHeight: 44,
          dataRowMaxHeight: 48,
          headingRowHeight: 40,
        ),
      ),
    );
  }

 Widget _buildFooterNotes() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOPRINTER-ID will be (99)',
          style: TextStyle(color: Colors.grey[700], height: 1.45),
        ),
        const SizedBox(height: 6),
        Text(
          'SEPARATE KOT PRINTER FOR DELIVERY-ID will be (98)',
          style: TextStyle(color: Colors.grey[700], height: 1.45),
        ),
        const SizedBox(height: 6),
        Text(
          'DUPLICATE KOT PRINTER-ID will be (97)',
          style: TextStyle(color: Colors.grey[700], height: 1.45),
        ),
        const SizedBox(height: 6),
        Text(
          'Separate KOT PRINTER for TakeAway-ID will be (96)',
          style: TextStyle(color: Colors.grey[700], height: 1.45),
        ),
      ],
    ),
  );
}

 Widget _buildActionButtons(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Save action logic
          },
          icon: const Icon(Icons.save, color: Colors.white, size: 20),
          label: const Text(
            'Save',
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

  TextStyle _tableHeaderStyle() {
    return TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFF521C1D),
    );
  }
}
