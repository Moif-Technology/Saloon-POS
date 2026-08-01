import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/services/api_service.dart';

/// Outstanding Bills — loads credit customers with O/S from the same
/// settlement API Counter-POS uses (`/salon-pos/settlement/credit-customers`).
class OutstandingBillsDialog extends StatefulWidget {
  const OutstandingBillsDialog({super.key});

  static const Color _primaryColor = Color(0xFF521C1D);

  static const int _flexSlNo = 1;
  static const int _flexCustomer = 4;
  static const int _flexCode = 2;
  static const int _flexOsAmount = 2;

  @override
  State<OutstandingBillsDialog> createState() => _OutstandingBillsDialogState();
}

class _OutstandingBillsDialogState extends State<OutstandingBillsDialog> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmt(num v) => NumberFormat('#,##0.00').format(v);

  Future<void> _load(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await ApiService().fetchCreditSettlementCustomers(search: q);
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(q));
  }

  double get _totalOs => _rows.fold<double>(0, (s, r) {
        final v = r['osAmount'] ?? r['OsAmount'] ?? 0;
        return s + (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
      });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth > 900 ? 900 : screenWidth * 0.95;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: dialogWidth,
        height:
            screenWidth > 600 ? 700 : MediaQuery.of(context).size.height * 0.88,
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
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.only(left: 20, right: 8),
              color: OutstandingBillsDialog._primaryColor,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Outstanding Bills',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading
                        ? null
                        : () => _load(_searchCtrl.text.trim()),
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Material(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search customer name / code / mobile',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildTable()),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total O/S: ${_fmt(_totalOs)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: OutstandingBillsDialog._primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: OutstandingBillsDialog._primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: const [
                _Hdr('Sl No', OutstandingBillsDialog._flexSlNo),
                _Hdr('Customer', OutstandingBillsDialog._flexCustomer),
                _Hdr('Code', OutstandingBillsDialog._flexCode),
                _Hdr('O/S Amount', OutstandingBillsDialog._flexOsAmount),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(
                        child: Text('No credit customers with outstanding'),
                      )
                    : ListView.builder(
                        itemCount: _rows.length,
                        itemBuilder: (context, index) {
                          final r = _rows[index];
                          final os = r['osAmount'] ?? 0;
                          final osNum = os is num
                              ? os.toDouble()
                              : double.tryParse('$os') ?? 0;
                          return Container(
                            color: index.isEven
                                ? Colors.white
                                : Colors.grey.shade50,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: Row(
                              children: [
                                _Cell('${index + 1}',
                                    OutstandingBillsDialog._flexSlNo),
                                _Cell(
                                  (r['customerName'] ?? '').toString(),
                                  OutstandingBillsDialog._flexCustomer,
                                  align: TextAlign.left,
                                ),
                                _Cell(
                                  (r['customerCode'] ?? '').toString(),
                                  OutstandingBillsDialog._flexCode,
                                ),
                                _Cell(
                                  _fmt(osNum),
                                  OutstandingBillsDialog._flexOsAmount,
                                  bold: true,
                                ),
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
}

class _Hdr extends StatelessWidget {
  final String label;
  final int flex;
  const _Hdr(this.label, this.flex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: OutstandingBillsDialog._primaryColor,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  final bool bold;
  const _Cell(this.text, this.flex,
      {this.align = TextAlign.center, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
