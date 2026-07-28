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
}
