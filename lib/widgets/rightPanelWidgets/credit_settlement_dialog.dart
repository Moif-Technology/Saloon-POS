import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/services/api_service.dart';

const _accent = Color(0xFF521C1D);

/// Credit Payment Receipt — same flow as Counter-POS CreditSettlementModal:
/// list customers → settle against O/S → history.
Future<void> showCreditSettlementDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const CreditSettlementDialog(),
  );
}

class CreditSettlementDialog extends StatefulWidget {
  const CreditSettlementDialog({super.key});

  @override
  State<CreditSettlementDialog> createState() => _CreditSettlementDialogState();
}

class _CreditSettlementDialogState extends State<CreditSettlementDialog> {
  String _step = 'list'; // list | settle | history
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selected;
  Map<String, dynamic>? _billData;
  final _amountCtrl = TextEditingController();
  String _payMode = 'CASH';

  bool _loading = false;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _success;

  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(num v) => NumberFormat('#,##0.00').format(v);

  Future<void> _loadCustomers(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await ApiService().fetchCreditSettlementCustomers(search: q);
      if (!mounted) return;
      setState(() {
        _customers = list;
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

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _loadCustomers(q));
  }

  Future<void> _openSettle(Map<String, dynamic> c) async {
    setState(() {
      _selected = c;
      _step = 'settle';
      _amountCtrl.clear();
      _payMode = 'CASH';
      _error = null;
      _success = null;
      _loading = true;
      _billData = null;
    });
    try {
      final id = (c['customerId'] ?? '').toString();
      final data = await ApiService().fetchCustomerOutstandingBills(id);
      if (!mounted) return;
      setState(() {
        _billData = data;
        _loading = false;
        final os = double.tryParse(
                (data['billsTotal'] ?? data['osAmount'] ?? 0).toString()) ??
            0;
        if (os > 0) _amountCtrl.text = os.toStringAsFixed(2);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _settle() async {
    if (_selected == null || _saving) return;
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid settlement amount');
      return;
    }
    final maxOs = double.tryParse(
            (_billData?['billsTotal'] ?? _billData?['osAmount'] ?? 0)
                .toString()) ??
        0;
    if (amount > maxOs + 0.02) {
      setState(() => _error = 'Amount cannot exceed O/S (${_fmt(maxOs)})');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ApiService().saveCreditSettlement(
        customerId: _selected!['customerId'],
        amount: amount,
        paymentMode: _payMode,
      );
      if (!mounted) return;
      setState(() {
        _success = result;
        _saving = false;
        _amountCtrl.clear();
      });
      final id = (_selected!['customerId'] ?? '').toString();
      final data = await ApiService().fetchCustomerOutstandingBills(id);
      if (!mounted) return;
      setState(() => _billData = data);
      _loadCustomers(_searchCtrl.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _step = 'history';
      _loading = true;
      _error = null;
    });
    try {
      final to = DateTime.now();
      final from = to.subtract(const Duration(days: 30));
      String ymd(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final list = await ApiService().fetchCreditSettlementHistory(
        dateFrom: ymd(from),
        dateTo: ymd(to),
      );
      if (!mounted) return;
      setState(() {
        _history = list;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: (size.width * 0.88).clamp(720.0, 1000.0),
        height: (size.height * 0.82).clamp(480.0, 700.0),
        child: Column(
          children: [
            _header(),
            if (_error != null)
              Material(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          if (_step != 'list')
            IconButton(
              tooltip: 'Back',
              onPressed: () => setState(() {
                _step = 'list';
                _success = null;
                _error = null;
              }),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          const Icon(Icons.receipt_long, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _step == 'list'
                  ? 'Credit Payment Receipt'
                  : _step == 'settle'
                      ? 'Settle Credit — ${_selected?['customerName'] ?? ''}'
                      : 'Settlement History',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17),
            ),
          ),
          if (_step == 'list')
            TextButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.history, color: Colors.white, size: 18),
              label: const Text('History',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_step == 'history') return _historyView();
    if (_step == 'settle') return _settleView();
    return _listView();
  }

  Widget _listView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Search credit customer code / name…',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _customers.isEmpty
                  ? const Center(
                      child: Text('No credit customers with outstanding',
                          style: TextStyle(color: Colors.black54)))
                  : ListView.separated(
                      itemCount: _customers.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, i) {
                        final c = _customers[i];
                        final os = double.tryParse(
                                (c['osAmount'] ?? 0).toString()) ??
                            0;
                        return ListTile(
                          title: Text(
                            (c['customerName'] ?? '').toString(),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('Code: ${c['customerCode'] ?? ''}'),
                          trailing: Text(
                            _fmt(os),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: _accent),
                          ),
                          onTap: () => _openSettle(c),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _settleView() {
    final bills = (_billData?['bills'] as List?) ?? const [];
    final os = double.tryParse(
            (_billData?['billsTotal'] ?? _billData?['osAmount'] ?? 0)
                .toString()) ??
        0;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_selected?['customerName'] ?? '').toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text('Code: ${_selected?['customerCode'] ?? ''}'),
                      const SizedBox(height: 6),
                      Text('Outstanding: ${_fmt(os)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _accent,
                              fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Outstanding Bills (oldest first)',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: _accent))
                      : bills.isEmpty
                          ? const Center(child: Text('No open bills'))
                          : ListView.separated(
                              itemCount: bills.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final b = Map<String, dynamic>.from(
                                    bills[i] as Map);
                                final amt = double.tryParse(
                                        (b['currentAmount'] ??
                                                b['invoiceAmount'] ??
                                                0)
                                            .toString()) ??
                                    0;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    (b['invoiceNo'] ?? b['billNo'] ?? b['billId'] ?? '')
                                        .toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                      (b['billDate'] ?? '').toString()),
                                  trailing: Text(_fmt(amt),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Settlement Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _payChip('CASH', Icons.attach_money)),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            _payChip('CREDITCARD', Icons.credit_card)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_success != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      'Receipt ${_success!['receiptNo'] ?? _success!['transactionNo'] ?? ''}\n'
                      'Paid: ${_fmt(num.tryParse((_success!['amount'] ?? 0).toString()) ?? 0)}\n'
                      'Remaining O/S: ${_fmt(num.tryParse((_success!['remainingOs'] ?? _success!['osAfter'] ?? 0).toString()) ?? 0)}',
                      style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _saving ? null : _settle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Settle',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _payChip(String mode, IconData icon) {
    final sel = _payMode == mode;
    return InkWell(
      onTap: () => setState(() => _payMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? _accent.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: sel ? _accent : Colors.grey.shade300, width: sel ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accent),
            const SizedBox(height: 4),
            Text(mode == 'CREDITCARD' ? 'CARD' : mode,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: sel ? _accent : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _historyView() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_history.isEmpty) {
      return const Center(child: Text('No receipts in the last 30 days'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = _history[i];
        return ListTile(
          title: Text(
            (r['receiptNo'] ?? r['transactionNo'] ?? '').toString(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
              '${r['customerName'] ?? ''} · ${r['transactionDate'] ?? ''}'),
          trailing: Text(
            _fmt(num.tryParse((r['paidAmount'] ?? 0).toString()) ?? 0),
            style: const TextStyle(fontWeight: FontWeight.w800, color: _accent),
          ),
        );
      },
    );
  }
}
