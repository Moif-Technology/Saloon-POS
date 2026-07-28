import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage the list of products
final productProvider = StateProvider<List<dynamic>>((ref) => []);

// Provider to manage the loading state
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Provider to manage error messages
final errorProvider = StateProvider<String?>((ref) => null);

// Stores the report data globally
final reportDataProvider = StateProvider<List<dynamic>>((ref) => []);

// Add SubGroup Provider
final subcategoryProvider =
    StateProvider<List<Map<String, String>>>((ref) => []);

// Provider for storing selected quantity (default is "1")
final selectedQtyProvider = StateProvider<String>((ref) => '1');

// Provider to store KOT Details fetched from API
final kotDetailsProvider = StateProvider<Map<String, dynamic>>((ref) => {});

final isUpdatingFromOrderListProvider = StateProvider<bool>((ref) => false);

// New provider for complete KOT details and items
final activeKotProvider = StateProvider<Map<String, dynamic>>((ref) => {});

final selectedGroupIdProvider = StateProvider<int?>((ref) => null);

// Provider to store sales viewer print details (header and items)
final salesViewerPrintDataProvider =
    StateProvider<Map<String, dynamic>>((ref) => {});

final returnModeProvider = StateProvider<bool>((ref) => false);
final lastReturnModeProvider = StateProvider<bool>((ref) => false);

// Provider to store fetched Return Bill Details
final returnBillProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// Provider to store delivery KOTs
final deliveryKotsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);


// --- selections / context ---
final selectedAreaIdProvider    = StateProvider<String?>((ref) => null);
final selectedAreaNameProvider  = StateProvider<String?>((ref) => null);
final selectedTableIdProvider   = StateProvider<String?>((ref) => null);
final selectedSeatNoProvider    = StateProvider<String?>((ref) => null);

final selectedCustomerIdProvider   = StateProvider<String?>((ref) => null);
final selectedCustomerNameProvider = StateProvider<String?>((ref) => null);

// cart snapshot (LeftPanel publishes; RightPanel reads to save)
final cartSnapshotProvider = StateProvider<List<Map<String, String>>>(
  (ref) => const [],
);
