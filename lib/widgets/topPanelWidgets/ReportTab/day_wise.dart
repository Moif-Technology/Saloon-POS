import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayWise extends StatefulWidget {
  const DayWise({Key? key}) : super(key: key);

  @override
  State<DayWise> createState() => _DayWiseState();
}

class _DayWiseState extends State<DayWise> {
  DateTime? _fromDate;
  DateTime? _toDate;
  
  List<Map<String, dynamic>> _dailyData = [];
  Map<String, dynamic>? _grandTotals;
  bool _isLoading = false;

  // App theme colors
  static const Color primaryColor = Color(0xFF521C1D);
  static const Color lightBg = Color(0xFFFAF6F1);

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    setState(() {
      _fromDate = DateTime(now.year, now.month, now.day);
      _toDate = DateTime(now.year, now.month, now.day);
    });
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    if (_fromDate == null || _toDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final fromDateStr = DateFormat('yyyy-MM-dd').format(_fromDate!);
      final toDateStr = DateFormat('yyyy-MM-dd').format(_toDate!);

      final result = <String, dynamic>{
        'dailyData': <dynamic>[],
        'grandTotals': <String, dynamic>{},
      };

      setState(() {
        _dailyData = List<Map<String, dynamic>>.from(result['dailyData'] ?? []);
        _grandTotals = result['grandTotals'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate ?? DateTime.now() : _toDate ?? DateTime.now(),
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
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    final number = value is String ? double.tryParse(value) ?? 0.0 : value.toDouble();
    return number.toStringAsFixed(2);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Day Wise Report',
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
          if (_dailyData.isNotEmpty)
            IconButton(
              icon: Icon(Icons.print, color: Colors.white),
              onPressed: _printReport,
              tooltip: 'Print Report',
            ),
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
          _buildFilterCard(),
          if (_grandTotals != null) _buildStatsSummary(),
          Expanded(child: _buildDataTable()),
        ],
      ),
    );
  }

  void _printReport() {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Print functionality will be implemented'),
        backgroundColor: primaryColor,
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // From Date
          Expanded(
            flex: 2,
            child: _buildDateField(
              label: 'From Date',
              value: _fromDate != null 
                  ? DateFormat('yyyy-MM-dd').format(_fromDate!)
                  : '',
              onTap: () => _selectDate(context, true),
            ),
          ),
          SizedBox(width: 8),
          
          // To Date
          Expanded(
            flex: 2,
            child: _buildDateField(
              label: 'To Date',
              value: _toDate != null 
                  ? DateFormat('yyyy-MM-dd').format(_toDate!)
                  : '',
              onTap: () => _selectDate(context, false),
            ),
          ),
          SizedBox(width: 8),
          
          // Search Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchReportData,
            icon: _isLoading
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.search, size: 14),
            label: Text(
              'Search',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size(0, 30),
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

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: primaryColor, size: 13),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  value.isEmpty ? label : value,
                  style: TextStyle(
                    fontSize: 11,
                    color: value.isEmpty ? Colors.grey[400] : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    if (_grandTotals == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStatItem(
              'Total Sales',
              _formatNumber(_grandTotals!['totalSales']),
              Icons.trending_up_outlined,
            ),
          ),
          _buildCompactDivider(),
          Expanded(
            child: _buildCompactStatItem(
              'Cash In Hand',
              _formatNumber(_grandTotals!['cashInHand']),
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
        Icon(icon, size: 14, color: primaryColor),
        SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
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
      height: 24,
      width: 1,
      color: Colors.grey[300],
      margin: EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildDataTable() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_dailyData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              'No data available',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Select a date range and click Search',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  'Daily Summary',
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
                    '${_dailyData.length} days',
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
            child: Column(
              children: [
                // Scrollable Table
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Table(
                      border: TableBorder.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      columnWidths: {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                        4: FlexColumnWidth(2),
                        5: FlexColumnWidth(2),
                        6: FlexColumnWidth(2),
                        7: FlexColumnWidth(2.5),
                      },
                      children: [
                        // Header Row
                        TableRow(
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                          ),
                          children: [
                            _buildTableHeaderCell('Date'),
                            _buildTableHeaderCell('Cash', isNumeric: true),
                            _buildTableHeaderCell('Credit', isNumeric: true),
                            _buildTableHeaderCell('Card', isNumeric: true),
                            _buildTableHeaderCell('Total', isNumeric: true),
                            _buildTableHeaderCell('Return', isNumeric: true),
                            _buildTableHeaderCell('Purchase', isNumeric: true),
                            _buildTableHeaderCell('Cash In Hand', isNumeric: true),
                          ],
                        ),
                        
                        // Data Rows
                        ..._dailyData.map((day) {
                          return TableRow(
                            children: [
                              _buildTableCell(_formatDate(day['date'].toString())),
                              _buildTableCell(_formatNumber(day['cashSales']), isNumeric: true),
                              _buildTableCell(_formatNumber(day['creditSales']), isNumeric: true),
                              _buildTableCell(_formatNumber(day['cardSales']), isNumeric: true),
                              _buildTableCell(_formatNumber(day['totalSales']), isNumeric: true, isBold: true),
                              _buildTableCell(_formatNumber(day['salesReturn']), isNumeric: true, isRed: true),
                              _buildTableCell(_formatNumber(day['cashPurchase']), isNumeric: true),
                              _buildTableCell(_formatNumber(day['cashInHand']), isNumeric: true, isBold: true),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
                // Total Row at Bottom
                if (_grandTotals != null)
                  Container(
                    margin: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(color: primaryColor.withOpacity(0.3), width: 1),
                        verticalInside: BorderSide(color: primaryColor.withOpacity(0.3), width: 1),
                      ),
                      columnWidths: {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                        4: FlexColumnWidth(2),
                        5: FlexColumnWidth(2),
                        6: FlexColumnWidth(2),
                        7: FlexColumnWidth(2.5),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                          ),
                          children: [
                            _buildTableCell('TOTAL', isBold: true, isTotal: true),
                            _buildTableCell(_formatNumber(_grandTotals!['cashSales']), isNumeric: true, isBold: true),
                            _buildTableCell(_formatNumber(_grandTotals!['creditSales']), isNumeric: true, isBold: true),
                            _buildTableCell(_formatNumber(_grandTotals!['cardSales']), isNumeric: true, isBold: true),
                            _buildTableCell(_formatNumber(_grandTotals!['totalSales']), isNumeric: true, isBold: true),
                            _buildTableCell(_formatNumber(_grandTotals!['salesReturn']), isNumeric: true, isBold: true, isRed: true),
                            _buildTableCell(_formatNumber(_grandTotals!['cashPurchase']), isNumeric: true, isBold: true),
                            _buildTableCell(_formatNumber(_grandTotals!['cashInHand']), isNumeric: true, isBold: true),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {bool isNumeric = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: isNumeric ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 10,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isNumeric = false, bool isBold = false, bool isRed = false, bool isTotal = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: isNumeric ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold || isTotal ? FontWeight.w700 : FontWeight.w500,
          color: isRed ? Colors.red.shade600 : (isTotal ? primaryColor : Colors.black87),
        ),
      ),
    );
  }
}
