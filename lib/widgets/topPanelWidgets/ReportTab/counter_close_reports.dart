import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CounterCloseReportPage extends StatefulWidget {
  @override
  _CounterCloseReportPageState createState() => _CounterCloseReportPageState();
}

class _CounterCloseReportPageState extends State<CounterCloseReportPage> {
  final TextEditingController _counterNoController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  
  // Color constants
  static const Color primaryColor = Color(0xFF521C1D);
  static const Color secondaryColor = Color(0xFF8B3A3C);
  static const Color accentColor = Color(0xFFFFF8E7);
  static const Color lightBg = Color(0xFFFAF6F1);

  List<Map<String, dynamic>> _reportData = [];
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = false;
  String? _selectedCashierId;
  Map<String, dynamic>? _selectedReport;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadStaffList();
    _fetchReportData();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _fromDateController.text = DateFormat('yyyy-MM-dd').format(now);
    _toDateController.text = DateFormat('yyyy-MM-dd').format(now);
  }

  Future<void> _loadStaffList() async {
    try {
      final data = <Map<String, dynamic>>[];
      setState(() {
        _staffList = data;
      });
    } catch (e) {
      print('Error loading staff list: $e');
    }
  }

  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);

    try {
      final data = <Map<String, dynamic>>[];

      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching counter close report: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.assessment_outlined, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Counter Close Report',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, 
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchReportData,
            tooltip: 'Refresh',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Modern Filter Card
          _buildFilterCard(),
          
          // Stats Summary Cards
          _buildStatsSummary(),
          
          // Data Table Section
          Expanded(
            child: _buildDataSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Counter Number
          Expanded(
            flex: 2,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _counterNoController,
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Counter No',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.countertops, color: primaryColor, size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          
          // Cashier Dropdown
          Expanded(
            flex: 3,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  hint: Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.grey[400], size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Select Cashier',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  value: _selectedCashierId,
                  icon: Icon(Icons.arrow_drop_down, color: primaryColor, size: 18),
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Cashiers', style: TextStyle(fontSize: 12)),
                    ),
                    ..._staffList.map((staff) {
                      return DropdownMenuItem<String>(
                        value: staff['StaffID'].toString(),
                        child: Text(staff['StaffName'], style: TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCashierId = value);
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          
          // From Date
          Expanded(
            flex: 2,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _fromDateController,
                readOnly: true,
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'From Date',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.calendar_today, color: primaryColor, size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                onTap: () => _selectDate(context, _fromDateController),
              ),
            ),
          ),
          SizedBox(width: 10),
          
          // To Date
          Expanded(
            flex: 2,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _toDateController,
                readOnly: true,
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'To Date',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.calendar_today, color: primaryColor, size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                onTap: () => _selectDate(context, _toDateController),
              ),
            ),
          ),
          SizedBox(width: 10),
          
          // Search Button
          ElevatedButton.icon(
            onPressed: _fetchReportData,
            icon: Icon(Icons.search, size: 16),
            label: Text(
              'Search',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildStatsSummary() {
    if (_reportData.isEmpty) return SizedBox.shrink();

    final totalCash = _reportData.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item['TotalCash']?.toString() ?? '0') ?? 0),
    );
    final totalBills = _reportData.fold<int>(
      0,
      (sum, item) => sum + (int.tryParse(item['BillCount']?.toString() ?? '0') ?? 0),
    );
    final totalCollected = _reportData.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item['CollectedCash']?.toString() ?? '0') ?? 0),
    );

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStatItem(
              'Sessions',
              _reportData.length.toString(),
              Icons.article_outlined,
            ),
          ),
          _buildCompactDivider(),
          Expanded(
            child: _buildCompactStatItem(
              'Bills',
              totalBills.toString(),
              Icons.receipt_long_outlined,
            ),
          ),
          _buildCompactDivider(),
          Expanded(
            child: _buildCompactStatItem(
              'Cash',
              totalCash.toStringAsFixed(2),
              Icons.payments_outlined,
            ),
          ),
          _buildCompactDivider(),
          Expanded(
            child: _buildCompactStatItem(
              'Collected',
              totalCollected.toStringAsFixed(2),
              Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: primaryColor),
        SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.grey[300],
      margin: EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildDataSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Compact Table Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: primaryColor, size: 16),
                SizedBox(width: 6),
                Text(
                  'Counter Close Records',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Spacer(),
                if (_reportData.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_reportData.length} records',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Table Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Loading reports...',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : _reportData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No records found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildModernDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDataTable() {
    return Container(
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart_outlined, color: primaryColor, size: 16),
                SizedBox(width: 8),
                Text(
                  'Counter Close Records',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_reportData.length} records',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Table Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
                columnWidths: {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(2.5),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(1.5),
                  5: FlexColumnWidth(2),
                  6: FlexColumnWidth(2),
                  7: FlexColumnWidth(2),
                  8: FlexColumnWidth(2),
                  9: FlexColumnWidth(1.5),
                  10: FlexColumnWidth(2),
                  11: FlexColumnWidth(1.5),
                  12: FlexColumnWidth(2),
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                    ),
                    children: [
                      _buildTableHeaderCell('Counter'),
                      _buildTableHeaderCell('Close No'),
                      _buildTableHeaderCell('Cashier'),
                      _buildTableHeaderCell('Date'),
                      _buildTableHeaderCell('Time'),
                      _buildTableHeaderCell('Cash', isNumeric: true),
                      _buildTableHeaderCell('Credit', isNumeric: true),
                      _buildTableHeaderCell('Card', isNumeric: true),
                      _buildTableHeaderCell('Online', isNumeric: true),
                      _buildTableHeaderCell('Bills', isNumeric: true),
                      _buildTableHeaderCell('Collected', isNumeric: true),
                      _buildTableHeaderCell('Diff', isNumeric: true),
                      _buildTableHeaderCell('Actions', isCenter: true),
                    ],
                  ),
                  
                  // Data Rows
                  ..._reportData.map((report) {
                    final cashDiff = double.tryParse(report['CashDifference']?.toString() ?? '0') ?? 0;
                    return TableRow(
                      children: [
                        _buildTableDataCell(
                          'C${report['CounterNo']?.toString() ?? ''}',
                          isBold: true,
                          color: primaryColor,
                        ),
                        _buildTableDataCell(
                          '${report['CounterCloseCode'] ?? ''}${report['CounterCloseNo'] ?? ''}',
                        ),
                        _buildTableDataCell(
                          report['CashierName'] ?? '',
                        ),
                        _buildTableDataCell(
                          report['CloseDate'] != null
                              ? DateFormat('dd/MM/yy').format(DateTime.parse(report['CloseDate']))
                              : '-',
                        ),
                        _buildTableDataCell(
                          report['CloseTime'] != null
                              ? DateFormat('HH:mm').format(DateTime.parse(report['CloseTime']))
                              : '-',
                        ),
                        _buildTableDataCell(
                          _formatNumber(report['TotalCash']),
                          isNumeric: true,
                        ),
                        _buildTableDataCell(
                          _formatNumber(report['TotalCredit']),
                          isNumeric: true,
                        ),
                        _buildTableDataCell(
                          _formatNumber(report['TotalCreditCard']),
                          isNumeric: true,
                        ),
                        _buildTableDataCell(
                          _formatNumber(report['TotalOnline']),
                          isNumeric: true,
                        ),
                        _buildTableDataCell(
                          report['BillCount']?.toString() ?? '0',
                          isNumeric: true,
                          isBold: true,
                        ),
                        _buildTableDataCell(
                          _formatNumber(report['CollectedCash']),
                          isNumeric: true,
                          isBold: true,
                        ),
                        _buildTableDataCell(
                          _formatNumber(cashDiff.abs()),
                          isNumeric: true,
                          isBold: true,
                          color: cashDiff != 0 ? Colors.red.shade600 : Colors.green.shade700,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility_outlined, size: 16),
                                color: primaryColor,
                                padding: EdgeInsets.all(2),
                                constraints: BoxConstraints(),
                                onPressed: () => _showDetailsDialog(report),
                                tooltip: 'View',
                              ),
                              SizedBox(width: 6),
                              IconButton(
                                icon: Icon(Icons.print_outlined, size: 16),
                                color: Colors.grey[600],
                                padding: EdgeInsets.all(2),
                                constraints: BoxConstraints(),
                                onPressed: () => _printReport(report),
                                tooltip: 'Print',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {bool isNumeric = false, bool isCenter = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : (isNumeric ? TextAlign.right : TextAlign.left),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 10,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildTableDataCell(String text, {bool isNumeric = false, bool isBold = false, Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        textAlign: isNumeric ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, {
    required int flex,
    bool isNumeric = false,
    bool isCenter = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : (isNumeric ? TextAlign.right : TextAlign.left),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    required int flex,
    bool isNumeric = false,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: isNumeric ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 12,
          fontWeight: fontWeight,
          color: color ?? Colors.black87,
          fontFamily: isNumeric ? 'monospace' : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDifferenceTableCell(double difference, {required int flex}) {
    final isPositive = difference > 0;
    final isZero = difference == 0;
    
    Color textColor;
    String prefix = '';
    
    if (isZero) {
      textColor = Colors.grey[600]!;
    } else if (isPositive) {
      textColor = Colors.green[700]!;
      prefix = '+';
    } else {
      textColor = Colors.red[700]!;
    }
    
    return Expanded(
      flex: flex,
      child: Text(
        '$prefix${difference.toStringAsFixed(2)}',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  DataColumn _buildCompactDataColumn(String label, {bool numeric = false}) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 12,
        ),
      ),
      numeric: numeric,
    );
  }

  Widget _buildCompactDifferenceCell(double difference) {
    final isPositive = difference > 0;
    final isZero = difference == 0;
    
    Color textColor;
    
    if (isZero) {
      textColor = Colors.grey[600]!;
    } else if (isPositive) {
      textColor = Colors.green[700]!;
    } else {
      textColor = Colors.red[700]!;
    }
    
    return Text(
      '${isPositive && !isZero ? '+' : ''}${difference.toStringAsFixed(2)}',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: textColor,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: primaryColor, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Counter Close Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          '${report['CounterCloseCode']}${report['CounterCloseNo']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 32),
              _buildDetailRow('Cashier', report['CashierName'] ?? '', Icons.person),
              _buildDetailRow('Date', DateFormat('dd MMMM yyyy').format(DateTime.parse(report['CloseDate'])), Icons.calendar_today),
              _buildDetailRow('Time', DateFormat('hh:mm a').format(DateTime.parse(report['CloseTime'])), Icons.access_time),
              _buildDetailRow('Total Cash', _formatNumber(report['TotalCash']), Icons.money),
              _buildDetailRow('Total Credit', _formatNumber(report['TotalCredit']), Icons.credit_card),
              _buildDetailRow('Credit Card', _formatNumber(report['TotalCreditCard']), Icons.payment),
              _buildDetailRow('Online', _formatNumber(report['TotalOnline']), Icons.online_prediction),
              _buildDetailRow('Discount', _formatNumber(report['TotalDiscount']), Icons.discount),
              _buildDetailRow('Bill Count', report['BillCount']?.toString() ?? '0', Icons.receipt),
              _buildDetailRow('To Collect', _formatNumber(report['CashToBeCollected']), Icons.account_balance),
              _buildDetailRow('Collected', _formatNumber(report['CollectedCash']), Icons.account_balance_wallet),
              _buildDetailRow('Difference', _formatNumber(report['CashDifference']), Icons.compare_arrows),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    label: Text('Close'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _printReport(report);
                    },
                    icon: Icon(Icons.print),
                    label: Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _printReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Printing ${report['CounterCloseCode']}${report['CounterCloseNo']}...'),
        backgroundColor: primaryColor,
      ),
    );
    // TODO: Implement print functionality
  }

  Widget _buildCashierDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.person_outline, color: primaryColor, size: 18),
              SizedBox(width: 8),
              Text(
                'Select Cashier',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          value: _selectedCashierId,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor, size: 20),
          style: TextStyle(fontSize: 13, color: Colors.black87),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('All Cashiers'),
            ),
            ..._staffList.map((staff) {
              return DropdownMenuItem<String>(
                value: staff['StaffID'].toString(),
                child: Text(staff['StaffName']),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() => _selectedCashierId = value);
          },
        ),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    final num = double.tryParse(value.toString()) ?? 0.0;
    return num.toStringAsFixed(2);
  }
}
