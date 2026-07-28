import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/widgets/topPanelWidgets/ReportTab/salesDetails.dart';
import 'package:my_app/utils/debouncer.dart';

class SalesViewerDialog extends ConsumerStatefulWidget {
  @override
  _SalesViewerDialogState createState() => _SalesViewerDialogState();
}

class _SalesViewerDialogState extends ConsumerState<SalesViewerDialog> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final Debouncer _debouncer =
      Debouncer(milliseconds: 300); // Debouncer for search

  List<Map<String, dynamic>> filteredProducts = [];
  String selectedFilter = 'Customer Name'; // Default dropdown filter option
  late Box<dynamic> _salesCacheBox; // Hive box for caching
  String? lastCacheKey; // To validate cached data

  final List<String> filterOptions = [
    'Customer Name',
    'Bill No',
    'Location',
    'Delivery Boy',
    'Payment Mode',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _salesCacheBox = await Hive.openBox('salesCache'); // Open Hive box once
      _fetchFilteredData(); // Fetch initial data
    });

    // Automatically set today's date
    String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    fromDateController.text = today;
    toDateController.text = today;
  }

  @override
  void dispose() {
    _debouncer.cancel();
    searchController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchFilteredData() async {
    final fromDate = fromDateController.text.trim();
    final toDate = toDateController.text.trim();
    final searchQuery = searchController.text.trim();
    final filterKey = _getFilterKey(selectedFilter);

    if (fromDate.isEmpty || toDate.isEmpty) {
      print("Please select both from and to dates.");
      return;
    }

    final reportStartTime = ref.read(StartTimeProvider);
    final reportEndTime = ref.read(EndTimeProvider);

    final fromDateTime = "$fromDate $reportStartTime";
    final toDateTime = "$toDate $reportEndTime";

    // Generate a cache key
    final cacheKey =
        "$fromDateTime|$toDateTime|$filterKey|$searchQuery".toLowerCase();

    try {
      // Use cached data if available and criteria haven't changed
      if (cacheKey == lastCacheKey && !await isCacheExpired(cacheKey)) {
        var cachedData = await getCachedSalesData(cacheKey);
      if (mounted) {
        setState(() {
          filteredProducts = cachedData;
        });
      }
        print("Loaded data from cache");
        return;
      }

      final response = <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          filteredProducts = response;
          lastCacheKey = cacheKey;
        });
      }

      // Cache the fetched data
      await cacheSalesData(cacheKey, response);
      print("Data fetched and cached successfully");
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  Future<void> cacheSalesData(
      String key, List<Map<String, dynamic>> salesData) async {
    try {
      await _salesCacheBox.put('salesData_$key', salesData);
      await _salesCacheBox.put(
          'cacheTimestamp_$key', DateTime.now().toIso8601String());
      print("Cache updated for key: $key");
    } catch (e) {
      print("Error caching data: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getCachedSalesData(String key) async {
    try {
      final cachedData = _salesCacheBox.get('salesData_$key', defaultValue: []);
      return List<Map<String, dynamic>>.from(cachedData ?? []);
    } catch (e) {
      print("Error fetching cached data: $e");
      return [];
    }
  }

  Future<bool> isCacheExpired(String key) async {
    try {
      final cacheTimestamp = _salesCacheBox.get('cacheTimestamp_$key');
      if (cacheTimestamp == null) return true;

      final cacheDate = DateTime.parse(cacheTimestamp);
      return DateTime.now().difference(cacheDate).inMinutes >
          10; // 10 mins expiry
    } catch (e) {
      print("Error checking cache expiry: $e");
      return true;
    }
  }

  String? _getFilterKey(String filter) {
    // Keys must match backend FILTER_MAP exactly (PascalCase)
    switch (filter) {
      case 'Customer Name':
        return 'CustomerName';
      case 'Bill No':
        return 'BillNo';
      case 'Location':
        return 'CounterNo';
      case 'Delivery Boy':
        return 'DeliveryBoyName';
      case 'Payment Mode':
        return 'PaymentMode';
      default:
        return null;
    }
  }

  void _onRowSelected(Map<String, dynamic> salesData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SalesDetailsDialog(
            salesData: salesData); // Pass the full sales data
      },
    );
  }

  double _parseMoney(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: MediaQuery.of(context).size.width * 1.02,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            Expanded(child: _buildTable()),
            _buildTotalsFooter(), // Footer with totals
            _buildFooterButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF521C1D), // Header background color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          "Sales Viewer",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white, // Header text color
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    _debouncer.run(() => _fetchFilteredData());
                  },
                  onSubmitted: (_) {
                    _debouncer.cancel(); // Cancel any pending debounced call
                    _fetchFilteredData(); // Search immediately on Enter
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedFilter,
                  decoration: InputDecoration(
                    labelText: "Filter By",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: filterOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value ?? 'Customer Name';
                      searchController.clear();
                      _fetchFilteredData();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildDateField("From Date", fromDateController),
                const SizedBox(height: 8),
                _buildDateField("To Date", toDateController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
        _fetchFilteredData(); // Fetch data when the date changes
      });
    }
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () => _selectDate(context, controller),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today, size: 16),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTableHeader(),
          ...filteredProducts.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> product = entry.value;
            return _buildTableRow(product, index + 1);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFF521C1D),
      child: Row(
        children: [
          _buildTableHeaderCell("SI No", flex: 1),
          _buildTableHeaderCell("Bill No", flex: 2),
          _buildTableHeaderCell("C. No", flex: 1),
          _buildTableHeaderCell("Bill Date", flex: 2),
          _buildTableHeaderCell("Bill Time", flex: 2),
          _buildTableHeaderCell("Payment Mode", flex: 2),
          _buildTableHeaderCell("Customer Name", flex: 2),
          _buildTableHeaderCell("Sales Man", flex: 2),
          _buildTableHeaderCell("Sub Total", flex: 2),
          _buildTableHeaderCell("Tax Amount", flex: 2),
          _buildTableHeaderCell("Amount", flex: 2),
          _buildTableHeaderCell("Counter Close Status", flex: 3),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> product, int siNo) {
    final currencyPrecession = ref.read(currencyPrecessionProvider);

    // Create a formatter with the precision
    final formatter = NumberFormat.currency(
      decimalDigits: currencyPrecession?.split('.')[1].length ?? 2,
      symbol: '', // Remove currency symbol
    );

    // Format monetary values - parse to double (API returns strings)
    final subTotal = product['SubTotalM'] != null
        ? formatter.format(_parseMoney(product['SubTotalM']))
        : '';
    final taxAmount = product['Tax1AmountM'] != null
        ? formatter.format(_parseMoney(product['Tax1AmountM']))
        : '';
    final amount = product['Amount'] != null
        ? formatter.format(_parseMoney(product['Amount']))
        : '';

    final billDate = product['BillDate'] != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(product['BillDate']))
        : '';

    final billTime = product['BillTime'] != null
        ? DateFormat('HH:mm:ss').format(DateTime.parse(product['BillTime']))
        : '';

    return GestureDetector(
      onTap: () => _onRowSelected(product), // Pass the full sales data
      onDoubleTap: () => _onRowSelected(product), // Pass the full sales data
      child: Row(
        children: [
          _buildTableCell(siNo.toString(), flex: 1), // SI No
          _buildTableCell(product['BillNo']?.toString() ?? '', flex: 2),
          _buildTableCell(product['CounterNo']?.toString() ?? '', flex: 1),
          _buildTableCell(billDate, flex: 2), // Use formatted BillDate
          _buildTableCell(billTime, flex: 2), // Use formatted BillTime
          _buildTableCell(product['PaymentMode']?.toString() ?? '', flex: 2),
          _buildTableCell(product['CustomerName']?.toString() ?? '', flex: 2),
          _buildTableCell(product['SalesManName']?.toString() ?? '', flex: 2),
          _buildTableCell(subTotal, flex: 2), // Formatted Sub Total
          _buildTableCell(taxAmount, flex: 2), // Formatted Tax Amount
          _buildTableCell(amount, flex: 2), // Formatted Amount
          _buildTableCell(
            product['CounterCloseStatus']?.toString() ?? '',
            flex: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        color: const Color(0xFF521C1D),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis, // Enable ellipsis
          maxLines: 1, // Restrict to a single line
        ),
      ),
    );
  }

  Widget _buildTotalsFooter() {
    // Calculate totals - parse to double (API returns strings)
    final subTotalSum = filteredProducts.fold<double>(
        0.0, (sum, product) => sum + _parseMoney(product['SubTotalM']));
    final taxAmountSum = filteredProducts.fold<double>(
        0.0, (sum, product) => sum + _parseMoney(product['Tax1AmountM']));
    final amountSum = filteredProducts.fold<double>(
        0.0, (sum, product) => sum + _parseMoney(product['Amount']));

    // Access currency precision from provider
    final currencyPrecession = ref.read(currencyPrecessionProvider);

    // Create formatter
    final formatter = NumberFormat.currency(
      decimalDigits: currencyPrecession?.split('.')[1].length ?? 2,
      symbol: '', // No currency symbol
    );

    // Format totals
    final formattedSubTotal = formatter.format(subTotalSum);
    final formattedTaxAmount = formatter.format(taxAmountSum);
    final formattedAmount = formatter.format(amountSum);

    return Container(
      color: Colors.grey.shade200, // Background color for totals footer
      padding: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 1), // Adjust padding here
      child: Row(
        children: [
          // Spacer for alignment
          Spacer(flex: 14),

          // Totals aligned under monetary columns
          _buildFooterCell(formattedSubTotal,
              flex: 2, isBold: true), // Sub Total
          _buildFooterCell(formattedTaxAmount,
              flex: 2, isBold: true), // Tax Amount
          _buildFooterCell(formattedAmount, flex: 2, isBold: true), // Amount

          // Empty cell for Counter Close Status
          Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildFooterCell(String text, {int flex = 1, bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center, // Center alignment for totals
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox.shrink(), // Removes the button

          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Close", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
