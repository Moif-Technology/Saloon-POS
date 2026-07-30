// lib/services/api_service.dart
//
// POS client for the Moifone Node API only: login, parameters, group list,
// area list, sub-group list. Branch = SessionManager.stationId; auth = JWT.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_app/services/mock_api_service.dart';
import 'package:my_app/utils/sessionManager.dart';

import '../config/api_config.dart';

class ApiService {
  factory ApiService() {
    if (useMockData) return MockApiService();
    return ApiService._();
  }

  ApiService._();

  static dynamic _decode(String? body) {
    if (body == null || body.trim().isEmpty) {
      throw const FormatException('Server returned an empty response.');
    }
    return jsonDecode(body);
  }

  Future<Map<String, String>> _headers() async {
    final stationId = SessionManager().stationId;
    final staffName = SessionManager().staffName;
    final staffID = SessionManager().staffID;
    if (stationId == null || staffName == null || staffID == null) {
      throw Exception('Missing session (stationId / staffName / staffID).');
    }
    final h = <String, String>{
      'Content-Type': 'application/json',
      'stationId': stationId,
      'staffName': staffName,
      'staffID': staffID,
    };
    final t = SessionManager().accessToken?.trim();
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  int _branchId() {
    final n = int.tryParse(SessionManager().stationId?.trim() ?? '');
    if (n == null || n < 1) throw Exception('Invalid branch (stationId).');
    return n;
  }

  Map<String, String> _bearerHeaders() {
    final t = SessionManager().accessToken?.trim();
    if (t == null || t.isEmpty) throw Exception('Not logged in.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $t',
    };
  }

  Future<Map<String, dynamic>> login(String login, String password) async {
    final response = await http.post(
      Uri.parse('$baseURL$posBasePath/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': login, 'password': password}),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(_decode(response.body) as Map);
    }
    dynamic err;
    try {
      err = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {}
    final msg = err is Map && err['message'] != null
        ? err['message'].toString()
        : response.body;
    throw Exception('Login failed: $msg');
  }

  Future<Map<String, dynamic>> pinLogin(String pin, int companyId,
      {int? staffPk}) async {
    final body = <String, dynamic>{'pin': pin, 'companyId': companyId};
    if (staffPk != null) body['staffId'] = staffPk;
    final response = await http.post(
      Uri.parse('$baseURL$posBasePath/pin-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(_decode(response.body) as Map);
    }
    dynamic err;
    try {
      err = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {}
    final msg = err is Map && err['message'] != null
        ? err['message'].toString()
        : response.body;
    throw Exception('PIN login failed: $msg');
  }

  Future<List<Map<String, dynamic>>> fetchPosStaffList(int companyId) async {
    final response = await http.post(
      Uri.parse('$baseURL$posBasePath/staff-list'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'companyId': companyId}),
    );
    if (response.statusCode == 200) {
      final data = _decode(response.body);
      if (data is Map && data['staff'] is List) {
        return (data['staff'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchCurrentSession() async {
    final response = await http.get(
      Uri.parse('$baseURL/api/auth/me'),
      headers: _bearerHeaders(),
    );
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to refresh session: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map || decoded['session'] is! Map) {
      throw const FormatException('session refresh: expected session object');
    }
    return Map<String, dynamic>.from(decoded['session'] as Map);
  }

  Future<Map<String, dynamic>> fetchParameters() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$baseURL$posBasePath/parameters'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch parameters: ${response.body}');
    }
    final decoded = _decode(response.body);
    if (decoded is Map && decoded['success'] == true) {
      return Map<String, dynamic>.from(decoded['data'] as Map);
    }
    throw Exception('Failed: ${decoded is Map ? decoded['message'] : decoded}');
  }

  Future<List<Map<String, dynamic>>> fetchPrivileges() async {
    final headers = _bearerHeaders();
    final response = await http.get(
      Uri.parse('$baseURL$posBasePath/privileges'),
      headers: headers,
    );
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load privileges: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map) throw FormatException('privileges: expected object');
    final list = decoded['privileges'];
    if (list is! List) return <Map<String, dynamic>>[];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> savePosParameters(Map<String, dynamic> params) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$baseURL$posBasePath/parameters'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(params),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save parameters: ${response.body}');
    }
    final decoded = _decode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to save parameters');
    }
  }

  Future<void> saveCompanyDetails({
    required String heading1,
    required String heading2,
    required String heading3,
    required String heading4,
    required String heading5,
    required String footer1,
    required String footer2,
    required String taxRegNo,
  }) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$baseURL$posBasePath/parameters/company-details'),
      headers: headers,
      body: jsonEncode({
        'heading1': heading1,
        'heading2': heading2,
        'heading3': heading3,
        'heading4': heading4,
        'heading5': heading5,
        'footer1': footer1,
        'footer2': footer2,
        'taxRegNo': taxRegNo,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save company details: ${response.body}');
    }
    final decoded = _decode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to save company details');
    }
  }

  /// Maps `/api/groups` row → keys used by POS widgets (`GroupID`, …).
  static Map<String, dynamic> groupRowForPos(dynamic raw) {
    if (raw is! Map) {
      return {'GroupID': '0', 'GroupDescription': '', 'KeyShift': ''};
    }
    final m = Map<String, dynamic>.from(raw);
    final gid = m['groupId'] ?? m['GroupID'] ?? 0;
    final desc =
        (m['groupDescription'] ?? m['GroupDescription'])?.toString().trim() ??
            '';
    final code = (m['groupCode'] ?? m['GroupCode'])?.toString().trim() ?? '';
    final display =
        desc.isNotEmpty ? desc : (code.isNotEmpty ? code : 'Group $gid');
    final keyShift = m['keyShift'] ?? m['KeyShift'];
    final keyCode = m['keyCode'] ?? m['KeyCode'];
    return {
      'GroupID': '$gid',
      'GroupDescription': display,
      'GroupDescriptionArabic':
          (m['groupDescriptionArabic'] ?? m['GroupDescriptionArabic'])
                  ?.toString() ??
              '',
      'KeyShift': keyShift == null ? '' : '$keyShift',
      'KeyCode': keyCode == null ? '' : '$keyCode',
    };
  }

  Future<List<dynamic>> fetchGroups() async {
    final headers = _bearerHeaders();
    final uri = Uri.parse('$baseURL/api/groups').replace(
      queryParameters: {'branchId': '${_branchId()}'},
    );
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load groups: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map) {
      throw FormatException('groups: expected object');
    }
    final list = decoded['groups'];
    if (list is! List) return [];
    return list.map((e) => groupRowForPos(e)).toList();
  }

  /// Maps `/api/areas` row → keys used by POS widgets (`AreaID`, …).
  static Map<String, dynamic> areaRowForPos(dynamic raw) {
    if (raw is! Map) {
      return {
        'AreaID': '0',
        'AreaName': '',
        'SupplyType': 'GENERAL',
        'AreaNameArabic': '',
      };
    }
    final m = Map<String, dynamic>.from(raw);
    final aid = m['areaId'] ?? m['AreaID'] ?? 0;
    final name = (m['areaName'] ?? m['AreaName'])?.toString() ?? '';
    final st = (m['supplyType'] ?? m['SupplyType'])?.toString() ?? 'GENERAL';
    final supplyLegacy = st.toUpperCase().trim().replaceAll('_', ' ');
    final arabic =
        (m['areaNameArabic'] ?? m['AreaNameArabic'])?.toString() ?? '';
    return {
      'AreaID': '$aid',
      'AreaName': name,
      'SupplyType': supplyLegacy,
      'AreaNameArabic': arabic,
      'KotPrefix': m['kotPrefix']?.toString() ?? '',
      'isTabletShow': m['isTabletShow'] ?? true,
      'TableCreationType': m['tableCreationType'] ?? 0,
    };
  }

  Future<List<dynamic>> fetchAreas({bool fetchAll = false}) async {
    final headers = _bearerHeaders();
    final uri = Uri.parse('$baseURL/api/areas').replace(
      queryParameters: {'branchId': '${_branchId()}'},
    );
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load areas: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map) throw FormatException('areas: expected object');
    final list = decoded['areas'];
    if (list is! List) return [];
    return list.map((e) => areaRowForPos(e)).toList();
  }

  /// Maps `/api/sub-groups` row → keys used by POS (`SubGroupID`, …).
  static Map<String, dynamic> subGroupRowForPos(dynamic raw) {
    if (raw is! Map) {
      return {'SubGroupID': '0', 'SubGroupDescription': '', 'GroupID': '0'};
    }
    final m = Map<String, dynamic>.from(raw);
    final sid = m['subGroupId'] ?? m['SubGroupID'] ?? 0;
    final gid = m['groupId'] ?? m['GroupID'] ?? 0;
    final desc = (m['subGroupDescription'] ?? m['SubGroupDescription'])
            ?.toString()
            .trim() ??
        '';
    final code =
        (m['subGroupCode'] ?? m['SubGroupCode'])?.toString().trim() ?? '';
    final display =
        desc.isNotEmpty ? desc : (code.isNotEmpty ? code : 'Sub $sid');
    return {
      'SubGroupID': '$sid',
      'SubGroupDescription': display,
      'SubGroupDescriptionArabic':
          (m['subGroupDescriptionArabic'] ?? m['SubGroupDescriptionArabic'])
                  ?.toString() ??
              '',
      'GroupID': '$gid',
      'SubGroupCode': code,
    };
  }

  /// Maps `/api/products` row → keys used by the POS product grid and cart.
  static Map<String, dynamic> productRowForPos(dynamic raw) {
    if (raw is! Map) {
      return {'ProductID': '0', 'ShortDescription': '', 'UnitPrice': '0'};
    }
    final m = Map<String, dynamic>.from(raw);
    final inv = m['inventory'] is Map
        ? Map<String, dynamic>.from(m['inventory'] as Map)
        : <String, dynamic>{};

    final pid = m['productId'] ?? m['ProductID'] ?? 0;
    final name =
        (m['productName'] ?? m['ProductName'])?.toString().trim() ?? '';
    final shortName =
        (m['shortName'] ?? m['ShortDescription'])?.toString().trim() ?? '';
    final display = shortName.isNotEmpty ? shortName : name;
    final unitPrice = inv['unitPrice'] ?? m['unitPrice'] ?? 0;
    final tax1Rate =
        inv['outputTax1Rate'] ?? m['tax1Rate'] ?? m['Tax1Rate'] ?? 0;
    final groupId = m['groupId'] ?? m['GroupID'] ?? 0;
    final subGroupId = m['subgroupId'] ?? m['SubGroupID'] ?? 0;
    final barcode = m['barcode']?.toString() ?? '';
    final unit = m['unitName']?.toString() ?? '';
    final packQty = inv['packQty'] ?? m['packQty'] ?? 1;

    // A salon line is either labour (SERVICE) or retail (PRODUCT). The backend
    // decides that from core.product_master.product_type, which is free-text
    // VARCHAR and holds mixed case across tenants ('Service', 'SERVICE',
    // 'Stock'), so compare case-insensitively rather than on an exact match.
    // Only SERVICE lines require a stylist, so getting this wrong means the
    // settlement is rejected with SERVICE_NEEDS_STYLIST.
    final productType =
        (m['productType'] ?? m['ProductType'])?.toString().trim() ?? '';
    final lineType =
        productType.toUpperCase() == 'SERVICE' ? 'SERVICE' : 'PRODUCT';

    return {
      'ProductID': '$pid',
      'ProductCode': (m['productCode'] ?? m['ProductCode'])?.toString() ?? '',
      'ShortDescription': display,
      'ProductName': name,
      'Barcode': barcode,
      'UnitPrice': '$unitPrice',
      'Tax1Rate': '$tax1Rate',
      'GroupID': '$groupId',
      'SubGroupID': '$subGroupId',
      'Unit': unit,
      'PackQty': '$packQty',
      'ProductType': productType,
      'LineType': lineType,
    };
  }

  /// Fetches products for the POS product grid.
  /// Pass [groupId] to filter by group, [subGroupId] to further filter by sub-group.
  Future<List<dynamic>> fetchProducts(
      {String? groupId, String? subGroupId}) async {
    final headers = _bearerHeaders();
    final qp = <String, String>{'branchId': '${_branchId()}'};
    if (groupId != null && groupId.isNotEmpty) qp['groupId'] = groupId;
    if (subGroupId != null && subGroupId.isNotEmpty)
      qp['subGroupId'] = subGroupId;
    final uri = Uri.parse('$baseURL/api/products').replace(queryParameters: qp);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode == 503 || response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load products: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map) throw FormatException('products: expected object');
    final list = decoded['products'];
    if (list is! List) return [];
    return list.map((e) => productRowForPos(e)).toList();
  }

  /// Maps `/api/tables` row → keys expected by [TableSelectionDialog] / [PosTableModel].
  static Map<String, dynamic> tableRowForPos(dynamic raw) {
    if (raw is! Map) {
      return {
        'TableID': '0',
        'TableName': 'T?',
        'TableNO': '0',
        'NoOfChairs': '4',
        'TableFormat': 'SQUARE'
      };
    }
    final m = Map<String, dynamic>.from(raw);
    final tid = m['tableId'] ?? m['TableID'] ?? 0;
    final tno = m['tableNo'] ?? m['TableNO'] ?? 0;
    final name = (m['tableName'] ?? m['TableName'] ?? 'T$tid').toString();
    final chairs = m['noOfChairs'] ?? m['NoOfChairs'] ?? 4;
    final format = (m['tableFormat'] ?? m['TableFormat'] ?? 'SQUARE')
        .toString()
        .toUpperCase();
    return {
      'TableID': '$tid',
      'TableName': name,
      'TableNO': '$tno',
      'NoOfChairs': '$chairs',
      'TableFormat': format,
      'AreaID': '${m['areaId'] ?? m['AreaID'] ?? 0}',
      'KOTPrefix': m['kotPrefix']?.toString() ?? '',
      'KOTNumber': '',
      'KOTStatus': '',
      'occupiedChairs': const <dynamic>[],
      'kotDetails': const <dynamic>[],
    };
  }

  /// Fetches tables for the POS floor dialog.
  /// Pass [areaId] to filter by a specific area; omit to get all tables for the branch.
  Future<List<dynamic>> fetchTables({String? areaId}) async {
    final headers = _bearerHeaders();
    final qp = <String, String>{'branchId': '${_branchId()}'};
    if (areaId != null && areaId.isNotEmpty) qp['areaId'] = areaId;
    final uri = Uri.parse('$baseURL/api/tables').replace(queryParameters: qp);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode == 503 || response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load tables: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map) throw FormatException('tables: expected object');
    final list = decoded['tables'];
    if (list is! List) return [];
    return list.map((e) => tableRowForPos(e)).toList();
  }

  /// Maps `/api/customers` row → legacy POS keys (`CustomerID`, …) and camelCase.
  static Map<String, dynamic> customerRowForPos(dynamic raw) {
    if (raw is! Map) {
      return {'CustomerID': '0', 'CustomerName': '', 'CustomerCode': ''};
    }
    final m = Map<String, dynamic>.from(raw);
    final cid = m['customerId'] ?? m['CustomerID'] ?? 0;
    final code =
        (m['customerCode'] ?? m['CustomerCode'])?.toString().trim() ?? '';
    final name =
        (m['customerName'] ?? m['CustomerName'])?.toString().trim() ?? '';
    final city =
        (m['cityName'] ?? m['City'] ?? m['city'])?.toString().trim() ?? '';
    final country =
        (m['countryName'] ?? m['Country'] ?? m['country'])?.toString().trim() ??
            '';
    final tel = (m['telephone'] ?? m['Telephone'])?.toString().trim() ?? '';
    final mobile = (m['mobileNo'] ?? m['MobileNo'])?.toString().trim() ?? '';
    final trn = (m['customerTaxRegNo'] ?? m['CustTRN'] ?? m['taxRegNo'])
            ?.toString()
            .trim() ??
        '';
    final loyalty = (m['loyaltyStatus'] ?? m['loyaltyCustStatus'])
            ?.toString()
            .trim()
            .toUpperCase() ??
        '';
    return {
      'CustomerID': '$cid',
      'customerId': cid,
      'CustomerCode': code,
      'customerCode': code,
      'CustomerName': name,
      'customerName': name,
      'companyName': (m['companyName'] ?? '').toString(),
      'CompanyName': (m['companyName'] ?? '').toString(),
      'City': city,
      'city': city,
      'Country': country,
      'country': country,
      'Telephone': tel,
      'telephone': tel,
      'MobileNo': mobile,
      'mobileNo': mobile,
      'CustTRN': trn,
      'taxRegNo': trn,
      'Address': (m['address'] ?? m['Address'])?.toString() ?? '',
      'address': (m['address'] ?? m['Address'])?.toString() ?? '',
      'addressArabic':
          (m['addressArabic'] ?? m['AddressArabic'])?.toString() ?? '',
      'poBox': (m['poBox'] ?? '').toString(),
      'contactPerson': (m['contactPerson'] ?? '').toString(),
      'designation': (m['designation'] ?? '').toString(),
      'faxNo': (m['fax'] ?? m['faxNo'] ?? '').toString(),
      'email': (m['email'] ?? '').toString(),
      'paymentMode': (m['paymentMode'] ?? m['PaymentMode'] ?? '').toString(),
      'creditLimit': (m['creditLimit'] ?? m['CreditLimit'] ?? '').toString(),
      'creditPeriodDays':
          (m['creditPeriod'] ?? m['creditPeriodDays'] ?? '').toString(),
      'creditBalance':
          (m['creditBalance'] ?? m['CreditBalance'] ?? '').toString(),
      'customerType': (m['customerType'] ?? '').toString(),
      'managedBy': (m['managedBy'] ?? '').toString(),
      'loyaltyCustStatus':
          (loyalty == 'ACTIVE' || loyalty == 'YES') ? 'Yes' : 'No',
      'creditStatus': (m['creditStatus'] ?? 'ACTIVE').toString(),
      'remarks': (m['remarks'] ?? '').toString(),
    };
  }

  /// Lists customers for the signed-in company (branch-independent master).
  Future<List<dynamic>> fetchCustomers(
      {int limit = 400, String? search}) async {
    final headers = _bearerHeaders();
    final cap = limit.clamp(1, 2000);
    final qp = <String, String>{'limit': '$cap'};
    final q = search?.trim() ?? '';
    if (q.isNotEmpty) qp['search'] = q;
    final uri =
        Uri.parse('$baseURL/api/customers').replace(queryParameters: qp);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode == 503 || response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load customers: ${response.body.isNotEmpty ? response.body : response.statusCode}',
      );
    }
    final decoded = _decode(response.body);
    if (decoded is! Map) throw FormatException('customers: expected object');
    final list = decoded['customers'];
    if (list is! List) return [];
    return list.map((e) => customerRowForPos(e)).toList();
  }

  /// POST `/api/customers` — ERP Customer Entry create payload.
  Future<Map<String, dynamic>> createCustomer(
      Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final response = await http.post(
      Uri.parse('$baseURL/api/customers'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Failed to create customer (${response.statusCode})';
    throw Exception(msg);
  }

  /// PUT `/api/customers/:customerId` — ERP Customer Entry update payload.
  Future<Map<String, dynamic>> updateCustomer(
      String customerId, Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final response = await http.put(
      Uri.parse(
          '$baseURL/api/customers/${Uri.encodeComponent(customerId)}'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode == 200 && decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Failed to update customer (${response.statusCode})';
    throw Exception(msg);
  }

  /// When [groupId] is set, only sub-groups for that parent are returned.
  Future<List<dynamic>> fetchSubGroups({String? groupId}) async {
    final headers = _bearerHeaders();
    final qp = <String, String>{'branchId': '${_branchId()}'};
    if (groupId != null && groupId.isNotEmpty) qp['groupId'] = groupId;
    final uri =
        Uri.parse('$baseURL/api/sub-groups').replace(queryParameters: qp);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode == 503 || response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load sub-groups: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map) throw FormatException('sub-groups: expected object');
    final list = decoded['subGroups'];
    if (list is! List) return [];
    return list.map((e) => subGroupRowForPos(e)).toList();
  }

  /// Returns staff for the signed-in company. Each row: `staffId`, `staffName`, `roleName`, `branchId`.
  Future<List<Map<String, dynamic>>> fetchStaff() async {
    final headers = _bearerHeaders();
    final response = await http.get(
      Uri.parse('$baseURL/api/staff/members'),
      headers: headers,
    );
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load staff: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map) throw const FormatException('staff: expected object');
    final list = decoded['staff'];
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createArea(Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final response = await http.post(
      Uri.parse('$baseURL/api/areas'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded is Map) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Failed to create area (${response.statusCode})';
    throw Exception(msg);
  }

  Future<Map<String, dynamic>> createTable(Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final response = await http.post(
      Uri.parse('$baseURL/api/tables'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded is Map) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Failed to create table (${response.statusCode})';
    throw Exception(msg);
  }

  /// Creates a product group for the current branch. [payload]: `branchId`, `groupCode`,
  /// `groupDescription`, `groupDescriptionArabic`. POST `/api/groups`.
  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final response = await http.post(
      Uri.parse('$baseURL/api/groups'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded is Map) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Failed to create group (${response.statusCode})';
    throw Exception(msg);
  }

  /// Creates a sub-group under a parent group. [payload]: `branchId`, `groupId`,
  /// `subGroupCode`, `subGroupDescription`, `subGroupDescriptionArabic`. POST `/api/sub-groups`.
  Future<Map<String, dynamic>> createSubGroup(
      Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final response = await http.post(
      Uri.parse('$baseURL/api/sub-groups'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded is Map) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Failed to create sub-group (${response.statusCode})';
    throw Exception(msg);
  }

  /// Creates a product (product_master + branch inventory row). [payload]: `branchId`,
  /// `productCode`, `description`, optional `groupId`/`subGroupId`, `unit`, `unitPrice`, etc.
  /// POST `/api/products`.
  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final response = await http.post(
      Uri.parse('$baseURL/api/products'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded is Map) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Failed to create product (${response.statusCode})';
    throw Exception(msg);
  }

  /// GET `/api/products/:productId?branchId=` — full product + inventory for edit.
  Future<Map<String, dynamic>> fetchProductById(String productId) async {
    final headers = _bearerHeaders();
    final uri = Uri.parse(
            '$baseURL/api/products/${Uri.encodeComponent(productId)}')
        .replace(queryParameters: {'branchId': '${_branchId()}'});
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode == 200 && decoded is Map) {
      final product = decoded['product'];
      if (product is Map) return Map<String, dynamic>.from(product);
      return Map<String, dynamic>.from(decoded);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Failed to load product (${response.statusCode})';
    throw Exception(msg);
  }

  /// PUT `/api/products/:productId` — same payload shape as [createProduct].
  Future<Map<String, dynamic>> updateProduct(
      String productId, Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final response = await http.put(
      Uri.parse('$baseURL/api/products/${Uri.encodeComponent(productId)}'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode == 200 && decoded is Map) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Failed to update product (${response.statusCode})';
    throw Exception(msg);
  }

  /// Saves a salon job. [payload] accepts restaurant-legacy keys
  /// (`mfAreaId`, `Items`, …) which the salon API normalises.
  Future<Map<String, dynamic>> saveKot(Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final response = await http.post(
      Uri.parse('$baseURL$posBasePath/job/save'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode == 200 && decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : (response.body.isNotEmpty
            ? response.body
            : 'Job save failed (${response.statusCode})');
    throw Exception(msg);
  }

  /// Returns open (unsettled) KOT list for Order List screen.
  /// Optional [areaId] and [search] (KOT number prefix/number search).
  Future<List<Map<String, dynamic>>> fetchOrderList(
      {String? areaId, String? search}) async {
    final headers = _bearerHeaders();
    final params = <String, String>{};
    if (areaId != null && areaId.isNotEmpty) params['areaId'] = areaId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final uri = Uri.parse('$baseURL$posBasePath/job/list')
        .replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load order list: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map)
      throw const FormatException('Order list: expected object');
    final list = decoded['data'];
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Loads KOT lines for settlement / left panel (`success` + `data` rows).
  Future<Map<String, dynamic>> fetchKotDetails(String kotMasterId) async {
    final headers = _bearerHeaders();
    final id = kotMasterId.trim();
    if (id.isEmpty) {
      return {'success': true, 'data': <dynamic>[]};
    }
    final uri = Uri.parse('$baseURL$posBasePath/job/${Uri.encodeComponent(id)}');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) throw Exception('Unauthorized.');
    if (response.statusCode == 404) {
      return {'success': false, 'data': <dynamic>[]};
    }
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load KOT: ${response.body.isNotEmpty ? response.body : response.statusCode}');
    }
    final decoded = _decode(response.body);
    if (decoded is! Map) throw FormatException('KOT: expected object');
    return Map<String, dynamic>.from(decoded as Map);
  }

  /// Persists settlement: `ops.sales_master`, `sales_child`, `sales_payment_split`; marks KOT settled.
  /// [payload] = orderData from POS + `paidAmount`, `paymentMode` (CASH | CREDITCARD).
  Future<Map<String, dynamic>> saveSettlement(
      Map<String, dynamic> payload) async {
    final headers = _bearerHeaders();
    final String body;
    try {
      body = jsonEncode(payload);
    } catch (e) {
      throw Exception(
          'Settlement payload is not valid JSON (check amounts are finite numbers): $e');
    }
    final uri = Uri.parse('$baseURL$posBasePath/sales/settle');
    final response = await http
        .post(
          uri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 60));
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is Map) {
      final map = Map<String, dynamic>.from(decoded as Map);
      if (map['ok'] == false) {
        final m = map['message']?.toString() ?? 'Settlement rejected';
        throw Exception(m);
      }
      final ok = map['ok'] == true || map['ok'] == 1;
      final bill = map['billNo']?.toString().trim() ?? '';
      final sid = map['salesId']?.toString().trim() ?? '';
      if (!ok || bill.isEmpty || sid.isEmpty) {
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}…'
            : response.body;
        throw Exception(
          'Settlement was not confirmed by the server (missing bill number). '
          'Check API base URL in settings. $snippet',
        );
      }
      return map;
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : (response.body.isNotEmpty
            ? response.body
            : 'Settlement failed (HTTP ${response.statusCode})');
    throw Exception(msg);
  }
}
