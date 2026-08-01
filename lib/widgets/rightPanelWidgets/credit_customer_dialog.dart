import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';

const _brand = Color(0xFF6B0000);
const _brand2 = Color(0xFF521C1D);
const _brandBg = Color(0xFFF8EDED);
const _brandBorder = Color(0xFFD4A5A5);
const _border = Color(0xFFE5E5E5);
const _green = Color(0xFF15803D);
const _greenBg = Color(0xFFDCFCE7);
const _red = Color(0xFFDC2626);
const _redBg = Color(0xFFFEE2E2);

/// Credit customer selected for bill settlement (Counter-POS CreditCustomerModal).
class CreditCustomerSelection {
  final String customerId;
  final String customerCode;
  final String customerName;
  final double osAmount;
  final String? mobileNo;
  final String? telephone;
  final String? address;
  final String? taxRegNo;

  const CreditCustomerSelection({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    this.osAmount = 0,
    this.mobileNo,
    this.telephone,
    this.address,
    this.taxRegNo,
  });
}

Future<CreditCustomerSelection?> showCreditCustomerDialog(
  BuildContext context, {
  String? initialSearch,
}) {
  return showDialog<CreditCustomerSelection>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CreditCustomerDialog(initialSearch: initialSearch),
  );
}

class CreditCustomerDialog extends StatefulWidget {
  final String? initialSearch;
  const CreditCustomerDialog({super.key, this.initialSearch});

  @override
  State<CreditCustomerDialog> createState() => _CreditCustomerDialogState();
}

class _CreditCustomerDialogState extends State<CreditCustomerDialog> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  final _nameFocus = FocusNode();
  Timer? _debounce;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  int _selected = -1;
  String _focus = 'code';

  @override
  void initState() {
    super.initState();
    final q = widget.initialSearch?.trim() ?? '';
    if (q.isNotEmpty) _nameCtrl.text = q;
    _codeFocus.addListener(() {
      if (_codeFocus.hasFocus) setState(() => _focus = 'code');
    });
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) setState(() => _focus = 'name');
    });
    _load(q);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _codeFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _schedule(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(q));
  }

  Future<void> _load(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<Map<String, dynamic>> list = [];
      try {
        list = await ApiService().fetchCreditSettlementCustomers(search: q);
      } catch (_) {
        list = [];
      }
      if (list.isEmpty) {
        final all = await ApiService().fetchCustomers(search: q, limit: 200);
        list = all
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((c) {
          final mode = (c['paymentMode'] ?? c['PaymentMode'] ?? '')
              .toString()
              .trim()
              .toUpperCase()
              .replaceAll(' ', '');
          return mode == 'CREDIT';
        }).map(_normalizeRow).toList();
      } else {
        list = list.map(_normalizeRow).toList();
      }
      if (!mounted) return;
      setState(() {
        _rows = list;
        _selected = -1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> c) {
    return {
      'customerId': c['customerId'] ?? c['CustomerID'],
      'customerCode': c['customerCode'] ?? c['CustomerCode'] ?? '',
      'customerName': c['customerName'] ?? c['CustomerName'] ?? '',
      'osAmount': double.tryParse(
              (c['osAmount'] ?? c['creditBalance'] ?? '0').toString()) ??
          0,
      'mobileNo': c['mobileNo'] ?? c['MobileNo'] ?? '',
      'telephone': c['telephone'] ?? c['Telephone'] ?? '',
      'address': c['address'] ?? c['Address'] ?? '',
      'taxRegNo': c['taxRegNo'] ?? c['CustTRN'] ?? '',
      'paymentMode': 'CREDIT',
    };
  }

  void _selectRow(int i) {
    if (i < 0 || i >= _rows.length) return;
    final c = _rows[i];
    setState(() {
      _selected = i;
      _codeCtrl.text = (c['customerCode'] ?? '').toString();
      _nameCtrl.text = (c['customerName'] ?? '').toString();
    });
  }

  void _pressKey(String k) {
    final ctrl = _focus == 'name' ? _nameCtrl : _codeCtrl;
    if (k == '⌫') {
      final t = ctrl.text;
      if (t.isEmpty) return;
      ctrl.text = t.substring(0, t.length - 1);
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
      _schedule(ctrl.text);
      return;
    }
    ctrl.text = ctrl.text + k;
    ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    _schedule(ctrl.text);
  }

  void _apply() {
    if (_selected < 0 || _selected >= _rows.length) return;
    final c = _rows[_selected];
    final id = (c['customerId'] ?? '').toString();
    if (id.isEmpty || id == '0') return;
    Navigator.of(context).pop(CreditCustomerSelection(
      customerId: id,
      customerCode: (c['customerCode'] ?? '').toString(),
      customerName: (c['customerName'] ?? '').toString(),
      osAmount: double.tryParse((c['osAmount'] ?? 0).toString()) ?? 0,
      mobileNo: (c['mobileNo'] ?? '').toString(),
      telephone: (c['telephone'] ?? '').toString(),
      address: (c['address'] ?? '').toString(),
      taxRegNo: (c['taxRegNo'] ?? '').toString(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        elevation: 12,
        child: SizedBox(
          width: 700,
          height: 520,
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_brand, _brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Credit Customer Selection',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: Row(
                  children: [
                    // Left list
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _brandBorder, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Container(
                                color: _brandBg,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        'CUSTOMER CODE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _brand,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'CUSTOMER NAME',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _brand,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(child: _buildList()),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: _border),
                    // Right pane
                    SizedBox(
                      width: 260,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _fieldLabel('Customer Code :'),
                            const SizedBox(height: 3),
                            _inputField(
                              controller: _codeCtrl,
                              focusNode: _codeFocus,
                              active: _focus == 'code',
                              onChanged: (v) {
                                _nameCtrl.clear();
                                _schedule(v);
                              },
                            ),
                            const SizedBox(height: 8),
                            _fieldLabel('Customer Name :'),
                            const SizedBox(height: 3),
                            _inputField(
                              controller: _nameCtrl,
                              focusNode: _nameFocus,
                              active: _focus == 'name',
                              onChanged: (v) {
                                _codeCtrl.clear();
                                _schedule(v);
                              },
                            ),
                            const SizedBox(height: 10),
                            Expanded(child: _numPad()),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed:
                                            _selected >= 0 ? _apply : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _selected >= 0
                                              ? _brand
                                              : _border,
                                          foregroundColor: _selected >= 0
                                              ? Colors.white
                                              : Colors.black38,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Apply',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: _border, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Close',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: Colors.black87,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _brand, strokeWidth: 2),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _red, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Text(
          'No credit customers found',
          style: TextStyle(color: Colors.black45, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      itemCount: _rows.length,
      itemBuilder: (_, i) {
        final c = _rows[i];
        final active = i == _selected;
        final os =
            double.tryParse((c['osAmount'] ?? 0).toString()) ?? 0;
        return Column(
          children: [
            InkWell(
              onTap: () => _selectRow(i),
              onDoubleTap: () {
                _selectRow(i);
                _apply();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? _brandBg : Colors.white,
                  border: Border(
                    left: BorderSide(
                        color: active ? _brand : Colors.transparent, width: 3),
                    bottom: const BorderSide(color: _border),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        (c['customerCode'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        (c['customerName'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (active)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: os > 0 ? _redBg : _greenBg,
                  border: Border(
                    left: BorderSide(
                        color: os > 0 ? _red : _green, width: 3),
                    bottom: const BorderSide(color: _border),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      os > 0 ? Icons.error_outline : Icons.check_circle_outline,
                      size: 13,
                      color: os > 0 ? _red : _green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Outstanding Balance',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: os > 0 ? _red : _green,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${os.toStringAsFixed(2)} ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: os > 0 ? _red : _green,
                      ),
                    ),
                    Text(
                      'AED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: (os > 0 ? _red : _green).withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _brand,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool active,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: active ? _brandBg : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
                color: active ? _brand : _border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
                color: active ? _brand : _border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: _brand, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _numPad() {
    const rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
    ];
    return Column(
      children: [
        for (final row in rows) ...[
          Expanded(
            child: Row(
              children: [
                for (final k in row) ...[
                  Expanded(child: _numBtn(k)),
                  if (k != row.last) const SizedBox(width: 5),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
        ],
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 2, child: _numBtn('0')),
              const SizedBox(width: 5),
              Expanded(child: _numBtn('.')),
              const SizedBox(width: 5),
              Expanded(
                child: _numBtn('⌫',
                    bg: _redBg, border: _red.withValues(alpha: 0.35), fg: _red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _numBtn(String label,
      {Color bg = Colors.white, Color? border, Color fg = Colors.black87}) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _pressKey(label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border ?? _border, width: 1.5),
          ),
          child: label == '⌫'
              ? Icon(Icons.backspace_outlined, size: 15, color: fg)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
        ),
      ),
    );
  }
}
