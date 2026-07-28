import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/parameterProviders.dart';

/// Dialog to apply bill-level discount to the current KOT (VB-style).
/// Pass [kotId], [totalAmount] (subtotal), [currentDiscount], and optionally [taxPercentage].
/// On Done, updates KOTMaster.BillDiscount via API and pops with the new discount value.
class DiscountDialog extends ConsumerStatefulWidget {
  final int kotId;
  final double totalAmount;
  final double currentDiscount;
  final double taxPercentage;

  const DiscountDialog({
    super.key,
    required this.kotId,
    required this.totalAmount,
    this.currentDiscount = 0,
    this.taxPercentage = 0,
  });

  @override
  ConsumerState<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends ConsumerState<DiscountDialog> {
  static const Color _primary = Color(0xFF521C1D);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _percentController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _percentFocus = FocusNode();

  bool _updatingFromAmount = false;
  bool _updatingFromPercent = false;
  bool _saving = false;

  double get _total => widget.totalAmount;
  double get _taxPerc => widget.taxPercentage;

  double _discAmount = 0;
  double _discPercent = 0;
  double get _taxable => (_total - _discAmount).clamp(0, double.infinity);
  double get _taxAmt => _taxable * (_taxPerc / 100);
  double get _netAmount => _taxable + _taxAmt;

  @override
  void initState() {
    super.initState();
    _discAmount = widget.currentDiscount;
    _discPercent = widget.totalAmount > 0 ? (widget.currentDiscount * 100 / widget.totalAmount) : 0;
    _amountController.text = _discAmount.toStringAsFixed(2);
    _percentController.text = _discPercent.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _percentController.dispose();
    _amountFocus.dispose();
    _percentFocus.dispose();
    super.dispose();
  }

  String _formatNum(double v) {
    final prec = ref.read(currencyPrecessionProvider);
    final n = (prec != null && prec.isNotEmpty) ? int.tryParse(prec) : null;
    if (n != null) return v.toStringAsFixed(n);
    return v.toStringAsFixed(2);
  }

  void _fromAmount(String s) {
    if (_updatingFromPercent) return;
    final v = double.tryParse(s) ?? 0;
    if (v < 0) return;
    setState(() {
      _updatingFromAmount = true;
      _discAmount = v.clamp(0, _total);
      _discPercent = _total > 0 ? (_discAmount * 100 / _total) : 0;
      _percentController.text = _formatNum(_discPercent);
      _updatingFromAmount = false;
    });
  }

  void _fromPercent(String s) {
    if (_updatingFromAmount) return;
    final v = double.tryParse(s) ?? 0;
    if (v < 0 || v > 100) return;
    setState(() {
      _updatingFromPercent = true;
      _discPercent = v.clamp(0, 100);
      _discAmount = _total * (_discPercent / 100);
      _amountController.text = _formatNum(_discAmount);
      _updatingFromPercent = false;
    });
  }

  void _applyQuickPercent(double pct) {
    setState(() {
      _discPercent = pct.clamp(0, 100);
      _discAmount = _total * (_discPercent / 100);
      _amountController.text = _formatNum(_discAmount);
      _percentController.text = _formatNum(_discPercent);
    });
  }

  void _numPad(String key) {
    final amountFocused = _amountFocus.hasFocus;
    if (key == 'C') {
      if (amountFocused) {
        _amountController.clear();
        _fromAmount('0');
      } else {
        _percentController.clear();
        _fromPercent('0');
      }
      return;
    }
    if (key == '.') {
      final c = amountFocused ? _amountController : _percentController;
      if (!c.text.contains('.')) c.text = '${c.text}.';
      if (amountFocused) _fromAmount(c.text);
      else _fromPercent(c.text);
      return;
    }
    final c = amountFocused ? _amountController : _percentController;
    final newText = c.text == '0' && key != '.' ? key : '${c.text}$key';
    c.text = newText;
    if (amountFocused) _fromAmount(newText);
    else _fromPercent(newText);
  }

  Future<void> _onDone() async {
    if (_saving) return;
    if (_discAmount > _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount cannot exceed total amount.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (!mounted) return;
      Navigator.of(context).pop(_discAmount);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save discount: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildDetailsSection()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildNumberPad()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildFooterButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Apply Discount',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          color: _primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Total Amount', _formatNum(_total), isBold: true, color: _primary),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Text(
                  'Discount Amount',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  focusNode: _amountFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.discount, size: 20, color: _primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  style: const TextStyle(fontSize: 15),
                  onChanged: (s) => _fromAmount(s),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Text(
                  'Disc %',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _percentController,
                  focusNode: _percentFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.percent, size: 20, color: _primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  style: const TextStyle(fontSize: 15),
                  onChanged: (s) => _fromPercent(s),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickChip('5%', () => _applyQuickPercent(5)),
              _quickChip('10%', () => _applyQuickPercent(10)),
              _quickChip('20%', () => _applyQuickPercent(20)),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Taxable Amount', _formatNum(_taxable)),
          const SizedBox(height: 8),
          _buildDetailRow('VAT @${_formatNum(_taxPerc)}%', _formatNum(_taxAmt)),
          const SizedBox(height: 8),
          _buildDetailRow('Net Amount', _formatNum(_netAmount), isBold: true, color: _primary),
        ],
      ),
    );
  }

  Widget _quickChip(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _primary.withOpacity(0.4)),
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: _primary)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[800],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberPad() {
    const keys = [
      '7', '8', '9',
      '4', '5', '6',
      '1', '2', '3',
      '0', '.', 'C',
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        return ElevatedButton(
          onPressed: () => _numPad(keys[index]),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 1,
            side: BorderSide(color: _primary.withOpacity(0.5), width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            keys[index],
            style: TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _saving ? null : _onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Done', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
