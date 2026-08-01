import 'package:flutter/material.dart';

const _brand = Color(0xFF6B0000);
const _brand2 = Color(0xFF521C1D);
const _brandBg = Color(0xFFF8EDED);
const _brandBorder = Color(0xFFD4A5A5);
const _border = Color(0xFFE5E5E5);
const _surface2 = Color(0xFFF5F5F5);
const _green = Color(0xFF15803D);
const _greenBg = Color(0xFFDCFCE7);
const _greenBorder = Color(0xFF86EFAC);
const _red = Color(0xFFDC2626);
const _redBg = Color(0xFFFEE2E2);
const _redBorder = Color(0xFFFECACA);
const _blue = Color(0xFF1D4ED8);
const _blueBg = Color(0xFFDBEAFE);
const _blueBorder = Color(0xFF93C5FD);
const _purple = Color(0xFF7C3AED);
const _purpleBg = Color(0xFFEDE9FE);
const _purpleBorder = Color(0xFFC4B5FD);

/// Result of Multi Payment / Split Payment dialog.
class MultiPayResult {
  final List<Map<String, dynamic>> splits;
  final double total;

  const MultiPayResult({required this.splits, required this.total});
}

Future<MultiPayResult?> showMultiPayDialog(
  BuildContext context, {
  required double billAmount,
  int currencyDecimals = 2,
  List<Map<String, dynamic>>? initialSplits,
}) {
  return showDialog<MultiPayResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => MultiPayDialog(
      billAmount: billAmount,
      currencyDecimals: currencyDecimals,
      initialSplits: initialSplits,
    ),
  );
}

class MultiPayDialog extends StatefulWidget {
  final double billAmount;
  final int currencyDecimals;
  final List<Map<String, dynamic>>? initialSplits;

  const MultiPayDialog({
    super.key,
    required this.billAmount,
    this.currencyDecimals = 2,
    this.initialSplits,
  });

  @override
  State<MultiPayDialog> createState() => _MultiPayDialogState();
}

class _MultiPayDialogState extends State<MultiPayDialog> {
  static const _modes = [
    _ModeStyle('CASH', _brand, _brandBg, _brandBorder),
    _ModeStyle('CREDITCARD', _brand, _brandBg, _brandBorder),
    _ModeStyle('ONLINE', _blue, _blueBg, _blueBorder),
    _ModeStyle('VOUCHER', Colors.black54, _surface2, _border),
  ];

  final _rows = <_SplitRow>[];
  int? _selectedId;
  int _seq = 1;
  String _payMode = 'CASH';
  String _amount = '';
  String _tip = '';
  String _ref = '';
  String _focusField = 'amount';
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSplits ?? const [];
    for (final s in initial) {
      _rows.add(_SplitRow(
        id: _seq++,
        payerNo: _rows.length + 1,
        payMode: (s['payMode'] ?? 'CASH').toString(),
        amount: double.tryParse(s['amount']?.toString() ?? '') ?? 0,
        tip: double.tryParse(s['tip']?.toString() ?? '') ?? 0,
        refNo: (s['refNo'] ?? '').toString(),
      ));
    }
    _renumber();
  }

  String _fmt(double v) => v.toStringAsFixed(widget.currencyDecimals);

  double get _billTotal =>
      _rows.fold<double>(0, (a, r) => a + r.amount);

  double get _tipTotal => _rows.fold<double>(0, (a, r) => a + r.tip);

  double get _remaining {
    final r = widget.billAmount - _billTotal;
    return double.parse(r.toStringAsFixed(widget.currencyDecimals));
  }

  double get _grandTotal => _billTotal + _tipTotal;

  bool get _balanced => _remaining.abs() <= 0.02 && _rows.isNotEmpty;

  void _renumber() {
    for (var i = 0; i < _rows.length; i++) {
      _rows[i] = _rows[i].copyWith(payerNo: i + 1);
    }
  }

  void _setFocus(String field) => setState(() => _focusField = field);

  String _fieldValue(String field) {
    if (field == 'amount') return _amount;
    if (field == 'tip') return _tip;
    return _ref;
  }

  void _setFieldValue(String field, String value) {
    setState(() {
      if (field == 'amount') {
        _amount = value;
      } else if (field == 'tip') {
        _tip = value;
      } else {
        _ref = value;
      }
      _error = null;
    });
  }

  bool _validMoney(String next) {
    if (next.isEmpty) return true;
    return RegExp(r'^\d*\.?\d{0,3}$').hasMatch(next);
  }

  void _appendKey(String key) {
    if (_focusField == 'ref') {
      _setFieldValue('ref', _ref + key);
      return;
    }
    final cur = _fieldValue(_focusField);
    final next = cur + key;
    if (!_validMoney(next)) return;
    _setFieldValue(_focusField, next);
  }

  void _backspace() {
    final cur = _fieldValue(_focusField);
    if (cur.isEmpty) return;
    _setFieldValue(_focusField, cur.substring(0, cur.length - 1));
  }

  void _clearField() => _setFieldValue(_focusField, '');

  void _useRemaining() {
    if (_remaining <= 0) {
      setState(() => _error = 'No remaining balance to apply.');
      return;
    }
    setState(() {
      _amount = _fmt(_remaining);
      _focusField = 'amount';
      _error = null;
    });
  }

  void _addRow() {
    if (_remaining <= 0.01) {
      setState(() => _error = 'Split balance is 0.00 — cannot add more rows.');
      return;
    }
    final amt = double.tryParse(_amount.replaceAll(',', '')) ?? 0;
    final tipAmt = double.tryParse(_tip.replaceAll(',', '')) ?? 0;
    if (amt <= 0) {
      setState(() {
        _error = 'Enter split amount.';
        _focusField = 'amount';
      });
      return;
    }
    if (amt > _remaining + 0.01) {
      setState(() {
        _error = 'Amount exceeds remaining balance (${_fmt(_remaining)}).';
        _focusField = 'amount';
      });
      return;
    }
    setState(() {
      final id = _seq++;
      _rows.add(_SplitRow(
        id: id,
        payerNo: _rows.length + 1,
        payMode: _payMode,
        amount: amt,
        tip: tipAmt,
        refNo: _ref.trim(),
      ));
      _renumber();
      _selectedId = id;
      _amount = '';
      _tip = '';
      _ref = '';
      _focusField = 'amount';
      _error = null;
    });
  }

  void _removeSelected() {
    if (_selectedId == null) return;
    setState(() {
      _rows.removeWhere((r) => r.id == _selectedId);
      _renumber();
      _selectedId = null;
      _error = null;
    });
  }

  void _clearAll() {
    setState(() {
      _rows.clear();
      _selectedId = null;
      _error = null;
    });
  }

  void _done() {
    if (_rows.isEmpty) {
      setState(() => _error = 'Add split rows first.');
      return;
    }
    if (!_balanced) {
      setState(
          () => _error = 'Split not completed. Balance: ${_fmt(_remaining)}');
      return;
    }
    Navigator.of(context).pop(MultiPayResult(
      total: _billTotal,
      splits: _rows
          .map((r) => {
                'payMode': r.payMode,
                'amount': r.amount,
                'tip': r.tip,
                'refNo': r.refNo,
              })
          .toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        elevation: 12,
        child: SizedBox(
          width: 700,
          height: 640,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _modeButtons(),
                      const SizedBox(height: 14),
                      _inputAndPad(),
                      const SizedBox(height: 14),
                      _splitsTable(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _actionBtn(
                                  'Remove Selected', _removeSelected)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _actionBtn('Clear All', _clearAll,
                                  danger: true)),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _redBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _redBorder, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 14, color: _red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: _red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: _border),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _summaryLabel('Paid', _fmt(_billTotal)),
                          const SizedBox(width: 20),
                          _summaryLabel('Tips', _fmt(_tipTotal)),
                          const SizedBox(width: 20),
                          _summaryLabel('Grand Total', _fmt(_grandTotal),
                              valueColor: _green),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  color: _surface2,
                  border: Border(top: BorderSide(color: _border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _balanced ? _done : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _balanced ? _brand : _border,
                            foregroundColor:
                                _balanced ? Colors.white : Colors.black38,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _redBg,
                            side: const BorderSide(
                                color: _redBorder, width: 1.5),
                            foregroundColor: _red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_brand, _brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.layers, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SETTLEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0x88FFFFFF),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Split Payment',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child:
                      const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _headerChip('Bill Total', _fmt(widget.billAmount)),
              const SizedBox(width: 8),
              _headerChip('Remaining', _fmt(_remaining),
                  accent: !_balanced),
              const SizedBox(width: 8),
              _headerChip('Paid', _fmt(_billTotal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label, String value, {bool accent = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            children: [
              TextSpan(text: '$label '),
              TextSpan(
                text: value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: accent ? const Color(0xFFFECACA) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButtons() {
    return Row(
      children: [
        for (var i = 0; i < _modes.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: () => setState(() => _payMode = _modes[i].key),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _payMode == _modes[i].key
                      ? _modes[i].bg
                      : Colors.white,
                  foregroundColor: _payMode == _modes[i].key
                      ? _modes[i].color
                      : Colors.black45,
                  side: BorderSide(
                    color: _payMode == _modes[i].key
                        ? _modes[i].border
                        : _border,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  _modes[i].key,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _inputAndPad() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _fieldRow('Amount', 'amount', _amount, mono: true),
              const SizedBox(height: 8),
              _fieldRow('Tip', 'tip', _tip, mono: true),
              const SizedBox(height: 8),
              _fieldRow('Ref', 'ref', _ref, mono: false),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: _addRow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'ADD PAYMENT',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 228,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton(
                  onPressed: _useRemaining,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _greenBg,
                    foregroundColor: _green,
                    side: const BorderSide(color: _greenBorder, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Use Remaining',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _numPad(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldRow(String label, String field, String value,
      {required bool mono}) {
    final focused = _focusField == field;
    final placeholder =
        field == 'ref' ? 'Reference…' : _fmt(0).replaceAll('0', '0');
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => _setFocus(field),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: focused ? _brandBg : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: focused ? _brandBorder : _border,
                  width: 1.5,
                ),
              ),
              child: Text(
                value.isEmpty
                    ? (field == 'ref' ? placeholder : '0.00')
                    : value,
                style: TextStyle(
                  fontSize: mono ? 15 : 12,
                  fontWeight: mono ? FontWeight.w800 : FontWeight.w600,
                  fontFamily: mono ? 'monospace' : null,
                  color: value.isEmpty ? Colors.black38 : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _numPad() {
    const keys = [
      '7', '8', '9',
      '4', '5', '6',
      '1', '2', '3',
      '0', '.', '00',
    ];
    return Column(
      children: [
        for (var r = 0; r < 4; r++) ...[
          if (r > 0) const SizedBox(height: 6),
          Row(
            children: [
              for (var c = 0; c < 3; c++) ...[
                if (c > 0) const SizedBox(width: 6),
                Expanded(
                  child: _numBtn(keys[r * 3 + c], () => _appendKey(keys[r * 3 + c])),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _numBtn('', _backspace,
                  child: const Icon(Icons.backspace_outlined, size: 15)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _numBtn('C', _clearField,
                  bg: _surface2, fg: Colors.black54),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _numBtn('ADD', _addRow,
                  bg: _purpleBg, border: _purpleBorder, fg: _purple),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numBtn(
    String label,
    VoidCallback onTap, {
    Color bg = Colors.white,
    Color? border,
    Color fg = Colors.black87,
    Widget? child,
  }) {
    return SizedBox(
      height: 44,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border ?? _border, width: 1.5),
            ),
            child: child ??
                Text(
                  label,
                  style: TextStyle(
                    fontSize: label.length > 2 ? 11 : 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: label == 'C' || label == 'ADD'
                        ? null
                        : 'monospace',
                    color: fg,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _splitsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: _surface2,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: const Row(
              children: [
                SizedBox(
                    width: 36,
                    child: Text('#',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black45))),
                Expanded(
                    flex: 2,
                    child: Text('REF',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black45))),
                Expanded(
                    flex: 2,
                    child: Text('MODE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black45))),
                Expanded(
                    child: Text('AMOUNT',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black45))),
                Expanded(
                    child: Text('TIP',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black45))),
              ],
            ),
          ),
          if (_rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No payments added',
                style: TextStyle(
                    color: Colors.black38, fontWeight: FontWeight.w600),
              ),
            )
          else
            for (final r in _rows)
              InkWell(
                onTap: () => setState(() => _selectedId = r.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: r.id == _selectedId ? _brandBg : Colors.white,
                    border: const Border(
                        bottom: BorderSide(color: _border)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text('${r.payerNo}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: r.id == _selectedId
                                  ? _brand
                                  : Colors.black87,
                            )),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.refNo.isEmpty ? '—' : r.refNo,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: r.id == _selectedId
                                ? _brand
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.payMode,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: r.id == _selectedId
                                ? _brand
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _fmt(r.amount),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: r.id == _selectedId
                                ? _brand
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _fmt(r.tip),
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: r.id == _selectedId
                                ? _brand
                                : Colors.black87,
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

  Widget _actionBtn(String label, VoidCallback onTap, {bool danger = false}) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: danger ? _redBg : Colors.white,
          foregroundColor: danger ? _red : Colors.black54,
          side: BorderSide(
            color: danger ? _redBorder : _border,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _summaryLabel(String label, String value, {Color? valueColor}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'monospace',
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeStyle {
  final String key;
  final Color color;
  final Color bg;
  final Color border;
  const _ModeStyle(this.key, this.color, this.bg, this.border);
}

class _SplitRow {
  final int id;
  final int payerNo;
  final String payMode;
  final double amount;
  final double tip;
  final String refNo;

  const _SplitRow({
    required this.id,
    required this.payerNo,
    required this.payMode,
    required this.amount,
    required this.tip,
    required this.refNo,
  });

  _SplitRow copyWith({int? payerNo}) => _SplitRow(
        id: id,
        payerNo: payerNo ?? this.payerNo,
        payMode: payMode,
        amount: amount,
        tip: tip,
        refNo: refNo,
      );
}
