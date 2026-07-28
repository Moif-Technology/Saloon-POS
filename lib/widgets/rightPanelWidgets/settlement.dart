import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/widgets/rightPanelWidgets/right_panels_widgets_import.dart';
import 'package:window_manager/window_manager.dart';

/// Settlement dialog – compact POS layout (1024×600–1366×768)
/// - Same compact button style for payment methods + actions
/// - Keypad redesigned as a unified POS keypad block (no “separate tiles” feel)
/// - Keypad edits Paid Amount (readOnly field)
/// - Balance auto-calculates (Net - Paid)
class SettlementDialog extends StatefulWidget {
  final double netTotal;
  final int currencyDecimals;
  final String customerName;
  final String startTime;
  final String elapsed;
  final Map<String, dynamic>? orderData;

  const SettlementDialog({
    super.key,
    this.netTotal = 1500.00,
    this.currencyDecimals = 2,
    this.customerName = "John Doe",
    this.startTime = "10:00 AM",
    this.elapsed = "00:25:43",
    this.orderData,
  });

  @override
  State<SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<SettlementDialog>
    with WindowListener {
  static const Color _themeColor = Color(0xFF521C1D);

  double screenWidth = 1024;
  double screenHeight = 768;

  // UI state
  String _selectedPayment = "Cash";
  final TextEditingController _paidCtrl = TextEditingController(text: "0");
  final TextEditingController _balanceCtrl = TextEditingController(text: "0");
  bool _editingPaid = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setScreenSize();
    windowManager.addListener(this);
    _paidCtrl.text = _fmtMoney(widget.netTotal);
    _recalcBalance();
    _paidCtrl.addListener(_recalcBalance);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _paidCtrl.removeListener(_recalcBalance);
    _paidCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _setScreenSize() async {
    try {
      final bounds = await windowManager.getBounds();
      if (!mounted) return;
      setState(() {
        screenWidth = bounds.width;
        screenHeight = bounds.height;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        screenWidth = 1024;
        screenHeight = 768;
      });
    }
  }

  double get _scale => (screenWidth < 1100 || screenHeight < 700) ? 0.88 : 1.0;
  double _dp(double v) => v * _scale;

  double _parseMoney(String s) {
    final cleaned = s.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  String _fmtMoney(double v) => v.toStringAsFixed(widget.currencyDecimals);

  /// Rounds to currency decimals so paid vs net comparison is stable (no float noise).
  double _roundToCurrency(double value) {
    final int d = widget.currencyDecimals;
    if (d <= 0) return value.roundToDouble();
    double factor = 1.0;
    for (int i = 0; i < d; i++) factor *= 10;
    return (value * factor).round() / factor;
  }

  void _recalcBalance() {
    final paid = _parseMoney(_paidCtrl.text);
    final bal = widget.netTotal - paid;
    _balanceCtrl.text = _fmtMoney(bal);
  }

  @override
  Widget build(BuildContext context) {
    final w = (screenWidth * 0.68).clamp(560.0, 940.0);
    final h = (screenHeight * 0.84).clamp(520.0, 740.0);
    final pad = _dp(10);

    return Dialog(
      insetPadding: EdgeInsets.all(_dp(12)),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(_dp(10))),
      child: Container(
        width: w,
        height: h,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_dp(10)),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(pad),
            SizedBox(height: pad),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT SIDE: payment methods + keypad
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildPaymentMethods(pad),
                        SizedBox(height: pad),
                        Expanded(child: _buildKeypad(pad)),
                      ],
                    ),
                  ),

                  SizedBox(width: pad),

                  // RIGHT SIDE: totals / fields
                  Expanded(
                    flex: 1,
                    child: _buildRightSummary(pad),
                  ),
                ],
              ),
            ),
            SizedBox(height: pad),
            _buildBottomActions(pad),
          ],
        ),
      ),
    );
  }

  // =========================
  // Header / Info Bar
  // =========================
  Widget _buildHeader(double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad * 0.9),
      decoration: BoxDecoration(
        color: _themeColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(_dp(10)),
        border: Border.all(color: _themeColor.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
              child:
                  _infoChip(Icons.access_time, "Start", widget.startTime, pad)),
          _dividerV(pad),
          Expanded(
              child:
                  _infoChip(Icons.timelapse, "Elapsed", widget.elapsed, pad)),
          _dividerV(pad),
          Expanded(
              child: _infoChip(
                  Icons.person, "Customer", widget.customerName, pad)),
        ],
      ),
    );
  }

  Widget _dividerV(double pad) {
    return Container(
      height: _dp(26),
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: pad),
      color: Colors.grey.shade300,
    );
  }

  Widget _infoChip(IconData icon, String label, String value, double pad) {
    return Row(
      children: [
        Container(
          width: _dp(30),
          height: _dp(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_dp(8)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, size: _dp(16), color: _themeColor),
        ),
        SizedBox(width: pad),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: _dp(10.5), color: Colors.grey.shade700),
              ),
              SizedBox(height: _dp(2)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _dp(12.5),
                  fontWeight: FontWeight.w800,
                  color: _themeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // Payment Methods
  // =========================
  Widget _buildPaymentMethods(double pad) {
    final methods = <_PayMethod>[
      _PayMethod("Cash", Icons.attach_money_rounded),
      _PayMethod("Card", Icons.credit_card_rounded),
      _PayMethod("Credit", Icons.account_balance_rounded),
      _PayMethod("M-Pay", Icons.account_balance_wallet_rounded),
      _PayMethod("Online", Icons.cloud_rounded),
      _PayMethod("Compliment", Icons.card_giftcard_rounded),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cross = (c.maxWidth < 520) ? 2 : 3;
        final ratio = (cross == 2) ? 3.4 : 3.2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cross,
          crossAxisSpacing: pad,
          mainAxisSpacing: pad,
          childAspectRatio: ratio,
          children: methods.map((m) {
            final selected = _selectedPayment == m.title;
            return _CompactBtn(
              label: m.title,
              icon: m.icon,
              themeColor: _themeColor,
              dense: true,
              selected: selected,
              onTap: () => _onPaymentTap(m.title),
            );
          }).toList(),
        );
      },
    );
  }

  void _onPaymentTap(String method) {
    setState(() => _selectedPayment = method);

    // keep your original dialogs
    if (method == "Credit") {
      showDialog(context: context, builder: (_) => CustomerLookupDialog());
    } else if (method == "M-Pay") {
      showDialog(context: context, builder: (_) => MultiPayDialog());
    } else if (method == "Online") {
      showDialog(context: context, builder: (_) => OnlineSourcesDialog());
    } else if (method == "Compliment") {
      showDialog(context: context, builder: (_) => Compliment());
    }
  }

  // =========================
  // NEW Keypad (unified POS keypad look)
  // =========================
  Widget _buildKeypad(double pad) {
    final keys = const [
      "7",
      "8",
      "9",
      "4",
      "5",
      "6",
      "1",
      "2",
      "3",
      "0",
      ".",
      "00",
      "Clear",
      "Back",
      "Close",
    ];

    bool isAction(String k) => (k == "Clear" || k == "Back" || k == "Close");

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_dp(10)),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final gap = _dp(8);

          // 5 rows × 3 cols
          const rows = 5;
          const cols = 3;

          final cellW = (c.maxWidth - gap * (cols - 1)) / cols;
          final cellH = (c.maxHeight - gap * (rows - 1)) / rows;

          // nice rectangle feel (not too tall)
          final h = cellH.clamp(_dp(44), _dp(72));
          final w = cellW;

          return Column(
            children: List.generate(rows, (r) {
              return Padding(
                padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : gap),
                child: Row(
                  children: List.generate(cols, (col) {
                    final index = r * cols + col;
                    final k = keys[index];
                    final action = isAction(k);

                    return Padding(
                      padding:
                          EdgeInsets.only(right: col == cols - 1 ? 0 : gap),
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: _KeypadTile(
                          label: k,
                          themeColor: _themeColor,
                          action: action,
                          onTap: () => _onKeyTap(k),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  void _onKeyTap(String key) {
    if (key == "Close") {
      Navigator.of(context).pop();
      return;
    }

    final ctrl = _editingPaid ? _paidCtrl : _balanceCtrl;
    final text = ctrl.text;

    if (key == "Clear") {
      ctrl.text = "0";
      return;
    }

    if (key == "Back") {
      if (text.isEmpty || text == "0") {
        ctrl.text = "0";
      } else {
        final t = text.substring(0, text.length - 1);
        ctrl.text = t.isEmpty ? "0" : t;
      }
      return;
    }

    // numeric input
    String next = text;
    if (next == "0") next = "";

    if (key == ".") {
      if (next.contains(".")) return;
      next = next.isEmpty ? "0." : "$next.";
    } else if (key == "00") {
      next = next.isEmpty ? "0" : "$next" "00";
    } else {
      next = "$next$key";
    }

    if (next.startsWith(".")) next = "0$next";
    ctrl.text = next;
  }

  // =========================
  // Right Summary Panel
  // =========================
  Widget _buildRightSummary(double pad) {
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_dp(10)),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _miniRow("Payment Mode", _selectedPayment, pad),
          SizedBox(height: pad),
          _highlightMoneyBox(
            title: "Net Total",
            value: _fmtMoney(widget.netTotal),
            pad: pad,
            strong: true,
          ),
          SizedBox(height: pad),
          _moneyField(
            label: "Paid Amount",
            controller: _paidCtrl,
            pad: pad,
            active: _editingPaid,
            readOnly: false,
            onTap: () => setState(() => _editingPaid = true),
          ),
          SizedBox(height: pad),
          _moneyField(
            label: "Balance Amount",
            controller: _balanceCtrl,
            pad: pad,
            active: !_editingPaid,
            readOnly: true,
            onTap: () => setState(() => _editingPaid = false),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: _themeColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(_dp(10)),
              border: Border.all(color: _themeColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: _dp(16), color: _themeColor),
                SizedBox(width: pad),
                Expanded(
                  child: Text(
                    "Use keypad to edit Paid Amount. Balance updates automatically.",
                    style: TextStyle(
                      fontSize: _dp(11),
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
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

  Widget _miniRow(String l, String v, double pad) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l,
            style: TextStyle(
                fontSize: _dp(11),
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: _dp(6)),
          decoration: BoxDecoration(
            color: _themeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(_dp(10)),
            border: Border.all(color: _themeColor.withOpacity(0.15)),
          ),
          child: Text(
            v,
            style: TextStyle(
                fontSize: _dp(11.5),
                fontWeight: FontWeight.w900,
                color: _themeColor),
          ),
        ),
      ],
    );
  }

  Widget _highlightMoneyBox({
    required String title,
    required String value,
    required double pad,
    bool strong = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: _dp(11),
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade800),
        ),
        SizedBox(height: _dp(6)),
        Container(
          height: _dp(44),
          padding: EdgeInsets.symmetric(horizontal: pad),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: strong ? Colors.grey.shade200 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(_dp(10)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: TextStyle(
                fontSize: _dp(16),
                fontWeight: FontWeight.w900,
                color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _moneyField({
    required String label,
    required TextEditingController controller,
    required double pad,
    bool readOnly = false,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: _dp(11),
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade800),
        ),
        SizedBox(height: _dp(6)),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_dp(10)),
          child: Container(
            height: _dp(42),
            padding: EdgeInsets.symmetric(horizontal: pad),
            decoration: BoxDecoration(
              color: readOnly ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(_dp(10)),
              border: Border.all(
                color: active ? _themeColor : Colors.grey.shade400,
                width: active ? 1.6 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: _themeColor.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(Icons.payments_outlined,
                    size: _dp(16),
                    color: active ? _themeColor : Colors.grey.shade700),
                SizedBox(width: pad),
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: true, // keypad controls this
                    style: TextStyle(
                        fontSize: _dp(13), fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (!readOnly)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: _dp(8), vertical: _dp(4)),
                    decoration: BoxDecoration(
                      color: _themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(_dp(10)),
                      border: Border.all(color: _themeColor.withOpacity(0.15)),
                    ),
                    child: Text(
                      "KEYPAD",
                      style: TextStyle(
                          fontSize: _dp(10),
                          fontWeight: FontWeight.w900,
                          color: _themeColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // Bottom Actions
  // =========================
  Widget _buildBottomActions(double pad) {
    return Row(
      children: [
        Expanded(
          child: _CompactBtn(
            label: _isSaving ? "Saving..." : "Save",
            icon: _isSaving ? null : Icons.save_rounded,
            themeColor: _themeColor,
            selected: true,
            enabled: !_isSaving,
            onTap: _onSave,
          ),
        ),
        SizedBox(width: pad),
        Expanded(
          child: _CompactBtn(
            label: _isSaving ? "..." : "Save & Entry",
            icon: _isSaving ? null : Icons.add_task_rounded,
            themeColor: _themeColor,
            selected: true,
            enabled: !_isSaving,
            onTap: _onSaveAndEntry,
          ),
        ),
        SizedBox(width: pad),
        Expanded(
          child: _CompactBtn(
            label: _isSaving ? "..." : "Enter",
            icon: _isSaving ? null : Icons.check_circle_rounded,
            themeColor: _themeColor,
            selected: true,
            enabled: !_isSaving,
            onTap: _onEnter,
          ),
        ),
      ],
    );
  }

  /// Maps UI payment label to API paymentMode (CASH | CREDITCARD).
  String get _paymentModeApi {
    if (_selectedPayment == "Card") return "CREDITCARD";
    return "CASH";
  }

  Future<void> _onSave() async {
    if (_selectedPayment != "Cash" && _selectedPayment != "Card") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Select Cash or Card to settle")),
      );
      return;
    }
    final orderData = widget.orderData;
    if (orderData == null || orderData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No order data. Add items and try again.")),
      );
      return;
    }
    final paid = _parseMoney(_paidCtrl.text);
    final net = widget.netTotal;
    const double _amountTolerance = 0.001;
    if (paid < net - _amountTolerance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Paid amount (${_fmtMoney(paid)}) must be >= Net amount (${_fmtMoney(net)})",
          ),
        ),
      );
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final payload = Map<String, dynamic>.from(orderData);
      payload["paidAmount"] = paid;
      payload["paymentMode"] = _paymentModeApi;
      final apiRes = await ApiService().saveSettlement(payload);
      if (!mounted) return;
      setState(() => _isSaving = false);
      final billNo = apiRes["billNo"]?.toString().trim() ?? "";
      final salesId = apiRes["salesId"]?.toString().trim() ?? "";
      if (apiRes["ok"] != true || billNo.isEmpty || salesId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiRes["message"]?.toString() ??
                  "Settlement was not saved. Check API connection and try again.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final balancePaid =
          double.tryParse(apiRes["balancePaid"]?.toString() ?? "") ??
              (paid - net).clamp(0.0, double.infinity);
      payload["billNo"] = billNo;
      payload["salesId"] = salesId;
      final result = <String, dynamic>{
        'billNo': billNo,
        'balancePaid': balancePaid,
        'salesId': salesId,
      };
      if (mounted) {
        // Show success dialog
        final modeLabel = _paymentModeApi == "CREDITCARD" ? " (Card)" : "";
        final message = "Bill #$billNo settled$modeLabel.\nChange: ${balancePaid.toStringAsFixed(widget.currencyDecimals)}";
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Success',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF521C1D),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF521C1D),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('OK',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        );
        if (!mounted) return;
        // Pass result + orderData so caller can print receipt (VB PrintCounterBill)
        Navigator.of(context).pop(<String, dynamic>{
          ...result,
          'orderData': payload,
          'customerName': widget.customerName,
          'currencyDecimals': widget.currencyDecimals,
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Settlement failed: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onSaveAndEntry() {
    _onSave();
  }

  void _onEnter() {
    _onSave();
  }
}

/// Payment method model
class _PayMethod {
  final String title;
  final IconData icon;
  const _PayMethod(this.title, this.icon);
}

/// Reusable compact button (same style everywhere)
class _CompactBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color themeColor;
  final bool selected;
  final bool dense;
  final bool enabled;
  final VoidCallback onTap;

  const _CompactBtn({
    required this.label,
    required this.themeColor,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.dense = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = 10.0;
    final height = dense ? 42.0 : 46.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? themeColor : Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border:
                Border.all(color: selected ? themeColor : Colors.grey.shade400),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: themeColor.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 18, color: selected ? Colors.white : themeColor),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : Colors.black,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keypad tile – unified POS keypad feel
class _KeypadTile extends StatelessWidget {
  final String label;
  final Color themeColor;
  final bool action;
  final VoidCallback onTap;

  const _KeypadTile({
    required this.label,
    required this.themeColor,
    required this.action,
    required this.onTap,
  });

  IconData? get _icon {
    switch (label) {
      case "Back":
        return Icons.backspace_outlined;
      case "Clear":
        return Icons.delete_sweep_outlined;
      case "Close":
        return Icons.close_rounded;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = 10.0;

    final bg = action ? themeColor.withOpacity(0.10) : Colors.grey.shade100;
    final border = action ? themeColor.withOpacity(0.35) : Colors.grey.shade300;
    final fg = action ? themeColor : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_icon != null) ...[
                  Icon(_icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: action ? 13 : 16,
                    fontWeight: FontWeight.w900,
                    color: fg,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
