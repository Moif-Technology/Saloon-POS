import 'package:flutter/material.dart';
import 'pos_button.dart';

class RightPanelCompactActions extends StatelessWidget {
  final bool isBaseVersion;
  final bool showCancelBill;
  final bool showPrintKot;
  final bool showReprintKot;
  final bool showSaveKot;
  final bool showDiscount;
  final bool showDummyBill;
  final bool showComments;
  final bool showKotJoin;
  final bool showCashInOut;
  final bool showBillPrint;

  final VoidCallback? onCancelBill;
  final VoidCallback onKotJoin;
  final VoidCallback onCashInOut;
  final VoidCallback? onPrintKot;
  final VoidCallback? onKotReprint;

  final VoidCallback? onSaveKot;
  final VoidCallback? onDiscount;
  final VoidCallback? onDummyBill;
  final VoidCallback onBillPrint;
  final VoidCallback? onComments;

  final VoidCallback? onSettlement;

  const RightPanelCompactActions({
    super.key,
    required this.isBaseVersion,
    required this.showCancelBill,
    required this.showPrintKot,
    required this.showReprintKot,
    required this.showSaveKot,
    required this.showDiscount,
    required this.showDummyBill,
    required this.showComments,
    this.showKotJoin = true,
    this.showCashInOut = true,
    this.showBillPrint = true,
    required this.onCancelBill,
    required this.onKotJoin,
    required this.onCashInOut,
    required this.onPrintKot,
    required this.onKotReprint,
    required this.onSaveKot,
    required this.onDiscount,
    required this.onDummyBill,
    required this.onBillPrint,
    required this.onComments,
    required this.onSettlement,
  });

  // ===== VB-like compact constants =====
  double _rowH(double w) {
    if (w < 520) return 34;
    if (w < 700) return 36;
    if (w < 900) return 38;
    return 40;
  }

  double _gap(double w) => (w < 700) ? 2 : 4;

  ButtonStyle _compactElevated(Color bg) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  // ✅ Better sizing: make Settlement prominent on all screens
  // - width is a % of available width (VB feels like a bigger block)
  // - clamped so it never gets too small or too huge
  double _settlementWidth(double w) {
    // 12% of screen width feels good for POS layouts
    // Clamp keeps it consistent across 800–1920 widths
    return (w * 0.12).clamp(120.0, 180.0).toDouble();
  }

  Widget _settlementButton(BuildContext context, double height) {
    final w = MediaQuery.sizeOf(context).width;
    final iconSize = w < 700 ? 14.0 : 18.0;
    final fontSize = w < 700 ? 11.0 : 13.0;

    return SizedBox(
      width: _settlementWidth(w),
      height: height,
      child: ElevatedButton(
        style: _compactElevated(const Color(0xFF800000)),
        onPressed: onSettlement,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: iconSize, color: Colors.white),
            const SizedBox(height: 3),
            Text(
              "Settlement",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buttons() {
    if (isBaseVersion) {
      // Base: Bill Print only (Settlement is in keypad actions as big corner button)
      return [
        PosButton(
            label: "Bill\nPrint", icon: Icons.print, onPressed: onBillPrint)
      ];
    }
    return <Widget>[
      if (showCancelBill)
        PosButton(
          label: "Cancel\nBill",
          icon: Icons.cancel,
          onPressed: onCancelBill,
        ),
      if (showKotJoin)
        PosButton(
            label: "Job\nJoin", icon: Icons.merge_type, onPressed: onKotJoin),
      if (showCashInOut)
        PosButton(
          label: "Cash In/Out",
          icon: Icons.attach_money,
          onPressed: onCashInOut,
        ),
      if (showPrintKot)
        PosButton(
            label: "Print\nJob", icon: Icons.print, onPressed: onPrintKot),
      if (showReprintKot)
        PosButton(
          label: "Job\nReprint",
          icon: Icons.replay,
          onPressed: onKotReprint,
        ),
      if (showSaveKot)
        PosButton(
          label: "Save\nJob",
          icon: Icons.save,
          onPressed: onSaveKot,
          textColor: Colors.red,
        ),
      if (showDiscount)
        PosButton(
          label: "Discount",
          icon: Icons.percent,
          onPressed: onDiscount,
          textColor: Colors.deepOrange,
        ),
      if (showDummyBill)
        PosButton(
          label: "Dummy\nBill",
          icon: Icons.receipt,
          onPressed: onDummyBill,
        ),
      if (showBillPrint)
        PosButton(
            label: "Bill\nPrint", icon: Icons.print, onPressed: onBillPrint),
      if (showComments)
        PosButton(
          label: "Comments",
          icon: Icons.comment,
          onPressed: onComments,
          filledColor: const Color(0xFF5F9EA0),
          textColor: Colors.white,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final gap = _gap(w);
    final rowH = _rowH(w);

    final all = _buttons();

    // Base: single row (Bill Print only); Full: 2 rows with Settlement
    final totalH = isBaseVersion ? rowH : (rowH * 2 + gap);
    final top = isBaseVersion ? all : all.take(5).toList();
    final bottom = isBaseVersion ? <Widget>[] : all.skip(5).toList();
    final showSettlement = !isBaseVersion && onSettlement != null;

    // Base: Print Bill is in the keypad panel — nothing to show here
    if (isBaseVersion) return const SizedBox.shrink();
    if (all.isEmpty && !showSettlement) return const SizedBox.shrink();

    return SizedBox(
      height: totalH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (top.isNotEmpty)
                  SizedBox(
                    height: rowH,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: top,
                    ),
                  ),
                if (bottom.isNotEmpty) ...[
                  SizedBox(height: gap),
                  SizedBox(
                    height: rowH,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: bottom,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showSettlement) ...[
            SizedBox(width: gap),
            _settlementButton(context, totalH),
          ],
        ],
      ),
    );
  }
}
