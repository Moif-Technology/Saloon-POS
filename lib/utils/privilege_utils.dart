import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/parameterProviders.dart';

/// A control the server never mentions is NOT a denied control.
///
/// The privilege list only carries rows for controls an admin has explicitly
/// configured. Treating "absent" as denied meant a tenant that had never opened
/// the privilege screen got a POS with every optional control switched off.
/// Only an explicit `IsEnable: false` hides something now.
bool isControlEnabled(WidgetRef ref, String controlName) {
  final privileges = ref.watch(privilegesProvider);
  if (privileges.isEmpty) return true;
  final row = privileges.cast<dynamic>().firstWhere(
        (e) => e is Map && e['ControlName'] == controlName,
        orElse: () => null,
      );
  if (row == null) return true;
  return row['IsEnable'] != false;
}

/// Feature gate. Three distinct states, and only one of them hides UI:
///
///   * features not loaded yet  -> show (the session is still bootstrapping;
///                                 rendering an empty shell looks like a bug)
///   * code absent from the map -> show (the server does not publish this code
///                                 at all, so there is no entitlement to honour)
///   * code present and false   -> HIDE (a real, deliberate entitlement denial)
///
/// The middle case is why the salon till came up blank: 35 codes this UI checks
/// — every `pos.ui.*`, most `pos.kot.*`, `pos.order_list`, `pos.price_change` —
/// have no row in `core.feature_master`, so the old `features[code] == true`
/// evaluated false and blanked the group panel, the area strip, the cart price
/// columns and the Save Job button. Gate on what the server actually says.
bool hasPosFeature(WidgetRef ref, String featureCode) {
  final subscription = ref.watch(subscriptionProvider);
  if (subscription != null && subscription['isUsable'] == false) return false;
  final features = ref.watch(featuresProvider);
  if (features.isEmpty) return true;
  final value = features[featureCode];
  if (value == null) return true;
  return value == true;
}

bool hasAnyPosFeature(WidgetRef ref, List<String> featureCodes) {
  return featureCodes.any((featureCode) => hasPosFeature(ref, featureCode));
}

bool isBasePosUi(WidgetRef ref) {
  // The POS now uses one normal layout for every plan. Plans/features should
  // hide or show individual panels, buttons, and fields instead of swapping
  // the whole screen into a separate "basic" layout.
  return false;
}

bool hasParentOrChildPosFeature(
  WidgetRef ref,
  String parentFeatureCode,
  String childFeatureCode,
) {
  return hasPosFeature(ref, parentFeatureCode) &&
      hasPosFeature(ref, childFeatureCode);
}

bool hasPosPermission(WidgetRef ref, String permissionCode) {
  final subscription = ref.watch(subscriptionProvider);
  if (subscription != null && subscription['isUsable'] == false) return false;
  final permissions = ref.watch(permissionsProvider);
  if (permissions.isEmpty) return true;
  return permissions.contains(permissionCode);
}

bool isBillingOnly(WidgetRef ref) {
  if (!hasPosFeature(ref, 'pos.billing')) return false;
  return !hasPosFeature(ref, 'pos.tables') &&
      !hasPosFeature(ref, 'pos.areas') &&
      !hasPosFeature(ref, 'pos.kot');
}

bool isSubscriptionUsable(WidgetRef ref) {
  final subscription = ref.watch(subscriptionProvider);
  if (subscription == null) return true;
  return subscription['isUsable'] != false;
}

String subscriptionStatus(WidgetRef ref) {
  final subscription = ref.watch(subscriptionProvider);
  if (subscription == null) return 'unknown';
  return (subscription['status'] as String?) ?? 'unknown';
}
