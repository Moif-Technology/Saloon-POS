import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/entitlements/pos_features.dart';
import 'package:my_app/widgets/center_panel.dart';
import 'package:my_app/widgets/footer.dart';
import 'package:my_app/widgets/left_panel.dart';
import 'package:my_app/widgets/right_panel.dart';
import 'package:my_app/widgets/table_selection_dialog.dart';
import 'package:my_app/widgets/top_bar.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/kot_reset_utils.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/utils/privilege_utils.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  static const bool kOpenTableDialogFromHome = true;
  static const String _kLeftPanelWidthKey = 'left_panel_width';
  static const String _kBaseLeftPanelWidthKey = 'base_left_panel_width';
  // ===== cart shared across panels =====
  List<Map<String, String>> selectedProducts = [];

  // ===== area / table / seat state =====
  bool showTables = false;
  String? selectedAreaId;
  String? selectedAreaName;

  String? selectedTableId;
  String? selectedSeatNo;

  // ===== customer state =====
  String? selectedCustomerId;
  String? selectedCustomerName;

  // layout
  double? leftPanelWidth;
  double? baseLeftPanelWidth; // Base version: cart width (resizable)
  double? _tempSavedWidth; // Full version: saved width before clamping
  double? _tempSavedBaseWidth; // Base version: saved cart width
  final double centerPanelFixedWidth = 118;
  int _kotResetCount = 0;
  bool _isRefocusingWindow = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      windowManager.addListener(this);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        maximizeWindow();
        // After hot restart the IDE may have stolen focus; retry at
        // staggered intervals to reclaim it.
        _scheduleRefocus();
      });
    }
    _loadLayoutPrefs();
  }

  void _scheduleRefocus() {
    Future.delayed(const Duration(milliseconds: 300), _refocusOnce);
    Future.delayed(const Duration(milliseconds: 800), _refocusOnce);
    Future.delayed(const Duration(seconds: 2), _refocusOnce);
  }

  void _refocusOnce() {
    if (!mounted) return;
    try {
      windowManager.focus();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowRestore() {
    if (kIsWeb) return;
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      await windowManager.setFullScreen(true);
      await _refocusAfterFullScreen();
    });
  }

  @override
  void onWindowFocus() {
    // Do not call windowManager.focus() from this callback. On Windows that can
    // trigger another focus event and keep rebuilding the POS while the user is
    // trying to click buttons.
  }

  /// Ensures the window has focus after full screen so buttons and input work on Windows.
  Future<void> _refocusAfterFullScreen() async {
    if (kIsWeb) return;
    if (!mounted) return;
    if (_isRefocusingWindow) return;
    _isRefocusingWindow = true;
    try {
      await windowManager.focus();
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      await windowManager.focus();
    } catch (_) {
    } finally {
      _isRefocusingWindow = false;
    }
  }

  Future<void> maximizeWindow() async {
    if (kIsWeb) return;
    try {
      await windowManager.ensureInitialized();
      // Allow full screen by relaxing constraints set on login (e.g. min 1000x700).
      await windowManager.setMinimumSize(const Size(1, 1));
      await windowManager.setMaximumSize(const Size(4096, 4096));
      // Short delay so the first frame is laid out before we resize to full screen.
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      await windowManager.setFullScreen(true);
    } catch (e) {
      debugPrint('maximizeWindow error: $e');
    }
    await _refocusAfterFullScreen();
  }

  Future<void> _loadLayoutPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_kLeftPanelWidthKey);
      if (saved != null && saved >= 280 && saved <= 1200 && mounted) {
        setState(() => _tempSavedWidth = saved);
      }
      final savedBase = prefs.getDouble(_kBaseLeftPanelWidthKey);
      if (savedBase != null &&
          savedBase >= 280 &&
          savedBase <= 1200 &&
          mounted) {
        setState(() => _tempSavedBaseWidth = savedBase);
      }
    } catch (_) {}
  }

  Future<void> _saveLeftPanelWidth(double width) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLeftPanelWidthKey, width);
    } catch (_) {}
  }

  Future<void> _saveBaseLeftPanelWidth(double width) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kBaseLeftPanelWidthKey, width);
    } catch (_) {}
  }

  /// Left panel: simple container with animated width. This is close to the old
  /// behaviour the user liked; only the width changes on drag.
  Widget _buildLeftPanel(double width, bool isBaseVersion) {
    final decoration = BoxDecoration(
      color: Colors.grey.shade50,
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
    );
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: decoration,
        child: PosLeftPanel(
          key: ValueKey('left_$_kotResetCount'),
          selectedProducts: selectedProducts,
          onTableSelected: _onTableSelected,
          onAreaSelected: _onAreaSelected,
          onKotReset: _onKotReset,
          isBaseVersion: isBaseVersion,
        ),
      ),
    );
  }

  Future<TableSeatSelection?> _openTableDialog({
    String? initialAreaId,
    String? initialAreaName,
  }) {
    return showDialog<TableSeatSelection>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TableSelectionDialog(
        initialAreaId: initialAreaId,
        initialAreaName: initialAreaName,
      ),
    );
  }

  void _onTableSelected(bool isSelected, {String? areaId}) {
    if (kOpenTableDialogFromHome && isSelected) {
      setState(() {
        selectedAreaId = areaId;
      });

      _openTableDialog(
        initialAreaId: areaId,
        initialAreaName: selectedAreaName,
      ).then((result) {
        if (!mounted) return;

        if (result == null) {
          setState(() {
            showTables = true;
          });
        } else {
          setState(() {
            showTables = false;
            selectedAreaId = result.areaId ?? selectedAreaId;
            selectedAreaName = result.areaName ?? selectedAreaName;
            selectedTableId = result.tableId;
            selectedSeatNo = result.seatNo?.toString();
          });

          final container = ProviderScope.containerOf(context);
          container.read(selectedAreaIdProvider.notifier).state =
              selectedAreaId;
          container.read(selectedAreaNameProvider.notifier).state =
              selectedAreaName;
          container.read(selectedTableIdProvider.notifier).state =
              selectedTableId;
          container.read(selectedSeatNoProvider.notifier).state =
              selectedSeatNo;
        }
      });
    } else {
      setState(() {
        showTables = isSelected;
        selectedAreaId = areaId;
      });

      final container = ProviderScope.containerOf(context);
      container.read(selectedAreaIdProvider.notifier).state = selectedAreaId;
    }
  }

  void _onAreaSelected(String areaId, String areaName) {
    setState(() {
      selectedAreaId = areaId;
      selectedAreaName = areaName;
      selectedProducts.clear();
    });

    final container = ProviderScope.containerOf(context);
    container.read(kotDetailsProvider.notifier).state = {};
    container.read(activeKotProvider.notifier).state = {};
    container.read(isUpdatingFromOrderListProvider.notifier).state = false;
    container.read(selectedQtyProvider.notifier).state = "1";
    container.read(selectedAreaIdProvider.notifier).state = areaId;
    container.read(selectedAreaNameProvider.notifier).state = areaName;
  }

  void _resetSelectedProducts() {
    setState(() {
      selectedProducts.clear();
    });
    if (mounted) {
      ProviderScope.containerOf(context)
          .read(cartSnapshotProvider.notifier)
          .state = [];
    }
  }

  void _onCustomerSelected(String? id, String? name) {
    setState(() {
      selectedCustomerId = id;
      selectedCustomerName = name;
    });
  }

  void _onKotReset() {
    final container = ProviderScope.containerOf(context);
    clearKotStateForNewOrder(container);
    setState(() {
      selectedProducts.clear();
      selectedAreaId = null;
      selectedAreaName = null;
      selectedTableId = null;
      selectedSeatNo = null;
      showTables = false;
      _kotResetCount++;
    });
  }

  Widget _buildSubscriptionBlocked(Map<String, dynamic> subscription) {
    final status = (subscription['status'] as String?) ?? 'expired';
    return Scaffold(
      backgroundColor: const Color(0xfff8f8ff),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Subscription ${status.toUpperCase()}',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'POS access is blocked. Please contact billing/support to reactivate.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final subscription = ref.watch(subscriptionProvider);
        if (subscription != null && subscription['isUsable'] == false) {
          return _buildSubscriptionBlocked(subscription);
        }
        final isBaseVersion = isBasePosUi(ref);
        final showCenterPanel = PosUiFeatures(ref).groupsPanel;
        return _buildHome(context, isBaseVersion, showCenterPanel);
      },
    );
  }

  Widget _buildHome(
      BuildContext context, bool isBaseVersion, bool showCenterPanel) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8ff),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: TopBar(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Right panel needs at least 320px to show keypad + products
          const double minRightPanel = 320.0;
          final maxAllowed = isBaseVersion
              ? constraints.maxWidth - minRightPanel
              : constraints.maxWidth -
                  (showCenterPanel ? centerPanelFixedWidth : 0) -
                  200;
          final maxWidth = isBaseVersion
              ? constraints.maxWidth -
                  minRightPanel // can go up to ~full width minus right panel min
              : constraints.maxWidth * 0.6;

          // Base: resizable cart (like full); Full: resizable
          final effectiveWidth = isBaseVersion
              ? (baseLeftPanelWidth ??
                  (_tempSavedBaseWidth != null
                      ? _tempSavedBaseWidth!.clamp(280.0, maxAllowed)
                      : 380.0.clamp(280.0, maxAllowed)))
              : (leftPanelWidth ??
                  (_tempSavedWidth != null
                      ? _tempSavedWidth!.clamp(340.0, maxAllowed)
                      : (constraints.maxWidth * 0.38)
                          .clamp(340.0, maxAllowed)));
          final currentWidth = effectiveWidth.clamp(260.0, maxWidth);

          return SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // left
                    _buildLeftPanel(currentWidth, isBaseVersion),

                    // resizer (between cart and product area - both base and full)
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            if (isBaseVersion) {
                              baseLeftPanelWidth =
                                  ((baseLeftPanelWidth ?? currentWidth) +
                                          details.delta.dx)
                                      .clamp(220.0, maxWidth);
                            } else {
                              leftPanelWidth =
                                  ((leftPanelWidth ?? currentWidth) +
                                          details.delta.dx)
                                      .clamp(220.0, maxWidth);
                            }
                          });
                        },
                        onHorizontalDragEnd: (_) {
                          final widthToSave = isBaseVersion
                              ? (baseLeftPanelWidth ?? currentWidth)
                              : (leftPanelWidth ?? currentWidth);
                          if (isBaseVersion) {
                            _saveBaseLeftPanelWidth(widthToSave);
                          } else {
                            _saveLeftPanelWidth(widthToSave);
                          }
                        },
                        child: Container(width: 4, color: Colors.grey[300]),
                      ),
                    ),

                    // center (full version only)
                    if (!isBaseVersion && showCenterPanel)
                      Container(
                        width: centerPanelFixedWidth,
                        color: Colors.grey.shade300,
                        child: CenterPanel(),
                      ),

                    // right (fills remaining)
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          return RightPanel(
                            key: ValueKey('right_$_kotResetCount'),
                            isBaseVersion: isBaseVersion,
                            onProductSelected: (product) {
                              setState(() {
                                final int selectedQty = int.tryParse(
                                        ref.read(selectedQtyProvider)) ??
                                    1;

                                final existingIndex =
                                    selectedProducts.indexWhere(
                                  (item) =>
                                      item["ProductID"] == product["ProductID"],
                                );

                                final isReturn = ref.read(returnModeProvider);
                                ref
                                    .read(lastReturnModeProvider.notifier)
                                    .state = isReturn;

                                if (existingIndex != -1) {
                                  int currentQty = int.tryParse(
                                          selectedProducts[existingIndex]
                                                  ["quantity"] ??
                                              "1") ??
                                      1;

                                  selectedProducts[existingIndex]["quantity"] =
                                      (currentQty + selectedQty).toString();
                                } else {
                                  product["quantity"] = selectedQty.toString();
                                  product["isReturn"] =
                                      isReturn ? "true" : "false";
                                  selectedProducts.add(product);
                                }

                                ref.read(selectedQtyProvider.notifier).state =
                                    "1";
                                ref.invalidate(returnModeProvider);
                                // Sync cart so Save KOT / Settlement see the items
                                ref.read(cartSnapshotProvider.notifier).state =
                                    List<Map<String, String>>.from(
                                        selectedProducts);
                              });
                            },
                            onResetProducts: _resetSelectedProducts,
                            onKotReset: _onKotReset,
                            onAreaSelected: _onAreaSelected,
                            onTableSelected: _onTableSelected,
                            showTables: showTables,
                            areaId: selectedAreaId,
                            areaName: selectedAreaName,
                            selectedTableId: selectedTableId,
                            selectedSeatNo: selectedSeatNo,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Footer(),
    );
  }
}
