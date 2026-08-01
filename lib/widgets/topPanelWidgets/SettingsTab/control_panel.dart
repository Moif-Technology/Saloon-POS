import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/api_service_provider.dart';
import 'package:my_app/core/providers/parameterProviders.dart';

class POSSettingsDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<POSSettingsDialog> createState() => _POSSettingsDialogState();
}

class _POSSettingsDialogState extends ConsumerState<POSSettingsDialog> {
  static const Color _primaryColor = Color(0xFF521C1D);
  int selectedTabIndex = 0;
  final GlobalKey<_CompanyDetailsTabState> _companyDetailsKey = GlobalKey();
  final GlobalKey<_TaxSettingsTabState> _taxSettingsKey = GlobalKey();

  final List<String> tabs = [
    'Company Details',
    'Main Form',
    'Job',
    'Bill',
    'Mail Sending',
    'General',
    'Game Zone',
    'Tax Settings',
  ];

  @override
Widget build(BuildContext context) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Container(
      width: 900,
      height: 750,
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
          _buildHeader(context),
          _buildTabs(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildTabContent(),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    ),
  );
}

Widget _buildHeader(BuildContext context) {
  return Container(
    constraints: const BoxConstraints(minHeight: 56),
    padding: const EdgeInsets.only(left: 20, right: 8),
    decoration: const BoxDecoration(
      color: _primaryColor,
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'POS Settings',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            tooltip: 'Close',
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    ),
  );
}

 Widget _buildTabs() {
  return Container(
    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = selectedTabIndex == index;
          return Padding(
            padding: EdgeInsets.only(
              right: index == tabs.length - 1 ? 0 : 8,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedTabIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? _primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildTabContent() {
    switch (selectedTabIndex) {
      case 0:
        return _CompanyDetailsTab(key: _companyDetailsKey);
      case 1:
        return _MainFormTab();
      case 2:
        return _KOTTab();
      case 3:
        return _BillTab();
      case 4:
        return _MailSendingTab();
      case 5:
        return _GeneralTab();
      case 6:
        return _GameZoneTab();
      case 7:
        return _TaxSettingsTab(key: _taxSettingsKey);
      default:
        return SizedBox.shrink();
    }
  }

  Future<void> _handleSave() async {
    if (selectedTabIndex == 0) {
      await _companyDetailsKey.currentState?.saveCompanyDetails();
    } else if (selectedTabIndex == 7) {
      await _taxSettingsKey.currentState?.saveTaxSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save for ${tabs[selectedTabIndex]} coming soon.')),
      );
    }
  }

Widget _buildActionButtons(BuildContext context) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(
        top: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () => _handleSave(),
          icon: const Icon(Icons.save, color: Colors.white, size: 20),
          label: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 44),
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ],
    ),
  );
}
}
Widget _posSettingsSectionBox({
  required String title,
  required Widget content,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    ),
  );
}
// Individual Tabs
class _CompanyDetailsTab extends ConsumerStatefulWidget {
  const _CompanyDetailsTab({super.key});

  @override
  ConsumerState<_CompanyDetailsTab> createState() => _CompanyDetailsTabState();
}

class _CompanyDetailsTabState extends ConsumerState<_CompanyDetailsTab> {
  late final TextEditingController _heading1;
  late final TextEditingController _heading2;
  late final TextEditingController _heading3;
  late final TextEditingController _heading4;
  late final TextEditingController _heading5;
  late final TextEditingController _footer1;
  late final TextEditingController _footer2;
  late final TextEditingController _taxRegNo;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final details = ref.read(companyDetailsProvider);
    _heading1 = TextEditingController(text: details['heading1'] ?? '');
    _heading2 = TextEditingController(text: details['heading2'] ?? '');
    _heading3 = TextEditingController(text: details['heading3'] ?? '');
    _heading4 = TextEditingController(text: details['heading4'] ?? '');
    _heading5 = TextEditingController(text: details['heading5'] ?? '');
    _footer1 = TextEditingController(text: details['footer1'] ?? '');
    _footer2 = TextEditingController(text: details['footer2'] ?? '');
    _taxRegNo = TextEditingController(text: details['taxRegNo'] ?? '');
  }

  @override
  void dispose() {
    _heading1.dispose();
    _heading2.dispose();
    _heading3.dispose();
    _heading4.dispose();
    _heading5.dispose();
    _footer1.dispose();
    _footer2.dispose();
    _taxRegNo.dispose();
    super.dispose();
  }

  Future<void> saveCompanyDetails() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.saveCompanyDetails(
        heading1: _heading1.text.trim(),
        heading2: _heading2.text.trim(),
        heading3: _heading3.text.trim(),
        heading4: _heading4.text.trim(),
        heading5: _heading5.text.trim(),
        footer1: _footer1.text.trim(),
        footer2: _footer2.text.trim(),
        taxRegNo: _taxRegNo.text.trim(),
      );
      ref.read(companyDetailsProvider.notifier).state = {
        'heading1': _heading1.text.trim(),
        'heading2': _heading2.text.trim(),
        'heading3': _heading3.text.trim(),
        'heading4': _heading4.text.trim(),
        'heading5': _heading5.text.trim(),
        'footer1': _footer1.text.trim(),
        'footer2': _footer2.text.trim(),
        'taxRegNo': _taxRegNo.text.trim(),
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company details saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _posSettingsSectionBox(
          title: 'Receipt Header',
          content: Column(
            children: [
              _buildLabeledField('Heading 1', _heading1),
              const SizedBox(height: 12),
              _buildLabeledField('Heading 2', _heading2),
              const SizedBox(height: 12),
              _buildLabeledField('Heading 3', _heading3),
              const SizedBox(height: 12),
              _buildLabeledField('Heading 4', _heading4),
              const SizedBox(height: 12),
              _buildLabeledField('Heading 5', _heading5),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _posSettingsSectionBox(
          title: 'Tax Information',
          content: _buildLabeledField('Tax Reg. No', _taxRegNo),
        ),
        const SizedBox(height: 16),
        _posSettingsSectionBox(
          title: 'Footer Information',
          content: Column(
            children: [
              _buildLabeledField('Footer 1', _footer1),
              const SizedBox(height: 12),
              _buildLabeledField('Footer 2', _footer2),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF521C1D),
      ),
    );
  }

  Widget _buildLabeledField(String label, TextEditingController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D),
            ),
          ),
        ),
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: controller,
            maxLength: 50,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF521C1D)),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

class _MainFormTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Column
              Expanded(
                child: Column(
                  children: [
                    // General Settings Box
                    _buildBox(
                      'General Settings',
                      Column(
                        children: [
                          _buildLabeledField('View Type', '0.0000', ''),
                          _buildLabeledField(
                              'Software Level', '0', '0-Normal, 1-With Combo'),
                          _buildLabeledField(
                              'Currency Precision', '0.00', 'eg: 0.00'),
                          _buildLabeledField(
                              'DSN', 'HmsDsn', 'Report Location'),
                          _buildLabeledField(
                              'CallPopup', '0', '0-No Popup, 1-Popup'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Popup Settings Box
                    _buildBox(
                      'Popup Settings',
                      Column(
                        children: [
                          _buildLabeledField('Settlement on Popup', '1',
                              '0-Normal, 1-Screen on Popup'),
                          _buildLabeledField('Default Search Item', '0',
                              '0-Item Name, 1-Barcode'),
                          _buildLabeledField('Default Area Name', '1',
                              '0-No Default, 1-TakeAway as Default'),
                          _buildLabeledField('Clear After Job Save', '1',
                              '0-Not Clear Job, 1-Clear Job Values'),
                          _buildLabeledField(
                              'Credit Card Popup', '0', '0-Not Show, 1-Show'),
                        ],
                      ),
                    ),
                   const SizedBox(height: 8),
_buildBox(
  'Table Settings',
  Column(
    children: [
      _buildLabeledField(
        'Show Tables Based on Waiter',
        '0',
        '0-Not Check, 1-Check',
      ),
    ],
  ),
),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Second Column
              Expanded(
                child: Column(
                  children: [
                    // Server Settings Box
                    _buildBox(
                      'Server Settings',
                      Column(
                        children: [
                          _buildLabeledField(
                              'Counter Server Path', '', 'Server Path'),
                          _buildLabeledField('Ask Pwd for Waiter Selection',
                              '0', '0-No Password, 1-Ask Password'),
                          _buildLabeledField('Waiter Mandatory', '0',
                              '0-Not Mandatory, 1-Mandatory'),
                          _buildLabeledField('Parcel Charge Automatic', '0',
                              '0-Not Automatic, 1-Automatic'),
                          _buildLabeledField('Delivery Charge Prd ID', '0',
                              'Product ID of Delivery Charge Item'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Barcode Settings Box
                    _buildBox(
                      'Barcode Settings',
                      Column(
                        children: [
                          _buildLabeledField('Print Barcode on Printer', '0',
                              'On Godex: 0-No Print, 1-Print'),
                          Row(
                            children: [
                              Expanded(child: _buildSubField('Top', '25', '')),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _buildSubField('Width', '100', '')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildSubField('Left', '15', '')),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _buildSubField('Height', '50', '')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Don’t Make Barcode Printer as Default Printer',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLabeledField('ItemCancel Job Print', '0',
                              '0-Print, 1-No Print'),
                          _buildLabeledField(
                              'AllowPriceChange for ZeroPriceItems',
                              '1',
                              '0-Not Allow, 1-Allow'),
                          _buildLabeledField('Enable Barcode Scanning', '1',
                              '0-Display List, 1-Barcode Scanning'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
_buildBox(
  'Settlement & Payment Options',
  Column(
    children: [
      _buildLabeledField(
        'Save Job on Settlement',
        '1.0000',
        '0-Nothing, 1-Save Job',
      ),
      _buildLabeledField(
        'Enable Online Payment',
        '0',
        '0-No, 1-Set',
      ),
      _buildLabeledField(
        'Enable Mess',
        '0',
        '0-No, 1-Set',
      ),
    ],
  ),
),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build Box Widget
 Widget _buildBox(String title, Widget content) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    ),
  );
}
  // Build Labeled Field Widget
  Widget _buildLabeledField(String label, String initialValue, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: initialValue,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build SubField Widget
  Widget _buildSubField(String label, String initialValue, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(fontSize: 10),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

// Build Box Widget
Widget _buildBox(String title, Widget content) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    ),
  );
}

// Build Labeled Field Widget
Widget _buildLabeledField(String label, String initialValue, String hint) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: TextFormField(
            initialValue: initialValue,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            hint,
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    ),
  );
}

// Build SubField Widget
Widget _buildSubField(String label, String initialValue, String hint) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF521C1D),
        ),
      ),
      const SizedBox(height: 4),
      TextFormField(
        initialValue: initialValue,
        style: const TextStyle(fontSize: 10),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ],
  );
}

// Placeholder tabs
class _KOTTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                child: Column(
                  children: [
                    // KOT General Settings Box
                    _buildBox(
                      'Job General Settings',
                      Column(
                        children: [
                          _buildLabeledField('Job Language', '0',
                              '0-English, 1-Arabic, 2-English and Arabic'),
                          _buildLabeledField(
                              'Job Heading Font Size', '0', 'eg: 14'),
                          _buildLabeledField(
                              'Job Print Item Font Size', '13', 'eg: 16'),
                          _buildLabeledField('Same Items on MultiLines', '0',
                              '0-Same Line, 1-MultiLine'),
                          _buildLabeledField('Job Price Print', '0.0000',
                              '0-With Out Price, 1-With Price'),
                          _buildLabeledField('Print Duplicate Job', '0',
                              '0-No Print, 1-Print'),
                          _buildLabeledField(
                              'Delivery Default Customer', 'CASH CUSTOMER', ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Android Print Timer Field
                    _buildLabeledField(
                      'Android Print Timer',
                      '1.0000',
                      'Set from Login Page',
                    ),
                    const SizedBox(height: 16),
                    // Dummy Bill in Kitchen Box
                    _buildBox(
                      'Dummy Bill in Kitchen',
                      Column(
                        children: [
                          _buildLabeledField('Kitchen Dummy Bill', '0',
                              '0-Only Job, 1-Job with Dummy Bill'),
                          const SizedBox(height: 8),
                          _buildCheckboxRow(),
                          const SizedBox(height: 16),
                          _buildLabeledField('Printer Name', '', ''),
                          _buildLabeledField('Automatic Dummy Bill Print', '0',
                              '0-No Print, 1-Print Dummy Bill on Cntr from Tablet Order'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right Column (Full Height Box)
              Expanded(
                child: _buildBox(
                  'Job Print & Save Settings',
                  Column(
                    children: [
                      _buildLabeledField('Job Print All Items', '0',
                          '0-Not All Items, 1-All Items'),
                      _buildLabeledField('Is Job Print for TakeAway', '0',
                          '0-Print, 1-No Print'),
                      _buildLabeledField('Is Job Print for Delivery', '0',
                          '0-Print, 1-No Print'),
                      _buildLabeledField(
                          'Is Job Print for DineIn', '0', '0-Print, 1-No Print'),
                      _buildLabeledField('Job Print on Direct Settlement', '0',
                          '0-No Print, 1-Print'),
                      _buildLabeledField('Print Delivery Job Separately', '0',
                          '0-Not Separate, 1-Separate'),
                      _buildLabeledField('Print TakeAway Job Separately', '0',
                          '0-Not Separate, 1-Separate'),
                      const SizedBox(height: 16),
                      _buildLabeledField('Print Dummy Bill on Save Job Print',
                          '0', '0-No Print, 1-Dummy Bill'),
                      _buildLabeledField(
                          'Save Job Print', '1.0000', '0-No Print, 1-Print'),
                      _buildLabeledField('Settlement Job Print', '1.0000',
                          '0-No Print, 1-Print'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build Box Widget
 Widget _buildBox(String title, Widget content) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    ),
  );
}

  // Build Labeled Field Widget
  Widget _buildLabeledField(String label, String initialValue, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: initialValue,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Checkbox Group Widget
  Widget _buildCheckboxRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(value: false, onChanged: (value) {}),
            const Text(
              'TakeAway',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(value: false, onChanged: (value) {}),
            const Text(
              'DineIn',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(value: false, onChanged: (value) {}),
            const Text(
              'Delivery',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _BillTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                child: Column(
                  children: [
                    // Bill General Settings Box
                    _buildBox(
                      'Bill General Settings',
                      Column(
                        children: [
                          _buildLabeledField('Bill Print Style', '0',
                              '0-Single Line, 1-Multiple Line, 2-Item Name on Single Line'),
                          _buildLabeledField(
                              'Counter Bill Print Type', '0', '0-UAE, 1-Oman'),
                          _buildLabeledField('Credit Card Bill Count', '1', ''),
                          _buildLabeledField('Bill Print Count', '1', ''),
                          _buildLabeledField('Credit Bill Count', '0', ''),
                          _buildLabeledField(
                              'Bill Print Amount Limit', '-100', ''),
                          _buildLabeledField(
                              'Coupon Amount', '100000.0000', ''),
                          _buildLabeledField('HideWaiterAndTableONBill', '0',
                              '0-Print Waiter&Table Line, 1-No Print'),
                          _buildLabeledField('AllowZeroPriceOnBill', '1',
                              '0-Not Allow Zero Price, 1-Allow'),
                          _buildLabeledField('Bill Reset Type', '2',
                              '0-Bill Reset with Date, 1-Bill Reset After Counter Close, 2-Continues Bill No'),
                          _buildLabeledField('Delivery Bill Print', '0',
                              '0-Default Print, 1-No Print'),
                          _buildLabeledField(
                              'Dummy Bill Name', 'Dummy Bill', ''),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right Column
              Expanded(
                child: Column(
                  children: [
                    // Logo and Footer Print Box
                    _buildBox(
                      'Logo and Footer Settings',
                      Column(
                        children: [
                          _buildLabeledField('Logo Print', '0.0000',
                              '0-No Logo, 1-With Logo, C:\\Program Files\\logo.jpg'),
                          _buildLabeledField(
                              'Logo XPosition', '0.0000', 'Bill Top Position'),
                          _buildLabeledField('Logo YPosition', '0.0000', ''),
                          _buildLabeledField('Footer Print', '0.0000',
                              '0-No Logo, 1-With Logo, C:\\Program Files\\footer.jpg'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bill X-Position Box with Vertical Alignment
                    _buildBox(
                      'Bill X-Position',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabeledField('Qty X', '150', 'Maximum: 145'),
                          _buildLabeledField('Price X', '165', 'Maximum: 165'),
                          _buildLabeledField(
                              'Line Total X', '200', 'Maximum: 220'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build Box Widget
Widget _buildBox(String title, Widget content) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    ),
  );
}

  // Build Labeled Field Widget
  Widget _buildLabeledField(String label, String initialValue, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: initialValue,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build SubField Widget (Not needed anymore since alignment is now vertical)
}

class _MailSendingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
return SingleChildScrollView(
  child: _posSettingsSectionBox(
    title: 'Mail Settings',
    content: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabeledField('Mail Sending', '0', '0-No Send, 1-Send'),
              _buildLabeledField('Mail Password', '**********', ''),
              _buildLabeledField('Mail From', 'inventsolutionsuae@gmail.com', ''),
              _buildLabeledField('Counter Close Details', '0', '0-Hide Counter Close, 1-Show'),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabeledField('Mail To', 'madhukarakkad@gmail.com', ''),
              _buildLabeledField('Mail Attachment', 'D:\\Mail.pdf', ''),
              _buildLabeledField('Dummy Bill', '0.0000', ''),
            ],
          ),
        ),
      ],
    ),
  ),
);
 }

  Widget _buildLabeledField(String label, String initialValue, String hint,
      {double width = 240}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: TextFormField(
              initialValue: initialValue,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
return SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _posSettingsSectionBox(
        title: 'Printing Options',
        content: Row(
          children: [
            Expanded(
              child: _buildLabeledField('REPORT PATH HMS', r'\Release', ''),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLabeledField('Select Printer', '', ''),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _posSettingsSectionBox(
        title: 'General Options',
        content: Column(
          children: [
            _buildLabeledField('MenuItemOrderByAlphabet', '0', '0 - No, 1 - Set'),
            const SizedBox(height: 8),
            _buildLabeledField('IsEnableRoundOff', '0', '0 - Not Enable, 1 - Enable'),
            const SizedBox(height: 8),
            _buildLabeledField('IsPendingJobCheck', '0', '0 - Not Enable, 1 - Enable'),
            const SizedBox(height: 8),
            _buildLabeledField('IsDeliveryPrintOnJobSave', '0', '0 - No, 1 - Set'),
            const SizedBox(height: 8),
            _buildLabeledField('CheckCounterCloseOnReports', '0', '0 - No, 1 - Set'),
          ],
        ),
      ),
    ],
  ),
);
  }

  Widget _buildLabeledField(String label, String initialValue, String hint,
      {double width = 100}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: TextFormField(
              initialValue: initialValue,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameZoneTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
 return SingleChildScrollView(
  child: _posSettingsSectionBox(
    title: 'Game Zone Settings',
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledField('Game Zone', '0', '0 - Disable, 1 - Enable'),
        const SizedBox(height: 12),
        _buildDropdownField('Game Area', ['Game Area 1', 'Game Area 2'], 'Select Game Area'),
        const SizedBox(height: 12),
        _buildDropdownField('Game Group', ['Group 1', 'Group 2'], 'Select the Category having game products'),
        const SizedBox(height: 12),
        _buildLabeledField('Game Zone Price Per', '0', 'Minute'),
        const SizedBox(height: 12),
        _buildLabeledField('Starting Time and Elapse Time', '0', '0 - No Print, 1 - Print Time Details on Bill'),
      ],
    ),
  ),
);
  }

  Widget _buildLabeledField(String label, String initialValue, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF521C1D),
              ),
            ),
          ),
          // Input Field
          SizedBox(
            width: 200,
            child: TextFormField(
              initialValue: initialValue,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Hint
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildDropdownField(String label, List<String> items, String hint) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D),
            ),
            softWrap: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            isExpanded: true, // critical — prevents dropdown internal overflow
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {},
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            hint: Text(
              hint,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            hint,
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
            softWrap: true,
          ),
        ),
      ],
    ),
  );
}
}

class _TaxSettingsTab extends ConsumerStatefulWidget {
  const _TaxSettingsTab({super.key});

  @override
  ConsumerState<_TaxSettingsTab> createState() => _TaxSettingsTabState();
}

class _TaxSettingsTabState extends ConsumerState<_TaxSettingsTab> {
  late final TextEditingController _tax1;
  late final TextEditingController _currencyPrecision;
  late final TextEditingController _taxRegNo;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final tax1Val = ref.read(tax1Provider);
    final currencyVal = ref.read(currencyPrecessionProvider);
    final details = ref.read(companyDetailsProvider);

    _tax1 = TextEditingController(
      text: tax1Val != null ? tax1Val.toStringAsFixed(0) : '',
    );
    _currencyPrecision = TextEditingController(
      text: currencyVal ?? '',
    );
    _taxRegNo = TextEditingController(
      text: details['taxRegNo'] ?? '',
    );
  }

  @override
  void dispose() {
    _tax1.dispose();
    _currencyPrecision.dispose();
    _taxRegNo.dispose();
    super.dispose();
  }

  Future<void> saveTaxSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);

      final tax1Num = double.tryParse(_tax1.text.trim());
      final precisionNum = int.tryParse(_currencyPrecision.text.trim());

      if (tax1Num == null) {
        throw Exception('Tax 1 must be a valid number');
      }
      if (precisionNum == null) {
        throw Exception('Currency decimals must be a valid integer');
      }

      await api.savePosParameters({
        'tax1': tax1Num,
        'currency_precision': precisionNum,
        'tax_registration_no': _taxRegNo.text.trim(),
      });

      // Update Riverpod providers
      ref.read(tax1Provider.notifier).state = tax1Num;
      ref.read(currencyPrecessionProvider.notifier).state =
          precisionNum.toString();
      ref.read(companyDetailsProvider.notifier).state = {
        ...ref.read(companyDetailsProvider),
        'taxRegNo': _taxRegNo.text.trim(),
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax settings saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: _posSettingsSectionBox(
      title: 'Tax Settings',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabeledField('Tax 1 (%)', _tax1,
              hint: 'e.g. 5 for 5%', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildLabeledField('Currency Decimals', _currencyPrecision,
              hint: 'e.g. 2 for 0.00', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildLabeledField('Tax Registration No.', _taxRegNo,
              hint: 'Tax / VAT registration number'),
          if (_isSaving) ...[
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF521C1D),
                strokeWidth: 2,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildLabeledField(
  String label,
  TextEditingController controller, {
  String hint = '',
  TextInputType keyboardType = TextInputType.text,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 200,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF521C1D),
          ),
        ),
      ),
      SizedBox(
        width: 220,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF521C1D)),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
      ),
    ],
  );
}
}
