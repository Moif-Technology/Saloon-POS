import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/parameterProviders.dart';

bool isControlEnabled(WidgetRef ref, String controlName) {
  final privileges = ref.watch(privilegesProvider);
  if (privileges.isEmpty) return false;
  return privileges
      .any((e) => e['ControlName'] == controlName && e['IsEnable'] == true);
}

bool hasPosFeature(WidgetRef ref, String featureCode) {
  final subscription = ref.watch(subscriptionProvider);
  if (subscription != null && subscription['isUsable'] == false) return false;
  final features = ref.watch(featuresProvider);
  if (features.isEmpty) return false;
  return features[featureCode] == true;
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
