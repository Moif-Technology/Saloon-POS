import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesBillWiseReport extends StatefulWidget {
  const SalesBillWiseReport({Key? key}) : super(key: key);

  @override
  State<SalesBillWiseReport> createState() => _SalesBillWiseReportState();
}

class _SalesBillWiseReportState extends State<SalesBillWiseReport> {
  DateTime? _fromDate;
  DateTime? _toDate;
  
  List<Map<String, dynamic>> _bills = [];
  double _totalAmount = 0.0;
  int _totalBills = 0;
  bool _isLoading = false;

  // App theme colors - Maroon/Burgundy scheme
  static const Color primaryColor = Color(0xFF521C1D);
  static const Color secondaryColor = Color(0xFF8B3A3C);
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
        'bills': <Map<String, dynamic>>[],
        'totalAmount': 0,
        'totalBills': 0,
      };

      setState(() {
        _bills = result['bills'] as List<Map<String, dynamic>>;
        
        // Safely parse totalAmount
        final totalAmountValue = result['totalAmount'] ?? 0;
        if (totalAmountValue is String) {
          _totalAmount = double.tryParse(totalAmountValue) ?? 0.0;
        } else if (totalAmountValue is int) {
          _totalAmount = totalAmountValue.toDouble();
        } else if (totalAmountValue is double) {
          _totalAmount = totalAmountValue;
        } else {
          _totalAmount = 0.0;
        }
        
        _totalBills = result['totalBills'] ?? 0;
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

  Future<void> _selectDate(bool isFromDate) async {
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
    
    double number;
    if (value is String) {
      number = double.tryParse(value) ?? 0.0;
    } else if (value is int) {
      number = value.toDouble();
    } else if (value is double) {
      number = value;
    } else {
      number = 0.0;
    }
    
    return number.toStringAsFixed(2);
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}';
        }
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.receipt_long_outlined, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Sales Bill Wise Report',
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
          _buildCompactFilterCard(),
          _buildCompactStatsSummary(),
          Expanded(child: _buildDataSection()),
        ],
      ),
    );
  }

  Widget _buildCompactFilterCard() {
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
          // From Date
          Expanded(
            flex: 2,
            child: _buildDateField(
              label: 'From Date',
              value: _fromDate != null 
                  ? DateFormat('yyyy-MM-dd').format(_fromDate!)
                  : '',
              onTap: () => _selectDate(true),
            ),
          ),
          SizedBox(width: 10),
          
          // To Date
          Expanded(
            flex: 2,
            child: _buildDateField(
              label: 'To Date',
              value: _toDate != null 
                  ? DateFormat('yyyy-MM-dd').format(_toDate!)
                  : '',
              onTap: () => _selectDate(false),
            ),
          ),
          SizedBox(width: 10),
          
          // Search Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchReportData,
            icon: _isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.search, size: 16),
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

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: primaryColor, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.isEmpty ? label : value,
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildCompactStatsSummary() {
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
              'Bills',
              _totalBills.toString(),
              Icons.receipt_long_outlined,
            ),
          ),
          _buildCompactDivider(),
          Expanded(
            child: _buildCompactStatItem(
              'Total',
              _formatNumber(_totalAmount),
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
      height: 30,
      width: 1,
      color: Colors.grey[300],
      margin: EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildDataSection() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              'No bills found',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  'Bills List (${_bills.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : SingleChildScrollView(
                    child: _buildCustomTable(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTable() {
    if (_bills.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.receipt_outlined, size: 48, color: Colors.grey[400]),
              SizedBox(height: 12),
              Text(
                'No bills found',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

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
                  'Bills List',
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
                    '${_bills.length} bills',
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
          SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: Table(
              border: TableBorder.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(2.5),
                4: FlexColumnWidth(2),
                5: FlexColumnWidth(1.5),
                6: FlexColumnWidth(1.5),
                7: FlexColumnWidth(2),
              },
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                  ),
                  children: [
                    _buildTableHeaderCell('Bill No'),
                    _buildTableHeaderCell('Date'),
                    _buildTableHeaderCell('Time', isCenter: true),
                    _buildTableHeaderCell('Area'),
                    _buildTableHeaderCell('Amount', isNumeric: true),
                    _buildTableHeaderCell('Discount', isNumeric: true),
                    _buildTableHeaderCell('Type', isCenter: true),
                    _buildTableHeaderCell('Payment', isCenter: true),
                  ],
                ),
                
                // Data Rows
                ..._bills.map((bill) {
                  final bool isReturn = bill['TransactionType'] == 'RETURN';
                  return TableRow(
                    children: [
                      _buildTableDataCell(
                        bill['BillNo']?.toString() ?? '',
                        isBold: true,
                      ),
                      _buildTableDataCell(
                        _formatDate(bill['BillDate']),
                      ),
                      _buildTableDataCell(
                        _formatTime(bill['BillTime']),
                        isCenter: true,
                      ),
                      _buildTableDataCell(
                        bill['AreaName']?.toString() ?? '-',
                      ),
                      _buildTableDataCell(
                        _formatNumber(bill['Amount']),
                        isNumeric: true,
                        isBold: true,
                        color: isReturn ? Colors.red.shade600 : Colors.black87,
                      ),
                      _buildTableDataCell(
                        _formatNumber(bill['DiscountAmount']),
                        isNumeric: true,
                        color: Colors.orange.shade600,
                      ),
                      _buildTableDataCell(
                        _getTypeShort(bill['TransactionType']),
                        isCenter: true,
                        isBold: true,
                        color: isReturn ? Colors.red.shade600 : Colors.green.shade700,
                      ),
                      _buildTableDataCell(
                        _getPaymentModeShort(bill['PaymentMode']),
                        isCenter: true,
                      ),
                    ],
                  );
                }),
              ],
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

  Widget _buildTableDataCell(String text, {bool isNumeric = false, bool isBold = false, bool isCenter = false, Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : (isNumeric ? TextAlign.right : TextAlign.left),
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }

  Widget _buildModernTableCell(
    String text, {
    required int flex,
    required TextAlign align,
    bool bold = false,
    IconData? icon,
  }) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: primaryColor.withOpacity(0.5)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: align,
              style: TextStyle(
                fontSize: 10,
                color: Colors.black87,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCell(String value, {required int flex, required bool isReturn}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isReturn 
              ? Colors.red.shade50 
              : Colors.green.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isReturn ? Colors.red.shade700 : Colors.green.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCell(String text, {required int flex, required bool isReturn}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isReturn 
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [primaryColor, secondaryColor],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCell(String text, {required int flex}) {
    IconData icon;
    Color color;
    
    switch (text.toUpperCase()) {
      case 'CSH':
        icon = Icons.payments_outlined;
        color = Colors.green.shade600;
        break;
      case 'CRD':
        icon = Icons.credit_card_outlined;
        color = Colors.blue.shade600;
        break;
      case 'ONL':
        icon = Icons.phone_android_outlined;
        color = Colors.purple.shade600;
        break;
      default:
        icon = Icons.account_balance_wallet_outlined;
        color = Colors.grey.shade600;
    }
    
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    required int flex,
    required TextAlign align,
    Color? color,
    bool bold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 10,
          color: color ?? Colors.black87,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return DateFormat('dd/MM/yy').format(parsed);
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _getTypeShort(String? type) {
    if (type == null) return '';
    if (type == 'SALES') return 'S';
    if (type == 'RETURN') return 'R';
    return type.substring(0, 1);
  }

  String _getPaymentModeShort(String? mode) {
    if (mode == null) return '';
    if (mode == 'CASH') return 'CSH';
    if (mode == 'CREDIT') return 'CRD';
    if (mode == 'CARD') return 'CRD';
    if (mode == 'ONLINE') return 'ONL';
    return mode.substring(0, 3);
  }

  void _showBillDetails(Map<String, dynamic> bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_outlined, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Bill #${bill['BillNo']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Bill No', bill['BillNo']?.toString() ?? '-'),
              _buildDetailRow('Date', _formatDate(bill['BillDate'])),
              _buildDetailRow('Time', bill['BillTime']?.toString() ?? '-'),
              _buildDetailRow('Counter No', bill['CounterNo']?.toString() ?? '-'),
              _buildDetailRow('Area', bill['AreaName']?.toString() ?? '-'),
              _buildDetailRow('Salesman', bill['SalesManName']?.toString() ?? '-'),
              Divider(height: 16, color: Colors.grey.shade300),
              _buildDetailRow('Amount', _formatNumber(bill['Amount'])),
              _buildDetailRow('Discount', _formatNumber(bill['DiscountAmount'])),
              Divider(height: 16, color: Colors.grey.shade300),
              _buildDetailRow('Transaction Type', bill['TransactionType']?.toString() ?? '-'),
              _buildDetailRow('Payment Mode', bill['PaymentMode']?.toString() ?? '-'),
              _buildDetailRow('Post Status', bill['PostStatus']?.toString() ?? '-'),
              _buildDetailRow('Counter Close', bill['CounterCloseStatus']?.toString() ?? '-'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
            ),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
