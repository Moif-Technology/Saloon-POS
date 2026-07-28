import 'package:flutter/material.dart';

/// Direct Settlement – minimal, compact layout for POS (1024×600–1366×768).
/// Keeps Color(0xFF521C1D) theme; touch-friendly buttons.
class DirectSettlement extends StatelessWidget {
  static const Color _themeColor = Color(0xFF521C1D);

  double _dp(BuildContext context, double base) {
    final w = MediaQuery.of(context).size.width;
    return (w < 1100) ? base * 0.9 : base;
  }

  @override
  Widget build(BuildContext context) {
    final pad = _dp(context, 6);
    final fs = _dp(context, 11);

    return Scaffold(
      appBar: AppBar(
        title: Text('AL BARAKA INT. SER.', style: TextStyle(fontSize: _dp(context, 14))),
        backgroundColor: _themeColor,
        centerTitle: true,
        toolbarHeight: 40,
      ),
      body: Padding(
        padding: EdgeInsets.all(pad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLeftSection(context, pad, fs),
            SizedBox(width: pad),
            Expanded(child: _buildMiddleSection(context, pad, fs)),
            SizedBox(width: pad),
            Expanded(flex: 1, child: _buildRightSection(context, pad, fs)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSection(BuildContext context, double pad, double fs) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 300, minWidth: 240),
      child: SingleChildScrollView(
        child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(context, "Area:", "DINE IN", "Table:", "1", pad, fs),
            _buildInfoRow(context, "KOT No:", "-", "Bill No:", "-", pad, fs),
            SizedBox(height: pad),
            _buildTableSection(context, pad, fs),
            SizedBox(height: pad),
            _buildBottomDetails(context, pad, fs),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String l1, String v1, String l2, String v2, double pad, double fs) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: pad * 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$l1 $v1", style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold)),
          Text("$l2 $v2", style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTableSection(BuildContext context, double pad, double fs) {
    final items = [
      {"Sl": "1", "Item": "KHOW SUEY ...", "Qty": "1", "Price": "1.500", "Total": "1.500"},
      {"Sl": "2", "Item": "MILESTONE ...", "Qty": "1", "Price": "1.000", "Total": "1.000"},
      {"Sl": "3", "Item": "BEEF ULATHI...", "Qty": "1", "Price": "1.800", "Total": "1.800"},
    ];
    return Container(
      height: 140,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: pad, horizontal: pad),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5))),
            child: Row(
              children: [
                _flexText("Sl", 1, fs),
                _flexText("Item", 4, fs),
                _flexText("Qty", 1, fs),
                _flexText("Price", 1, fs),
                _flexText("Total", 1, fs),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: pad * 0.5, horizontal: pad),
                  child: Row(
                    children: [
                      _flexText(item["Sl"]!, 1, fs - 1),
                      _flexText(item["Item"]!, 4, fs - 1),
                      _flexText(item["Qty"]!, 1, fs - 1),
                      _flexText(item["Price"]!, 1, fs - 1),
                      _flexText(item["Total"]!, 1, fs - 1),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _flexText(String text, int flex, double fs) => Expanded(flex: flex, child: Text(text, style: TextStyle(fontSize: fs), overflow: TextOverflow.ellipsis));

  Widget _buildBottomDetails(BuildContext context, double pad, double fs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Total: 4.300", style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold)), Text("Net: 4.300", style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold))]),
        SizedBox(height: pad),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _smallBtn(context, "Take Away", Colors.blue, pad, fs),
            _smallBtn(context, "Dine In", Colors.green, pad, fs),
            _smallBtn(context, "Delete", Colors.red, pad, fs),
          ],
        ),
      ],
    );
  }

  Widget _smallBtn(BuildContext context, String label, Color color, double pad, double fs) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: pad, horizontal: pad * 1.5),
          child: Text(label, style: TextStyle(fontSize: fs - 1, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildMiddleSection(BuildContext context, double pad, double fs) {
    final methods = ["Cash", "Credit-Card", "Credit", "M-Pay", "Online", "Compliment", "Home"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...methods.map((t) => Padding(
              padding: EdgeInsets.symmetric(vertical: pad * 0.5),
              child: Material(
                color: _themeColor,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    child: Text(t, style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            )),
        Spacer(),
        _buildNumericPad(context, pad, fs),
      ],
    );
  }

  Widget _buildNumericPad(BuildContext context, double pad, double fs) {
    final rows = [
      ["7", "8", "9", "Clear", "Back"],
      ["4", "5", "6", "X", "Item"],
      ["1", "2", "3", "SAVE", "ENTER"],
      ["0", ".", "00"],
    ];
    const btnMinSize = 44.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: pad),
          child: Row(
            children: row.asMap().entries.map((e) {
              final t = e.value;
              final isPrimary = t == "SAVE" || t == "ENTER";
              final isAction = isPrimary || t == "Clear" || t == "Back" || t == "X" || t == "Item";
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key < row.length - 1 ? pad : 0),
                  child: SizedBox(
                    height: btnMinSize,
                    child: Material(
                      color: isPrimary ? Colors.green : (isAction ? _themeColor.withOpacity(0.2) : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(6),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: fs,
                                  fontWeight: FontWeight.bold,
                                  color: isPrimary ? Colors.white : (isAction ? _themeColor : Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRightSection(BuildContext context, double pad, double fs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Payment Mode: Cash", style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold)),
        Text("Customer: Cash Customer", style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold)),
        SizedBox(height: pad),
        TextField(
          decoration: InputDecoration(labelText: "Net Total", border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          style: TextStyle(fontSize: fs),
        ),
        SizedBox(height: pad),
        TextField(
          decoration: InputDecoration(labelText: "Paid Amount", border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          style: TextStyle(fontSize: fs),
        ),
        SizedBox(height: pad),
        TextField(
          decoration: InputDecoration(labelText: "Balance Amount", border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          style: TextStyle(fontSize: fs),
        ),
        Spacer(),
        _buildRightButtons(context, pad, fs),
      ],
    );
  }

  Widget _buildRightButtons(BuildContext context, double pad, double fs) {
    final btns = [("New Bill", _themeColor), ("Bill Join", _themeColor), ("Print KOT", _themeColor), ("Duplicate Bill", Colors.orange), ("Bill", Colors.green)];
    return Column(
      children: btns.map((b) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: pad * 0.5),
          child: Material(
            color: b.$2,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                child: Text(b.$1, style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
