import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'parameterProviders.dart';

/// ✅ **FutureProvider to Fetch Counter Close Details**
/// Accepts: reportType (or staffId when used from admin)
final counterCloseProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, staffIdOrReportType) async {
  final startTime = ref.watch(StartTimeProvider);
  final endTime = ref.watch(EndTimeProvider);

  if (startTime == null || endTime == null) {
    throw Exception("Start time or End time is missing.");
  }

  // ✅ If input is a number → treat as staffId, else treat as reportType
  final isStaffId = int.tryParse(staffIdOrReportType) != null;

  return <String, dynamic>{};
});
