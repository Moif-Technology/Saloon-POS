import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/api_service_provider.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/utils/sessionManager.dart';

/// Fetches Parameters and Privileges when session is restored at app start.
/// Skips fetching if data is already loaded (e.g. after login).
/// Treats empty/whitespace session as no session so new device goes to login.
final sessionBootstrapProvider =
    FutureProvider<SessionBootstrapData?>((ref) async {
  final session = SessionManager();
  final stationId = session.stationId?.trim() ?? '';
  final staffName = session.staffName?.trim() ?? '';
  final staffID = session.staffID?.trim() ?? '';
  if (stationId.isEmpty || staffName.isEmpty || staffID.isEmpty) {
    return null;
  }

  // Already bootstrapped? (e.g. came from login)
  final currencyPrecession = ref.read(currencyPrecessionProvider);
  if (currencyPrecession != null) {
    return null;
  }

  final apiService = ref.read(apiServiceProvider);
  const timeout = Duration(seconds: 20);

  final parametersResponse = await apiService.fetchParameters().timeout(
        timeout,
        onTimeout: () => throw Exception(
            'Connection timed out. Check network and try again.'),
      );
  final privilegesResponse = await apiService.fetchPrivileges().timeout(
        timeout,
        onTimeout: () => throw Exception(
            'Privilege load timed out. Check network and try again.'),
      );

  final tax1 = (parametersResponse['Tax1'] as num?)?.toDouble();
  final currencyPrecessionVal = parametersResponse['currencyPrecession'];
  final reportStartTime = parametersResponse['reportStartTime'];
  final reportEndTime = parametersResponse['reportEndTime'];
  final pendingKotCheck = parametersResponse['pendingKotCheck'] as int? ?? 0;
  final isWaiterMandatory =
      parametersResponse['ISWaiterMandotory'] as int? ?? 0;
  final clearAfterKotSave =
      parametersResponse['ClearAfterKOTSave'] as int? ?? 0;
  final saveKotOnSettlement =
      parametersResponse['SaveKOTonSettlement'] as int? ?? 0;

  if (tax1 != null &&
      currencyPrecessionVal != null &&
      reportStartTime != null &&
      reportEndTime != null) {
    debugPrint("Session bootstrap: Parameters fetched successfully.");
    return SessionBootstrapData(
      subscription: session.subscription,
      features: session.features ?? {},
      limits: session.limits ?? {},
      permissions: session.permissions ?? [],
      privileges: privilegesResponse,
      tax1: tax1,
      currencyPrecession: currencyPrecessionVal.toString(),
      reportStartTime: reportStartTime.toString(),
      reportEndTime: reportEndTime.toString(),
      pendingKotCheck: pendingKotCheck,
      isWaiterMandatory: isWaiterMandatory,
      clearAfterKotSave: clearAfterKotSave,
      saveKotOnSettlement: saveKotOnSettlement,
      companyDetails: {
        'heading1': (parametersResponse['heading1Counter'] as String?) ?? '',
        'heading2': (parametersResponse['heading2Counter'] as String?) ?? '',
        'heading3': (parametersResponse['heading3Counter'] as String?) ?? '',
        'heading4': (parametersResponse['heading4Counter'] as String?) ?? '',
        'heading5': (parametersResponse['heading5Counter'] as String?) ?? '',
        'footer1': (parametersResponse['heading6Counter'] as String?) ?? '',
        'footer2': (parametersResponse['heading7Counter'] as String?) ?? '',
        'taxRegNo': (parametersResponse['taxRegistrationNo'] as String?) ?? '',
      },
    );
  } else {
    debugPrint(
        "Session bootstrap: Parameters missing or null in the response.");
    throw Exception('Parameters missing or null in the response.');
  }
});

class SessionBootstrapData {
  final Map<String, dynamic>? subscription;
  final Map<String, dynamic> features;
  final Map<String, dynamic> limits;
  final List<dynamic> permissions;
  final List<Map<String, dynamic>> privileges;
  final double tax1;
  final String currencyPrecession;
  final String reportStartTime;
  final String reportEndTime;
  final int pendingKotCheck;
  final int isWaiterMandatory;
  final int clearAfterKotSave;
  final int saveKotOnSettlement;
  final Map<String, String> companyDetails;

  const SessionBootstrapData({
    required this.subscription,
    required this.features,
    required this.limits,
    required this.permissions,
    required this.privileges,
    required this.tax1,
    required this.currencyPrecession,
    required this.reportStartTime,
    required this.reportEndTime,
    required this.pendingKotCheck,
    required this.isWaiterMandatory,
    required this.clearAfterKotSave,
    required this.saveKotOnSettlement,
    required this.companyDetails,
  });
}
