/// Response model for app update check API.
/// Matches backend response shape; extensible for future subscription fields.
class AppUpdateResponse {
  final bool success;
  final bool updateAvailable;
  final bool blockApp;
  final String reason;
  final String? latestVersion;
  final String? minimumSupportedVersion;
  final String updateMode;
  final bool isMandatory;
  final bool isOptional;
  final String? title;
  final String? message;
  final String? changelog;
  final String? updateUrl;
  final String? releaseDate;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final String? currentVersion;
  final int? buildNumber;

  const AppUpdateResponse({
    required this.success,
    required this.updateAvailable,
    required this.blockApp,
    required this.reason,
    this.latestVersion,
    this.minimumSupportedVersion,
    this.updateMode = 'none',
    this.isMandatory = false,
    this.isOptional = false,
    this.title,
    this.message,
    this.changelog,
    this.updateUrl,
    this.releaseDate,
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.currentVersion,
    this.buildNumber,
  });

  factory AppUpdateResponse.fromJson(Map<String, dynamic> json) {
    return AppUpdateResponse(
      success: json['success'] as bool? ?? false,
      updateAvailable: json['update_available'] as bool? ?? false,
      blockApp: json['block_app'] as bool? ?? false,
      reason: (json['reason'] as String?) ?? 'unknown',
      latestVersion: json['latest_version'] as String?,
      minimumSupportedVersion: json['minimum_supported_version'] as String?,
      updateMode: (json['update_mode'] as String?) ?? 'none',
      isMandatory: json['is_mandatory'] as bool? ?? false,
      isOptional: json['is_optional'] as bool? ?? false,
      title: json['title'] as String?,
      message: json['message'] as String?,
      changelog: json['changelog'] as String?,
      updateUrl: json['update_url'] as String?,
      releaseDate: json['release_date'] as String?,
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      maintenanceMessage: json['maintenance_message'] as String?,
      currentVersion: json['current_version'] as String?,
      buildNumber: json['build_number'] != null
          ? (json['build_number'] is int
              ? json['build_number'] as int
              : int.tryParse(json['build_number'].toString()))
          : null,
    );
  }

  /// App should block usage (maintenance or mandatory update).
  bool get shouldBlock => blockApp;

  /// Optional update available; user can choose "Later".
  bool get canDefer => isOptional && !blockApp;

  /// No update and not blocked.
  bool get upToDate => !updateAvailable && !blockApp;
}
