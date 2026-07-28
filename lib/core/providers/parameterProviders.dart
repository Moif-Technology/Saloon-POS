import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to store Tax1 value
final tax1Provider = StateProvider<double?>((ref) => null);

// Provider to store Currency Precession
final currencyPrecessionProvider = StateProvider<String?>((ref) => null);

// Provider to store Report Start Time
final StartTimeProvider = StateProvider<String?>((ref) => null);

// Provider to store Report End Time
final EndTimeProvider = StateProvider<String?>((ref) => null);
final pendingKotCheckProvider = StateProvider<int>((ref) => 0);

final ISWaiterMandotoryProvider = StateProvider<int>((ref) => 0);

final ClearAfterKOTSaveProvider = StateProvider<int>((ref) => 0);

final SaveKOTonSettlementProvider = StateProvider<int>((ref) => 0);

final privilegesProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

final subscriptionProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

final featuresProvider =
    StateProvider<Map<String, dynamic>>((ref) => {});

final limitsProvider =
    StateProvider<Map<String, dynamic>>((ref) => {});

final permissionsProvider =
    StateProvider<List<dynamic>>((ref) => []);

// Company details (Control Panel > Company Details tab)
final companyDetailsProvider = StateProvider<Map<String, String>>((ref) => {
      'heading1': '',
      'heading2': '',
      'heading3': '',
      'heading4': '',
      'heading5': '',
      'footer1': '',
      'footer2': '',
      'taxRegNo': '',
    });
