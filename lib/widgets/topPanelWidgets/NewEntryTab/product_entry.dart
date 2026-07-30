import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/utils/sessionManager.dart';
import 'package:quickalert/quickalert.dart';

/// Touch-optimised Product Entry dialog aligned with ERP
/// `ERP_frontend/.../ProductEntry.jsx` (General / Stock / Pricing tabs).
class ProductMasterDetailsDialog extends ConsumerStatefulWidget {
  final String uniqueMultiProductID;
  final int? groupId;
  final bool fromTopBar;

  const ProductMasterDetailsDialog({
    Key? key,
    required this.uniqueMultiProductID,
    this.groupId,
    this.fromTopBar = false,
  }) : super(key: key);

  @override
  ConsumerState<ProductMasterDetailsDialog> createState() =>
      _ProductMasterDetailsDialogState();
}

class _ProductMasterDetailsDialogState
    extends ConsumerState<ProductMasterDetailsDialog> {
  static const Color _maroon = Color(0xFF521C1D);
  static const Color _maroonAccent = Color(0xFF780829);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFF8F6F6);
  static const double _fieldH = 54;
  static const double _gap = 12;

  // Controllers — General
  final _barcodeCtrl = TextEditingController();
  final _productCodeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _arabicCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _specCtrl = TextEditingController();

  // Controllers — Pricing / VAT
  final _baseCostCtrl = TextEditingController();
  final _unitCostCtrl = TextEditingController();
  final _avgCostCtrl = TextEditingController();
  final _lastPurchCtrl = TextEditingController();
  final _unitPriceCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _priceWithVatCtrl = TextEditingController();
  final _costWithVatCtrl = TextEditingController();
  final _vatInPctCtrl = TextEditingController();
  final _vatOutPctCtrl = TextEditingController();
  final _vatInAmtCtrl = TextEditingController();
  final _vatOutAmtCtrl = TextEditingController();
  final _discountPctCtrl = TextEditingController();
  final _marginPctCtrl = TextEditingController();
  final _priceLevel1Ctrl = TextEditingController();
  final _priceLevel2Ctrl = TextEditingController();
  final _priceLevel3Ctrl = TextEditingController();
  final _priceLevel4Ctrl = TextEditingController();
  final _priceLevel5Ctrl = TextEditingController();

  // Controllers — Stock
  final _packQtyCtrl = TextEditingController(text: '1');
  final _qtyOnHandCtrl = TextEditingController();
  final _reorderLevelCtrl = TextEditingController();
  final _reorderQtyCtrl = TextEditingController();
  final _packetDetailsCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'Main');
  final _originCtrl = TextEditingController();
  final _supplierRefCtrl = TextEditingController();

  bool _newBarcode = true;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;
  int _tab = 0; // 0 General, 1 Stock, 2 Pricing

  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _subGroups = [];
  int? _groupId;
  int? _subGroupId;
  String _makeType = 'Standard';
  String _productType = 'Service';
  String _stockType = 'Normal';
  String _unit = 'PCS';
  String _productIdentity = 'No';

  // Enter-key flow: Barcode → Name → Group → Unit Cost → Unit Price → …
  final _fnBarcode = FocusNode();
  final _fnName = FocusNode();
  final _fnGroup = FocusNode();
  final _fnUnitCost = FocusNode();
  final _fnUnitPrice = FocusNode();
  final _fnVatOutPct = FocusNode();
  final _fnPriceWithVat = FocusNode();
  final _fnVatInPct = FocusNode();
  final _fnCostWithVat = FocusNode();

  String? _formError;
  bool _nameHasError = false;

  bool get _isEdit => widget.uniqueMultiProductID.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final tax = ref.read(tax1Provider) ?? 0.0;
    _vatOutPctCtrl.text = tax.toStringAsFixed(2);
    _vatInPctCtrl.text = tax.toStringAsFixed(2);

    final providerGroupId = ref.read(selectedGroupIdProvider);
    final seedGroup =
        widget.fromTopBar ? null : (widget.groupId ?? providerGroupId);
    if (seedGroup != null) _groupId = seedGroup;

    _unitPriceCtrl.addListener(_recalcOutputVatFromNet);
    _vatOutPctCtrl.addListener(_recalcOutputVatFromNet);
    _priceWithVatCtrl.addListener(_recalcOutputVatFromGross);
    _baseCostCtrl.addListener(_recalcInputVatFromNet);
    _unitCostCtrl.addListener(_recalcInputVatFromNet);
    _vatInPctCtrl.addListener(_recalcInputVatFromNet);
    _costWithVatCtrl.addListener(_recalcInputVatFromGross);
    _descriptionCtrl.addListener(() {
      if (_nameHasError && _descriptionCtrl.text.trim().isNotEmpty) {
        setState(() {
          _nameHasError = false;
          _formError = null;
        });
      }
    });

    _bootstrap();
  }

  @override
  void dispose() {
    for (final c in [
      _barcodeCtrl,
      _productCodeCtrl,
      _descriptionCtrl,
      _shortDescCtrl,
      _arabicCtrl,
      _brandCtrl,
      _specCtrl,
      _baseCostCtrl,
      _unitCostCtrl,
      _avgCostCtrl,
      _lastPurchCtrl,
      _unitPriceCtrl,
      _minPriceCtrl,
      _priceWithVatCtrl,
      _costWithVatCtrl,
      _vatInPctCtrl,
      _vatOutPctCtrl,
      _vatInAmtCtrl,
      _vatOutAmtCtrl,
      _discountPctCtrl,
      _marginPctCtrl,
      _priceLevel1Ctrl,
      _priceLevel2Ctrl,
      _priceLevel3Ctrl,
      _priceLevel4Ctrl,
      _priceLevel5Ctrl,
      _packQtyCtrl,
      _qtyOnHandCtrl,
      _reorderLevelCtrl,
      _reorderQtyCtrl,
      _packetDetailsCtrl,
      _remarkCtrl,
      _locationCtrl,
      _originCtrl,
      _supplierRefCtrl,
    ]) {
      c.dispose();
    }
    for (final n in [
      _fnBarcode,
      _fnName,
      _fnGroup,
      _fnUnitCost,
      _fnUnitPrice,
      _fnVatOutPct,
      _fnPriceWithVat,
      _fnVatInPct,
      _fnCostWithVat,
    ]) {
      n.dispose();
    }
    super.dispose();
  }

  void _focusNext(FocusNode next) {
    next.requestFocus();
  }

  // ── VAT helpers (match ERP gvtax net ↔ gross) ─────────────────────────────
  bool _suppressVat = false;

  double _n(String s) => double.tryParse(s.trim()) ?? 0.0;

  String _money(double v) => v.toStringAsFixed(2);

  void _recalcOutputVatFromNet() {
    if (_suppressVat) return;
    final net = _n(_unitPriceCtrl.text);
    final rate = _n(_vatOutPctCtrl.text);
    final vat = net * rate / 100;
    final gross = net + vat;
    _suppressVat = true;
    _vatOutAmtCtrl.text = _money(vat);
    _priceWithVatCtrl.text = _money(gross);
    _suppressVat = false;
  }

  void _recalcOutputVatFromGross() {
    if (_suppressVat) return;
    final gross = _n(_priceWithVatCtrl.text);
    final rate = _n(_vatOutPctCtrl.text);
    final net = rate <= 0 ? gross : gross / (1 + rate / 100);
    final vat = gross - net;
    _suppressVat = true;
    _unitPriceCtrl.text = _money(net);
    _vatOutAmtCtrl.text = _money(vat);
    _suppressVat = false;
  }

  void _recalcInputVatFromNet() {
    if (_suppressVat) return;
    final net = _firstFilledNum([
      _unitCostCtrl.text,
      _baseCostCtrl.text,
      _avgCostCtrl.text,
    ]);
    final rate = _n(_vatInPctCtrl.text);
    final vat = net * rate / 100;
    final gross = net + vat;
    _suppressVat = true;
    _vatInAmtCtrl.text = _money(vat);
    _costWithVatCtrl.text = _money(gross);
    _suppressVat = false;
  }

  void _recalcInputVatFromGross() {
    if (_suppressVat) return;
    final gross = _n(_costWithVatCtrl.text);
    final rate = _n(_vatInPctCtrl.text);
    final net = rate <= 0 ? gross : gross / (1 + rate / 100);
    final vat = gross - net;
    _suppressVat = true;
    _unitCostCtrl.text = _money(net);
    _vatInAmtCtrl.text = _money(vat);
    _suppressVat = false;
  }

  double _firstFilledNum(List<String> vals) {
    for (final v in vals) {
      if (v.trim().isNotEmpty) return _n(v);
    }
    return 0.0;
  }

  String? _firstFilledStr(List<String> vals) {
    for (final v in vals) {
      final t = v.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  // ── Data load ─────────────────────────────────────────────────────────────
  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _loadGroups();
      if (_groupId != null) await _loadSubGroups(_groupId!);
      if (_isEdit) {
        await _loadProduct(widget.uniqueMultiProductID.trim());
      }
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        // Start keyboard flow on Product Name (or barcode if Manual).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_newBarcode || _isEdit) {
            _fnName.requestFocus();
          } else {
            _fnBarcode.requestFocus();
          }
        });
      }
    }
  }

  Future<void> _loadGroups() async {
    final data = await ApiService().fetchGroups();
    _groups = data
        .map((g) => Map<String, dynamic>.from(g as Map))
        .toList();
  }

  Future<void> _loadSubGroups(int groupId) async {
    final data =
        await ApiService().fetchSubGroups(groupId: groupId.toString());
    _subGroups = data
        .map((g) => Map<String, dynamic>.from(g as Map))
        .toList();
  }

  Future<void> _loadProduct(String productId) async {
    final p = await ApiService().fetchProductById(productId);
    final inv = p['inventory'] is Map
        ? Map<String, dynamic>.from(p['inventory'] as Map)
        : <String, dynamic>{};

    _suppressVat = true;
    _productCodeCtrl.text = p['productCode']?.toString() ?? '';
    _barcodeCtrl.text = p['barcode']?.toString() ?? '';
    _newBarcode = false;
    _descriptionCtrl.text =
        (p['productName'] ?? p['description'])?.toString() ?? '';
    _shortDescCtrl.text = (p['shortName'] ?? p['shortDescription'])
            ?.toString() ??
        '';
    _arabicCtrl.text = p['descriptionArabic']?.toString() ?? '';
    _brandCtrl.text =
        (p['brandName'] ?? p['productBrand'])?.toString() ?? '';
    _specCtrl.text = p['specification']?.toString() ?? '';

    _makeType = (p['makeType']?.toString().trim().isNotEmpty == true)
        ? p['makeType'].toString()
        : 'Standard';
    _productType = (p['productType']?.toString().trim().isNotEmpty == true)
        ? p['productType'].toString()
        : 'Stock';
    _stockType = (p['stockType']?.toString().trim().isNotEmpty == true)
        ? p['stockType'].toString()
        : 'Normal';
    _unit = (p['unitName'] ?? p['unit'])?.toString().trim().isNotEmpty == true
        ? (p['unitName'] ?? p['unit']).toString()
        : 'PCS';

    final identity = p['productIdentity'];
    _productIdentity =
        (identity == 1 || identity == '1' || identity == 'Yes') ? 'Yes' : 'No';

    _groupId = int.tryParse(p['groupId']?.toString() ?? '');
    _subGroupId = int.tryParse(
        (p['subgroupId'] ?? p['subGroupId'])?.toString() ?? '');

    _baseCostCtrl.text = _numStr(inv['averageCost'] ?? p['baseCost']);
    _unitCostCtrl.text = _numStr(inv['averageCost'] ?? inv['lastPurchaseCost']);
    _avgCostCtrl.text = _numStr(inv['averageCost']);
    _lastPurchCtrl.text = _numStr(inv['lastPurchaseCost']);
    _unitPriceCtrl.text = _numStr(inv['unitPrice']);
    _minPriceCtrl.text = _numStr(inv['minimumRetailPrice']);
    _discountPctCtrl.text = _numStr(inv['discountPercentage']);
    _marginPctCtrl.text = _numStr(inv['minimumMarginPercentage']);
    _vatInPctCtrl.text = _numStr(inv['inputTax1Rate']);
    _vatOutPctCtrl.text = _numStr(inv['outputTax1Rate']);
    _vatInAmtCtrl.text = _numStr(inv['inputTax1Amount']);
    _vatOutAmtCtrl.text = _numStr(inv['outputTax1Amount']);
    _priceLevel1Ctrl.text = _numStr(inv['priceLevel1']);
    _priceLevel2Ctrl.text = _numStr(inv['priceLevel2']);
    _priceLevel3Ctrl.text = _numStr(inv['priceLevel3']);
    _priceLevel4Ctrl.text = _numStr(inv['priceLevel4']);
    _priceLevel5Ctrl.text = _numStr(inv['priceLevel5']);

    final unitPrice = _n(_unitPriceCtrl.text);
    final vatOutPct = _n(_vatOutPctCtrl.text);
    _priceWithVatCtrl.text = _money(unitPrice + unitPrice * vatOutPct / 100);
    final unitCost = _n(_unitCostCtrl.text);
    final vatInPct = _n(_vatInPctCtrl.text);
    _costWithVatCtrl.text = _money(unitCost + unitCost * vatInPct / 100);

    _packQtyCtrl.text =
        _numStr(inv['packQty'] ?? p['packQty'], fallback: '1');
    _qtyOnHandCtrl.text = _numStr(inv['qtyOnHand']);
    _reorderLevelCtrl.text = _numStr(inv['reorderLevel']);
    _reorderQtyCtrl.text = _numStr(inv['reorderQty']);
    _packetDetailsCtrl.text = p['packDescription']?.toString() ?? '';
    _remarkCtrl.text = p['remarks']?.toString() ?? '';
    _locationCtrl.text =
        (inv['locationCode']?.toString().trim().isNotEmpty == true)
            ? inv['locationCode'].toString()
            : 'Main';
    _originCtrl.text = p['countryOfOrigin']?.toString() ?? '';
    _supplierRefCtrl.text = p['supplierRefNo']?.toString() ?? '';
    _suppressVat = false;

    if (_groupId != null) await _loadSubGroups(_groupId!);
  }

  String _numStr(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final n = double.tryParse(v.toString());
    if (n == null) return fallback;
    if (n == 0 && fallback.isEmpty) return '';
    return n.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Map<String, dynamic> _buildPayload(int branchId) {
    final description = _descriptionCtrl.text.trim();
    // Salon/POS: product code optional — derive from name like ERP RESTAURANT/POS.
    final typedCode = _productCodeCtrl.text.trim();
    final derived = description
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '-');
    final sliced = derived.isEmpty
        ? ''
        : derived.substring(0, derived.length > 20 ? 20 : derived.length);
    final code = typedCode.isNotEmpty
        ? (typedCode.length > 50 ? typedCode.substring(0, 50) : typedCode)
        : (sliced.isNotEmpty
            ? sliced
            : 'PRD-${DateTime.now().millisecondsSinceEpoch % 1000000}');

    final unitPrice = _firstFilledStr([
          _money(_n(_priceWithVatCtrl.text) /
              (1 + _n(_vatOutPctCtrl.text) / 100)),
          _unitPriceCtrl.text,
        ]) ??
        '0';

    final averageCost = _firstFilledStr([
          _unitCostCtrl.text,
          _avgCostCtrl.text,
          _baseCostCtrl.text,
        ]) ??
        '0';

    return <String, dynamic>{
      'branchId': branchId,
      'productCode': code,
      if (!_newBarcode && _barcodeCtrl.text.trim().isNotEmpty)
        'barcode': _barcodeCtrl.text.trim(),
      'newBarcode': _newBarcode,
      'description': description,
      if (_shortDescCtrl.text.trim().isNotEmpty)
        'shortDescription': _shortDescCtrl.text.trim(),
      if (_arabicCtrl.text.trim().isNotEmpty)
        'descriptionArabic': _arabicCtrl.text.trim(),
      'makeType': _makeType,
      if (_brandCtrl.text.trim().isNotEmpty)
        'productBrand': _brandCtrl.text.trim(),
      if (_specCtrl.text.trim().isNotEmpty)
        'specification': _specCtrl.text.trim(),
      if (_groupId != null) 'groupId': _groupId,
      if (_subGroupId != null) 'subGroupId': _subGroupId,
      'baseCost': _baseCostCtrl.text.trim().isEmpty
          ? averageCost
          : _baseCostCtrl.text.trim(),
      'unitCost': averageCost,
      'averageCost': averageCost,
      'lastPurchCost': _firstFilledStr([
            _lastPurchCtrl.text,
            averageCost,
          ]) ??
          '0',
      'discountPct': _discountPctCtrl.text.trim(),
      'marginPct': _marginPctCtrl.text.trim(),
      'minUnitPrice': _minPriceCtrl.text.trim(),
      'unitPrice': unitPrice,
      'vatIn': _vatInAmtCtrl.text.trim(),
      'vatInPct': _vatInPctCtrl.text.trim(),
      'costWithVat': _costWithVatCtrl.text.trim(),
      'vatOut': _vatOutAmtCtrl.text.trim(),
      'vatOutPct': _vatOutPctCtrl.text.trim(),
      'priceWithVat': _priceWithVatCtrl.text.trim(),
      'priceLevel1': _priceLevel1Ctrl.text.trim(),
      'priceLevel2': _priceLevel2Ctrl.text.trim(),
      'priceLevel3': _priceLevel3Ctrl.text.trim(),
      'priceLevel4': _priceLevel4Ctrl.text.trim(),
      'priceLevel5': _priceLevel5Ctrl.text.trim(),
      'productType': _productType,
      'stockType': _stockType,
      'unit': _unit,
      'packQty': _packQtyCtrl.text.trim().isEmpty ? '1' : _packQtyCtrl.text.trim(),
      if (_packetDetailsCtrl.text.trim().isNotEmpty)
        'packetDetails': _packetDetailsCtrl.text.trim(),
      'location': _locationCtrl.text.trim().isEmpty
          ? 'Main'
          : _locationCtrl.text.trim(),
      'reorderLevel': _reorderLevelCtrl.text.trim(),
      'reorderQty': _reorderQtyCtrl.text.trim(),
      'qtyOnHand': _qtyOnHandCtrl.text.trim(),
      'productIdentity': _productIdentity,
      if (_remarkCtrl.text.trim().isNotEmpty) 'remark': _remarkCtrl.text.trim(),
      if (_supplierRefCtrl.text.trim().isNotEmpty)
        'supplierRefNo': _supplierRefCtrl.text.trim(),
      if (_originCtrl.text.trim().isNotEmpty) 'origin': _originCtrl.text.trim(),
      'packLines': <dynamic>[],
      'substituteProductIds': <dynamic>[],
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    final description = _descriptionCtrl.text.trim();
    if (description.isEmpty) {
      setState(() {
        _nameHasError = true;
        _formError = 'Product Name is required.';
        _tab = 0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fnName.requestFocus();
      });
      return;
    }
    final branchId = int.tryParse(SessionManager().stationId?.trim() ?? '');
    if (branchId == null || branchId < 1) {
      setState(() {
        _formError = 'Branch not set. Please log in again.';
        _nameHasError = false;
      });
      return;
    }

    setState(() {
      _formError = null;
      _nameHasError = false;
    });

    final payload = _buildPayload(branchId);
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await ApiService()
            .updateProduct(widget.uniqueMultiProductID.trim(), payload);
      } else {
        await ApiService().createProduct(payload);
      }
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Saved',
        text: 'Product "$description" saved.',
        width: 320,
        confirmBtnText: 'OK',
        confirmBtnColor: Colors.green,
        onConfirmBtnTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(true);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wide = size.width >= 1100;
    final dialogW = size.width > 1366 ? size.width * 0.82 : size.width * 0.96;
    final dialogH = size.height * 0.94;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dialogW,
        height: dialogH,
        child: Column(
          children: [
            _header(),
            _tabBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? _errorBody()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                          child: _tab == 0
                              ? _generalTab(wide)
                              : _tab == 1
                                  ? _stockTab(wide)
                                  : _pricingTab(wide),
                        ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      decoration: const BoxDecoration(
        color: _maroon,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(left: 20, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEdit ? 'Edit Product' : 'Add New Product',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (_isEdit)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ID ${widget.uniqueMultiProductID}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    const tabs = ['General', 'Stock & Supplier', 'Pricing'];
    return Container(
      color: const Color(0xFFFCFBFB),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _tab == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
              child: Material(
                color: selected ? _maroonAccent : Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? _maroonAccent : _border,
                      ),
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _maroon,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _errorBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _bootstrap,
              style: ElevatedButton.styleFrom(backgroundColor: _maroon),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBFB),
        border: Border(top: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
              label: const Text('Cancel', style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _maroon,
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving || _loading ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 22),
              label: Text(
                _isEdit ? 'Update' : 'Save',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _maroonAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(160, 52),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _generalTab(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_formError != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFDC2626), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formError!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        _section('Product Identity', [
          // Flow: Barcode → Product Name (mirrors Short Description) → Group
          _row(wide, [
            _barcodeField(),
            _field(
              'Product Name *',
              _descriptionCtrl,
              focusNode: _fnName,
              error: _nameHasError,
              onEditingComplete: () => _focusNext(_fnGroup),
              onChanged: (v) {
                // TextChange: keep Short Description in sync while typing name
                _shortDescCtrl.text = v;
                setState(() {});
              },
            ),
          ]),
          _row(wide, [
            _field('Short Description', _shortDescCtrl),
            _field('Arabic Description', _arabicCtrl,
                textDirection: TextDirection.rtl),
          ]),
          _row(wide, [
            _groupPicker(),
            _subGroupPicker(),
          ]),
          _row(wide, [
            _choiceField(
              'Make Type',
              _makeType,
              const ['Standard', 'Assembly', 'Service'],
              (v) => setState(() => _makeType = v),
            ),
            _choiceField(
              'Product Type',
              _productType,
              const ['Stock', 'Non-stock', 'Service'],
              (v) => setState(() => _productType = v),
            ),
          ]),
          _row(wide, [
            _field('Brand', _brandCtrl),
            _field('Own / Product Code (optional)', _productCodeCtrl),
          ]),
        ]),
        const SizedBox(height: 14),
        // Cost first in Enter flow: Group → Unit Cost → Unit Price
        _section('Cost', [
          _row3([
            _field(
              'Unit Cost',
              _unitCostCtrl,
              keyboard: TextInputType.number,
              focusNode: _fnUnitCost,
              onEditingComplete: () => _focusNext(_fnUnitPrice),
            ),
            _field(
              'VAT In %',
              _vatInPctCtrl,
              keyboard: TextInputType.number,
              focusNode: _fnVatInPct,
              onEditingComplete: () => _focusNext(_fnCostWithVat),
            ),
            _field('VAT In Amt', _vatInAmtCtrl, readOnly: true),
          ]),
          _row3([
            _field(
              'Cost With VAT',
              _costWithVatCtrl,
              keyboard: TextInputType.number,
              focusNode: _fnCostWithVat,
              onEditingComplete: () => _focusNext(_fnUnitPrice),
            ),
            const SizedBox.shrink(),
            const SizedBox.shrink(),
          ]),
        ]),
        const SizedBox(height: 14),
        // Sell: Unit Price | VAT Out % | VAT Out Amt  then  Price With VAT
        _section('Sell Price', [
          _row3([
            _field(
              'Unit Price',
              _unitPriceCtrl,
              keyboard: TextInputType.number,
              focusNode: _fnUnitPrice,
              onEditingComplete: () => _focusNext(_fnVatOutPct),
            ),
            _field(
              'VAT Out %',
              _vatOutPctCtrl,
              keyboard: TextInputType.number,
              focusNode: _fnVatOutPct,
              onEditingComplete: () => _focusNext(_fnPriceWithVat),
            ),
            _field('VAT Out Amt', _vatOutAmtCtrl, readOnly: true),
          ]),
          _row3([
            _field(
              'Price With VAT',
              _priceWithVatCtrl,
              keyboard: TextInputType.number,
              focusNode: _fnPriceWithVat,
              onEditingComplete: () => _fnPriceWithVat.unfocus(),
            ),
            const SizedBox.shrink(),
            const SizedBox.shrink(),
          ]),
        ]),
        const SizedBox(height: 14),
        _section('Specification', [
          _field('Notes / Specification', _specCtrl, maxLines: 3),
        ]),
      ],
    );
  }

  Widget _stockTab(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Stock Controls', [
          _row(wide, [
            _choiceField(
              'Unit',
              _unit,
              const ['PCS', 'KG', 'LTR', 'Nos', 'BOX', 'SET'],
              (v) => setState(() => _unit = v),
            ),
            _choiceField(
              'Stock Type',
              _stockType,
              const ['Normal', 'Batch', 'Serial'],
              (v) => setState(() => _stockType = v),
            ),
          ]),
          _row(wide, [
            _field('Pack Qty', _packQtyCtrl, keyboard: TextInputType.number),
            _field('Packet Details', _packetDetailsCtrl),
          ]),
          _row(wide, [
            _field('Qty On Hand', _qtyOnHandCtrl,
                keyboard: TextInputType.number),
            _field('Location', _locationCtrl),
          ]),
          _row(wide, [
            _field('Reorder Level', _reorderLevelCtrl,
                keyboard: TextInputType.number),
            _field('Reorder Qty', _reorderQtyCtrl,
                keyboard: TextInputType.number),
          ]),
          _row(wide, [
            _choiceField(
              'Product Identity',
              _productIdentity,
              const ['Yes', 'No'],
              (v) => setState(() => _productIdentity = v),
            ),
            _field('Origin', _originCtrl),
          ]),
        ]),
        const SizedBox(height: 14),
        _section('Supplier', [
          _row(wide, [
            _field('Supplier Ref No', _supplierRefCtrl),
            _field('Remark', _remarkCtrl),
          ]),
        ]),
      ],
    );
  }

  Widget _pricingTab(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Costs & Margins', [
          _row(wide, [
            _field('Base Cost', _baseCostCtrl, keyboard: TextInputType.number),
            _field('Average Cost', _avgCostCtrl,
                keyboard: TextInputType.number),
          ]),
          _row(wide, [
            _field('Last Purchase Cost', _lastPurchCtrl,
                keyboard: TextInputType.number),
            _field('Min Unit Price', _minPriceCtrl,
                keyboard: TextInputType.number),
          ]),
          _row(wide, [
            _field('Discount %', _discountPctCtrl,
                keyboard: TextInputType.number),
            _field('Margin %', _marginPctCtrl, keyboard: TextInputType.number),
          ]),
        ]),
        const SizedBox(height: 14),
        _section('Price Levels', [
          _row(wide, [
            _field('Price Level 1', _priceLevel1Ctrl,
                keyboard: TextInputType.number),
            _field('Price Level 2', _priceLevel2Ctrl,
                keyboard: TextInputType.number),
          ]),
          _row(wide, [
            _field('Price Level 3', _priceLevel3Ctrl,
                keyboard: TextInputType.number),
            _field('Price Level 4', _priceLevel4Ctrl,
                keyboard: TextInputType.number),
          ]),
          _field('Price Level 5', _priceLevel5Ctrl,
              keyboard: TextInputType.number),
        ]),
      ],
    );
  }

  // ── Field widgets ─────────────────────────────────────────────────────────
  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _maroon,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: _gap),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _row(bool wide, List<Widget> kids) {
    if (!wide) {
      return Column(
        children: [
          for (var i = 0; i < kids.length; i++) ...[
            if (i > 0) const SizedBox(height: _gap),
            kids[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < kids.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(child: kids[i]),
        ],
      ],
    );
  }

  /// Always one row of three equal columns (price / cost VAT layout).
  Widget _row3(List<Widget> kids) {
    assert(kids.length == 3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(child: kids[i]),
        ],
      ],
    );
  }

  Widget _barcodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Barcode',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _muted)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _fieldH,
                child: TextField(
                  controller: _barcodeCtrl,
                  focusNode: _fnBarcode,
                  enabled: !_newBarcode,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _focusNext(_fnName),
                  style: const TextStyle(fontSize: 16),
                  decoration: _inputDec(
                    _newBarcode ? 'Auto-generated on save' : 'Scan or type',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: _fieldH,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _newBarcode = !_newBarcode);
                  // Auto mode: jump straight to Product Name
                  if (!_newBarcode) {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _focusNext(_fnBarcode));
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _focusNext(_fnName));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _newBarcode ? _maroonAccent : const Color(0xFF374151),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _newBarcode ? 'Auto' : 'Manual',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    bool readOnly = false,
    int maxLines = 1,
    TextDirection? textDirection,
    FocusNode? focusNode,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onChanged,
    bool error = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: error ? const Color(0xFFDC2626) : _muted,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: maxLines > 1 ? null : _fieldH,
          child: TextField(
            controller: ctrl,
            focusNode: focusNode,
            readOnly: readOnly,
            maxLines: maxLines,
            textDirection: textDirection,
            keyboardType: keyboard,
            textInputAction: maxLines > 1
                ? TextInputAction.newline
                : TextInputAction.next,
            onEditingComplete: onEditingComplete,
            onChanged: onChanged,
            inputFormatters: keyboard == TextInputType.number
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
                : null,
            style: TextStyle(
              fontSize: 16,
              color: readOnly ? _muted : const Color(0xFF111827),
            ),
            decoration: _inputDec(null, readOnly: readOnly, error: error),
          ),
        ),
        if (error) ...[
          const SizedBox(height: 4),
          Text(
            _formError ?? 'Required',
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDec(String? hint,
      {bool readOnly = false, bool error = false}) {
    final borderColor =
        error ? const Color(0xFFDC2626) : _border;
    final focusColor =
        error ? const Color(0xFFDC2626) : _maroonAccent;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: error
          ? const Color(0xFFFEF2F2)
          : (readOnly ? const Color(0xFFF3F4F6) : _fieldBg),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor, width: error ? 1.5 : 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor, width: error ? 1.5 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: focusColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }

  Widget _choiceField(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final safe = options.contains(value) ? value : options.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _muted)),
        const SizedBox(height: 6),
        SizedBox(
          height: _fieldH,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _fieldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safe,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                style: const TextStyle(
                    fontSize: 16, color: Color(0xFF111827)),
                items: options
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(o, style: const TextStyle(fontSize: 16)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _groupPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Group',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _muted)),
        const SizedBox(height: 6),
        Focus(
          focusNode: _fnGroup,
          onFocusChange: (_) {
            if (mounted) setState(() {});
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
              _focusNext(_fnUnitCost);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: SizedBox(
            height: _fieldH,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _fnGroup.hasFocus ? _maroonAccent : _border,
                  width: _fnGroup.hasFocus ? 1.5 : 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _groups.any((g) =>
                          int.tryParse(g['GroupID']?.toString() ?? '') ==
                          _groupId)
                      ? _groupId
                      : null,
                  isExpanded: true,
                  hint: const Text('— select —',
                      style:
                          TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                  style: const TextStyle(
                      fontSize: 16, color: Color(0xFF111827)),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('— select —'),
                    ),
                    ..._groups.map((g) {
                      final id =
                          int.tryParse(g['GroupID']?.toString() ?? '');
                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(
                          g['GroupDescription']?.toString() ??
                              g['GroupCode']?.toString() ??
                              'Group',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (id) async {
                    setState(() {
                      _groupId = id;
                      _subGroupId = null;
                      _subGroups = [];
                    });
                    if (id != null) {
                      await _loadSubGroups(id);
                      if (mounted) setState(() {});
                    }
                    // After picking a group, continue flow → Unit Cost
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _focusNext(_fnUnitCost));
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _subGroupPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Subgroup',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _muted)),
        const SizedBox(height: 6),
        SizedBox(
          height: _fieldH,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _fieldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _subGroups.any((g) =>
                        int.tryParse(g['SubGroupID']?.toString() ?? '') ==
                        _subGroupId)
                    ? _subGroupId
                    : null,
                isExpanded: true,
                hint: Text(
                  _groupId == null ? 'Select group first' : '— select —',
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF9CA3AF)),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                style: const TextStyle(
                    fontSize: 16, color: Color(0xFF111827)),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('— select —'),
                  ),
                  ..._subGroups.map((g) {
                    final id =
                        int.tryParse(g['SubGroupID']?.toString() ?? '');
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(
                        g['SubGroupDescription']?.toString() ??
                            g['SubGroupCode']?.toString() ??
                            'Subgroup',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: _groupId == null
                    ? null
                    : (id) => setState(() => _subGroupId = id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
