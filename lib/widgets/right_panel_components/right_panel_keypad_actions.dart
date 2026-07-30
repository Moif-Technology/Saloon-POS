import 'package:flutter/material.dart';
import 'pos_button.dart';
import 'pos_keypad_button.dart';

class RightPanelKeypadActions extends StatelessWidget {
  final bool isBaseVersion;
  final String enteredQty;
  final ValueChanged<String> onKeypadAppend;
  final VoidCallback onKeypadDot;
  final VoidCallback onKeypadBackspace;

  final VoidCallback? onAreaChange;
  final VoidCallback onNoSale;

  final VoidCallback onOrderList;
  final VoidCallback onQtyCommit;

  final VoidCallback onReturn1;
  final VoidCallback onDirectSettlement;

  final VoidCallback onItemCancel;
  final VoidCallback onReceipts;
  final VoidCallback? onSettlement;
  final bool showNoSale;
  final bool showOrderList;
  final bool showQtyCommit;
  final bool showReturn;
  final bool showDirectSettlement;
  final bool showReceipts;
  final bool showItemCancel;

  const RightPanelKeypadActions({
    super.key,
    required this.isBaseVersion,
    required this.enteredQty,
    required this.onKeypadAppend,
    required this.onKeypadDot,
    required this.onKeypadBackspace,
    required this.onAreaChange,
    required this.onNoSale,
    required this.onOrderList,
    required this.onQtyCommit,
    required this.onReturn1,
    required this.onDirectSettlement,
    required this.onItemCancel,
    required this.onReceipts,
    this.onSettlement,
    this.showNoSale = true,
    this.showOrderList = true,
    this.showQtyCommit = true,
    this.showReturn = true,
    this.showDirectSettlement = true,
    this.showReceipts = true,
    this.showItemCancel = true,
  });

  double _h(double w) {
    if (w < 520) return 42;
    if (w < 700) return 44;
    if (w < 900) return 46;
    return 48;
  }

  double _gap(double w) => (w < 700) ? 3 : 5;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final gap = _gap(w);
    final rowH = _h(w);

    // section height = 4 rows of same height (VB)
    final sectionH = rowH * 4 + gap * 3;

    // Keypad items in VB: 4 rows x 3 cols
    final keypad = <Widget>[
      PosKeypadButton(
          label: '7',
          onPressed: () => onKeypadAppend('7'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '8',
          onPressed: () => onKeypadAppend('8'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '9',
          onPressed: () => onKeypadAppend('9'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '4',
          onPressed: () => onKeypadAppend('4'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '5',
          onPressed: () => onKeypadAppend('5'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '6',
          onPressed: () => onKeypadAppend('6'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '1',
          onPressed: () => onKeypadAppend('1'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '2',
          onPressed: () => onKeypadAppend('2'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '3',
          onPressed: () => onKeypadAppend('3'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '0',
          onPressed: () => onKeypadAppend('0'),
          isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: '.', onPressed: onKeypadDot, isBaseVersion: isBaseVersion),
      PosKeypadButton(
          label: 'C',
          onPressed: onKeypadBackspace,
          isBaseVersion: isBaseVersion),
    ];

    // Right-side 4 rows x 3 cols (VB). Disabled feature buttons are removed.
    // Base version layout (matches sketch):
    // [Keypad 4x3] | [No Sale / QTY ]  | [         ]
    //              | [Order List / Receipts] | [Settle]
    //              | [Return / Print Bill]   | [      ]
    if (isBaseVersion && onSettlement != null) {
      Widget _actionRow(Widget a, Widget b) => SizedBox(
            height: rowH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: a),
                SizedBox(width: gap),
                Expanded(child: b),
              ],
            ),
          );

      return Container(
        height: sectionH,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT: Keypad 4 rows × 3 cols
            Flexible(
              flex: 9,
              child: Column(
                children: [
                  for (int r = 0; r < 4; r++) ...[
                    SizedBox(
                      height: rowH,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          keypad[r * 3],
                          SizedBox(width: gap),
                          keypad[r * 3 + 1],
                          SizedBox(width: gap),
                          keypad[r * 3 + 2],
                        ],
                      ),
                    ),
                    if (r != 3) SizedBox(height: gap),
                  ],
                ],
              ),
            ),

            SizedBox(width: gap),

            // MIDDLE: 2-col × 3-row action buttons (bottom-aligned — rows 2-4 of keypad)
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                      height: rowH + gap), // spacer = 1 keypad row (top empty)
                  if (showNoSale || showQtyCommit)
                    _actionRow(
                      showNoSale
                          ? PosButton(
                              label: "No\nSale",
                              icon: Icons.block,
                              onPressed: onNoSale,
                              isBaseVersion: true)
                          : const SizedBox.shrink(),
                      showQtyCommit
                          ? PosButton(
                              label: "QTY",
                              icon: Icons.calculate,
                              onPressed: onQtyCommit,
                              isBaseVersion: true)
                          : const SizedBox.shrink(),
                    ),
                  if (showNoSale || showQtyCommit) SizedBox(height: gap),
                  if (showOrderList || showReceipts)
                    _actionRow(
                      showOrderList
                          ? PosButton(
                              label: "Job\nList",
                              icon: Icons.shopping_cart,
                              onPressed: onOrderList,
                              isBaseVersion: true)
                          : const SizedBox.shrink(),
                      showReceipts
                          ? PosButton(
                              label: "Receipts",
                              icon: Icons.receipt,
                              onPressed: onReceipts,
                              isBaseVersion: true)
                          : const SizedBox.shrink(),
                    ),
                  if (showOrderList || showReceipts) SizedBox(height: gap),
                  if (showReturn || showDirectSettlement)
                    _actionRow(
                      showReturn
                          ? PosButton(
                              label: "Return",
                              icon: Icons.undo,
                              onPressed: onReturn1,
                              isBaseVersion: true)
                          : const SizedBox.shrink(),
                      showDirectSettlement
                          ? PosButton(
                              label: "Print\nBill",
                              icon: Icons.print,
                              onPressed: onDirectSettlement,
                              isBaseVersion: true)
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),

            SizedBox(width: gap),

            // RIGHT: Settlement — tall button spanning bottom 3 rows (bottom-aligned)
            SizedBox(
              width: rowH * 2.8 + gap,
              height: sectionH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                      height: rowH + gap), // spacer = 1 keypad row (top empty)
                  if (onSettlement != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onSettlement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF800000),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: rowH * 1.2, color: Colors.white),
                            SizedBox(height: 6),
                            Text(
                              "Settle",
                              style: TextStyle(
                                fontSize: rowH * 0.42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final actions = <List<Widget>>[
      [
        if (!isBaseVersion && onAreaChange != null)
          PosButton(
              label: "Section\nChange",
              icon: Icons.location_on,
              onPressed: onAreaChange!),
        if (showNoSale)
          PosButton(
              label: "No\nSale",
              icon: Icons.block,
              onPressed: onNoSale,
              isBaseVersion: isBaseVersion),
      ],
      [
        if (showOrderList)
          PosButton(
              label: "Job\nList",
              icon: Icons.shopping_cart,
              onPressed: onOrderList,
              isBaseVersion: isBaseVersion),
        if (showQtyCommit)
          PosButton(
              label: "QTY",
              icon: Icons.calculate,
              onPressed: onQtyCommit,
              isBaseVersion: isBaseVersion),
      ],
      [
        if (showReturn)
          PosButton(
              label: "Return",
              icon: Icons.undo,
              onPressed: onReturn1,
              isBaseVersion: isBaseVersion),
        if (!isBaseVersion && showDirectSettlement)
          PosButton(
              label: "Direct",
              icon: Icons.account_balance,
              onPressed: onDirectSettlement),
      ],
      [
        if (!isBaseVersion && showItemCancel)
          PosButton(
              label: "Item\nCancel",
              icon: Icons.cancel,
              onPressed: onItemCancel),
      ],
    ];

    return Container(
      height: sectionH,
      decoration: isBaseVersion
          ? BoxDecoration(
              color: const Color(0xFFF4F4F8),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT: keypad grid fixed
          Flexible(
            flex: 4,
            child: Column(
              children: [
                for (int r = 0; r < 4; r++) ...[
                  SizedBox(
                    height: rowH,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        keypad[r * 3],
                        SizedBox(width: gap),
                        keypad[r * 3 + 1],
                        SizedBox(width: gap),
                        keypad[r * 3 + 2],
                      ],
                    ),
                  ),
                  if (r != 3) SizedBox(height: gap),
                ],
              ],
            ),
          ),

          SizedBox(width: gap),

          // RIGHT: action grid fixed
          Expanded(
            flex: 6,
            child: Column(
              children: [
                for (int r = 0; r < 4; r++) ...[
                  SizedBox(
                    height: rowH,
                    child: actions[r].isEmpty
                        ? const SizedBox.shrink()
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < actions[r].length; i++) ...[
                                actions[r][i],
                                if (i != actions[r].length - 1)
                                  SizedBox(width: gap),
                              ],
                            ],
                          ),
                  ),
                  if (r != 3) SizedBox(height: gap),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
