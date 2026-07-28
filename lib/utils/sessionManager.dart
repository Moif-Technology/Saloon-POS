class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  String? stationId;
  String? staffName;
  String? staffID;
  /// Moifone unified API JWT (Bearer) for `/api/pos/*` and future migrated routes.
  String? accessToken;
  String? refreshToken;
  Map<String, dynamic>? subscription;
  Map<String, dynamic>? features;
  Map<String, dynamic>? limits;
  List<dynamic>? permissions;

  // Set session data
  void setSession({
    required String stationId,
    required String staffName,
    required String staffID,
    String? accessToken,
    String? refreshToken,
    Map<String, dynamic>? subscription,
    Map<String, dynamic>? features,
    Map<String, dynamic>? limits,
    List<dynamic>? permissions,
  }) {
    this.stationId = stationId;
    this.staffName = staffName;
    this.staffID = staffID;
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.subscription = subscription;
    this.features = features;
    this.limits = limits;
    this.permissions = permissions;
  }

  // Clear session data
  void clearSession() {
    stationId = null;
    staffName = null;
    staffID = null;
    accessToken = null;
    refreshToken = null;
    subscription = null;
    features = null;
    limits = null;
    permissions = null;
  }
}
