import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/services/api_service.dart';

/// Touch-optimised Customer Entry dialog — ERP field set with split layout:
/// left = entry form, right = searchable list (select → update).
class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({Key? key}) : super(key: key);

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  static const Color _maroon = Color(0xFF521C1D);
  static const Color _accent = Color(0xFF780829);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _fieldBg = Color(0xFFF8F6F6);
  static const double _fieldH = 48;

  static const _countries = [
    'UNITED ARAB EMIRATES',
    'KSA',
    'Qatar',
    'Oman',
    'Bahrain',
    'India',
  ];
  static const _cities = [
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Riyadh',
    'Doha',
    'Muscat',
  ];
  static const _paymentModes = ['CASH', 'CREDIT', 'CREDIT CARD', 'TRANSFER'];
  static const _customerTypes = ['Retail', 'Wholesale', 'Corporate'];
  static const _creditStatuses = ['ACTIVE', 'INACTIVE', 'HOLD'];
  static const _loyaltyOptions = ['Yes', 'No'];

  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _trnCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _addressArCtrl = TextEditingController();
  final _poBoxCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _faxCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _creditLimitCtrl = TextEditingController();
  final _creditPeriodCtrl = TextEditingController();
  final _creditBalanceCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  bool _newCode = true;
  bool _saving = false;
  bool _loadingList = true;
  String? _listError;
  String? _editingId;
  int? _selectedIndex;

  /// Inline validation (SnackBar sits behind Dialog).
  String? _formError;
  String? _errorField; // 'code' | 'name' | null

  final _fnCode = FocusNode();
  final _fnName = FocusNode();
  final _formScroll = ScrollController();

  String _country = '';
  String _city = '';
  String _paymentMode = 'CASH';
  String _customerType = 'Retail';
  String _creditStatus = 'ACTIVE';
  String _loyalty = 'No';

  List<Map<String, dynamic>> _customers = [];
  Timer? _searchDebounce;

  bool get _isEdit => _editingId != null && _editingId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _nameCtrl.addListener(_clearNameErrorOnType);
    _codeCtrl.addListener(_clearCodeErrorOnType);
  }

  void _clearNameErrorOnType() {
    if (_errorField == 'name' && _nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _errorField = null;
        _formError = null;
      });
    }
  }

  void _clearCodeErrorOnType() {
    if (_errorField == 'code' && _codeCtrl.text.trim().isNotEmpty) {
      setState(() {
        _errorField = null;
        _formError = null;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _nameCtrl.removeListener(_clearNameErrorOnType);
    _codeCtrl.removeListener(_clearCodeErrorOnType);
    _fnCode.dispose();
    _fnName.dispose();
    _formScroll.dispose();
    for (final c in [
      _codeCtrl,
      _nameCtrl,
      _companyCtrl,
      _trnCtrl,
      _addressCtrl,
      _addressArCtrl,
      _poBoxCtrl,
      _contactCtrl,
      _designationCtrl,
      _telCtrl,
      _mobileCtrl,
      _faxCtrl,
      _emailCtrl,
      _creditLimitCtrl,
      _creditPeriodCtrl,
      _creditBalanceCtrl,
      _remarksCtrl,
      _searchCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCustomers({String search = ''}) async {
    setState(() {
      _loadingList = true;
      _listError = null;
    });
    try {
      final rows = await ApiService()
          .fetchCustomers(limit: 500, search: search.isEmpty ? null : search);
      if (!mounted) return;
      setState(() {
        _customers =
            rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _listError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      _loadCustomers(search: q.trim());
    });
  }

  void _clearForm({bool keepListSelection = false}) {
    _codeCtrl.clear();
    _nameCtrl.clear();
    _companyCtrl.clear();
    _trnCtrl.clear();
    _addressCtrl.clear();
    _addressArCtrl.clear();
    _poBoxCtrl.clear();
    _contactCtrl.clear();
    _designationCtrl.clear();
    _telCtrl.clear();
    _mobileCtrl.clear();
    _faxCtrl.clear();
    _emailCtrl.clear();
    _creditLimitCtrl.clear();
    _creditPeriodCtrl.clear();
    _creditBalanceCtrl.clear();
    _remarksCtrl.clear();
    setState(() {
      _newCode = true;
      _editingId = null;
      _formError = null;
      _errorField = null;
      _country = '';
      _city = '';
      _paymentMode = 'CASH';
      _customerType = 'Retail';
      _creditStatus = 'ACTIVE';
      _loyalty = 'No';
      if (!keepListSelection) _selectedIndex = null;
    });
  }

  void _showFieldError(String field, String message) {
    setState(() {
      _errorField = field;
      _formError = message;
    });
    if (_formScroll.hasClients) {
      _formScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (field == 'name') {
        _fnName.requestFocus();
      } else if (field == 'code') {
        _fnCode.requestFocus();
      }
    });
  }

  void _populateFrom(Map<String, dynamic> c, int index) {
    setState(() {
      _editingId = c['CustomerID']?.toString() ?? c['customerId']?.toString();
      _selectedIndex = index;
      _newCode = false;
      _formError = null;
      _errorField = null;
      _codeCtrl.text = c['CustomerCode']?.toString() ?? '';
      _nameCtrl.text = c['CustomerName']?.toString() ?? '';
      _companyCtrl.text = c['companyName']?.toString() ?? '';
      _trnCtrl.text =
          c['CustTRN']?.toString() ?? c['taxRegNo']?.toString() ?? '';
      _addressCtrl.text =
          c['Address']?.toString() ?? c['address']?.toString() ?? '';
      _addressArCtrl.text = c['addressArabic']?.toString() ?? '';
      _poBoxCtrl.text = c['poBox']?.toString() ?? '';
      _contactCtrl.text = c['contactPerson']?.toString() ?? '';
      _designationCtrl.text = c['designation']?.toString() ?? '';
      _telCtrl.text =
          c['Telephone']?.toString() ?? c['telephone']?.toString() ?? '';
      _mobileCtrl.text =
          c['MobileNo']?.toString() ?? c['mobileNo']?.toString() ?? '';
      _faxCtrl.text = c['faxNo']?.toString() ?? '';
      _emailCtrl.text = c['email']?.toString() ?? '';
      _creditLimitCtrl.text = c['creditLimit']?.toString() ?? '';
      _creditPeriodCtrl.text = c['creditPeriodDays']?.toString() ?? '';
      _creditBalanceCtrl.text = c['creditBalance']?.toString() ?? '';
      _remarksCtrl.text = c['remarks']?.toString() ?? '';
      _country = c['country']?.toString() ?? c['Country']?.toString() ?? '';
      _city = c['city']?.toString() ?? c['City']?.toString() ?? '';
      final pm = c['paymentMode']?.toString() ?? '';
      _paymentMode = _paymentModes.contains(pm) ? pm : 'CASH';
      final ct = c['customerType']?.toString() ?? '';
      _customerType = _customerTypes.contains(ct) ? ct : 'Retail';
      final cs = c['creditStatus']?.toString() ?? 'ACTIVE';
      _creditStatus = _creditStatuses.contains(cs) ? cs : 'ACTIVE';
      final ly = c['loyaltyCustStatus']?.toString() ?? 'No';
      _loyalty = _loyaltyOptions.contains(ly) ? ly : 'No';
    });
  }

  Map<String, dynamic> _buildPayload() {
    return <String, dynamic>{
      if (!_newCode && _codeCtrl.text.trim().isNotEmpty)
        'customerCode': _codeCtrl.text.trim(),
      'newBarcode': _newCode && !_isEdit,
      'customerName': _nameCtrl.text.trim(),
      if (_companyCtrl.text.trim().isNotEmpty)
        'companyName': _companyCtrl.text.trim(),
      if (_trnCtrl.text.trim().isNotEmpty) 'taxRegNo': _trnCtrl.text.trim(),
      if (_contactCtrl.text.trim().isNotEmpty)
        'contactPerson': _contactCtrl.text.trim(),
      if (_designationCtrl.text.trim().isNotEmpty)
        'designation': _designationCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_addressArCtrl.text.trim().isNotEmpty)
        'addressArabic': _addressArCtrl.text.trim(),
      if (_poBoxCtrl.text.trim().isNotEmpty) 'poBox': _poBoxCtrl.text.trim(),
      if (_country.isNotEmpty) 'country': _country,
      if (_city.isNotEmpty) 'city': _city,
      if (_telCtrl.text.trim().isNotEmpty) 'telephone': _telCtrl.text.trim(),
      if (_mobileCtrl.text.trim().isNotEmpty)
        'mobileNo': _mobileCtrl.text.trim(),
      if (_faxCtrl.text.trim().isNotEmpty) 'faxNo': _faxCtrl.text.trim(),
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_paymentMode.isNotEmpty) 'paymentMode': _paymentMode,
      if (_creditLimitCtrl.text.trim().isNotEmpty)
        'creditLimit': _creditLimitCtrl.text.trim(),
      if (_creditPeriodCtrl.text.trim().isNotEmpty)
        'creditPeriodDays': _creditPeriodCtrl.text.trim(),
      if (_creditBalanceCtrl.text.trim().isNotEmpty)
        'creditBalance': _creditBalanceCtrl.text.trim(),
      if (_customerType.isNotEmpty) 'customerType': _customerType,
      'loyaltyCustStatus': _loyalty,
      'creditStatus': _creditStatus,
      if (_remarksCtrl.text.trim().isNotEmpty)
        'remarks': _remarksCtrl.text.trim(),
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showFieldError('name', 'Customer Name is required.');
      return;
    }
    if (!_isEdit && !_newCode && _codeCtrl.text.trim().isEmpty) {
      _showFieldError('code', 'Customer Code is required (or switch to Auto).');
      return;
    }
    if (_isEdit && _codeCtrl.text.trim().isEmpty) {
      _showFieldError('code', 'Customer Code is required for update.');
      return;
    }

    setState(() {
      _formError = null;
      _errorField = null;
    });

    final payload = _buildPayload();
    if (_isEdit) {
      payload['customerCode'] = _codeCtrl.text.trim();
      payload['newBarcode'] = false;
    }

    setState(() => _saving = true);
    try {
      final Map<String, dynamic> result;
      if (_isEdit) {
        result = await ApiService().updateCustomer(_editingId!, payload);
      } else {
        result = await ApiService().createCustomer(payload);
      }
      if (!mounted) return;
      _toast(
        '${_isEdit ? 'Updated' : 'Saved'} "${result['customerName'] ?? name}".',
      );
      _clearForm();
      await _loadCustomers(search: _searchCtrl.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = e.toString().replaceFirst('Exception: ', '');
        _errorField = null;
      });
      if (_formScroll.hasClients) {
        _formScroll.animateTo(0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _selectAndClose() {
    if (_selectedIndex == null ||
        _selectedIndex! < 0 ||
        _selectedIndex! >= _customers.length) {
      setState(() {
        _formError = 'Select a customer from the list first.';
        _errorField = null;
      });
      return;
    }
    final c = _customers[_selectedIndex!];
    Navigator.of(context).pop({
      'CustomerID': c['CustomerID']?.toString() ?? '',
      'CustomerCode': c['CustomerCode']?.toString() ?? '',
      'CustomerName': c['CustomerName']?.toString() ?? '',
      'Telephone': c['Telephone']?.toString() ?? '',
      'MobileNo': c['MobileNo']?.toString() ?? '',
      'CustTRN': c['CustTRN']?.toString() ?? '',
      'Address': c['Address']?.toString() ?? '',
    });
  }

  void _toast(String msg, {bool error = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogW = size.width > 1200 ? size.width * 0.88 : size.width * 0.96;
    final dialogH = size.height * 0.92;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: dialogW,
        height: dialogH,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _header(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: _formPane()),
                    Container(width: 1, color: _border),
                    Expanded(flex: 4, child: _listPane()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: const BoxDecoration(
        color: _maroon,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      padding: const EdgeInsets.only(left: 18, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEdit ? 'Edit Customer' : 'Customer Entry',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_isEdit)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'ID $_editingId',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          SizedBox(
            width: 46,
            height: 46,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Left: form ────────────────────────────────────────────────────────────
  Widget _formPane() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _formScroll,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_formError != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                _card('Basic Info', [
                  _codeField(),
                  const SizedBox(height: 10),
                  _row2(
                    _field(
                      'Customer Name *',
                      _nameCtrl,
                      focusNode: _fnName,
                      error: _errorField == 'name',
                    ),
                    _field('Company / Trading Name', _companyCtrl),
                  ),
                  const SizedBox(height: 10),
                  _row2(
                    _field('Tax Registration No.', _trnCtrl),
                    _dropdown('Customer Type', _customerType, _customerTypes,
                        (v) => setState(() => _customerType = v)),
                  ),
                ]),
                const SizedBox(height: 12),
                _card('Address', [
                  _field('Street Address', _addressCtrl, maxLines: 2),
                  const SizedBox(height: 10),
                  _field('Address Arabic', _addressArCtrl,
                      maxLines: 2, textDirection: TextDirection.rtl),
                  const SizedBox(height: 10),
                  _row3(
                    _field('P.O. Box', _poBoxCtrl),
                    _dropdown('Country', _country, _countries,
                        (v) => setState(() => _country = v),
                        allowEmpty: true),
                    _dropdown('City', _city, _cities,
                        (v) => setState(() => _city = v),
                        allowEmpty: true),
                  ),
                ]),
                const SizedBox(height: 12),
                _card('Contact', [
                  _row2(
                    _field('Contact Person', _contactCtrl),
                    _field('Designation', _designationCtrl),
                  ),
                  const SizedBox(height: 10),
                  _row2(
                    _field('Telephone', _telCtrl,
                        keyboard: TextInputType.phone),
                    _field('Mobile No.', _mobileCtrl,
                        keyboard: TextInputType.phone,
                        digitsOnly: true),
                  ),
                  const SizedBox(height: 10),
                  _row2(
                    _field('Fax', _faxCtrl),
                    _field('Email', _emailCtrl,
                        keyboard: TextInputType.emailAddress),
                  ),
                ]),
                const SizedBox(height: 12),
                _card('Payment & Credit', [
                  _row2(
                    _dropdown('Payment Mode', _paymentMode, _paymentModes,
                        (v) => setState(() => _paymentMode = v)),
                    _dropdown('Credit Status', _creditStatus, _creditStatuses,
                        (v) => setState(() => _creditStatus = v)),
                  ),
                  const SizedBox(height: 10),
                  _row3(
                    _field('Credit Limit', _creditLimitCtrl,
                        keyboard: TextInputType.number),
                    _field('Credit Period (days)', _creditPeriodCtrl,
                        keyboard: TextInputType.number),
                    _field('Credit Balance', _creditBalanceCtrl,
                        keyboard: TextInputType.number),
                  ),
                  const SizedBox(height: 10),
                  _dropdown('Loyalty Customer', _loyalty, _loyaltyOptions,
                      (v) => setState(() => _loyalty = v)),
                ]),
                const SizedBox(height: 12),
                _card('Remarks', [
                  _field('Notes', _remarksCtrl, maxLines: 3),
                ]),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFCFBFB),
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _clearForm(),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('New',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _maroon,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            _isEdit ? Icons.update : Icons.save_outlined,
                            size: 20),
                    label: Text(
                      _isEdit ? 'Update' : 'Save',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Right: list ───────────────────────────────────────────────────────────
  Widget _listPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SizedBox(
            height: _fieldH,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search name, code, mobile, city…',
                hintStyle:
                    const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _maroon),
                filled: true,
                fillColor: _fieldBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _accent, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        Container(
          color: const Color(0xFFF3EDED),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: const Row(
            children: [
              _HeaderCell('Code', flex: 2),
              _HeaderCell('Name', flex: 3),
              _HeaderCell('City', flex: 2),
              _HeaderCell('Mobile', flex: 2),
            ],
          ),
        ),
        Expanded(
          child: _loadingList
              ? const Center(child: CircularProgressIndicator())
              : _listError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_listError!, textAlign: TextAlign.center),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => _loadCustomers(
                                  search: _searchCtrl.text.trim()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _customers.isEmpty
                      ? const Center(child: Text('No customers found'))
                      : ListView.builder(
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final c = _customers[index];
                            final selected = _selectedIndex == index;
                            return Material(
                              color: selected
                                  ? const Color(0xFFFFF0F3)
                                  : (index.isEven
                                      ? const Color(0xFFFCFBFB)
                                      : Colors.white),
                              child: InkWell(
                                onTap: () => _populateFrom(c, index),
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minHeight: 48),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: selected
                                            ? _accent
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                      bottom: const BorderSide(
                                          color: _border, width: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _cell(
                                          c['CustomerCode']?.toString() ?? '',
                                          flex: 2,
                                          bold: true),
                                      _cell(
                                          c['CustomerName']?.toString() ?? '',
                                          flex: 3),
                                      _cell(c['City']?.toString() ?? '',
                                          flex: 2),
                                      _cell(c['MobileNo']?.toString() ?? '',
                                          flex: 2),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFCFBFB),
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _selectAndClose,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Select',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _maroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _muted,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared field widgets ──────────────────────────────────────────────────
  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _accent,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row2(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
        ],
      );

  Widget _row3(Widget a, Widget b, Widget c) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 8),
          Expanded(child: b),
          const SizedBox(width: 8),
          Expanded(child: c),
        ],
      );

  Widget _codeField() {
    final hasError = _errorField == 'code';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Customer Code *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hasError ? const Color(0xFFDC2626) : _muted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _fieldH,
                child: TextField(
                  controller: _codeCtrl,
                  focusNode: _fnCode,
                  enabled: !_newCode || _isEdit,
                  style: const TextStyle(fontSize: 15),
                  decoration: _dec(
                    _newCode && !_isEdit
                        ? 'Auto-generated on save'
                        : 'e.g. CUST-001',
                    error: hasError,
                  ),
                ),
              ),
            ),
            if (!_isEdit) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: _fieldH,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _newCode = !_newCode;
                    if (_errorField == 'code') {
                      _errorField = null;
                      _formError = null;
                    }
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _newCode ? _accent : const Color(0xFF374151),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _newCode ? 'Auto' : 'Manual',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasError) ...[
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

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    int maxLines = 1,
    TextDirection? textDirection,
    bool digitsOnly = false,
    FocusNode? focusNode,
    bool error = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: error ? const Color(0xFFDC2626) : _muted,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: maxLines > 1 ? null : _fieldH,
          child: TextField(
            controller: ctrl,
            focusNode: focusNode,
            maxLines: maxLines,
            textDirection: textDirection,
            keyboardType: keyboard,
            inputFormatters: digitsOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : (keyboard == TextInputType.number
                    ? [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.\-]'))
                      ]
                    : null),
            style: const TextStyle(fontSize: 15),
            decoration: _dec(null, error: error),
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

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged, {
    bool allowEmpty = false,
  }) {
    final items = allowEmpty ? ['', ...options] : options;
    final safe = items.contains(value) ? value : (items.isNotEmpty ? items.first : '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
        const SizedBox(height: 4),
        SizedBox(
          height: _fieldH,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _fieldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safe.isEmpty && allowEmpty ? '' : safe,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 26),
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                items: items
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(o.isEmpty ? '— select —' : o,
                              overflow: TextOverflow.ellipsis),
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

  InputDecoration _dec(String? hint, {bool error = false}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        filled: true,
        fillColor: error ? const Color(0xFFFEF2F2) : _fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: error ? const Color(0xFFDC2626) : _border,
            width: error ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: error ? const Color(0xFFDC2626) : _border,
            width: error ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: error ? const Color(0xFFDC2626) : _accent,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: error ? const Color(0xFFDC2626) : _border,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      );

  Widget _cell(String text, {int flex = 1, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  const _HeaderCell(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF521C1D),
        ),
      ),
    );
  }
}
