import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/services/api_service.dart';

String formatJobTime(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '—';
  try {
    final dateTime = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd-MM-yy hh:mm a').format(dateTime);
  } catch (_) {
    return isoDate;
  }
}

/// Open jobs list — searchable table with Invoice to load into the main grid.
class OrderList extends ConsumerStatefulWidget {
  @override
  _OrderListState createState() => _OrderListState();
}

class _OrderListState extends ConsumerState<OrderList> {
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _error;
  Timer? _debounce;
  final _searchCtrl = TextEditingController();

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
      final fetched = await ApiService().fetchOrderList(
        search: _searchQuery.isEmpty ? null : _searchQuery,
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = query.trim());
      _loadJobs();
    });
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

  Future<void> _loadInvoice(Map<String, dynamic> job) async {
    final id = _jobIdOf(job);
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid job id')),
      );
      return;
    }
    try {
      final details = await ApiService().fetchKotDetails(id);
      if (!mounted) return;
      final data = details['data'];
      if (data is! List || data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This job has no items')),
        );
        return;
      }
      ref.read(isUpdatingFromOrderListProvider.notifier).state = true;
      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 200), () {
        ref.read(kotDetailsProvider.notifier).state = details;
        ref.read(activeKotProvider.notifier).state = details;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load job: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF780829);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F6),
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        title: const Text('Job List'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadJobs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search job no, customer, chair, stylist…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: accent))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadJobs,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: accent),
                                child: const Text('Retry',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _jobs.isEmpty
                        ? const Center(child: Text('No open jobs found'))
                        : _buildTable(accent),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 1,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: const Row(
                children: [
                  _HCell('Job No', flex: 2),
                  _HCell('Time', flex: 2),
                  _HCell('Customer', flex: 2),
                  _HCell('Chair', flex: 1),
                  _HCell('Stylist', flex: 2),
                  _HCell('Amount', flex: 1, align: TextAlign.right),
                  _HCell('Status', flex: 1),
                  SizedBox(width: 100, child: Text('Invoice',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12))),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _jobs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final job = _jobs[index];
                  final amount = (job['Amount'] ??
                          job['amount'] ??
                          job['totalAmount'] ??
                          '0')
                      .toString();
                  final customer = (job['CustomerName'] ??
                          job['customerName'] ??
                          'Walk-in')
                      .toString();
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
                  final status =
                      (job['JobStatus'] ?? job['status'] ?? 'OPEN').toString();
                  final time = formatJobTime(
                      (job['StartTime'] ?? job['KotTime'] ?? job['createdAt'])
                          ?.toString());

                  return Container(
                    color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        _CCell(_jobNoOf(job), flex: 2, bold: true),
                        _CCell(time, flex: 2),
                        _CCell(customer, flex: 2),
                        _CCell(chair, flex: 1),
                        _CCell(stylist, flex: 2),
                        _CCell(amount, flex: 1, align: TextAlign.right),
                        _CCell(status, flex: 1),
                        SizedBox(
                          width: 100,
                          child: Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () => _loadInvoice(job),
                              style: TextButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Invoice',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  const _HCell(this.text, {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Color(0xFF521C1D),
        ),
      ),
    );
  }
}

class _CCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final TextAlign align;
  const _CCell(this.text,
      {this.flex = 1, this.bold = false, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
