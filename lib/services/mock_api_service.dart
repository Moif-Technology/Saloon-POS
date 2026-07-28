import 'package:my_app/services/api_service.dart';

class MockApiService implements ApiService {
  static final List<Map<String, dynamic>> _createdGroups = [];
  static final List<Map<String, dynamic>> _createdAreas = [];
  static final List<Map<String, dynamic>> _createdSubGroups = [];
  static final List<Map<String, dynamic>> _createdProducts = [];
  static final List<Map<String, dynamic>> _createdTables = [];
  static final Map<String, Map<String, dynamic>> _openKots = {};
  static int _nextGroupId = 100;
  static int _nextAreaId = 100;
  static int _nextSubGroupId = 100;
  static int _nextProductId = 100;
  static int _nextTableId = 100;
  static int _nextKotNo = 3;
  static int _nextSaleNo = 2;

  static Map<String, dynamic> get _fullMockFeatures => {
        'pos': true,
        'pos.billing': true,
        'pos.product_search': true,
        'pos.customer_selection': true,
        'pos.takeaway': true,
        'pos.kot': true,
        'pos.kot.save': true,
        'pos.kot.print': true,
        'pos.kot.reprint': true,
        'pos.kot.dummy_bill': true,
        'pos.kot.comments': true,
        'pos.kot.join_split': true,
        'pos.kot.item_cancel': true,
        'pos.kot.save_without_area': true,
        'pos.settlement': true,
        'pos.settlement.cash': true,
        'pos.settlement.card': true,
        'pos.settlement.credit': true,
        'pos.settlement.direct': true,
        'pos.settlement.change': true,
        'pos.settlement.unsaved_cart': true,
        'pos.reprint_bill': true,
        'pos.return_bill': true,
        'pos.counter_open_close': true,
        'pos.counter_reports': true,
        'pos.full_ui': true,
        'pos.ui.basic': true,
        'pos.ui.normal': true,
        'pos.ui.groups_panel': true,
        'pos.ui.subgroups_panel': true,
        'pos.ui.areas_panel': true,
        'pos.ui.tables_panel': true,
        'pos.ui.cart.kot_label': true,
        'pos.ui.cart.customer_selector': true,
        'pos.ui.cart.add_customer': true,
        'pos.ui.cart.modifier': true,
        'pos.ui.cart.qty_controls': true,
        'pos.ui.cart.unit_price': true,
        'pos.ui.cart.subtotal': true,
        'pos.ui.cart.tax': true,
        'pos.ui.cart.line_total': true,
        'pos.ui.cart.delete': true,
        'pos.ui.totals.subtotal': true,
        'pos.ui.totals.tax': true,
        'pos.ui.totals.grand_total': true,
        'pos.dine_in': true,
        'pos.areas': true,
        'pos.tables': true,
        'pos.subgroup_master': true,
        'pos.delivery': true,
        'pos.void_bill': true,
        'pos.discount': true,
        'pos.discount.admin': true,
        'pos.cash_in_out': true,
        'pos.price_change': true,
        'pos.quantity_change': true,
        'pos.no_sale': true,
        'pos.order_list': true,
        'pos.group_master': true,
        'pos.product_master': true,
        'pos.printer_setup': true,
        'pos.user_setup': true,
        'pos.recipe': true,
        'pos.combo': true,
        'pos.barcode': true,
        'pos.kitchen_message': true,
        'pos.online_orders': true,
        'pos.stock_reports': true,
        'pos.production': true,
        'pos.stock_transfer': true,
        'pos.purchase': true,
        'pos.credit': true,
        'pos.advanced_reports': true,
        'pos.vat_reports': true,
        'pos.report_export': true,
        'pos.vat': true,
        'pos.settings': true,
        'pos.privilege_setup': true,
        'pos.language_setup': true,
        'pos.mess': true,
        'pos.notes': true,
        'pos.kds': true,
        'pos.customer_display': true,
        'pos.multi_supplier': true,
        'pos.sync_tools': true,
        'pos.cashier_change': true,
        'pos.day_close': true,
        'pos.game_zone': true,
      };

  static List<dynamic> get _fullMockPermissions => [
        'admin',
        'pos.admin',
        'pos.discount.apply',
        'pos.settlement.change',
        'pos.void_bill.execute',
        'pos.counter.close',
        'settlement',
        'reports',
        'edit_master',
        'discount',
      ];

  static Map<String, dynamic> get _mockSubscription => {
        'isActive': true,
        'isUsable': true,
        'status': 'active',
        'plan': 'mock-full',
        'expiresAt': '2027-12-31',
      };

  static Map<String, dynamic> get _mockLimits => {
        'max_staff': 20,
        'max_products': 10000,
        'max_branches': 5,
      };

  static Map<String, dynamic> get _mockParameters => {
        'Tax1': 15.0,
        'currencyPrecession': '2',
        'reportStartTime': '00:00',
        'reportEndTime': '23:59',
        'pendingKotCheck': 1,
        'ISWaiterMandotory': 0,
        'ClearAfterKOTSave': 1,
        'SaveKOTonSettlement': 0,
        'heading1Counter': 'Moif Technology',
        'heading2Counter': 'Restaurant POS',
        'heading3Counter': 'Branch #1',
        'heading4Counter': 'VAT Registered',
        'heading5Counter': 'Thank You',
        'heading6Counter': 'Please come again',
        'heading7Counter': 'Hotline: 800-MOIF',
        'taxRegistrationNo': 'TRN-123456789',
      };

  static Map<int, String> get _mockControlNames => {
        0: 'btnSaveKOT',
        1: 'btnPrintKOT',
        2: 'btnKOTReprint',
        3: 'btnDiscount',
        4: 'btnDummyBill',
        5: 'btnComments',
        6: 'btnBillCancel',
        7: 'btnAreaMaster',
        8: 'settlement',
        9: 'discount',
        10: 'item_cancel',
        11: 'compliment',
        12: 'price_change',
        13: 'reports',
        14: 'edit_master',
        15: 'cash_in_out',
      };

  static double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  static String _areaName(String? areaId) {
    final all = [
      {'AreaID': '1', 'AreaName': 'Main Hall'},
      {'AreaID': '2', 'AreaName': 'Terrace'},
      {'AreaID': '3', 'AreaName': 'VIP Room'},
      {'AreaID': '4', 'AreaName': 'Takeaway'},
      {'AreaID': '5', 'AreaName': 'Delivery'},
      ..._createdAreas,
    ];
    final match = all.where((a) => a['AreaID']?.toString() == areaId).toList();
    return match.isEmpty ? 'Main Hall' : match.first['AreaName'].toString();
  }

  static List<Map<String, dynamic>> _withOpenKotTableState(
    List<Map<String, dynamic>> tables,
  ) {
    return tables.map((table) {
      final tableId = table['TableID']?.toString() ?? '';
      final kots = _openKots.values
          .where((k) => k['tableId']?.toString() == tableId)
          .toList();
      if (kots.isEmpty) return Map<String, dynamic>.from(table);
      final first = kots.first;
      return {
        ...table,
        'KOTPrefix': first['kotPrefix']?.toString() ?? table['KOTPrefix'] ?? '',
        'KOTNumber': first['kotNumber']?.toString() ?? '',
        'KOTStatus': 'OPEN',
        'occupiedChairs': kots
            .map((k) => k['chairNo']?.toString() ?? '1')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList(),
        'kotDetails': kots
            .map((k) => {
                  'kotMasterID': k['kotMasterId'],
                  'KotPrefix': k['kotPrefix'],
                  'KotNumber': k['kotNumber'],
                  'ChairNo': k['chairNo'] ?? '1',
                  'KOTStatus': 'OPEN',
                })
            .toList(),
      };
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> login(String login, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'stationId': '1',
      'staffName': 'Admin',
      'staffID': '1',
      'accessToken': 'mock_access_token_xxx',
      'refreshToken': 'mock_refresh_token_xxx',
      'companyId': '1',
      'subscription': _mockSubscription,
      'features': _fullMockFeatures,
      'limits': _mockLimits,
      'permissions': _fullMockPermissions,
    };
  }

  @override
  Future<Map<String, dynamic>> pinLogin(String pin, int companyId,
      {int? staffPk}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'stationId': '1',
      'staffName': 'John Waiter',
      'staffID': '5',
      'accessToken': 'mock_access_token_pin_xxx',
      'refreshToken': 'mock_refresh_token_pin_xxx',
      'subscription': _mockSubscription,
      'features': _fullMockFeatures,
      'limits': _mockLimits,
      'permissions': _fullMockPermissions,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPosStaffList(int companyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {
        'staffPk': 1,
        'staffName': 'Admin',
        'roleName': 'Manager',
        'pin': '1234'
      },
      {
        'staffPk': 2,
        'staffName': 'Sarah',
        'roleName': 'Cashier',
        'pin': '2222'
      },
      {'staffPk': 3, 'staffName': 'Ahmed', 'roleName': 'Waiter', 'pin': '3333'},
      {
        'staffPk': 4,
        'staffName': 'Fatima',
        'roleName': 'Waiter',
        'pin': '4444'
      },
      {'staffPk': 5, 'staffName': 'John', 'roleName': 'Waiter', 'pin': '5555'},
      {
        'staffPk': 6,
        'staffName': 'Maria',
        'roleName': 'Cashier',
        'pin': '6666'
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> fetchCurrentSession() async {
    return {
      'stationId': '1',
      'staffName': 'Admin',
      'staffID': '1',
      'accessToken': 'mock_access_token_xxx',
      'refreshToken': 'mock_refresh_token_xxx',
      'subscription': _mockSubscription,
      'features': _fullMockFeatures,
      'limits': _mockLimits,
      'permissions': _fullMockPermissions,
      'expiresAt': '2027-12-31T23:59:59Z',
    };
  }

  @override
  Future<Map<String, dynamic>> fetchParameters() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockParameters;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPrivileges() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      for (final entry in _mockControlNames.entries)
        {
          'id': entry.key + 1,
          'name': entry.value,
          'ControlName': entry.value,
          'label': entry.value,
          'granted': true,
          'IsEnable': true,
        },
    ];
  }

  @override
  Future<void> savePosParameters(Map<String, dynamic> params) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
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
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<List<dynamic>> fetchGroups() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {
        'GroupID': '1',
        'GroupDescription': 'Burgers',
        'GroupDescriptionArabic': 'برجر',
        'KeyShift': 'B',
        'KeyCode': '1'
      },
      {
        'GroupID': '2',
        'GroupDescription': 'Pizza',
        'GroupDescriptionArabic': 'بيتزا',
        'KeyShift': 'P',
        'KeyCode': '2'
      },
      {
        'GroupID': '3',
        'GroupDescription': 'Sandwiches',
        'GroupDescriptionArabic': 'ساندويش',
        'KeyShift': 'S',
        'KeyCode': '3'
      },
      {
        'GroupID': '4',
        'GroupDescription': 'Drinks',
        'GroupDescriptionArabic': 'مشروبات',
        'KeyShift': 'D',
        'KeyCode': '4'
      },
      {
        'GroupID': '5',
        'GroupDescription': 'Appetizers',
        'GroupDescriptionArabic': 'مقبلات',
        'KeyShift': 'A',
        'KeyCode': '5'
      },
      {
        'GroupID': '6',
        'GroupDescription': 'Desserts',
        'GroupDescriptionArabic': 'حلويات',
        'KeyShift': 'E',
        'KeyCode': '6'
      },
      {
        'GroupID': '7',
        'GroupDescription': 'Salads',
        'GroupDescriptionArabic': 'سلطات',
        'KeyShift': 'R',
        'KeyCode': '7'
      },
      {
        'GroupID': '8',
        'GroupDescription': 'Seafood',
        'GroupDescriptionArabic': 'مأكولات بحرية',
        'KeyShift': 'F',
        'KeyCode': '8'
      },
      ..._createdGroups,
    ];
  }

  @override
  Future<List<dynamic>> fetchAreas({bool fetchAll = false}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {
        'AreaID': '1',
        'AreaName': 'Main Hall',
        'SupplyType': 'DINE IN',
        'AreaNameArabic': 'القاعة الرئيسية',
        'KotPrefix': 'H',
        'isTabletShow': true,
        'TableCreationType': 0
      },
      {
        'AreaID': '2',
        'AreaName': 'Terrace',
        'SupplyType': 'DINE IN',
        'AreaNameArabic': 'الشرفة',
        'KotPrefix': 'T',
        'isTabletShow': true,
        'TableCreationType': 0
      },
      {
        'AreaID': '3',
        'AreaName': 'VIP Room',
        'SupplyType': 'DINE IN',
        'AreaNameArabic': 'غرفة كبار الشخصيات',
        'KotPrefix': 'V',
        'isTabletShow': true,
        'TableCreationType': 0
      },
      {
        'AreaID': '4',
        'AreaName': 'Takeaway',
        'SupplyType': 'TAKE AWAY',
        'AreaNameArabic': 'الطلبات الخارجية',
        'KotPrefix': 'TA',
        'isTabletShow': true,
        'TableCreationType': 1
      },
      {
        'AreaID': '5',
        'AreaName': 'Delivery',
        'SupplyType': 'DELIVERY',
        'AreaNameArabic': 'التوصيل',
        'KotPrefix': 'DL',
        'isTabletShow': true,
        'TableCreationType': 2
      },
      ..._createdAreas,
    ];
  }

  @override
  Future<List<dynamic>> fetchSubGroups({String? groupId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final all = <Map<String, dynamic>>[
      {
        'SubGroupID': '1',
        'SubGroupDescription': 'Beef Burgers',
        'SubGroupDescriptionArabic': 'برجر لحم',
        'GroupID': '1',
        'SubGroupCode': 'BB'
      },
      {
        'SubGroupID': '2',
        'SubGroupDescription': 'Chicken Burgers',
        'SubGroupDescriptionArabic': 'برجر دجاج',
        'GroupID': '1',
        'SubGroupCode': 'CB'
      },
      {
        'SubGroupID': '3',
        'SubGroupDescription': 'Margherita',
        'SubGroupDescriptionArabic': 'مارغريتا',
        'GroupID': '2',
        'SubGroupCode': 'MG'
      },
      {
        'SubGroupID': '4',
        'SubGroupDescription': 'Pepperoni',
        'SubGroupDescriptionArabic': 'بيبروني',
        'GroupID': '2',
        'SubGroupCode': 'PP'
      },
      {
        'SubGroupID': '5',
        'SubGroupDescription': 'Hot Sandwiches',
        'SubGroupDescriptionArabic': 'ساندويش حار',
        'GroupID': '3',
        'SubGroupCode': 'HS'
      },
      {
        'SubGroupID': '6',
        'SubGroupDescription': 'Cold Sandwiches',
        'SubGroupDescriptionArabic': 'ساندويش بارد',
        'GroupID': '3',
        'SubGroupCode': 'CS'
      },
      {
        'SubGroupID': '7',
        'SubGroupDescription': 'Soft Drinks',
        'SubGroupDescriptionArabic': 'مشروبات غازية',
        'GroupID': '4',
        'SubGroupCode': 'SD'
      },
      {
        'SubGroupID': '8',
        'SubGroupDescription': 'Juices',
        'SubGroupDescriptionArabic': 'عصائر',
        'GroupID': '4',
        'SubGroupCode': 'J'
      },
      {
        'SubGroupID': '9',
        'SubGroupDescription': 'Hot Drinks',
        'SubGroupDescriptionArabic': 'مشروبات ساخنة',
        'GroupID': '4',
        'SubGroupCode': 'HD'
      },
      {
        'SubGroupID': '10',
        'SubGroupDescription': 'Starters',
        'SubGroupDescriptionArabic': 'مقبلات',
        'GroupID': '5',
        'SubGroupCode': 'ST'
      },
      {
        'SubGroupID': '11',
        'SubGroupDescription': 'Ice Cream',
        'SubGroupDescriptionArabic': 'آيس كريم',
        'GroupID': '6',
        'SubGroupCode': 'IC'
      },
      {
        'SubGroupID': '12',
        'SubGroupDescription': 'Cakes',
        'SubGroupDescriptionArabic': 'كيك',
        'GroupID': '6',
        'SubGroupCode': 'CK'
      },
      ..._createdSubGroups,
    ];
    if (groupId != null && groupId.isNotEmpty) {
      return all.where((sg) => sg['GroupID'] == groupId).toList();
    }
    return all;
  }

  @override
  Future<List<dynamic>> fetchProducts(
      {String? groupId, String? subGroupId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final all = <Map<String, dynamic>>[
      {
        'ProductID': '1',
        'ProductCode': 'BB001',
        'ShortDescription': 'Classic Beef Burger',
        'ProductName': 'Classic Beef Burger',
        'Barcode': '10000001',
        'UnitPrice': '45.00',
        'Tax1Rate': '15',
        'GroupID': '1',
        'SubGroupID': '1',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '2',
        'ProductCode': 'BB002',
        'ShortDescription': 'Cheese Burger',
        'ProductName': 'Cheese Burger',
        'Barcode': '10000002',
        'UnitPrice': '50.00',
        'Tax1Rate': '15',
        'GroupID': '1',
        'SubGroupID': '1',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '3',
        'ProductCode': 'BB003',
        'ShortDescription': 'Double Decker',
        'ProductName': 'Double Decker Burger',
        'Barcode': '10000003',
        'UnitPrice': '65.00',
        'Tax1Rate': '15',
        'GroupID': '1',
        'SubGroupID': '1',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '4',
        'ProductCode': 'CB001',
        'ShortDescription': 'Grilled Chicken Burger',
        'ProductName': 'Grilled Chicken Burger',
        'Barcode': '10000004',
        'UnitPrice': '42.00',
        'Tax1Rate': '15',
        'GroupID': '1',
        'SubGroupID': '2',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '5',
        'ProductCode': 'CB002',
        'ShortDescription': 'Crispy Chicken',
        'ProductName': 'Crispy Chicken Burger',
        'Barcode': '10000005',
        'UnitPrice': '44.00',
        'Tax1Rate': '15',
        'GroupID': '1',
        'SubGroupID': '2',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '6',
        'ProductCode': 'MG001',
        'ShortDescription': 'Margherita Pizza',
        'ProductName': 'Margherita Pizza',
        'Barcode': '10000006',
        'UnitPrice': '55.00',
        'Tax1Rate': '15',
        'GroupID': '2',
        'SubGroupID': '3',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '7',
        'ProductCode': 'PP001',
        'ShortDescription': 'Pepperoni Pizza',
        'ProductName': 'Pepperoni Pizza',
        'Barcode': '10000007',
        'UnitPrice': '60.00',
        'Tax1Rate': '15',
        'GroupID': '2',
        'SubGroupID': '4',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '8',
        'ProductCode': 'PP002',
        'ShortDescription': 'Supreme Pizza',
        'ProductName': 'Supreme Pizza',
        'Barcode': '10000008',
        'UnitPrice': '75.00',
        'Tax1Rate': '15',
        'GroupID': '2',
        'SubGroupID': '4',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '9',
        'ProductCode': 'HS001',
        'ShortDescription': 'Chicken Shawarma',
        'ProductName': 'Chicken Shawarma',
        'Barcode': '10000009',
        'UnitPrice': '25.00',
        'Tax1Rate': '15',
        'GroupID': '3',
        'SubGroupID': '5',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '10',
        'ProductCode': 'HS002',
        'ShortDescription': 'Meat Shawarma',
        'ProductName': 'Meat Shawarma',
        'Barcode': '10000010',
        'UnitPrice': '28.00',
        'Tax1Rate': '15',
        'GroupID': '3',
        'SubGroupID': '5',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '11',
        'ProductCode': 'CS001',
        'ShortDescription': 'Club Sandwich',
        'ProductName': 'Club Sandwich',
        'Barcode': '10000011',
        'UnitPrice': '32.00',
        'Tax1Rate': '15',
        'GroupID': '3',
        'SubGroupID': '6',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '12',
        'ProductCode': 'SD001',
        'ShortDescription': 'Coca Cola',
        'ProductName': 'Coca Cola',
        'Barcode': '10000012',
        'UnitPrice': '8.00',
        'Tax1Rate': '15',
        'GroupID': '4',
        'SubGroupID': '7',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '13',
        'ProductCode': 'SD002',
        'ShortDescription': 'Pepsi',
        'ProductName': 'Pepsi',
        'Barcode': '10000013',
        'UnitPrice': '8.00',
        'Tax1Rate': '15',
        'GroupID': '4',
        'SubGroupID': '7',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '14',
        'ProductCode': 'SD003',
        'ShortDescription': 'Mineral Water',
        'ProductName': 'Mineral Water 500ml',
        'Barcode': '10000014',
        'UnitPrice': '5.00',
        'Tax1Rate': '15',
        'GroupID': '4',
        'SubGroupID': '7',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '15',
        'ProductCode': 'J001',
        'ShortDescription': 'Orange Juice',
        'ProductName': 'Fresh Orange Juice',
        'Barcode': '10000015',
        'UnitPrice': '18.00',
        'Tax1Rate': '15',
        'GroupID': '4',
        'SubGroupID': '8',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '16',
        'ProductCode': 'HD001',
        'ShortDescription': 'Turkish Coffee',
        'ProductName': 'Turkish Coffee',
        'Barcode': '10000016',
        'UnitPrice': '12.00',
        'Tax1Rate': '15',
        'GroupID': '4',
        'SubGroupID': '9',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '17',
        'ProductCode': 'ST001',
        'ShortDescription': 'French Fries',
        'ProductName': 'French Fries',
        'Barcode': '10000017',
        'UnitPrice': '15.00',
        'Tax1Rate': '15',
        'GroupID': '5',
        'SubGroupID': '10',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '18',
        'ProductCode': 'ST002',
        'ShortDescription': 'Mozzarella Sticks',
        'ProductName': 'Mozzarella Sticks (6pcs)',
        'Barcode': '10000018',
        'UnitPrice': '22.00',
        'Tax1Rate': '15',
        'GroupID': '5',
        'SubGroupID': '10',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '19',
        'ProductCode': 'IC001',
        'ShortDescription': 'Vanilla Ice Cream',
        'ProductName': 'Vanilla Ice Cream',
        'Barcode': '10000019',
        'UnitPrice': '14.00',
        'Tax1Rate': '15',
        'GroupID': '6',
        'SubGroupID': '11',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '20',
        'ProductCode': 'CK001',
        'ShortDescription': 'Chocolate Cake',
        'ProductName': 'Chocolate Cake Slice',
        'Barcode': '10000020',
        'UnitPrice': '20.00',
        'Tax1Rate': '15',
        'GroupID': '6',
        'SubGroupID': '12',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '21',
        'ProductCode': 'SA001',
        'ShortDescription': 'Caesar Salad',
        'ProductName': 'Caesar Salad',
        'Barcode': '10000021',
        'UnitPrice': '28.00',
        'Tax1Rate': '15',
        'GroupID': '7',
        'SubGroupID': '',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      {
        'ProductID': '22',
        'ProductCode': 'SF001',
        'ShortDescription': 'Grilled Salmon',
        'ProductName': 'Grilled Salmon',
        'Barcode': '10000022',
        'UnitPrice': '85.00',
        'Tax1Rate': '15',
        'GroupID': '8',
        'SubGroupID': '',
        'Unit': 'PCS',
        'PackQty': '1'
      },
      ..._createdProducts,
    ];
    var filtered = all;
    if (groupId != null && groupId.isNotEmpty) {
      filtered = filtered.where((p) => p['GroupID'] == groupId).toList();
    }
    if (subGroupId != null && subGroupId.isNotEmpty) {
      filtered = filtered.where((p) => p['SubGroupID'] == subGroupId).toList();
    }
    return filtered;
  }

  @override
  Future<List<dynamic>> fetchTables({String? areaId}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    Map<String, dynamic> t({
      required String id,
      required String name,
      required String no,
      required String chairs,
      required String format,
      required String areaId,
      String prefix = '',
      String kotNo = '',
      String kotStatus = '',
      List<String> occChairs = const [],
      List<Map<String, dynamic>> kDetails = const [],
    }) =>
        {
          'TableID': id,
          'TableName': name,
          'TableNO': no,
          'NoOfChairs': chairs,
          'TableFormat': format,
          'AreaID': areaId,
          'KOTPrefix': prefix,
          'KOTNumber': kotNo,
          'KOTStatus': kotStatus,
          'occupiedChairs': occChairs,
          'kotDetails': kDetails,
        };

    final all = <Map<String, dynamic>>[
      // ── Main Hall (Area 1): T1–T8 ──
      t(id: '1', name: 'T1', no: '1', chairs: '4', format: 'SQUARE', areaId: '1', prefix: 'H'),
      t(id: '2', name: 'T2', no: '2', chairs: '4', format: 'SQUARE', areaId: '1', prefix: 'H'),
      t(id: '3', name: 'T3', no: '3', chairs: '6', format: 'RECTANGLE', areaId: '1', prefix: 'H',
          kotNo: 'H-001', kotStatus: 'OPEN', occChairs: ['1', '2'],
          kDetails: [
            {'kotMasterID': 'MK-001', 'KotPrefix': 'H', 'KotNumber': 'H-001', 'ChairNo': '1', 'KOTStatus': 'OPEN'},
            {'kotMasterID': 'MK-001', 'KotPrefix': 'H', 'KotNumber': 'H-001', 'ChairNo': '2', 'KOTStatus': 'OPEN'},
          ]),
      t(id: '4', name: 'T4', no: '4', chairs: '2', format: 'SQUARE', areaId: '1', prefix: 'H'),
      t(id: '5', name: 'T5', no: '5', chairs: '4', format: 'ROUND', areaId: '1', prefix: 'H',
          kotNo: 'H-002', kotStatus: 'OPEN', occChairs: ['1'],
          kDetails: [
            {'kotMasterID': 'MK-003', 'KotPrefix': 'H', 'KotNumber': 'H-002', 'ChairNo': '1', 'KOTStatus': 'OPEN'},
          ]),
      t(id: '6', name: 'T6', no: '6', chairs: '6', format: 'RECTANGLE', areaId: '1', prefix: 'H'),
      t(id: '7', name: 'T7', no: '7', chairs: '4', format: 'SQUARE', areaId: '1', prefix: 'H',
          kotNo: 'H-003', kotStatus: 'BILL_REQUESTED', occChairs: ['1', '2', '3'],
          kDetails: [
            {'kotMasterID': 'MK-004', 'KotPrefix': 'H', 'KotNumber': 'H-003', 'ChairNo': '1', 'KOTStatus': 'BILL_REQUESTED'},
            {'kotMasterID': 'MK-004', 'KotPrefix': 'H', 'KotNumber': 'H-003', 'ChairNo': '2', 'KOTStatus': 'BILL_REQUESTED'},
            {'kotMasterID': 'MK-004', 'KotPrefix': 'H', 'KotNumber': 'H-003', 'ChairNo': '3', 'KOTStatus': 'BILL_REQUESTED'},
          ]),
      t(id: '8', name: 'T8', no: '8', chairs: '8', format: 'ROUND', areaId: '1', prefix: 'H'),

      // ── Terrace (Area 2): T9–T12 ──
      t(id: '9', name: 'T9', no: '9', chairs: '2', format: 'SQUARE', areaId: '2', prefix: 'T'),
      t(id: '10', name: 'T10', no: '10', chairs: '4', format: 'SQUARE', areaId: '2', prefix: 'T'),
      t(id: '11', name: 'T11', no: '11', chairs: '6', format: 'RECTANGLE', areaId: '2', prefix: 'T'),
      t(id: '12', name: 'T12', no: '12', chairs: '4', format: 'ROUND', areaId: '2', prefix: 'T'),

      // ── VIP Room (Area 3): V1–V3 ──
      t(id: '13', name: 'V1', no: '13', chairs: '8', format: 'ROUND', areaId: '3', prefix: 'V',
          kotNo: 'V-001', kotStatus: 'OPEN', occChairs: ['1', '3', '5'],
          kDetails: [
            {'kotMasterID': 'MK-002', 'KotPrefix': 'V', 'KotNumber': 'V-001', 'ChairNo': '1', 'KOTStatus': 'OPEN'},
            {'kotMasterID': 'MK-002', 'KotPrefix': 'V', 'KotNumber': 'V-001', 'ChairNo': '3', 'KOTStatus': 'OPEN'},
            {'kotMasterID': 'MK-002', 'KotPrefix': 'V', 'KotNumber': 'V-001', 'ChairNo': '5', 'KOTStatus': 'OPEN'},
          ]),
      t(id: '14', name: 'V2', no: '14', chairs: '6', format: 'RECTANGLE', areaId: '3', prefix: 'V'),
      t(id: '15', name: 'V3', no: '15', chairs: '4', format: 'SQUARE', areaId: '3', prefix: 'V'),

      ..._createdTables,
    ];
    final filtered = areaId != null && areaId.isNotEmpty
        ? all.where((t) => t['AreaID']?.toString() == areaId).toList()
        : all;
    return _withOpenKotTableState(filtered);
  }

  @override
  Future<List<dynamic>> fetchCustomers({int limit = 400}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {
        'CustomerID': '1',
        'customerId': 1,
        'CustomerCode': 'C001',
        'customerCode': 'C001',
        'CustomerName': 'Ahmed Ali',
        'customerName': 'Ahmed Ali',
        'City': 'Dubai',
        'Telephone': '0501111111',
        'MobileNo': '0501111111',
        'CustTRN': 'TRN-001',
        'Address': 'Dubai Marina'
      },
      {
        'CustomerID': '2',
        'customerId': 2,
        'CustomerCode': 'C002',
        'customerCode': 'C002',
        'CustomerName': 'Sara Khan',
        'customerName': 'Sara Khan',
        'City': 'Abu Dhabi',
        'Telephone': '0502222222',
        'MobileNo': '0502222222',
        'CustTRN': 'TRN-002',
        'Address': 'Corniche Road'
      },
      {
        'CustomerID': '3',
        'customerId': 3,
        'CustomerCode': 'C003',
        'customerCode': 'C003',
        'CustomerName': 'Mohammed Noor',
        'customerName': 'Mohammed Noor',
        'City': 'Sharjah',
        'Telephone': '0503333333',
        'MobileNo': '0503333333',
        'CustTRN': '',
        'Address': 'Al Majaz'
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> createArea(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final id = (_nextAreaId++).toString();
    _createdAreas.add({
      'AreaID': id,
      'AreaName': payload['areaName']?.toString() ??
          payload['AreaName']?.toString() ??
          'Area $id',
      'SupplyType': payload['supplyType']?.toString() ??
          payload['SupplyType']?.toString() ??
          'DINE_IN',
      'AreaNameArabic': payload['areaNameArabic']?.toString() ??
          payload['AreaNameArabic']?.toString() ??
          '',
      'KotPrefix': payload['kotPrefix']?.toString() ?? 'A$id',
      'isTabletShow': payload['isTabletShow'] ?? true,
      'TableCreationType': payload['tableCreationType'] ?? 0,
    });
    return {
      'success': true,
      'areaId': int.parse(id),
      'message': 'Area created'
    };
  }

  @override
  Future<Map<String, dynamic>> createTable(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final id = (_nextTableId++).toString();
    final areaId = payload['areaId']?.toString() ?? '1';
    _createdTables.add({
      'TableID': id,
      'TableName': payload['tableName']?.toString() ?? 'T$id',
      'TableNO': payload['tableNo']?.toString() ?? id,
      'TableNameArabic': payload['tableNameArabic']?.toString() ?? '',
      'NoOfChairs': payload['noOfChairs']?.toString() ?? '4',
      'TableFormat': payload['tableFormat']?.toString() ?? 'SQUARE',
      'AreaID': areaId,
      'AreaId': areaId,
      'WaiterID': payload['waiterId']?.toString() ?? '',
      'KOTPrefix': '',
      'KOTNumber': '',
      'KOTStatus': '',
      'occupiedChairs': <dynamic>[],
      'kotDetails': <dynamic>[],
    });
    return {
      'success': true,
      'tableId': int.parse(id),
      'message': 'Table created'
    };
  }

  @override
  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final id = (_nextGroupId++).toString();
    _createdGroups.add({
      'GroupID': id,
      'GroupDescription': payload['groupDescription']?.toString() ??
          payload['description']?.toString() ??
          'Group $id',
      'GroupDescriptionArabic':
          payload['groupDescriptionArabic']?.toString() ?? '',
      'GroupCode': payload['groupCode']?.toString() ?? 'G$id',
      'KeyShift': payload['keyShift']?.toString() ?? '',
      'KeyCode': payload['keyCode']?.toString() ?? '',
    });
    return {
      'success': true,
      'groupId': int.parse(id),
      'message': 'Group created'
    };
  }

  @override
  Future<Map<String, dynamic>> createSubGroup(
      Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final id = (_nextSubGroupId++).toString();
    _createdSubGroups.add({
      'SubGroupID': id,
      'SubGroupDescription': payload['subGroupDescription']?.toString() ??
          payload['description']?.toString() ??
          'Sub Group $id',
      'SubGroupDescriptionArabic':
          payload['subGroupDescriptionArabic']?.toString() ?? '',
      'GroupID': payload['groupId']?.toString() ?? '1',
      'SubGroupCode': payload['subGroupCode']?.toString() ?? 'SG$id',
    });
    return {
      'success': true,
      'subGroupId': int.parse(id),
      'message': 'Sub-group created'
    };
  }

  @override
  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final id = (_nextProductId++).toString();
    final description = payload['description']?.toString() ??
        payload['productName']?.toString() ??
        'Product $id';
    _createdProducts.add({
      'ProductID': id,
      'ProductCode': payload['productCode']?.toString() ?? 'P$id',
      'ShortDescription': description,
      'ProductName': description,
      'Barcode': payload['barcode']?.toString() ?? '',
      'UnitPrice': payload['unitPrice']?.toString() ?? '0.00',
      'Tax1Rate': payload['vatOutPct']?.toString() ?? '15',
      'GroupID': payload['groupId']?.toString() ?? '',
      'SubGroupID': payload['subGroupId']?.toString() ?? '',
      'Unit': payload['unit']?.toString() ?? 'PCS',
      'PackQty': payload['packQty']?.toString() ?? '1',
    });
    return {
      'success': true,
      'productId': int.parse(id),
      'message': 'Product created'
    };
  }

  @override
  Future<Map<String, dynamic>> saveKot(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final kotNo = _nextKotNo++;
    final kotMasterId = 'MK-${kotNo.toString().padLeft(3, '0')}';
    final areaId = (payload['mfAreaId'] ??
            payload['areaId'] ??
            payload['AreaID'] ??
            payload['TableAreaID'] ??
            '1')
        .toString();
    final tableId =
        (payload['TableId'] ?? payload['tableId'] ?? payload['TableID'] ?? '3')
            .toString();
    final chairNo =
        (payload['ChairNo'] ?? payload['chairNo'] ?? payload['SeatNo'] ?? '1')
            .toString();
    final prefix = (payload['KotPrefix'] ??
            payload['KOTPrefix'] ??
            (areaId == '3' ? 'V' : 'H'))
        .toString();
    final kotNumber = '$prefix-${kotNo.toString().padLeft(3, '0')}';
    final items = List<Map<String, dynamic>>.from(
      (payload['Items'] ?? payload['items'] ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)),
    );
    final lines = items.isEmpty
        ? <Map<String, dynamic>>[
            {
              'productName': 'Classic Beef Burger',
              'qty': 1,
              'rate': 45.00,
              'amount': 45.00,
              'status': 'PENDING',
              'AndroidPrint': 'PENDING',
              'ChairNo': chairNo,
              'kotMasterID': kotMasterId,
            }
          ]
        : items.map((item) {
            final qty =
                _toDouble(item['Qty'] ?? item['qty'] ?? item['Quantity']);
            final rate = _toDouble(
              item['Rate'] ??
                  item['rate'] ??
                  item['UnitPrice'] ??
                  item['price'],
            );
            final amount = _toDouble(item['Amount'] ?? item['amount']);
            return {
              ...item,
              'productName': item['ProductName'] ??
                  item['productName'] ??
                  item['ShortDescription'] ??
                  'Mock Item',
              'qty': qty == 0 ? 1 : qty,
              'rate': rate,
              'amount': amount == 0 ? (qty == 0 ? 1 : qty) * rate : amount,
              'status': 'PENDING',
              'AndroidPrint': item['AndroidPrint'] ?? 'PENDING',
              'ChairNo': item['ChairNo'] ?? chairNo,
              'kotMasterID': kotMasterId,
            };
          }).toList();

    final totalAmount = lines.fold<double>(
      0,
      (sum, line) => sum + _toDouble(line['amount'] ?? line['Amount']),
    );
    _openKots[kotMasterId] = {
      'kotMasterId': kotMasterId,
      'kotNumber': kotNumber,
      'kotPrefix': prefix,
      'tableId': tableId,
      'tableName': payload['TableName']?.toString() ?? 'T$tableId',
      'chairNo': chairNo,
      'areaId': areaId,
      'areaName': _areaName(areaId),
      'staffName': payload['gvCashierName']?.toString() ?? 'Admin',
      'customerName': payload['CustomerName']?.toString() ?? 'Cash Customer',
      'totalAmount': totalAmount,
      'status': 'OPEN',
      'itemCount': lines.length,
      'createdAt': DateTime.now().toIso8601String(),
      'lines': lines,
    };
    return {
      'success': true,
      'kotMasterId': kotMasterId,
      'kotNumber': kotNumber,
      'message': 'KOT saved successfully',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOrderList(
      {String? areaId, String? search}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final rows = <Map<String, dynamic>>[
      {
        'kotMasterId': 'MK-001',
        'kotNumber': 'H-001',
        'tableName': 'T3',
        'AreaName': 'Main Hall',
        'staffName': 'Ahmed',
        'customerName': 'Ahmed Ali',
        'totalAmount': 145.00,
        'status': 'OPEN',
        'itemCount': 3,
        'createdAt': '2026-06-16T12:30:00',
      },
      {
        'kotMasterId': 'MK-002',
        'kotNumber': 'V-001',
        'tableName': 'V1',
        'AreaName': 'VIP Room',
        'staffName': 'John',
        'customerName': 'Sara Khan',
        'totalAmount': 320.00,
        'status': 'OPEN',
        'itemCount': 5,
        'createdAt': '2026-06-16T13:00:00',
      },
      {
        'kotMasterId': 'MK-003',
        'kotNumber': 'H-002',
        'tableName': 'T5',
        'AreaName': 'Main Hall',
        'staffName': 'Fatima',
        'customerName': 'Omar Hassan',
        'totalAmount': 78.50,
        'status': 'OPEN',
        'itemCount': 2,
        'createdAt': '2026-06-16T13:30:00',
      },
      {
        'kotMasterId': 'MK-004',
        'kotNumber': 'H-003',
        'tableName': 'T7',
        'AreaName': 'Main Hall',
        'staffName': 'Ali',
        'customerName': 'Layla Mahmoud',
        'totalAmount': 215.00,
        'status': 'BILL_REQUESTED',
        'itemCount': 4,
        'createdAt': '2026-06-16T14:00:00',
      },
      ..._openKots.values.map((kot) => {
            'kotMasterId': kot['kotMasterId'],
            'kotNumber': kot['kotNumber'],
            'tableName': kot['tableName'],
            'AreaName': kot['AreaName'],
            'staffName': kot['staffName'],
            'customerName': kot['customerName'],
            'totalAmount': kot['totalAmount'],
            'status': kot['status'],
            'itemCount': kot['itemCount'],
            'createdAt': kot['createdAt'],
            'areaId': kot['areaId'],
          }),
    ];
    return rows.where((row) {
      final areaOk = areaId == null ||
          areaId.isEmpty ||
          areaId == 'All' ||
          row['areaId']?.toString() == areaId ||
          row['areaName']?.toString() == areaId;
      final q = search?.trim().toLowerCase() ?? '';
      final searchOk = q.isEmpty ||
          row.values.any((v) => v.toString().toLowerCase().contains(q));
      return areaOk && searchOk;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> fetchKotDetails(String kotMasterId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final open = _openKots[kotMasterId];
    if (open != null) {
      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(open['lines'] as List),
      };
    }
    return {
      'success': true,
      'data': [
        {
          'productName': 'Classic Beef Burger',
          'qty': 2,
          'rate': 45.00,
          'amount': 90.00,
          'status': 'PENDING'
        },
        {
          'productName': 'French Fries',
          'qty': 1,
          'rate': 15.00,
          'amount': 15.00,
          'status': 'PENDING'
        },
        {
          'productName': 'Coca Cola',
          'qty': 2,
          'rate': 8.00,
          'amount': 16.00,
          'status': 'PENDING'
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> saveSettlement(
      Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final kotId = (payload['kotMasterId'] ??
            payload['kotMasterID'] ??
            payload['KOTMasterID'] ??
            payload['orderData']?['kotMasterId'] ??
            '')
        .toString();
    if (kotId.isNotEmpty) _openKots.remove(kotId);
    final saleNo = _nextSaleNo++;
    return {
      'ok': true,
      'billNo': 'S-2026-${saleNo.toString().padLeft(4, '0')}',
      'salesId': 'SL-${saleNo.toString().padLeft(3, '0')}',
      'message': 'Settlement completed',
      'changeAmount': 15.50,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchStaff() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {
        'staffId': 1,
        'staffName': 'Admin',
        'roleName': 'Manager',
        'branchId': 1
      },
      {
        'staffId': 2,
        'staffName': 'Sarah',
        'roleName': 'Cashier',
        'branchId': 1
      },
      {'staffId': 3, 'staffName': 'Ahmed', 'roleName': 'Waiter', 'branchId': 1},
      {
        'staffId': 4,
        'staffName': 'Fatima',
        'roleName': 'Waiter',
        'branchId': 1
      },
      {'staffId': 5, 'staffName': 'John', 'roleName': 'Waiter', 'branchId': 1},
      {
        'staffId': 6,
        'staffName': 'Maria',
        'roleName': 'Cashier',
        'branchId': 1
      },
    ];
  }
}
