# RestaurantPOS — agent instructions

## Commands

```sh
flutter analyze            # lint + typecheck (prefer before any commit)
dart format .              # format all Dart files
flutter build windows      # Windows desktop release (main target)
flutter build apk          # Android build
```

No test directory or test files exist (`flutter test` has nothing to run). No code generation (`build_runner`, `freezed`, `json_serializable`). No CI.

## Startup flow

`main()` → `Hive.initFlutter()` → `SessionStorage.loadSession()` → `UpdateGate` → if valid session: `SessionBootstrapWrapper` (fetches params+privileges from API) → `HomeScreen`; else: `MainLoginPage`.

## State management

`flutter_riverpod` 2.6.1 — all state set programmatically via `ref.notifier.state = value`. No `StateNotifier`/`NotifierProvider`. Riverpod providers live in `lib/core/providers/`:
- `providers.dart` — core POS state (products, cart, KOT, selection)
- `parameterProviders.dart` — backend parameters (tax1, currency, privileges, limits)
- `api_service_provider.dart` — API service (real vs mock)
- `session_bootstrap_provider.dart` — startup data fetch
- `update_provider.dart` — update check chain

## Feature gating

All UI flags are `pos.<feature>` string codes defined in `lib/entitlements/pos_features.dart`. Checked via `hasPosFeature(ref, code)` / `PosUiFeatures(ref)`. `privilege_utils.dart` has helpers: `isControlEnabled()`, `isBasePosUi()`, `isSubscriptionUsable()`.

## API / mock toggle

`lib/config/api_config.dart`:
- `useMockData = true` — uses `MockApiService` (1380-line mock data) vs real API at `baseURL` (default `http://192.168.1.144:5010`)
- `ApiService` uses the unified HMS backend API (login, parameters, privileges, groups, areas, sub-groups, products, tables, KOT save/list, settlement)

## Printing architecture

- **Windows native GDI** (default on Windows): platform channel `com.myapp/native_settlement_print` → C++ code. Enabled via `useWindowsNativeSettlementPrint`, `useWindowsNativeSalesReceiptPrint`, `useWindowsNativeKOTPrint` flags.
- **Android** (Sunmi + thermal): `PosPrint` → `AndroidEscPosSender`. Prefers Sunmi built-in (`sunmi_printer_plus`), then network IP (`receiptPrinterIP:9100`), then USB whose name contains `counter` / `innerprinter` / `sunmi`. Flags: `useAndroidPrinting`, `preferSunmiBuiltInPrinter`.
- **Thermal ESC/POS** (shared builders): `SettlementReceiptPrinter` / `KotReceiptPrinter` using `thermal_printer` for non-Sunmi Android and legacy USB/network.
- **Web**: `dart:html` via `receipt_printer_web_impl.dart`.
- Printer names go in `settlementPrintPrinterNameWindows` / `kotPrintPrinterNameWindows`.
- Call sites should use `lib/services/printService/pos_print.dart` (`PosPrint.printSettlement` / `printSalesReceipt` / `printKOT`).

## Session

`SessionManager` singleton (in-memory) + `SessionStorage` (SharedPreferences JSON). Restored in `main()` before app startup. Valid session requires non-empty `stationId`, `staffName`, `staffID`.

## Routing

No routing package. Imperative `Navigator.pushReplacement(MaterialPageRoute(...))`.

## Known quirks

- Keyboard assertion errors suppressed in `main.dart` (Alt key + hot restart). Saw the error? Release Alt.
- `prefer_const_literals_to_create_immutables: ignore` in `analysis_options.yaml`.
- `TextScaler.linear(1.0)` forced in `MaterialApp.builder` — do NOT force `devicePixelRatio = 1.0`, it breaks Windows HiDPI.
- No `test/` directory exists.
- Standard flutter_lints, no extra strictness.

## Existing instruction files

`.github/instructions/kluster-code-verify.instructions.md` — auto-review tool (run after any file change). Not part of normal workflow but may be enforced by the environment.

## Key files

| File | Purpose |
|---|---|
| `lib/main.dart` | Entry, Hive init, session restore, keyboard error suppression |
| `lib/config/api_config.dart` | Mock/real toggle, API URL, printer config |
| `lib/entitlements/pos_features.dart` | All feature flag code constants |
| `lib/utils/privilege_utils.dart` | Feature/permission check helpers |
| `lib/services/api_service.dart` | Real API client |
| `lib/services/mock_api_service.dart` | Mock data (development offline) |
| `lib/core/providers/providers.dart` | Core Riverpod state |
| `lib/screens/home_screen.dart` | Main POS layout (left cart, center groups, right products) |
| `installers/iss.iss` | Inno Setup for Windows installer |
