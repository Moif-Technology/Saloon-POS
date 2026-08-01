// lib/config/api_config.dart

/// Mock mode. Defaults to FALSE so a mock build can never ship by accident.
/// Turn it on per-run without editing source:
///     flutter run --dart-define=MOCK=true
const bool useMockData = bool.fromEnvironment('MOCK', defaultValue: false);

/// API host. Override per-run without editing source:
///     flutter run --dart-define=API_BASE=http://192.168.1.55:5010
/// Production is https://api.moifone.com
const String baseURL = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost:5010',
);

/// Base path for this POS product. Salon endpoints are under /api/salon-pos;
/// restaurant's are under /api/pos. Kept in one place so switching product is
/// not a hunt for string literals across api_service.dart.
const String posBasePath = '/api/salon-pos';

/// Legacy HMS toggle (kept for reference). **`ApiService` now uses the unified API only** for
/// login, POS parameters, privileges list, groups, areas, and sub-groups; other features are
/// in-memory stubs until migrated.
///

/// Receipt (counter) printer: network by IP or USB by name "counter".
/// If set, use network printer at this IP (port receiptPrinterPort).
/// If empty, use USB discovery and select printer whose name contains "counter".
const String receiptPrinterIP = ""; // e.g. "192.168.1.100" for network printer
const int receiptPrinterPort = 9100;

/// Android printing (settlement / sales receipt / KOT).
/// Uses Sunmi built-in when present, else network IP, else USB ("counter" / "innerprinter").
const bool useAndroidPrinting = true;

/// Prefer Sunmi inner printer on Android when the device exposes one.
const bool preferSunmiBuiltInPrinter = true;

/// When true (Windows only), settlement receipt is printed via Windows GDI (same as VB: Courier New, same layout).
/// Requires Windows; ignored on other platforms. Set settlementPrintPrinterNameWindows to target a specific printer, or leave empty for default.
const bool useWindowsNativeSettlementPrint = true;

/// Windows native settlement print: printer name (e.g. "XP-N160I" or "Receipt Printer").
/// Set to your thermal printer's exact name as shown in Windows (Settings → Printers).
/// Empty = use Windows default printer (only when useMicrosoftPrintToPdfForSettlement is false).
const String settlementPrintPrinterNameWindows = "";

/// When true, always use "Microsoft Print to PDF" for settlement (e.g. when no printer connected).
const bool useMicrosoftPrintToPdfForSettlement = false;

/// When true (Windows only), sales receipt (reprint from Sales Viewer) uses Windows native GDI
/// (physical thermal or Microsoft Print to PDF), same layout as settlement.
const bool useWindowsNativeSalesReceiptPrint = true;

/// Printer name for sales receipt reprint. Empty = use settlement printer.
const String salesReceiptPrintPrinterNameWindows = '';

/// When true (Windows only), KOT (Save KOT / Print KOT) uses Windows native GDI.
const bool useWindowsNativeKOTPrint = true;

/// Printer name for KOT. Set to your thermal printer name (same as in Windows). Empty = use settlement printer, then Windows default.
const String kotPrintPrinterNameWindows = '';

/// When true, use "Microsoft Print to PDF" for KOT (e.g. when no kitchen printer).
const bool useMicrosoftPrintToPdfForKOT = false;

/// POS uses one normal layout. Subscription features show/hide individual
/// panels, buttons, fields, and workflows inside that layout.
