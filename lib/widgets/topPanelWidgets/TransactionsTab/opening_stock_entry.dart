import 'package:flutter/material.dart';

class OpeningStockEntryDialog extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF521C1D);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final double dialogWidth = screen.width > 1000 ? 900 : screen.width * 0.9;
    final double dialogHeight =
        screen.height > 720 ? 720 : screen.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                    _buildStockInfoSection(),
                    const SizedBox(height: 12),
                    _buildItemEntrySection(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildTableSection()),
                  ],
                ),
              ),
            ),
            _buildFooter(),
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
      decoration: const BoxDecoration(
        color: _primaryColor,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Opening Stock Entry',
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

  // ── 2. Stock Information ─────────────────────────────────────────────────
  Widget _buildStockInfoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(child: _buildLabeledField('Opening Stock No.')),
          const SizedBox(width: 12),
          Expanded(child: _buildLabeledField('Stock Date')),
          const SizedBox(width: 12),
          Expanded(child: _buildLabeledField('Warehouse / Location')),
        ],
      ),
    );
  }

  // ── 3. Item Entry ────────────────────────────────────────────────────────
  Widget _buildItemEntrySection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(flex: 2, child: _buildLabeledField('Barcode')),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _buildLabeledField('Short Description')),
          const SizedBox(width: 8),
          Expanded(child: _buildLabeledField('Pkt Qty')),
          const SizedBox(width: 8),
          Expanded(child: _buildLabeledField('Pkt Details')),
          const SizedBox(width: 8),
          Expanded(child: _buildLabeledField('Opening Quantity')),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                // Add logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text(
                'ADD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Opening Stock Table ───────────────────────────────────────────────
  Widget _buildTableSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: _primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: const Row(
              children: [
                Expanded(flex: 1, child: _HeaderCell('Sl No')),
                Expanded(flex: 2, child: _HeaderCell('Barcode')),
                Expanded(flex: 3, child: _HeaderCell('Short Description')),
                Expanded(flex: 2, child: _HeaderCell('Packet Details')),
                Expanded(flex: 2, child: _HeaderCell('Opening Stock')),
                Expanded(flex: 2, child: _HeaderCell('Actions')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: _generateStockRows(),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Footer ────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // Save
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save',
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

  Widget _buildLabeledField(String label) {
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
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primaryColor, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  // Sample Data Rows — same sample data & edit/delete stubs as before
  List<Widget> _generateStockRows() {
    final stockItems = [
      {
        "slNo": "1",
        "barcode": "123456",
        "description": "Sample Item",
        "packetDetails": "Box",
        "openingStock": "100",
      },
      {
        "slNo": "2",
        "barcode": "123457",
        "description": "Sample Item 2",
        "packetDetails": "Box",
        "openingStock": "200",
      },
    ];

    return List.generate(stockItems.length, (index) {
      final item = stockItems[index];
      return Container(
        constraints: const BoxConstraints(minHeight: 44),
        color: index.isEven ? Colors.white : Colors.grey.shade50,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            _bodyCell(item["slNo"] ?? "", flex: 1),
            _bodyCell(item["barcode"] ?? "", flex: 2),
            _bodyCell(item["description"] ?? "", flex: 3),
            _bodyCell(item["packetDetails"] ?? "", flex: 2),
            _bodyCell(item["openingStock"] ?? "", flex: 2),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () {
                      // Edit action
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      // Delete action
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _bodyCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}