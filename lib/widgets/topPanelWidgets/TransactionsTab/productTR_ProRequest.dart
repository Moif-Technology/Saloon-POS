import 'package:flutter/material.dart';

class ProductRequestDialog extends StatelessWidget {
    static const Color _primaryColor = Color(0xFF521C1D);

  // Simulating data fetched from the backend
  final String barcodeData = "123456";
  final String availableStock = "50";

 @override
Widget build(BuildContext context) {
  final screen = MediaQuery.of(context).size;
 final double dialogWidth = screen.width > 1100 ? 1080 : screen.width * 0.95;
final double dialogHeight =
    screen.height > 720 ? 720 : screen.height * 0.92;

  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
    child: Container(
      width: dialogWidth,
      height: dialogHeight,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRequestInfoSection(),
                  const SizedBox(height: 12),
                  _buildItemEntrySection(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildTableSection()),
                 
                ],
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    ),
  );
}
// ── 1. Header ────────────────────────────────────────────────────────────
Widget _buildHeader(BuildContext context) {
  return Container(
    constraints: const BoxConstraints(minHeight: 56),
    padding: const EdgeInsets.only(left: 20, right: 8),
    decoration: const BoxDecoration(color: _primaryColor),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Stock Request Entry',
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
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
        ),
      ],
    ),
  );
}
// ── 2. Request Information ───────────────────────────────────────────────
Widget _buildRequestInfoSection() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildLabelledTextField('Request No', Colors.yellow[100]),
              const SizedBox(height: 12),
              _buildDateField('Request Date'),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildDropdownField('Request From', 'AUH'),
              const SizedBox(height: 12),
              _buildDropdownField('Request To', ''),
            ],
          ),
        ),
      ],
    ),
  );
}
// ── 3. Item Entry + Live Stock ───────────────────────────────────────────
Widget _buildItemEntrySection() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // LEFT — two input rows
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1 — Barcode + Short Description
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildCompactTextField('Barcode', Colors.yellow[100]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _buildCompactTextField(
                        'Short Description', Colors.yellow[100]),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2 — Qty / Unit Cost / Unit Price + Add
              Row(
                children: [
                  Expanded(
                    child: _buildSmallInputField('Qty', double.infinity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallInputField('Unit Cost', double.infinity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallInputField('Unit Price', double.infinity),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Add item logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // RIGHT — live stock badge
        _buildBarcodeInfo(),
      ],
    ),
  );
}
// ── 4. Items Table ───────────────────────────────────────────────────────
Widget _buildTableSection() {
  return Container(
    width: double.infinity, // match section width
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        // Header fills full card width (like Opening Stock)
        Container(
          width: double.infinity,
          color: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              _headerCell('Sl No', flex: 1),
              _headerCell('Barcode', flex: 2),
              _headerCell('Short Description', flex: 3),
              _headerCell('Qty', flex: 1),
              _headerCell('Unit', flex: 1),
              _headerCell('Pack Qty', flex: 1),
              _headerCell('Packet Details', flex: 2),
              _headerCell('Unit Cost', flex: 2),
              _headerCell('Unit Price', flex: 2),
              _headerCell('Line Total', flex: 2),
              _headerCell('Delete', flex: 1),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _buildAlignedDataRow(
                [
                  '1',
                  '123456',
                  'Sample Item',
                  '2',
                  'Unit',
                  '5',
                  'Details',
                  '10.00',
                  '12.00',
                  '24.00'
                ],
                index: 0,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
// ── 5. Footer ────────────────────────────────────────────────────────────
Widget _buildFooter(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      color: Color(0xFFFCFBFB),
      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
    ),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1 — Remarks (left) + Total Amount (right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildRemarksField()),
            const SizedBox(width: 16),
            _buildTotalAmountField(),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2 — Print (far left) + Save (far right)
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Print'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(color: _primaryColor),
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 44),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

double _tableColumnWidth(String label) {
  switch (label) {
    case 'Sl No':
      return 56;
    case 'Barcode':
      return 110;
    case 'Short Description':
      return 180;
    case 'Qty':
      return 60;
    case 'Unit':
      return 60;
    case 'Pack Qty':
      return 80;
    case 'Packet Details':
      return 120;
    case 'Unit Cost':
      return 90;
    case 'Unit Price':
      return 90;
    case 'Line Total':
      return 90;
    case 'Delete':
      return 64;
    default:
      return 90;
  }
}

double _tableTotalWidth() {
  const labels = [
    'Sl No',
    'Barcode',
    'Short Description',
    'Qty',
    'Unit',
    'Pack Qty',
    'Packet Details',
    'Unit Cost',
    'Unit Price',
    'Line Total',
    'Delete',
  ];
  return labels.fold<double>(0, (sum, l) => sum + _tableColumnWidth(l));
}

Widget _headerCell(String label, {int flex = 1}) {
  return Expanded(
    flex: flex,
    child: Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}
Widget _buildAlignedDataRow(List<String> cells, {required int index}) {
  final labels = [
    'Sl No',
    'Barcode',
    'Short Description',
    'Qty',
    'Unit',
    'Pack Qty',
    'Packet Details',
    'Unit Cost',
    'Unit Price',
    'Line Total',
  ];

  return Container(
    constraints: const BoxConstraints(minHeight: 40),
    color: index.isEven ? Colors.white : Colors.grey.shade50,
    child: Row(
      children: [
        for (int i = 0; i < cells.length; i++)
          SizedBox(
            width: _tableColumnWidth(labels[i]),
            child: Text(
              cells[i],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        SizedBox(
          width: _tableColumnWidth('Delete'),
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              // Delete action
            },
          ),
        ),
      ],
    ),
  );
}

Widget _buildRemarksAndTotalRow() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _buildRemarksField()),
      const SizedBox(width: 16),
      _buildTotalAmountField(),
    ],
  );
}

  Widget _buildLabelledTextField(String label, Color? fillColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(
  label,
  style: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: _primaryColor,
  ),
),
        const SizedBox(height: 4),
       TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
isDense: true,
contentPadding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
enabledBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: BorderSide(color: Colors.grey.shade300),
),
focusedBorder: const OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(8)),
  borderSide: BorderSide(color: _primaryColor, width: 1.5),
),
            ),
          ),
        
      ],
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              suffixIcon: Icon(Icons.calendar_today, size: 16),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onTap: () {
              // Show date picker logic
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          child: DropdownButtonFormField<String>(
            value: initialValue.isEmpty ? null : initialValue,
            items: ["AUH", "DXB", "SHJ"]
                .map((location) =>
                    DropdownMenuItem(value: location, child: Text(location)))
                .toList(),
            onChanged: (value) {},
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }

 Widget _buildBarcodeInfo() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _primaryColor.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _primaryColor.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Barcode: $barcodeData',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Available Stock: $availableStock',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    ),
  );
}

Widget _buildCompactTextField(String label, Color? fillColor) {
  return SizedBox(
    height: 30,
    child: TextField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    ),
  );
}

  Widget _buildSmallInputField(String label, double width) {
  final field = TextField(
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    style: const TextStyle(fontSize: 13),
  );

  if (width == double.infinity) {
    return field;
  }
  return SizedBox(width: width, child: field);
}

 List<DataColumn> _buildTableColumns() {
    return [
      DataColumn(label: Text("Sl No")),
      DataColumn(label: Text("Barcode")),
      DataColumn(label: Text("Short Description")),
      DataColumn(label: Text("Qty")),
      DataColumn(label: Text("Unit")),
      DataColumn(label: Text("Pack Qty")),
      DataColumn(label: Text("Packet Details")),
      DataColumn(label: Text("Unit Cost")),
      DataColumn(label: Text("Unit Price")),
      DataColumn(label: Text("Line Total")),
      DataColumn(label: Text("Delete")),
    ];
  }

  List<DataRow> _buildTableRows() {
    return [
      DataRow(cells: [
        DataCell(Text("1")),
        DataCell(Text("123456")),
        DataCell(Text("Sample Item")),
        DataCell(Text("2")),
        DataCell(Text("Unit")),
        DataCell(Text("5")),
        DataCell(Text("Details")),
        DataCell(Text("10.00")),
        DataCell(Text("12.00")),
        DataCell(Text("24.00")),
        DataCell(IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            // Delete action
          },
        )),
      ]),
    ];
  }

  Widget _buildRemarksField() {
    return TextField(
      maxLines: 2,
      decoration: InputDecoration(
        labelText: "Remarks",
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildTotalAmountField() {
    return Column(
      children: [
        const Text("Total Amount",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
           color: _primaryColor.withOpacity(0.06),
border: Border.all(color: _primaryColor.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            "0",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

 
}
