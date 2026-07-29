import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Salon POS device enrollment + PIN login.
///
/// Mirrors the Counter-POS flow:
///   1. [fetchStations]  admin credentials -> the company's SALON_POS tills
///   2. [enrollDevice]   admin credentials + stationId -> pairs this device
///   3. [fetchStaff]     deviceToken -> staff picker (names are NOT public)
///   4. [pinLogin]       deviceToken + staffPk + pin -> POS-scoped token
///
/// The device token is generated once per install and persisted. The backend
/// stores it in core.pos_device_enrollment and derives company + station from
/// it, so the till never has to be told which company it belongs to.
class SalonDeviceService {
  SalonDeviceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _kDeviceToken = 'salon_device_token';
  static const _kCompanyId = 'salon_company_id';
  static const _kStationId = 'salon_station_id';
  static const _kStationName = 'salon_station_name';

  static const _base = '$baseURL/api/salon-pos';
  static const _timeout = Duration(seconds: 20);

  // ── device token ─────────────────────────────────────────────────────────

  /// Stable per-install identifier. Created on first call, reused forever after.
  static Future<String> deviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kDeviceToken);
    if (existing != null && existing.isNotEmpty) return existing;

    // Random.secure() so a token cannot be guessed from another device's.
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    final token = 'salon-${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

    await prefs.setString(_kDeviceToken, token);
    return token;
  }

  /// True once this device has been paired to a station.
  static Future<bool> isEnrolled() async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt(_kCompanyId);
    final token = prefs.getString(_kDeviceToken);
    return companyId != null && token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> enrollment() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'deviceToken': prefs.getString(_kDeviceToken),
      'companyId': prefs.getInt(_kCompanyId),
      'stationId': prefs.getInt(_kStationId),
      'stationName': prefs.getString(_kStationName),
    };
  }

  /// Unpair. The device token itself is kept so re-enrolling reuses the same
  /// row rather than orphaning the old one.
  static Future<void> clearEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCompanyId);
    await prefs.remove(_kStationId);
    await prefs.remove(_kStationName);
  }

  // ── http ─────────────────────────────────────────────────────────────────

  /// Every salon auth endpoint answers `{ ok, code, message }` on failure, so
  /// one decoder covers them all. Throws [SalonApiException] with the server's
  /// own message — those messages are written to be shown to staff.
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    late http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$_base$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } catch (e) {
      throw SalonApiException(
        'Cannot reach the server at $baseURL.\n'
        'Check the network and that the API is running.',
        code: 'NETWORK',
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw SalonApiException(
        'Server returned an unexpected response (HTTP ${res.statusCode}).',
        code: 'BAD_RESPONSE',
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

    throw SalonApiException(
      (decoded['message'] ?? 'Request failed (HTTP ${res.statusCode})').toString(),
      code: decoded['code']?.toString(),
      statusCode: res.statusCode,
    );
  }

  // ── flow ─────────────────────────────────────────────────────────────────

  /// Step 1 — verify admin credentials, list this company's SALON_POS stations.
  Future<List<SalonStation>> fetchStations({
    required String username,
    required String password,
  }) async {
    final data = await _post('/device/stations', {
      'adminUsername': username,
      'adminPassword': password,
    });
    final list = (data['stations'] as List?) ?? const [];
    return list
        .map((e) => SalonStation.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Step 2 — pair this device to [stationId] and remember the result.
  Future<Map<String, dynamic>> enrollDevice({
    required String username,
    required String password,
    required int stationId,
    String? label,
  }) async {
    final token = await deviceToken();
    final data = await _post('/device/enroll', {
      'adminUsername': username,
      'adminPassword': password,
      'deviceToken': token,
      'stationId': stationId,
      if (label != null && label.isNotEmpty) 'label': label,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCompanyId, (data['companyId'] as num).toInt());
    await prefs.setInt(_kStationId, (data['stationId'] as num).toInt());
    await prefs.setString(_kStationName, (data['stationName'] ?? '').toString());
    return data;
  }

  /// Step 3 — staff picker for this device. Only staff who have a PIN.
  Future<List<SalonStaff>> fetchStaff() async {
    final token = await deviceToken();
    final data = await _post('/staff-list', {'deviceToken': token});

    // The server may have been re-pointed at another company; keep local state
    // in step with what it says rather than trusting the cached value.
    final prefs = await SharedPreferences.getInstance();
    if (data['companyId'] != null) {
      await prefs.setInt(_kCompanyId, (data['companyId'] as num).toInt());
    }
    if (data['stationId'] != null) {
      await prefs.setInt(_kStationId, (data['stationId'] as num).toInt());
    }

    final list = (data['staff'] as List?) ?? const [];
    return list
        .map((e) => SalonStaff.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Step 4 — verify one staff member's PIN. Returns the session payload.
  Future<Map<String, dynamic>> pinLogin({
    required int staffPk,
    required String pin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await deviceToken();
    final companyId = prefs.getInt(_kCompanyId);

    if (companyId == null) {
      throw SalonApiException(
        'This device is not enrolled yet.',
        code: 'NOT_ENROLLED',
      );
    }

    return _post('/pin-login', {
      'deviceToken': token,
      'companyId': companyId,
      'staffId': staffPk, // the picker's staffPk = core.staff_master.id
      'pin': pin,
    });
  }
}

/// Carries the server's own error text and machine-readable code so the UI can
/// branch (e.g. NOT_ENROLLED sends the user back to the enroll screen).
class SalonApiException implements Exception {
  SalonApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class SalonStation {
  const SalonStation({
    required this.stationId,
    required this.stationName,
    this.stationCode,
    this.branchName,
    this.counterNo,
  });

  final int stationId;
  final String stationName;
  final String? stationCode;
  final String? branchName;
  final int? counterNo;

  factory SalonStation.fromJson(Map<String, dynamic> j) => SalonStation(
        stationId: (j['stationId'] as num).toInt(),
        stationName: (j['stationName'] ?? '').toString(),
        stationCode: j['stationCode']?.toString(),
        branchName: j['branchName']?.toString(),
        counterNo: j['counterNo'] == null ? null : (j['counterNo'] as num).toInt(),
      );
}

class SalonStaff {
  const SalonStaff({
    required this.staffPk,
    required this.staffId,
    required this.staffName,
    this.staffCode,
    this.roleName,
  });

  /// core.staff_master.id — what /pin-login expects as `staffId`.
  final int staffPk;

  /// The business staff id, shown in the UI where a human-facing number is wanted.
  final int staffId;
  final String staffName;
  final String? staffCode;
  final String? roleName;

  /// Up to two initials for the avatar tile.
  String get initials {
    final parts = staffName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory SalonStaff.fromJson(Map<String, dynamic> j) => SalonStaff(
        staffPk: (j['staffPk'] as num).toInt(),
        staffId: (j['staffId'] as num?)?.toInt() ?? 0,
        staffName: (j['staffName'] ?? '').toString(),
        staffCode: j['staffCode']?.toString(),
        roleName: j['roleName']?.toString(),
      );
}
