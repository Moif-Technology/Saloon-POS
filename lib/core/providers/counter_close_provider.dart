import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/services/counter_close_mapper.dart';
import 'package:my_app/utils/sessionManager.dart';

/// Loads live counter summary for Counter Close UI / print.
/// Pass `admin` to include all cashiers' pending on this counter.
final counterCloseProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, staffIdOrReportType) async {
  final isAdmin = staffIdOrReportType.toLowerCase() == 'admin';
  final raw = await ApiService().fetchCounterSummary(allStaff: isAdmin);
  return mapCounterCloseForUi(raw, session: SessionManager());
});
