import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/utils/empty_kot_response.dart';
import 'package:my_app/services/printService/pos_print.dart';
import 'package:my_app/utils/sessionManager.dart';

class BillReprintDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<BillReprintDialog> createState() => _BillReprintDialogState();
}

class _BillReprintDialogState extends ConsumerState<BillReprintDialog> {
  List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  int? _selectedSalesId;
 int? _selectedKotId;
Map<String, dynamic>? _selectedBillDetails;

// App theme colors
  static const primaryColor = Color(0xFF521C1D);
  static const primaryLight = Color(0xFF7D2A2B);
  static const accentColor = Color(0xFF8B3A3C);

  @override
  void initState() {
    super.initState();
    _loadTodayBills();
  }

  Future<void> _loadTodayBills() async {
    try {
      setState(() => _isLoading = true);
      
      final stationIdStr = SessionManager().stationId ?? '1';
      final counterNo = int.tryParse(stationIdStr) ?? 1;
      
      print('🔵 Bill Reprint - Fetching bills for counter: $counterNo');
      
      final bills = <Map<String, dynamic>>[];
      
      print('🟢 Bill Reprint - Fetched ${bills.length} bills');
      
      setState(() {
        _bills = bills;
        _isLoading = false;
      });

      if (_bills.isNotEmpty) {
        print('🔵 Bill Reprint - Auto-selecting first bill');
        _selectBill(_bills[0]);
      } else {
        print('⚠️ Bill Reprint - No bills found for today');
      }
    } catch (e, stackTrace) {
      print('❌ Bill Reprint - Error loading bills: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _selectBill(Map<String, dynamic> bill) async {
    try {
      final salesIdRaw = bill['SalesID'];
      final salesId = salesIdRaw is int 
          ? salesIdRaw 
          : int.parse(salesIdRaw.toString());
      
      print('🔵 Bill Reprint - Loading items for SalesID: $salesId');
      
      final details = <String, dynamic>{'salesItems': <dynamic>[]};
      
      print('🟢 Bill Reprint - Loaded details: ${details.keys}');
      
      final holdNoRaw = bill['HoldNo'];
      final holdNo = holdNoRaw == null 
          ? null 
          : (holdNoRaw is int ? holdNoRaw : int.tryParse(holdNoRaw.toString()));
      
      setState(() {
        _selectedSalesId = salesId;
        _selectedKotId = holdNo;
        _selectedBillDetails = bill;
        _items = List<Map<String, dynamic>>.from(details['salesItems'] ?? []);
      });
      
      print('🟢 Bill Reprint - Items count: ${_items.length}');
    } catch (e, stackTrace) {
      print('❌ Bill Reprint - Error loading items: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e'), duration: Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _printBill() async {
    if (_selectedSalesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bill selected')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryColor),
                SizedBox(height: 16),
                Text('Printing...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );

      final receiptData = <String, dynamic>{
        'header': <String, dynamic>{},
        'salesItems': <dynamic>[],
      };
      
      if (mounted) Navigator.of(context).pop();
      
      if (receiptData['header'] == null) {
        throw Exception('Invalid receipt data');
      }

      await PosPrint.printSalesReceipt(
        receiptData: receiptData,
        currencyDecimals: 2,
        onError: (String message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Print error: $message')),
            );
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bill printed successfully'),
            backgroundColor: primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Print failed: $e')),
        );
      }
    }
  }

  Future<void> _printKOT() async {
    if (_selectedKotId == null || _selectedKotId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No job available')),
      );
      return;
    }

    try {
      await emptyKotDetails();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job reprint - Coming soon')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job print failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 920,
        height: 680,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // Modern Header
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, 
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bill Reprint",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "View and reprint previous bills",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_bills.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.list_alt_rounded, 
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${_bills.length} Bills',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                          SizedBox(height: 16),
                          Text('Loading bills...', 
                              style: TextStyle(fontSize: 15, color: Colors.black54)),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        // Bills List
                        Expanded(
                          flex: 4,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                // Bills Header
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildModernHeader('Bill No', flex: 2),
                                      _buildModernHeader('Time', flex: 2),
                                      _buildModernHeader('Payment', flex: 2),
                                      _buildModernHeader('Amount', flex: 2, 
                                          align: TextAlign.right),
                                    ],
                                  ),
                                ),
                                // Bills List
                                Expanded(
                                  child: _bills.isEmpty
                                      ? _buildEmptyState(
                                          Icons.receipt_long_outlined,
                                          'No bills today',
                                          'Bills will appear here after checkout',
                                        )
                                      : ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                              bottom: Radius.circular(16)),
                                          child: ListView.builder(
                                            itemCount: _bills.length,
                                            itemBuilder: (context, index) =>
                                                _buildModernBillRow(_bills[index]),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Items Panel
                        Expanded(
                          flex: 6,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                // Items Header with Summary
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                  ),
                                  child: _selectedBillDetails != null
                                      ? Row(
                                          children: [
                                            _buildModernChip(
                                              _selectedBillDetails!['BillNo']?.toString() ?? '-',
                                              Icons.receipt_rounded,
                                            ),
                                            const SizedBox(width: 10),
                                            _buildModernChip(
                                              _selectedBillDetails!['PaymentMode']?.toString() ?? '-',
                                              Icons.payment_rounded,
                                            ),
                                            const Spacer(),
                                            _buildSummaryBox(),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Icon(Icons.shopping_cart_outlined, 
                                                size: 20, color: Colors.grey[400]),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Bill Items',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                // Items Table Header
                                if (_selectedSalesId != null)
                                  Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildModernHeader('#', flex: 1),
                                        _buildModernHeader('Item Description', flex: 5),
                                        _buildModernHeader('Qty', flex: 1, 
                                            align: TextAlign.center),
                                        _buildModernHeader('Price', flex: 2, 
                                            align: TextAlign.right),
                                        _buildModernHeader('Total', flex: 2, 
                                            align: TextAlign.right),
                                      ],
                                    ),
                                  ),
                                // Items List
                                Expanded(
                                  child: _selectedSalesId == null
                                      ? _buildEmptyState(
                                          Icons.touch_app_rounded,
                                          'Select a bill',
                                          'Tap on any bill to view details',
                                        )
                                      : _items.isEmpty
                                          ? _buildEmptyState(
                                              Icons.inventory_2_outlined,
                                              'No items',
                                              'This bill has no items',
                                            )
                                          : ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                  bottom: Radius.circular(16)),
                                              child: ListView.builder(
                                                itemCount: _items.length,
                                                itemBuilder: (context, index) =>
                                                    _buildModernItemRow(_items[index], index),
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

            // Modern Action Bar
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  _buildModernButton(
                    'Print Bill',
                    Icons.print_rounded,
                    _selectedSalesId == null ? null : _printBill,
                    isPrimary: true,
                  ),
                  const SizedBox(width: 12),
                  _buildModernButton(
                    'Print Job',
                    Icons.restaurant_menu_rounded,
                    _selectedKotId == null || _selectedKotId == 0 ? null : _printKOT,
                  ),
                  const SizedBox(width: 12),
                  _buildModernButton(
                    'Refresh',
                    Icons.refresh_rounded,
                    _loadTodayBills,
                  ),
                  const Spacer(),
                  _buildModernButton(
                    'Close',
                    Icons.close_rounded,
                    () => Navigator.of(context).pop(),
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBillRow(Map<String, dynamic> bill) {
    final salesIdRaw = bill['SalesID'];
    final currentSalesId = salesIdRaw is int 
        ? salesIdRaw 
        : int.tryParse(salesIdRaw.toString());
    final isSelected = currentSalesId == _selectedSalesId;
    
    final amountRaw = bill['Amount'];
    final amount = (amountRaw is int || amountRaw is double)
        ? (amountRaw as num).toDouble() 
        : double.tryParse(amountRaw.toString()) ?? 0.0;
    
    final billTime = bill['BillTime']?.toString() ?? '';
    final timeStr = _formatTime(billTime);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectBill(bill),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.04) : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
              left: BorderSide(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  bill['BillNo']?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? primaryColor : Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  bill['PaymentMode']?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  amount.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? primaryColor : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernItemRow(Map<String, dynamic> item, int index) {
    final qtyRaw = item['Qty'];
    final qty = (qtyRaw is int || qtyRaw is double)
        ? qtyRaw 
        : (double.tryParse(qtyRaw.toString()) ?? 0);
    
    final priceRaw = item['UnitPrice'];
    final price = (priceRaw is int || priceRaw is double)
        ? (priceRaw as num).toDouble() 
        : (double.tryParse(priceRaw.toString()) ?? 0.0);
    
    final totalRaw = item['LineTotal'];
    final total = (totalRaw is int || totalRaw is double)
        ? (totalRaw as num).toDouble() 
        : (double.tryParse(totalRaw.toString()) ?? 0.0);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              item['ShortDescription']?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              qty.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              price.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              total.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(String text, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildModernButton(String label, IconData icon, VoidCallback? onPressed,
      {bool isPrimary = false, bool isOutlined = false}) {
    final isEnabled = onPressed != null;
    
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? (isPrimary ? primaryColor : (isOutlined ? Colors.white : Colors.grey[100]))
              : Colors.grey[200],
          foregroundColor: isEnabled
              ? (isPrimary ? Colors.white : (isOutlined ? primaryColor : Colors.black87))
              : Colors.grey[400],
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isOutlined && isEnabled
                ? BorderSide(color: Colors.grey[300]!, width: 1.5)
                : BorderSide.none,
          ),
          elevation: isPrimary && isEnabled ? 2 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            '${_items.length} Items',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 20,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(width: 16),
          Text(
            _formatAmount(_selectedBillDetails!['Amount']),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return dateTimeStr.length > 10 ? dateTimeStr.substring(11, 16) : '-';
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    final value = (amount is int || amount is double) 
        ? (amount as num).toDouble() 
        : double.tryParse(amount.toString()) ?? 0.0;
    return value.toStringAsFixed(2);
  }
}
