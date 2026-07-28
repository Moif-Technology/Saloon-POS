import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/api_service_provider.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/core/providers/update_provider.dart';
import 'package:my_app/utils/privilege_utils.dart';
import 'package:my_app/utils/sessionManager.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/widgets/topPanelWidgets/ReportTab/areawise_reportsummary.dart';
import 'package:my_app/widgets/topPanelWidgets/ReportTab/reportViewer.dart';
import 'package:my_app/widgets/topPanelWidgets/ReportTab/salesVatReport.dart';
import 'package:my_app/widgets/topPanelWidgets/top_panel_widgets_imports.dart';
import 'package:my_app/utils/sessionStorage.dart';
import 'package:window_manager/window_manager.dart';

class TopBar extends ConsumerWidget {
  static const Map<String, String> _dialogFeatureGate = {
    "Counter Close": "pos.counter_open_close",
    "Counter Close - Admin": "pos.counter_open_close",
    "Counter Close Reports": "pos.counter_reports",
    "Day Close Report": "pos.counter_reports",
    "Income OR Expenses": "pos.cash_in_out",
    "Discount Entry": "pos.discount",
    "Discount List": "pos.discount",
    "Change Discount % Button": "pos.discount",
    "Change Settlement": "pos.settlement",
    "Bill Reprint": "pos.reprint_bill",
    "Cancel Bill Details": "pos.void_bill",
    "Cancel Bill Summary": "pos.void_bill",
    "Item Void Report": "pos.void_bill",
    "Advance Payment": "pos.credit",
    "Credit Payment Reciept": "pos.credit",
    "Payment List": "pos.credit",
    "OS Balance List": "pos.credit",
    "Reciept List": "pos.credit",
    "Advance Viewer": "pos.credit",
    "Mess Bill Viewer": "pos.credit",
    "Privillage Setup": "pos.privilege_setup",
    "User List": "pos.user_setup",
    "Printer Setup": "pos.printer_setup",
    "Control Panel": "pos.settings",
    "KDS Refresh": "pos.kds",
    "Cashier Change": "pos.cashier_change",
    "VAT Activation": "pos.vat",
    "Disable VAT": "pos.vat",
    "Multi Supplier Setup": "pos.multi_supplier",
    "Product List Edit": "pos.product_master",
    "Purchase Entry": "pos.purchase",
    "Purchase List": "pos.purchase",
    "Purchase Return": "pos.purchase",
    "Purchase Return List": "pos.purchase",
    "Supplier List": "pos.purchase",
    "Stock Report": "pos.stock_reports",
    "Movement Report": "pos.stock_reports",
    "Opening Stock Entry": "pos.stock_reports",
    "Production Entry": "pos.production",
    "Production List": "pos.production",
    "Product Request": "pos.stock_transfer",
    "Product Receipt": "pos.stock_transfer",
    "Product Transfer": "pos.stock_transfer",
    "Transfer List": "pos.stock_transfer",
    "Receipt List": "pos.stock_transfer",
    "Upload To Main Server": "pos.sync_tools",
    "Download New Items from main server": "pos.sync_tools",
    "Recipe Entry": "pos.recipe",
    "Kitchen Message": "pos.kitchen_message",
    "Combo": "pos.combo",
    "Combo Edit": "pos.combo",
    "Barcode Print Utility": "pos.barcode",
    "Notes Entry": "pos.notes",
    "Mess Master Entry": "pos.mess",
    "Mess List": "pos.mess",
    "Online Source Entry": "pos.online_orders",
    "Area Entry": "pos.areas",
    "Area Edit": "pos.areas",
    "Area Wise Report": "pos.areas",
    "Area Wise ReportSummary": "pos.areas",
    "Group Wise": "pos.counter_reports",
    "Item Wise": "pos.counter_reports",
    "Sales Bill Wise": "pos.advanced_reports",
    "Day Wise": "pos.counter_reports",
    "Sales Viewer": "pos.counter_reports",
    "Sales Vat Report": "pos.vat_reports",
    "Report View": "pos.report_export",
    "Table Entry": "pos.tables",
    "Table Edit": "pos.tables",
    "Language Setup": "pos.language_setup",
    "Utility For VAT Correction": "pos.vat",
  };

  static const Map<String, String> _dialogPermissionGate = {
    "Discount Entry": "pos.discount.apply",
    "Discount List": "pos.discount.apply",
    "Change Discount % Button": "pos.discount.apply",
    "Change Settlement": "pos.settlement.change",
    "Cancel Bill Details": "pos.void_bill.execute",
    "Counter Close - Admin": "pos.counter.close",
    "Privillage Setup": "pos.admin",
    "User List": "pos.admin",
    "Control Panel": "pos.admin",
  };

  bool _gateAllows(BuildContext context, String dialogName) {
    final container = ProviderScope.containerOf(context, listen: false);
    final subscription = container.read(subscriptionProvider);
    if (subscription != null && subscription['isUsable'] == false) return false;
    final features = container.read(featuresProvider);
    final permissions = container.read(permissionsProvider);
    final feature = _dialogFeatureGate[dialogName];
    if (feature != null && features.isNotEmpty && features[feature] != true) {
      return false;
    }
    final permission = _dialogPermissionGate[dialogName];
    if (permission != null &&
        permissions.isNotEmpty &&
        !permissions.contains(permission)) {
      return false;
    }
    return true;
  }

  void _denyAccess(BuildContext context, String dialogName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Not available: $dialogName is not enabled for this subscription/role.')),
    );
  }

  void _openDialog(BuildContext context, String dialogName) {
    print("Opening dialog: $dialogName"); // Debugging log
    if (!_gateAllows(context, dialogName)) {
      _denyAccess(context, dialogName);
      return;
    }
    if (dialogName == "Clear KOT") {
      _showClearKOTConfirmation(context);
      return;
    }
    if (dialogName == "Shut Down") {
      _showShutdownConfirmation(context);
      return;
    }

    final dialogMap = {
      "Area Entry": () => AreaDetailsEntryDialog(task: "New"),
      "Table Entry": () => TableDetailsDialog(),
      "Group Entry": () => GroupDetailsDialog(),
      "Sub Group Entry": () => SubgroupDetailsDialog(),
      "Product Entry": () => ProductMasterDetailsDialog(
            uniqueMultiProductID: "",
            groupId: null,
            fromTopBar: true, // ✅ Add this!
          ),
      "Kitchen Message": () => KitchenMessageEntryDialog(),
      "Combo": () => ComboDetailsEntryDialog(),
      "Recipe Entry": () => RecipeDetailsEntryDialog(),
      "Barcode Print Utility": () => BarcodePrintUtilityDialog(),
      "Notes Entry": () => NotesEntryDialog(),
      "Online Source Entry": () => SourceEntry(),
      "Mess Master Entry": () => MessMasterEntryDialog(),
      "Area Edit": () => AreaListDialog(),
      "Table Edit": () => TableListDialog(),
      "Group Edit": () => GroupListDialog(),
      "Sub Group Edit": () => SubGroupListDialog(),
      "Product Edit": () => ProductListDialog(),
      "Combo Edit": () => ComboListDialog(),
      "Mess List": () => MessListDialog(),
      "Production Entry": () => ProductionEntryDialog(),
      "Opening Stock Entry": () => OpeningStockEntryDialog(),
      "Stock Report": () => StockProductDialog(),
      "Movement Report": () => ProductMovementReportDialog(),
      "Product Request": () => ProductRequestDialog(),
      "Product Receipt": () => ProductReceiptDialog(),
      "Product Transfer": () => ProductTransferDialog(),
      "Receipt List": () => ProductReceiptListDialog(),
      "Supplier List": () => SupplierMasterListDialog(),
      "Purchase Entry": () => PurchaseEntryDialog(),
      "Purchase List": () => PurchaseListDialog(),
      "Purchase Return": () => PurchaseReturnDialog(),
      "Purchase Return List": () => PurchaseReturnListDialog(),
      "Bill Reprint": () => BillReprintDialog(),
      "Counter Close": () => CounterCloseDialog(),
      "Area Wise Report": () => AreaWiseReportDialog(),
      "Group Wise": () => GroupWiseReportDialog(),
      "Item Wise": () => ItemWiseReportDialog(),
      "Item Void Report": () => ItemVoidReportDialog(),
      "Cancel Bill Details": () => CancelBillReportDialog(),
      "Cancel Bill Summary": () => CancelBillSummary(),
      "Counter Close Reports": () => CounterCloseReportPage(),
      "Sales Bill Wise": () => SalesBillWiseReport(),
      "Day Wise": () => DayWise(),
      "Advance Payment": () => AdvancePaymentDialog(),
      "Credit Payment Reciept": () => CustomerLookupDialog(),
      "Payment List": () => PaymentList(),
      "OS Balance List": () => OutstandingBillsDialog(),
      "Reciept List": () => ReceiptListDialog(),
      "Advance Viewer": () => AdvanceViewer(),
      "Mess Bill Viewer": () => MessBillViewer(),
      "Counter Close - Admin": () => CounterCloseAdminDialog(),
      "Day Close Report": () => DayCloseReport(),
      "Income OR Expenses": () => IncomeExpenseDialog(),
      "Discount Entry": () => DiscountSettingsDialog(),
      "Discount List": () => DiscountListingDialog(),
      "Change Settlement": () => ChangeSettlementDialog(),
      "Product List Edit": () => ProductListDialog(),
      "Change Discount % Button": () => DiscountPercentageDialog(),
      "Printer Setup": () => CounterPrinterSetupDialog(),
      "User List": () => UsersListDialog(),
      "Privillage Setup": () => PrivilegeSettingsTabbedDialog(),
      "Control Panel": () => POSSettingsDialog(),
      "Language Setup": () => LanguageSettingsDialog(),
      "Utility For VAT Correction": () => UtilityDialog(),
      "Sales Viewer": () => SalesViewerDialog(),
      "Sales Vat Report": () => Salesvatreport(),
      "Area Wise ReportSummary": () => AreaWiseReportSummaryDialog(),
      "Report View": () => ReportViewerDialog(),
    };

    final dialogBuilder = dialogMap[dialogName];
    if (dialogBuilder != null) {
      bool barrierDismissible = dialogName != "Privillage Setup";
      showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (BuildContext context) => dialogBuilder(),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    SessionManager().clearSession();
    await SessionStorage.clearSession();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainLoginPage()),
      (route) => false,
    );
  }

  // Method to handle logout button press
  void _handleLogout(BuildContext context, String action) {
    if (action == "Logout") {
      _logout(context); // Call logout method
    } else if (action == "EXIT") {
      exit(0);
    }
  }

  void _showClearKOTConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: Text(
            "Clear KOT",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D), // Primary color matching your theme
            ),
          ),
          content: Text(
            "Are you sure you want to clear all KOTs?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400], // Neutral color for "Cancel"
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black, // Text color to contrast with button
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add logic to clear KOTs here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor:
                        Color(0xFF521C1D), // Custom color for SnackBar
                    content: Text(
                      "All KOTs have been cleared.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Color(0xFF521C1D), // Custom color for "Confirm"
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Confirm",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showShutdownConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: Text(
            "Shutdown System",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF521C1D), // Primary color matching your theme
            ),
          ),
          content: Text(
            "Are you sure you want to shut down the system?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400], // Neutral color for "Cancel"
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add logic for system shutdown here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor:
                        Color(0xFF521C1D), // Custom color for SnackBar
                    content: Text(
                      "System is shutting down.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
                // Additional logic for shutting down the system can be placed here.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Color(0xFF521C1D), // Custom color for "Shutdown"
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Shutdown",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildMenuButton(BuildContext context, String title,
      {List<PopupMenuEntry<String>>? subMenuItems}) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (title == "Logout") {
          _handleLogout(context, value);
        } else {
          _openDialog(context, value);
        }
      },
      itemBuilder: (context) =>
          subMenuItems ??
          [
            PopupMenuItem<String>(value: title, child: Text(title)),
          ],
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
      color: Colors.white,
    );
  }

  /// Waiter/Cashier name chip — avatar + name. Alternatives:
  /// - Label-only: small "Cashier" grey text, name bold below/next to it.
  /// - Minimal pill: single rounded pill with name only, no icon.
  /// - Full-height strip: name in a right-edge vertical strip.
  Widget _buildWaiterNameChip(BuildContext context) {
    final name = SessionManager().staffName ?? '—';
    final initial = name.isNotEmpty && name != '—'
        ? name.trim().substring(0, 1).toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// App version label for top bar (right side).
  Widget _buildVersionChip(BuildContext context, WidgetRef ref) {
    final asyncPkg = ref.watch(appPackageInfoProvider);
    return asyncPkg.when(
      data: (pkg) => Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'v${pkg.version}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 12,
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _refreshEntitlements(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Refreshing plan features...'),
          duration: Duration(seconds: 1),
        ),
      );

      final apiService = ref.read(apiServiceProvider);
      final session = await apiService.fetchCurrentSession();
      final user = session['user'] is Map
          ? Map<String, dynamic>.from(session['user'] as Map)
          : <String, dynamic>{};
      final subscription = session['subscription'] is Map
          ? Map<String, dynamic>.from(session['subscription'] as Map)
          : null;
      final features = session['features'] is Map
          ? Map<String, dynamic>.from(session['features'] as Map)
          : <String, dynamic>{};
      final limits = session['limits'] is Map
          ? Map<String, dynamic>.from(session['limits'] as Map)
          : <String, dynamic>{};
      final permissions = session['permissions'] is List
          ? List<dynamic>.from(session['permissions'] as List)
          : <dynamic>[];
      List<Map<String, dynamic>> privileges = ref.read(privilegesProvider);
      if (subscription?['isUsable'] != false && features['pos'] == true) {
        try {
          privileges = await apiService.fetchPrivileges();
        } catch (e) {
          debugPrint('Feature refresh: privilege refresh skipped: $e');
        }
      } else {
        privileges = <Map<String, dynamic>>[];
      }

      final manager = SessionManager();
      final stationId =
          user['stationId']?.toString() ?? manager.stationId ?? '';
      final staffName =
          user['staffName']?.toString() ?? manager.staffName ?? '';
      final staffID = user['staffId']?.toString() ?? manager.staffID ?? '';

      manager.setSession(
        stationId: stationId,
        staffName: staffName,
        staffID: staffID,
        accessToken: manager.accessToken,
        refreshToken: manager.refreshToken,
        subscription: subscription,
        features: features,
        limits: limits,
        permissions: permissions,
      );

      await SessionStorage.saveSession(
        stationId,
        staffName,
        staffID,
        accessToken: manager.accessToken,
        refreshToken: manager.refreshToken,
        subscription: subscription,
        features: features,
        limits: limits,
        permissions: permissions,
      );

      ref.read(subscriptionProvider.notifier).state = subscription;
      ref.read(featuresProvider.notifier).state = features;
      ref.read(limitsProvider.notifier).state = limits;
      ref.read(permissionsProvider.notifier).state = permissions;
      ref.read(privilegesProvider.notifier).state = privileges;

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Plan features refreshed (${features.length} loaded).'),
          backgroundColor: const Color(0xFF521C1D),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not refresh plan features: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildRefreshFeaturesButton(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Refresh plan features',
      child: IconButton(
        onPressed: () => _refreshEntitlements(context, ref),
        icon: const Icon(Icons.sync, color: Colors.white, size: 20),
        splashRadius: 20,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBaseVersion = isBasePosUi(ref);

    return Container(
      height: 50,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(52, 5, 15, 1),
            Color.fromRGBO(128, 0, 0, 1),
            Color.fromRGBO(52, 5, 15, 1),
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              buildMenuButton(
                context,
                "New Entry",
                subMenuItems: [
                  if (!isBaseVersion &&
                      isControlEnabled(ref, 'btnAreaMaster') &&
                      hasPosFeature(ref, 'pos.areas'))
                    const PopupMenuItem<String>(
                      value: "Area Entry",
                      child: Text("Area Entry"),
                    ),
                  if (!isBaseVersion && hasPosFeature(ref, 'pos.tables'))
                    const PopupMenuItem<String>(
                        value: "Table Entry", child: Text("Table Entry")),
                  if (hasPosFeature(ref, 'pos.group_master'))
                    const PopupMenuItem<String>(
                        value: "Group Entry", child: Text("Group Entry")),
                  if (!isBaseVersion &&
                      hasPosFeature(ref, 'pos.subgroup_master'))
                    const PopupMenuItem<String>(
                        value: "Sub Group Entry",
                        child: Text("Sub Group Entry")),
                  if (hasPosFeature(ref, 'pos.product_master'))
                    const PopupMenuItem<String>(
                        value: "Product Entry", child: Text("Product Entry")),
                  if (!isBaseVersion) ...[
                    if (hasPosFeature(ref, 'pos.kitchen_message'))
                      const PopupMenuItem<String>(
                          value: "Kitchen Message",
                          child: Text("Kitchen Message")),
                    if (hasPosFeature(ref, 'pos.combo'))
                      const PopupMenuItem<String>(
                          value: "Combo", child: Text("Combo")),
                    if (hasPosFeature(ref, 'pos.recipe'))
                      const PopupMenuItem<String>(
                          value: "Recipe Entry", child: Text("Recipe Entry")),
                    if (hasPosFeature(ref, 'pos.barcode'))
                      const PopupMenuItem<String>(
                          value: "Barcode Print Utility",
                          child: Text("Barcode Print Utility")),
                    if (hasPosFeature(ref, 'pos.notes'))
                      const PopupMenuItem<String>(
                          value: "Notes Entry", child: Text("Notes Entry")),
                    if (hasPosFeature(ref, 'pos.online_orders'))
                      const PopupMenuItem<String>(
                          value: "Online Source Entry",
                          child: Text("Online Source Entry")),
                    if (hasPosFeature(ref, 'pos.mess'))
                      const PopupMenuItem<String>(
                          value: "Mess Master Entry",
                          child: Text("Mess Master Entry")),
                  ],
                ],
              ),
              const SizedBox(width: 20),
              buildMenuButton(
                context,
                "Edit",
                subMenuItems: [
                  if (!isBaseVersion) ...[
                    if (hasPosFeature(ref, 'pos.areas'))
                      const PopupMenuItem<String>(
                          value: "Area Edit", child: Text("Area Edit")),
                    if (hasPosFeature(ref, 'pos.tables'))
                      const PopupMenuItem<String>(
                          value: "Table Edit", child: Text("Table Edit")),
                  ],
                  if (hasPosFeature(ref, 'pos.group_master'))
                    const PopupMenuItem<String>(
                        value: "Group Edit", child: Text("Group Edit")),
                  if (!isBaseVersion &&
                      hasPosFeature(ref, 'pos.subgroup_master'))
                    const PopupMenuItem<String>(
                        value: "Sub Group Edit", child: Text("Sub Group Edit")),
                  if (hasPosFeature(ref, 'pos.product_master'))
                    const PopupMenuItem<String>(
                        value: "Product Edit", child: Text("Product Edit")),
                  if (!isBaseVersion) ...[
                    if (hasPosFeature(ref, 'pos.combo'))
                      const PopupMenuItem<String>(
                          value: "Combo Edit", child: Text("Combo Edit")),
                    if (hasPosFeature(ref, 'pos.recipe'))
                      const PopupMenuItem<String>(
                          value: "Recipe Edit", child: Text("Recipe Edit")),
                    if (hasPosFeature(ref, 'pos.mess'))
                      const PopupMenuItem<String>(
                          value: "Mess List", child: Text("Mess List")),
                  ],
                ],
              ),
              if (!isBaseVersion) const SizedBox(width: 20),
              if (!isBaseVersion &&
                  hasAnyPosFeature(ref, [
                    'pos.production',
                    'pos.purchase',
                    'pos.stock_reports',
                    'pos.stock_transfer',
                    'pos.sync_tools'
                  ]))
                buildMenuButton(
                  context,
                  "Transactions",
                  subMenuItems: [
                    if (hasPosFeature(ref, 'pos.production'))
                      PopupMenuItem<String>(
                        padding: EdgeInsets
                            .zero, // Remove default padding to make entire area clickable
                        child: PopupMenuButton<String>(
                          offset: const Offset(150, 0),
                          onSelected: (value) => _openDialog(context, value),
                          tooltip:
                              '', // Remove tooltip to avoid "Show menu" text
                          itemBuilder: (context) => [
                            if (hasPosFeature(ref, 'pos.production'))
                              const PopupMenuItem<String>(
                                  value: "Production Entry",
                                  child: Text("Entry")),
                            if (hasPosFeature(ref, 'pos.production'))
                              const PopupMenuItem<String>(
                                  value: "Production List",
                                  child: Text("List")),
                          ],
                          child: Container(
                            width: double.infinity, // Make it take full width
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Production"),
                                Icon(Icons.arrow_right,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (hasPosFeature(ref, 'pos.stock_reports'))
                      const PopupMenuItem<String>(
                          value: "Opening Stock Entry",
                          child: Text("Opening Stock Entry")),
                    if (hasPosFeature(ref, 'pos.stock_reports'))
                      const PopupMenuItem<String>(
                          value: "Stock Report", child: Text("Stock Report")),
                    if (hasPosFeature(ref, 'pos.stock_reports'))
                      const PopupMenuItem<String>(
                          value: "Movement Report",
                          child: Text("Movement Report")),
                    if (hasPosFeature(ref, 'pos.stock_transfer'))
                      PopupMenuItem<String>(
                        padding: EdgeInsets.zero,
                        child: PopupMenuButton<String>(
                          offset: const Offset(150, 0),
                          onSelected: (value) => _openDialog(context, value),
                          tooltip: '',
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                                value: "Product Request",
                                child: Text("Product Request")),
                            const PopupMenuItem<String>(
                                value: "Product Receipt",
                                child: Text("Product Receipt")),
                            const PopupMenuItem<String>(
                                value: "Product Transfer",
                                child: Text("Product Transfer")),
                            const PopupMenuItem<String>(
                                value: "Transfer List",
                                child: Text("Transfer List")),
                            const PopupMenuItem<String>(
                                value: "Receipt List",
                                child: Text("Receipt List")),
                          ],
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Product Transfer/Receive"),
                                Icon(Icons.arrow_right,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (hasPosFeature(ref, 'pos.sync_tools'))
                      PopupMenuItem<String>(
                        padding: EdgeInsets.zero,
                        child: PopupMenuButton<String>(
                          offset: const Offset(150, 0),
                          onSelected: (value) => _openDialog(context, value),
                          tooltip: '',
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                                value: "Upload To Main Server",
                                child: Text("Upload To Main Server")),
                            const PopupMenuItem<String>(
                                value: "Download New Items from main server",
                                child: Text(
                                    "Download New Items from main server")),
                          ],
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Upload/Download"),
                                Icon(Icons.arrow_right,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (hasPosFeature(ref, 'pos.purchase'))
                      PopupMenuItem<String>(
                        padding: EdgeInsets.zero,
                        child: PopupMenuButton<String>(
                          offset: const Offset(150, 0),
                          onSelected: (value) => _openDialog(context, value),
                          tooltip: '',
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: "Supplier List",
                              child: Text("Supplier List"),
                            ),
                            const PopupMenuItem<String>(
                              value: "Purchase Entry",
                              child: Text("Purchase Entry"),
                            ),
                            const PopupMenuItem<String>(
                              value: "Purchase List",
                              child: Text("Purchase List"),
                            ),
                            const PopupMenuItem<String>(
                              value: "Purchase Return",
                              child: Text("Purchase Return"),
                            ),
                            const PopupMenuItem<String>(
                              value: "Purchase Return List",
                              child: Text("Purchase Return List"),
                            ),
                          ],
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Purchase"),
                                Icon(Icons.arrow_right,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(width: 20),
              buildMenuButton(
                context,
                "Reports",
                subMenuItems: [
                  const PopupMenuItem<String>(
                      value: "Bill Reprint", child: Text("Bill Reprint")),
                  const PopupMenuItem<String>(
                      value: "Counter Close", child: Text("Counter Close")),
                  if (!isBaseVersion)
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      child: PopupMenuButton<String>(
                        offset: const Offset(150, 0),
                        onSelected: (value) => _openDialog(context, value),
                        tooltip: '',
                        itemBuilder: (context) => [
                          if (hasPosFeature(ref, 'pos.areas'))
                            const PopupMenuItem<String>(
                                value: "Area Wise Report",
                                child: Text("Area Wise Report")),
                          if (hasPosFeature(ref, 'pos.counter_reports'))
                            const PopupMenuItem<String>(
                                value: "Group Wise", child: Text("Group Wise")),
                          if (hasPosFeature(ref, 'pos.counter_reports'))
                            const PopupMenuItem<String>(
                                value: "Item Wise", child: Text("Item Wise")),
                          if (hasPosFeature(ref, 'pos.void_bill'))
                            const PopupMenuItem<String>(
                                value: "Item Void Report",
                                child: Text("Item Void Report")),
                          if (hasPosFeature(ref, 'pos.void_bill'))
                            const PopupMenuItem<String>(
                                value: "Cancel Bill Details",
                                child: Text("Cancel Bill Details")),
                          if (hasPosFeature(ref, 'pos.void_bill'))
                            const PopupMenuItem<String>(
                                value: "Cancel Bill Summary",
                                child: Text("Cancel Bill Summary")),
                          if (hasPosFeature(ref, 'pos.counter_reports'))
                            const PopupMenuItem<String>(
                                value: "Counter Close Reports",
                                child: Text("Counter Close Reports")),
                          if (hasPosFeature(ref, 'pos.advanced_reports'))
                            const PopupMenuItem<String>(
                                value: "Sales Bill Wise",
                                child: Text("Sales Bill Wise")),
                          if (hasPosFeature(ref, 'pos.counter_reports'))
                            const PopupMenuItem<String>(
                                value: "Day Wise", child: Text("Day Wise")),
                        ],
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Reports Reciept Printer"),
                              Icon(Icons.arrow_right,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!isBaseVersion)
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      child: PopupMenuButton<String>(
                        offset: const Offset(150, 0),
                        onSelected: (value) => _openDialog(context, value),
                        tooltip: '',
                        itemBuilder: (context) => [
                          if (hasPosFeature(ref, 'pos.counter_reports'))
                            const PopupMenuItem<String>(
                                value: "Sales Viewer",
                                child: Text("Sales Viewer")),
                          if (hasPosFeature(ref, 'pos.vat_reports'))
                            const PopupMenuItem<String>(
                                value: "Sales Vat Report",
                                child: Text("Sales Vat Report")),
                          if (hasPosFeature(ref, 'pos.areas'))
                            const PopupMenuItem<String>(
                                value: "Area Wise ReportSummary",
                                child: Text("Area Wise Report/Summary")),
                        ],
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Report A4"),
                              Icon(Icons.arrow_right,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!isBaseVersion && hasPosFeature(ref, 'pos.report_export'))
                    const PopupMenuItem<String>(
                        value: "Report View", child: Text("Report View")),
                ],
              ),
              if (!isBaseVersion) const SizedBox(width: 20),
              if (!isBaseVersion && hasPosFeature(ref, 'pos.credit'))
                buildMenuButton(
                  context,
                  "Credit",
                  subMenuItems: [
                    const PopupMenuItem<String>(
                        value: "Advance Payment",
                        child: Text("Advance Payment")),
                    const PopupMenuItem<String>(
                        value: "Credit Payment Reciept",
                        child: Text("Credit Payment Reciept")),
                    const PopupMenuItem<String>(
                        value: "Payment List", child: Text("Payment List")),
                    const PopupMenuItem<String>(
                        value: "OS Balance List",
                        child: Text("OS Balance List")),
                    const PopupMenuItem<String>(
                        value: "Reciept List", child: Text("Reciept List")),
                    const PopupMenuItem<String>(
                        value: "Advance Viewer", child: Text("Advance Viewer")),
                    if (hasPosFeature(ref, 'pos.mess'))
                      const PopupMenuItem<String>(
                          value: "Mess Bill Viewer",
                          child: Text("Mess Bill Viewer")),
                  ],
                ),
              const SizedBox(width: 20),
              buildMenuButton(
                context,
                "Admin",
                subMenuItems: [
                  const PopupMenuItem<String>(
                      value: "Counter Close - Admin",
                      child: Text("Counter Close - Admin")),
                  if (!isBaseVersion)
                    if (hasPosFeature(ref, 'pos.day_close'))
                      const PopupMenuItem<String>(
                          value: "Day Close Report",
                          child: Text("Day Close Report")),
                  if (!isBaseVersion &&
                      hasPosFeature(ref, 'pos.cashier_change'))
                    const PopupMenuItem<String>(
                        value: "Cashier Change", child: Text("Cashier Change")),
                  const PopupMenuItem<String>(
                      value: "Clear KOT", child: Text("Clear KOT")),
                  if (!isBaseVersion) ...[
                    if (hasPosFeature(ref, 'pos.cash_in_out'))
                      const PopupMenuItem<String>(
                          value: "Income OR Expenses",
                          child: Text("Income OR Expenses")),
                    const PopupMenuItem<String>(
                        value: "Shut Down", child: Text("Shut Down")),
                    if (hasPosFeature(ref, 'pos.discount'))
                      const PopupMenuItem<String>(
                          value: "Discount Entry",
                          child: Text("Discount Entry")),
                    if (hasPosFeature(ref, 'pos.discount'))
                      const PopupMenuItem<String>(
                          value: "Discount List", child: Text("Discount List")),
                    if (hasPosFeature(ref, 'pos.settlement.change'))
                      const PopupMenuItem<String>(
                          value: "Change Settlement",
                          child: Text("Change Settlement")),
                    if (hasPosFeature(ref, 'pos.vat'))
                      const PopupMenuItem<String>(
                          value: "VAT Activation",
                          child: Text("VAT Activation")),
                    const PopupMenuItem<String>(
                        value: "Product List Edit",
                        child: Text("Product List Edit")),
                    if (hasPosFeature(ref, 'pos.kds'))
                      const PopupMenuItem<String>(
                          value: "KDS Refresh", child: Text("KDS Refresh")),
                    if (hasPosFeature(ref, 'pos.discount.admin'))
                      const PopupMenuItem<String>(
                          value: "Change Discount % Button",
                          child: Text("Change Discount % Button")),
                  ],
                ],
              ),
              const SizedBox(width: 20),
              buildMenuButton(
                context,
                "Settings",
                subMenuItems: [
                  const PopupMenuItem<String>(
                      value: "Printer Setup", child: Text("Printer Setup")),
                  const PopupMenuItem<String>(
                      value: "User List", child: Text("User List")),
                  if (!isBaseVersion) ...[
                    if (hasPosFeature(ref, 'pos.privilege_setup'))
                      const PopupMenuItem<String>(
                          value: "Privillage Setup",
                          child: Text("Privillage Setup")),
                    if (hasPosFeature(ref, 'pos.settings'))
                      const PopupMenuItem<String>(
                          value: "Control Panel", child: Text("Control Panel")),
                    if (hasPosFeature(ref, 'pos.language_setup'))
                      const PopupMenuItem<String>(
                          value: "Language Setup",
                          child: Text("Language Setup")),
                    if (hasPosFeature(ref, 'pos.multi_supplier'))
                      const PopupMenuItem<String>(
                          value: "Multi Supplier Setup",
                          child: Text("Multi Supplier Setup")),
                    if (hasPosFeature(ref, 'pos.vat'))
                      const PopupMenuItem<String>(
                          value: "Disable VAT", child: Text("Disable VAT")),
                    if (hasPosFeature(ref, 'pos.vat'))
                      const PopupMenuItem<String>(
                          value: "Utility For VAT Correction",
                          child: Text("Utility For VAT Correction")),
                  ],
                ],
              ),
              const SizedBox(width: 20),
              buildMenuButton(
                context,
                "Logout",
                subMenuItems: [
                  const PopupMenuItem<String>(
                      value: "Logout", child: Text("Logout")),
                  const PopupMenuItem<String>(
                      value: "EXIT", child: Text("EXIT")),
                ],
              ),
            ],
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () async {
                final wm = WindowManager.instance;
                await wm.ensureInitialized();
                try {
                  if (await wm.isFullScreen()) {
                    await wm.setFullScreen(false);
                  }
                  await wm.minimize();
                } catch (e) {
                  debugPrint('Minimize error: $e');
                }
              },
              child: const SizedBox.expand(),
            ),
          ),
          _buildWaiterNameChip(context),
          _buildRefreshFeaturesButton(context, ref),
          _buildVersionChip(context, ref),
        ],
      ),
    );
  }
}
