import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  // Save basic session data
  static Future<void> saveSession(
    String stationId,
    String staffName,
    String staffID, {
    String? accessToken,
    String? refreshToken,
    Map<String, dynamic>? subscription,
    Map<String, dynamic>? features,
    Map<String, dynamic>? limits,
    List<dynamic>? permissions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stationId', stationId);
    await prefs.setString('staffName', staffName);
    await prefs.setString('staffID', staffID);
    if (accessToken != null) {
      await prefs.setString('accessToken', accessToken);
    } else {
      await prefs.remove('accessToken');
    }
    if (refreshToken != null) {
      await prefs.setString('refreshToken', refreshToken);
    } else {
      await prefs.remove('refreshToken');
    }
    if (subscription != null) {
      await prefs.setString('subscription', jsonEncode(subscription));
    } else {
      await prefs.remove('subscription');
    }
    if (features != null) {
      await prefs.setString('features', jsonEncode(features));
    } else {
      await prefs.remove('features');
    }
    if (limits != null) {
      await prefs.setString('limits', jsonEncode(limits));
    } else {
      await prefs.remove('limits');
    }
    if (permissions != null) {
      await prefs.setString('permissions', jsonEncode(permissions));
    } else {
      await prefs.remove('permissions');
    }
  }

  // Load session data
  static Future<Map<String, dynamic>> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'stationId': prefs.getString('stationId'),
      'staffName': prefs.getString('staffName'),
      'staffID': prefs.getString('staffID'),
      'accessToken': prefs.getString('accessToken'),
      'refreshToken': prefs.getString('refreshToken'),
      'subscription': _decodeMap(prefs.getString('subscription')),
      'features': _decodeMap(prefs.getString('features')),
      'limits': _decodeMap(prefs.getString('limits')),
      'permissions': _decodeList(prefs.getString('permissions')),
    };
  }

  // Clear all session data
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stationId');
    await prefs.remove('staffName');
    await prefs.remove('staffID');
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('subscription');
    await prefs.remove('features');
    await prefs.remove('limits');
    await prefs.remove('permissions');
  }

  static Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static List<dynamic>? _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? List<dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }
}
