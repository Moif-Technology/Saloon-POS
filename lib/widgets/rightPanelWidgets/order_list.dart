import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/services/api_service.dart';

const _accent = Color(0xFF780829);

/// Formats job date/time like `10-01-2026 07:10 AM`.
String formatJobDateTime(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '—';
  try {
    final dateTime = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
  } catch (_) {
    return isoDate;
  }
}

String formatMoney(num value) {
  return NumberFormat('#,##0.00').format(value);
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Opens Job List as a centered popup dialog.
Future<void> showJobListDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      child: OrderList(),
    ),
  );
}

/// Open jobs list — filterable popup table with Invoice to load into the grid.
class OrderList extends ConsumerStatefulWidget {
  const OrderList({super.key});

  @override
  ConsumerState<OrderList> createState() => _OrderListState();
}

class _OrderListState extends ConsumerState<OrderList> {
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  String? _loadingInvoiceId;
  String? _error;
  Timer? _debounce;

  final _searchCtrl = TextEditingController();

  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Column widths tuned for popup layout
  static const double _wJobNo = 100;
  static const double _wDate = 148;
  static const double _wMobile = 110;
  static const double _wChair = 80;
  static const double _wAmount = 96;
  static const double _wStatus = 80;
  static const double _wInvoice = 96;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = _searchCtrl.text.trim();
      final fetched = await ApiService().fetchOrderList(
        search: q.isEmpty ? null : q,
        dateFrom: _dateFrom != null ? _ymd(_dateFrom!) : null,
        dateTo: _dateTo != null ? _ymd(_dateTo!) : null,
      );
      if (!mounted) return;
      setState(() {
        _jobs = fetched;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _scheduleSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadJobs);
  }

  void _clearFilters() {
    _debounce?.cancel();
    setState(() {
      _searchCtrl.clear();
      _dateFrom = null;
      _dateTo = null;
    });
    _loadJobs();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_dateFrom ?? DateTime.now())
        : (_dateTo ?? _dateFrom ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
        if (_dateTo != null && _dateTo!.isBefore(picked)) {
          _dateTo = picked;
        }
      } else {
        _dateTo = picked;
        if (_dateFrom != null && _dateFrom!.isAfter(picked)) {
          _dateFrom = picked;
        }
      }
    });
    _loadJobs();
  }

  String _jobIdOf(Map<String, dynamic> job) {
    return (job['JobID'] ??
            job['jobId'] ??
            job['kotMasterID'] ??
            job['kotMasterId'] ??
            job['KotMasterID'] ??
            '')
        .toString();
  }

  String _jobNoOf(Map<String, dynamic> job) {
    final direct = (job['JobNo'] ?? job['jobNo'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final combined =
        '${job['KotPrefix'] ?? ''}${job['KotNumber'] ?? job['kotNumber'] ?? ''}'
            .trim();
    return combined.isEmpty ? '—' : combined;
  }

  String _mobileOf(Map<String, dynamic> job) {
    final m = (job['MobileNo'] ?? job['mobileNo'] ?? job['telephone'] ?? '')
        .toString()
        .trim();
    return m.isEmpty ? '—' : m;
  }

  double _amountOf(Map<String, dynamic> job) {
    final raw = job['Amount'] ?? job['amount'] ?? job['totalAmount'] ?? 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  double get _totalAmount =>
      _jobs.fold<double>(0, (sum, j) => sum + _amountOf(j));

  Future<void> _loadInvoice(Map<String, dynamic> job) async {
    final id = _jobIdOf(job);
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid job id')),
      );
      return;
    }

    // Capture before pop — OrderList is disposed when the dialog closes,
    // so using widget `ref` in a delayed callback hangs / throws.
    final container = ProviderScope.containerOf(context);
    final navigator = Navigator.of(context);

    setState(() => _loadingInvoiceId = id);
    try {
      final details = await ApiService()
          .fetchKotDetails(id)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;

      final data = details['data'];
      if (data is! List || data.isEmpty) {
        setState(() => _loadingInvoiceId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This job has no items')),
        );
        return;
      }

      // Close popup first, then load into the main grid on the next frame.
      navigator.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container.read(isUpdatingFromOrderListProvider.notifier).state = true;
        container.read(kotDetailsProvider.notifier).state =
            Map<String, dynamic>.from(details);
        container.read(activeKotProvider.notifier).state =
            Map<String, dynamic>.from(details);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingInvoiceId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load job: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = (size.width * 0.90).clamp(780.0, 1180.0);
    final height = (size.height * 0.82).clamp(460.0, 760.0);

    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _accent,
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Job List',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadJobs,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  InputDecoration _filterDeco(String label, {Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF7F5F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    );
  }

  Widget _dateChip({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final text = value == null ? label : DateFormat('dd-MM-yyyy').format(value);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: _accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      value == null ? FontWeight.w500 : FontWeight.w600,
                  color: value == null ? Colors.black54 : Colors.black87,
                ),
              ),
            ),
            if (value != null)
              InkWell(
                onTap: onClear,
                child: const Icon(Icons.clear, size: 16, color: Colors.black45),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _scheduleSearch(),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadJobs(),
              decoration: _filterDeco(
                'Search job no, customer, mobile…',
                prefix: const Icon(Icons.search, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dateChip(
              label: 'From Date',
              value: _dateFrom,
              onTap: () => _pickDate(isFrom: true),
              onClear: () {
                setState(() => _dateFrom = null);
                _loadJobs();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dateChip(
              label: 'To Date',
              value: _dateTo,
              onTap: () => _pickDate(isFrom: false),
              onClear: () {
                setState(() => _dateTo = null);
                _loadJobs();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _loadJobs,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: _loading ? null : _clearFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadJobs,
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    if (_jobs.isEmpty) {
      return const Center(
        child: Text('No jobs found for the selected filters',
            style: TextStyle(fontSize: 15, color: Colors.black54)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          _buildColHeader(),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _jobs.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) => _buildRow(_jobs[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColHeader() {
    return Container(
      color: _accent.withValues(alpha: 0.07),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          _fixed('Job No', _wJobNo, bold: true),
          _fixed('Job Date', _wDate, bold: true),
          _flex('Customer', 3, bold: true),
          _fixed('Mobile', _wMobile, bold: true),
          _fixed('Chair', _wChair, bold: true),
          _flex('Stylist', 2, bold: true),
          _fixed('Amount', _wAmount, bold: true, align: TextAlign.right),
          _fixed('Status', _wStatus, bold: true, align: TextAlign.center),
          SizedBox(
            width: _wInvoice,
            child: Text(
              'Invoice',
              textAlign: TextAlign.center,
              style: _headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> job, int index) {
    final amount = _amountOf(job);
    final customer =
        (job['CustomerName'] ?? job['customerName'] ?? 'Walk-in').toString();
    final chair = (job['ChairName'] ??
            job['chairName'] ??
            job['TableName'] ??
            job['ChairID'] ??
            '—')
        .toString();
    final stylist = (job['PrimaryStylistName'] ??
            job['primaryStylistName'] ??
            job['staffName'] ??
            '—')
        .toString();
    final status = (job['JobStatus'] ?? job['status'] ?? 'OPEN').toString();
    final dateText = formatJobDateTime(
        (job['StartTime'] ?? job['KotTime'] ?? job['createdAt'])?.toString());

    return Container(
      color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _fixed(_jobNoOf(job), _wJobNo, weight: FontWeight.w700),
          _fixed(dateText, _wDate),
          _flex(customer, 3),
          _fixed(_mobileOf(job), _wMobile),
          _fixed(chair, _wChair),
          _flex(stylist, 2),
          _fixed(formatMoney(amount), _wAmount,
              align: TextAlign.right, weight: FontWeight.w600),
          _fixed(status, _wStatus, align: TextAlign.center),
          SizedBox(
            width: _wInvoice,
            child: Center(
              child: _loadingInvoiceId == _jobIdOf(job)
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _accent,
                      ),
                    )
                  : TextButton(
                      onPressed: _loadingInvoiceId != null
                          ? null
                          : () => _loadInvoice(job),
                      style: TextButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _accent.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        minimumSize: const Size(0, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Invoice',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F6),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text(
            '${_jobs.length} job${_jobs.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const Spacer(),
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMoney(_loading ? 0 : _totalAmount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _accent,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Close',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 12,
    color: Color(0xFF521C1D),
  );

  Widget _fixed(
    String text,
    double width, {
    bool bold = false,
    FontWeight? weight,
    TextAlign align = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: bold ? 12 : 13,
          fontWeight: weight ?? (bold ? FontWeight.w700 : FontWeight.w500),
          color: bold ? const Color(0xFF521C1D) : Colors.black87,
        ),
      ),
    );
  }

  Widget _flex(
    String text,
    int flex, {
    bool bold = false,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          text,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: bold ? 12 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? const Color(0xFF521C1D) : Colors.black87,
          ),
        ),
      ),
    );
  }
}
