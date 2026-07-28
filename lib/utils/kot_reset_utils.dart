import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/providers.dart';

/// Clears all KOT-related providers for a fresh New KOT.
/// Call from New KOT button (after confirm) and after Save KOT success.
void clearKotStateForNewOrder(ProviderContainer container) {
  container.read(kotDetailsProvider.notifier).state = {};
  container.read(activeKotProvider.notifier).state = {};
  container.read(returnBillProvider.notifier).state = {};
  container.read(isUpdatingFromOrderListProvider.notifier).state = false;
  container.read(returnModeProvider.notifier).state = false;
  container.read(selectedQtyProvider.notifier).state = "1";
  container.read(selectedCustomerNameProvider.notifier).state = null;
  container.read(selectedCustomerIdProvider.notifier).state = null;
  container.read(cartSnapshotProvider.notifier).state = const [];
  container.read(selectedAreaIdProvider.notifier).state = null;
  container.read(selectedAreaNameProvider.notifier).state = null;
  container.read(selectedTableIdProvider.notifier).state = null;
  container.read(selectedSeatNoProvider.notifier).state = null;
  container.read(selectedGroupIdProvider.notifier).state = null;
}
