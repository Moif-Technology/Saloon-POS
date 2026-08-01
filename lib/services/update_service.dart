import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_app/config/api_config.dart';
import 'package:my_app/core/update/models/app_update_response.dart';

import 'package:my_app/core/update/update_platform_io.dart'
    if (dart.library.html) 'package:my_app/core/update/update_platform_stub.dart'
    as platform;

/// Current platform for update check: windows | android | web.
String get currentUpdatePlatform => platform.currentUpdatePlatform;

/// Service to call the app update check API.
/// No session required; used at startup before login.
/// TODO: When adding subscription logic, this service can call an additional
/// subscription status endpoint; keep update check independent for POS-safe flow.
class UpdateService {
  final String baseUrl = baseURL;

  Future<AppUpdateResponse> checkUpdate({
    required String currentVersion,
    int? buildNumber,
    String? platformOverride,
  }) async {
    final mocked = _mockUpdateResponse(currentVersion, buildNumber);
    if (mocked != null) return mocked;

    if (useMockData) {
      return const AppUpdateResponse(
        success: true,
        updateAvailable: false,
        blockApp: false,
        reason: 'mock',
      );
    }

    final platformName = platformOverride ?? currentUpdatePlatform;
    final uri = Uri.parse('$baseUrl/api/app/check-update');
    final body = jsonEncode({
      'platform': platformName,
      'current_version': currentVersion,
      if (buildNumber != null) 'build_number': buildNumber,
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Update check timed out'),
        );

    if (response.statusCode != 200) {
      throw Exception('Update check failed: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUpdateResponse.fromJson(decoded);
  }

  AppUpdateResponse? _mockUpdateResponse(
      String currentVersion, int? buildNumber) {
    switch (mockUpdateMode.trim().toLowerCase()) {
      case 'optional':
        return AppUpdateResponse(
          success: true,
          updateAvailable: true,
          blockApp: false,
          reason: 'mock_optional_update',
          latestVersion: '9.9.9',
          updateMode: 'optional',
          isOptional: true,
          title: 'New update available',
          message: 'Test update is ready. Use Download or Later to confirm UI.',
          updateUrl: 'https://example.com/salonpos-update',
          currentVersion: currentVersion,
          buildNumber: buildNumber,
        );
      case 'mandatory':
        return AppUpdateResponse(
          success: true,
          updateAvailable: true,
          blockApp: true,
          reason: 'mock_mandatory_update',
          latestVersion: '9.9.9',
          minimumSupportedVersion: '9.9.9',
          updateMode: 'mandatory',
          isMandatory: true,
          title: 'Update required',
          message: 'This is a mandatory update test. POS should be blocked.',
          updateUrl: 'https://example.com/salonpos-update',
          currentVersion: currentVersion,
          buildNumber: buildNumber,
        );
      case 'maintenance':
        return const AppUpdateResponse(
          success: true,
          updateAvailable: false,
          blockApp: true,
          reason: 'mock_maintenance',
          maintenanceMode: true,
          maintenanceMessage:
              'Maintenance mode test. Retry when server is ready.',
        );
      case 'none':
        return AppUpdateResponse(
          success: true,
          updateAvailable: false,
          blockApp: false,
          reason: 'mock_no_update',
          currentVersion: currentVersion,
          buildNumber: buildNumber,
        );
      case '':
        return null;
      default:
        return null;
    }
  }
}
