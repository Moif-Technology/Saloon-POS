import 'package:flutter/material.dart';

class LeftItemsList extends StatefulWidget {
  final List<Map<String, String>> products;
  final int? selectedRowIndex;
  final double fontSize;

  final String currencyPrecession;
  final bool compact;
  final bool isBaseVersion;
  final bool showModifier;
  final bool showQtyControls;
  final bool showUnitPrice;
  final bool showSubtotal;
  final bool showTax;
  final bool showLineTotal;
  final bool allowDelete;

  final ValueChanged<int> onRowTap;
  final void Function(int index, Offset globalPos) onRowContextMenu;
  final ValueChanged<int> onModifierTap;
  final void Function(int index)? onRemoveItem;
  final void Function(int index, int delta)? onQtyChange;

  final double Function(dynamic v) asDouble;
  final int Function(String? pattern) currencyDecimalsFrom;

  const LeftItemsList({
    super.key,
    required this.products,
    required this.selectedRowIndex,
    required this.fontSize,
    required this.currencyPrecession,
    required this.onRowTap,
    required this.onRowContextMenu,
    required this.onModifierTap,
    required this.asDouble,
    required this.currencyDecimalsFrom,
    this.compact = false,
    this.isBaseVersion = false,
    this.showModifier = true,
    this.showQtyControls = true,
    this.showUnitPrice = true,
    this.showSubtotal = true,
    this.showTax = true,
    this.showLineTotal = true,
    this.allowDelete = true,
    this.onRemoveItem,
    this.onQtyChange,
  });

  @override
  State<LeftItemsList> createState() => _LeftItemsListState();
}

class _LeftItemsListState extends State<LeftItemsList> {
  final ScrollController _vCtrl = ScrollController();

  @override
  void dispose() {
    _vCtrl.dispose();
    super.dispose();
  }

  // ====== Column widths: fixed for small cols, flexible for table to fit left width ======
  double get _wNo => widget.compact ? 28 : 36;
  double get _wQty => widget.compact ? 42 : 52;
  double get _wTax => widget.compact ? 48 : 58;
  // Item Name, Unit Price, SubTotal, Line Total use flexible width via Expanded

  double get _headH => widget.compact ? 22 : 28;

  /// Responsive row height: smaller on short screens so more items visible.
  double _rowHForHeight(double availableHeight) {
    if (widget.compact) {
      if (availableHeight < 280) return 22;
      if (availableHeight < 360) return 24;
      return 26;
    }
    if (availableHeight < 320) return 26;
    if (availableHeight < 400) return 28;
    if (availableHeight < 500) return 30;
    return 34;
  }

  int _decimals() => widget.currencyDecimalsFrom(widget.currencyPrecession);

  String _money(num v) => v.toStringAsFixed(_decimals());

  TextStyle _headStyle() => TextStyle(
        fontSize: (widget.fontSize - 1).clamp(9, 12).toDouble(),
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade800,
        height: 1.0,
      );

  TextStyle _cellStyle(Color c, {bool bold = false}) => TextStyle(
        fontSize: widget.fontSize.clamp(9, 13).toDouble(),
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        color: c,
        height: 1.0,
      );

  Widget _cell(
    String text,
    double width, {
    Alignment align = Alignment.centerLeft,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 6),
    TextStyle? style,
    bool ellipsis = true,
  }) {
    return SizedBox(
      width: width,
      child: _cellContent(text,
          align: align, padding: padding, style: style, ellipsis: ellipsis),
    );
  }

  /// Cell content for use inside Expanded (flexible width).
  Widget _cellContent(
    String text, {
    Alignment align = Alignment.centerLeft,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 4),
    TextStyle? style,
    bool ellipsis = true,
  }) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: align,
        child: Text(
          text,
          maxLines: 1,
          overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.visible,
          softWrap: false,
          style: style,
        ),
      ),
    );
  }

  Widget _dividerV() => Container(
        width: 1,
        color: Colors.grey.shade200,
      );

  Widget _headerRow({required int itemNameFlex, required int numFlex}) {
    return Container(
      height: _headH,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          _cell("No", _wNo, align: Alignment.center, style: _headStyle()),
          _dividerV(),
          Expanded(
              flex: itemNameFlex,
              child: _cellContent("Item Name", style: _headStyle())),
          if (widget.showModifier) ...[
            _dividerV(),
            Expanded(
                flex: 2,
                child: _cellContent("Mod",
                    align: Alignment.centerLeft, style: _headStyle())),
          ],
          _dividerV(),
          _cell("Qty", _wQty, align: Alignment.center, style: _headStyle()),
          if (widget.showUnitPrice) ...[
            _dividerV(),
            Expanded(
                flex: numFlex,
                child: _cellContent("Unit",
                    align: Alignment.centerRight, style: _headStyle())),
          ],
          if (widget.showSubtotal) ...[
            _dividerV(),
            Expanded(
                flex: numFlex,
                child: _cellContent("Sub",
                    align: Alignment.centerRight, style: _headStyle())),
          ],
          if (widget.showTax) ...[
            _dividerV(),
            _cell("Tax %", _wTax, align: Alignment.center, style: _headStyle()),
          ],
          if (widget.showLineTotal) ...[
            _dividerV(),
            Expanded(
                flex: numFlex,
                child: _cellContent("Total",
                    align: Alignment.centerRight, style: _headStyle())),
          ],
        ],
      ),
    );
  }

  /// Responsive flex: on narrow panels, give Item Name more space.
  (int itemNameFlex, int numFlex) _flexForWidth(double width) {
    if (width < 320) return (6, 1);
    if (width < 400) return (5, 1);
    if (width < 480) return (4, 2);
    return (3, 2);
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;

    if (widget.isBaseVersion) {
      return _buildBaseModernContent(products);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final (itemNameFlex, numFlex) = _flexForWidth(constraints.maxWidth);
        final rowH = _rowHForHeight(constraints.maxHeight);
        return _buildContent(products, itemNameFlex, numFlex, rowH);
      },
    );
  }

  // ── BASE VERSION: fully responsive card layout ───────────────────────────

  static const Color _accent = Color(0xFF521C1D);
  static const Color _accentLight = Color(0xFFFFF5F5);

  Widget _buildBaseModernContent(List<Map<String, String>> products) {
    return LayoutBuilder(builder: (context, constraints) {
      final panelW = constraints.maxWidth;

      if (products.isEmpty) {
        return _emptyCart();
      }

      // ── Header ──
      final header = Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 16, color: _accent),
            const SizedBox(width: 6),
            Text('Order',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                    letterSpacing: 0.3)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _accentLight, borderRadius: BorderRadius.circular(20)),
              child: Text('${products.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accent)),
            ),
          ],
        ),
      );

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12)),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, i) =>
                      _responsiveCard(products[i], i, panelW),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Cart is empty',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Picks compact / medium / wide layout based on panel width
  Widget _responsiveCard(Map<String, String> p, int index, double panelW) {
    if (panelW < 300) return _cardCompact(p, index);
    if (panelW < 480) return _cardMedium(p, index);
    return _cardWide(p, index);
  }

  // ── NARROW (< 300px): single row ─────────────────────────────────────────
  Widget _cardCompact(Map<String, String> p, int index) {
    final name = (p["ShortDescription"] ?? "Item").trim();
    final qty = int.tryParse(p["quantity"] ?? "1") ?? 1;
    final unitPrice = widget.asDouble(p["UnitPrice"]);
    final taxRate = widget.asDouble(p["Tax1Rate"]);
    final lineTotal = unitPrice * qty * (1 + taxRate / 100);
    final dec = _decimals();
    final isReturn = p["isReturn"] == "true";
    final dispTotal = (isReturn ? -lineTotal : lineTotal).toStringAsFixed(dec);

    return _dismissibleWrapper(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: _cardDeco(),
        child: Row(
          children: [
            if (widget.showQtyControls) ...[
              _qtyCtrl(index, qty, compact: true),
              const SizedBox(width: 8),
            ],
            // Name
            Expanded(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333)))),
            const SizedBox(width: 6),
            // Total
            if (widget.showLineTotal)
              Text(dispTotal,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accent)),
            if (widget.showModifier) ...[
              const SizedBox(width: 4),
              _modifierIcon(p, index, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  // ── MEDIUM (300–480px): name + total top, qty + modifier bottom ──────────
  Widget _cardMedium(Map<String, String> p, int index) {
    final name = (p["ShortDescription"] ?? "Item").trim();
    final qty = int.tryParse(p["quantity"] ?? "1") ?? 1;
    final unitPrice = widget.asDouble(p["UnitPrice"]);
    final taxRate = widget.asDouble(p["Tax1Rate"]);
    final lineTotal = unitPrice * qty * (1 + taxRate / 100);
    final dec = _decimals();
    final isReturn = p["isReturn"] == "true";
    final dispTotal = (isReturn ? -lineTotal : lineTotal).toStringAsFixed(dec);
    final mods = (p["modifiers"] ?? "").trim();

    return _dismissibleWrapper(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333)))),
                const SizedBox(width: 8),
                if (widget.showLineTotal)
                  Text(dispTotal,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _accent)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.showQtyControls) ...[
                  _qtyCtrl(index, qty),
                  const SizedBox(width: 8),
                ],
                // Modifier chip
                if (widget.showModifier)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onModifierTap(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: mods.isNotEmpty
                              ? const Color(0xFFF3E5F5)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: mods.isNotEmpty
                                  ? Colors.purple.shade200
                                  : Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              mods.isNotEmpty
                                  ? Icons.edit_note
                                  : Icons.add_comment_outlined,
                              size: 13,
                              color: mods.isNotEmpty
                                  ? Colors.purple.shade700
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                mods.isNotEmpty ? mods : 'Add modifier',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: mods.isNotEmpty
                                      ? Colors.purple.shade700
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDE (≥ 480px): full detail card ─────────────────────────────────────
  Widget _cardWide(Map<String, String> p, int index) {
    final name = (p["ShortDescription"] ?? "Item").trim();
    final qty = int.tryParse(p["quantity"] ?? "1") ?? 1;
    final unitPrice = widget.asDouble(p["UnitPrice"]);
    final taxRate = widget.asDouble(p["Tax1Rate"]);
    final subTotal = unitPrice * qty;
    final taxAmt = subTotal * taxRate / 100;
    final lineTotal = subTotal + taxAmt;
    final dec = _decimals();
    final isReturn = p["isReturn"] == "true";
    final sign = isReturn ? -1 : 1;
    final mods = (p["modifiers"] ?? "").trim();

    return _dismissibleWrapper(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _cardDeco(elevated: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── top row: name + total ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A)))),
                  const SizedBox(width: 12),
                  if (widget.showLineTotal)
                    Text(
                      (sign * lineTotal).toStringAsFixed(dec),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isReturn ? Colors.red.shade700 : _accent),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── price details row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (widget.showUnitPrice) ...[
                    _detailChip(
                        'Unit', (sign * unitPrice).toStringAsFixed(dec)),
                    const SizedBox(width: 6),
                  ],
                  if (widget.showSubtotal) ...[
                    _detailChip('Sub', (sign * subTotal).toStringAsFixed(dec)),
                    const SizedBox(width: 6),
                  ],
                  if (widget.showTax)
                    _detailChip('Tax', '${taxRate.toStringAsFixed(1)}%',
                        small: true),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // ── bottom row: qty stepper + modifier ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (widget.showQtyControls) ...[
                    _qtyCtrl(index, qty),
                    const SizedBox(width: 10),
                  ],
                  if (widget.showModifier)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onModifierTap(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: mods.isNotEmpty
                                ? const Color(0xFFF3E5F5)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: mods.isNotEmpty
                                    ? Colors.purple.shade200
                                    : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                mods.isNotEmpty
                                    ? Icons.edit_note
                                    : Icons.add_comment_outlined,
                                size: 15,
                                color: mods.isNotEmpty
                                    ? Colors.purple.shade700
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  mods.isNotEmpty
                                      ? mods
                                      : 'Tap to add modifier',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: mods.isNotEmpty
                                        ? Colors.purple.shade700
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  BoxDecoration _cardDeco({bool elevated = false}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: elevated
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ]
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1)),
              ],
      );

  Widget _qtyCtrl(int index, int qty, {bool compact = false}) {
    final btnSz = compact ? 20.0 : 26.0;
    final numW = compact ? 28.0 : 36.0;
    return Container(
      decoration: BoxDecoration(
          color: _accentLight,
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          border: Border.all(color: _accent.withOpacity(0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sqBtn(
              () => widget.onQtyChange?.call(index, -1), Icons.remove, btnSz),
          SizedBox(
              width: numW,
              child: Center(
                  child: Text('$qty',
                      style: TextStyle(
                          fontSize: compact ? 11 : 13,
                          fontWeight: FontWeight.w700,
                          color: _accent)))),
          _sqBtn(() => widget.onQtyChange?.call(index, 1), Icons.add, btnSz),
        ],
      ),
    );
  }

  Widget _sqBtn(VoidCallback onTap, IconData icon, double size) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.55, color: _accent)),
      ),
    );
  }

  Widget _modifierIcon(Map<String, String> p, int index, {double size = 18}) {
    final hasMods = (p["modifiers"] ?? "").trim().isNotEmpty;
    return GestureDetector(
      onTap: () => widget.onModifierTap(index),
      child: Icon(
        hasMods ? Icons.edit_note : Icons.add_comment_outlined,
        size: size,
        color: hasMods ? Colors.purple.shade600 : Colors.grey.shade400,
      ),
    );
  }

  Widget _detailChip(String label, String value, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 3 : 4),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: '$label ',
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
            TextSpan(
                text: value,
                style: TextStyle(
                    fontSize: small ? 10 : 11,
                    color: const Color(0xFF333333),
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _dismissibleWrapper({required int index, required Widget child}) {
    return Dismissible(
      key: ValueKey(
          '${widget.products[index]["ProductID"]}_${index}_${widget.products[index]["quantity"]}'),
      direction: widget.allowDelete
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.delete_outline, color: Colors.red.shade700, size: 26),
      ),
      onDismissed: (_) {
        if (widget.allowDelete) widget.onRemoveItem?.call(index);
      },
      child: child,
    );
  }

  Widget _buildContent(List<Map<String, String>> products, int itemNameFlex,
      int numFlex, double rowH) {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 4.0 : 6.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF521C1D).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Items + count)
          Padding(
            padding: EdgeInsets.only(bottom: widget.compact ? 4.0 : 6.0),
            child: Row(
              children: [
                Text(
                  "Items",
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF521C1D),
                  ),
                ),
                const Spacer(),
                if (products.isNotEmpty)
                  Text(
                    "${products.length} item(s)",
                    style: TextStyle(
                      fontSize: widget.fontSize - 1,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),

          // Table: fixed to left panel width, no horizontal scroll
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerRow(itemNameFlex: itemNameFlex, numFlex: numFlex),
                  Expanded(
                    child: Scrollbar(
                      controller: _vCtrl,
                      thumbVisibility: true,
                      notificationPredicate: (n) =>
                          n.metrics.axis == Axis.vertical,
                      child: ListView.builder(
                        controller: _vCtrl,
                        itemCount: products.length,
                        itemExtent: rowH,
                        itemBuilder: (context, index) {
                          final p = products[index];
                          final isSelected = widget.selectedRowIndex == index;
                          return _row(
                              index: index,
                              p: p,
                              isSelected: isSelected,
                              itemNameFlex: itemNameFlex,
                              numFlex: numFlex,
                              rowH: rowH);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required int index,
    required Map<String, String> p,
    required bool isSelected,
    required int itemNameFlex,
    required int numFlex,
    required double rowH,
  }) {
    final isReturn = p["isReturn"] == "true";

    final itemName = (p["ShortDescription"] ?? "Item").trim();
    final qtyStr = p["quantity"] ?? "1";

    final unitPrice = widget.asDouble(p["UnitPrice"]);
    final qty = int.tryParse(qtyStr) ?? 1;

    final subTotal = unitPrice * qty;
    final taxRate = widget.asDouble(p["Tax1Rate"]);
    final taxAmount = (subTotal * taxRate) / 100;
    final lineTotal = subTotal + taxAmount;

    final mods = (p["modifiers"] ?? "").trim();
    final hasMods = mods.isNotEmpty;

    final rowBg = isSelected ? const Color(0xFF521C1D) : Colors.white;
    final textColor = isSelected ? Colors.white : Colors.grey.shade900;
    final subtle = isSelected ? Colors.white70 : Colors.grey.shade700;

    final dispQty = isReturn ? "-$qtyStr" : qtyStr;
    final dispUnit = isReturn ? "-${_money(unitPrice)}" : _money(unitPrice);
    final dispSub = isReturn ? "-${_money(subTotal)}" : _money(subTotal);
    final dispLine = isReturn ? "-${_money(lineTotal)}" : _money(lineTotal);

    // Tax% should show percent number only (like VB)
    final taxPct = taxRate.toStringAsFixed(2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onRowTap(index),
      onSecondaryTapDown: (d) =>
          widget.onRowContextMenu(index, d.globalPosition),
      onLongPressStart: (d) => widget.onRowContextMenu(index, d.globalPosition),
      child: Container(
        height: rowH,
        decoration: BoxDecoration(
          color: rowBg,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            _cell("${index + 1}", _wNo,
                align: Alignment.center,
                style: _cellStyle(
                    isSelected ? Colors.white : const Color(0xFF521C1D),
                    bold: true)),
            _dividerV(),

            Expanded(
                flex: itemNameFlex,
                child: _cellContent(itemName,
                    style: _cellStyle(textColor), align: Alignment.centerLeft)),
            _dividerV(),

            // Modifier column – shows selected modifier(s), click to add/edit
            if (widget.showModifier)
              Expanded(
                flex: 2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onModifierTap(index),
                    child: Tooltip(
                      message: hasMods ? mods : 'Tap to add modifier',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            hasMods ? mods : 'M',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize:
                                  (widget.fontSize - 2).clamp(9, 12).toDouble(),
                              fontWeight:
                                  hasMods ? FontWeight.w700 : FontWeight.w600,
                              color: hasMods
                                  ? (isSelected
                                      ? Colors.white
                                      : const Color(0xFF521C1D))
                                  : (isSelected
                                      ? Colors.white70
                                      : Colors.grey.shade600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.showModifier) _dividerV(),

            _cell(dispQty, _wQty,
                align: Alignment.center,
                style: _cellStyle(textColor, bold: true)),
            _dividerV(),

            if (widget.showUnitPrice) ...[
              Expanded(
                  flex: numFlex,
                  child: _cellContent(dispUnit,
                      align: Alignment.centerRight,
                      style: _cellStyle(textColor))),
              _dividerV(),
            ],

            if (widget.showSubtotal) ...[
              Expanded(
                  flex: numFlex,
                  child: _cellContent(dispSub,
                      align: Alignment.centerRight,
                      style: _cellStyle(textColor))),
              _dividerV(),
            ],

            if (widget.showTax) ...[
              _cell(taxPct, _wTax,
                  align: Alignment.center, style: _cellStyle(subtle)),
              _dividerV(),
            ],

            if (widget.showLineTotal)
              Expanded(
                  flex: numFlex,
                  child: _cellContent(dispLine,
                      align: Alignment.centerRight,
                      style: _cellStyle(textColor, bold: true))),
          ],
        ),
      ),
    );
  }
}
