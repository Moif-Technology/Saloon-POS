import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:my_app/core/update/models/app_update_response.dart';
import 'package:my_app/services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// App version and build from package_info_plus (cached).
final appPackageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

/// Result of the startup update check. Run once when entering the update gate.
/// TODO: When adding subscription logic, you can add a separate subscriptionCheckProvider
/// and combine block_app from both update and subscription here.
final updateCheckResultProvider =
    FutureProvider.autoDispose<AppUpdateResponse>((ref) async {
  final pkg = await ref.watch(appPackageInfoProvider.future);
  final service = ref.read(updateServiceProvider);
  final version = pkg.version;
  final buildNumber = int.tryParse(pkg.buildNumber);
  return service.checkUpdate(
    currentVersion: version,
    buildNumber: buildNumber,
  );
});
