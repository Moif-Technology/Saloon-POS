# App Versioning & Update System – What Was Done, How to Test, and File/Function Reference

---

## Part 1: What Was Done (Summary)

### Backend (Node.js + Express + PostgreSQL)

1. **Database**
   - New table `app_update_config`: one row per platform (`windows`, `android`, `web`) with latest version, minimum supported version, update mode (`none`/`optional`/`mandatory`), title, message, changelog, update URL, release date, enabled flag, maintenance mode, and timestamps.
   - Seed data for all three platforms at version 1.0.0 with `update_mode = 'none'`.

2. **Version comparison**
   - Utility that compares semantic versions correctly (e.g. 1.0.9 < 1.0.10). Supports optional build suffix (e.g. 1.0.0+1).

3. **Update API**
   - Public endpoint **GET/POST `/api/app/check-update`** (no login). Accepts `platform`, `current_version`, optional `build_number`. Returns whether an update is available, optional/mandatory, maintenance, and all display fields (title, message, changelog, update_url, etc.).

4. **App wiring**
   - New route mounted in `index.js` so the app serves the update check.

### Flutter (MOIF POS)

1. **Model**
   - `AppUpdateResponse` that mirrors the API response (updateAvailable, blockApp, reason, title, message, changelog, updateUrl, maintenanceMode, etc.) and helpers like `shouldBlock`, `canDefer`, `upToDate`.

2. **Update service**
   - Calls the backend `/api/app/check-update` with the current app version from `package_info_plus` and platform (windows/android/web via conditional import so web doesn’t use `dart:io`).

3. **State (Riverpod)**
   - `updateServiceProvider`, `appPackageInfoProvider` (version/build from package), `updateCheckResultProvider` (runs the update check when the gate is shown).

4. **Update UI (platform-aware)**
   - **Maintenance:** full-screen message + Retry.
   - **Mandatory update:** full-screen “Update required” with changelog and “Update now”.
   - **Optional (Windows):** compact modal with Update / Later.
   - **Optional (Android):** larger, touch-friendly dialog with Update / Later.
   - **Optional (Web):** top bar with “Refresh” / “Later”.
   - **No update:** no extra UI.
   - **Update check failed:** small banner with Retry (app still proceeds).

5. **Update launcher**
   - Opens `update_url` in browser (Windows/Android). On web, “Update” triggers a full page reload.

6. **Update gate (startup)**
   - `UpdateGate` wraps the first screen (login or session restore). It runs the update check once, then:
   - **Loading:** shows “Checking for updates...”.
   - **Error:** shows retry banner and still shows the app (no block).
   - **Block (maintenance or mandatory):** shows full-screen update/maintenance UI; user cannot proceed until they update or maintenance ends.
   - **Optional:** shows dialog (Windows/Android) or bar (Web) with Update / Later; “Later” dismisses and shows the app.

7. **Dependencies**
   - `package_info_plus`, `url_launcher` added in `pubspec.yaml`.

---

## Part 2: How to Test Versioning and UI

### Prerequisites

1. **Database**
   - Run the SQL script once (use your DB name/user):
     ```bash
     psql -U postgres -d moif_inventory -f database/app_update_config_create.sql
     ```
     Or run the contents of `backend/database/app_update_config_create.sql` in your SQL client.

2. **Backend**
   - Start the API (e.g. `node index.js` or your usual command). Ensure it listens on the same host/port as in Flutter’s `api_config.dart` (e.g. `http://localhost:5002`).

3. **Flutter**
   - From `AdminMainDesktop`: run `flutter pub get`.

---

### Test 1: No update (current behavior by default)

- App and DB both at 1.0.0, `update_mode = 'none'`.
- **Expected:** Short “Checking for updates...” then login or home. No dialog, no bar.

---

### Test 2: Optional update (dialog / bar)

**Backend:** Set a *newer* version and optional mode for your platform, e.g. for Windows:

```sql
UPDATE public.app_update_config
SET latest_version = '1.0.1',
    update_mode = 'optional',
    title = 'Update available',
    message = 'Version 1.0.1 is available with improvements.',
    changelog = '- Bug fixes\n- Performance improvements',
    update_url = 'https://example.com/download'
WHERE platform = 'windows';
```

- Keep app at 1.0.0 (from `pubspec.yaml`).
- Run the app (Windows desktop or Android).
- **Expected:**
  - **Windows:** Modal dialog “Update available”, Version 1.0.1, message, changelog, **Update** and **Later**. Tapping “Later” closes the dialog and shows login/home.
  - **Android:** Same but larger, touch-friendly dialog.
  - **Web:** Blue bar at top with “Refresh” and “Later”; “Later” hides the bar and shows the app.

---

### Test 3: Mandatory update (block)

```sql
UPDATE public.app_update_config
SET latest_version = '1.0.1',
    update_mode = 'mandatory',
    title = 'Update required',
    message = 'You must update to continue.'
WHERE platform = 'windows';
```

- App still at 1.0.0.
- **Expected:** Full-screen “Update required” with “Update now”. No way to proceed; tapping “Update now” opens `update_url` in the browser.

---

### Test 4: Maintenance mode (block)

```sql
UPDATE public.app_update_config
SET maintenance_mode = true,
    maintenance_message = 'We are performing scheduled maintenance. Please try again in 30 minutes.'
WHERE platform = 'windows';
```

- **Expected:** Full-screen “Maintenance” with the message and a “Retry” button. App is blocked until you set `maintenance_mode = false` and user retries.

---

### Test 5: Update check failure (network / server down)

- Stop the backend or disconnect network.
- **Expected:** “Checking for updates...” then “Could not check for updates” banner with “Retry”, and the app still shows (login or home). No block.

---

### Test 6: API directly (curl / Postman)

```bash
# Optional: GET
curl "http://localhost:5002/api/app/check-update?platform=windows&current_version=1.0.0&build_number=1"

# Or POST
curl -X POST "http://localhost:5002/api/app/check-update" \
  -H "Content-Type: application/json" \
  -d '{"platform":"windows","current_version":"1.0.0","build_number":1}'
```

- Inspect JSON: `update_available`, `block_app`, `reason`, `latest_version`, `update_mode`, `title`, `message`, `changelog`, `update_url`, `maintenance_mode`, etc.

---

### Resetting after tests

To go back to “no update” for Windows:

```sql
UPDATE public.app_update_config
SET latest_version = '1.0.0',
    minimum_supported_version = '1.0.0',
    update_mode = 'none',
    maintenance_mode = false,
    message = 'You are on the latest version.'
WHERE platform = 'windows';
```

Repeat for `android` / `web` if you changed them.

---

## Part 3: File-by-File and Function-by-Function

### Backend

---

#### `backend/database/app_update_config_create.sql`

| What it does |
|--------------|
| Creates table `app_update_config` with columns: `id`, `platform` (windows/android/web), `latest_version`, `minimum_supported_version`, `update_mode` (none/optional/mandatory), `title`, `message`, `changelog`, `update_url`, `release_date`, `is_enabled`, `maintenance_mode`, `maintenance_message`, `created_at`, `updated_at`. |
| Adds indexes on `platform` and `is_enabled`. |
| Inserts one row per platform (windows, android, web) with version 1.0.0 and `update_mode = 'none'`. Uses `ON CONFLICT (platform) DO NOTHING` so re-running doesn’t duplicate rows. |

---

#### `backend/utils/versionCompare.js`

| Function | Purpose |
|----------|--------|
| **parseVersion(version)** | Takes a string like `"1.0.10"` or `"1.0.0+1"`. Returns `{ major, minor, patch, build }`. Build is optional; patch/major/minor are numbers. |
| **compareVersions(a, b)** | Compares two version strings. Returns `-1` if a < b, `0` if equal, `1` if a > b. Uses major, then minor, then patch, then optional build. Ensures 1.0.9 < 1.0.10. |
| **isVersionLessThan(current, target)** | `true` if current < target. |
| **isVersionLessOrEqual(current, target)** | `true` if current <= target. |
| **isVersionGreaterThan(current, target)** | `true` if current > target. |
| **isVersionSupported(current, minimumSupported)** | `true` if current >= minimumSupported (app still supported). |

---

#### `backend/services/appUpdateService.js`

| Function | Purpose |
|----------|--------|
| **normalizePlatform(platform)** | Maps input (e.g. `"Windows"`, `"win"`) to one of `windows`, `android`, `web`. Defaults to `web` if invalid. |
| **getUpdateConfigByPlatform(platform)** | Runs `SELECT ... FROM app_update_config WHERE platform = $1 AND is_enabled = true`, returns one row or null. |
| **buildUpdateCheckResponse(config, currentVersion, buildNumber)** | Takes DB row + client version. Uses versionCompare to decide: maintenance → block; below minimum_supported → block (unsupported); mandatory + newer version → block; optional + newer → optional update. Returns the full JSON object for the API (success, update_available, block_app, reason, latest_version, minimum_supported_version, update_mode, is_mandatory, is_optional, title, message, changelog, update_url, release_date, maintenance_mode, maintenance_message, current_version, build_number). |
| **checkUpdate(params)** | Entry point. Expects `params.platform`, `params.current_version`, `params.build_number`. Fetches config with `getUpdateConfigByPlatform`, then returns `buildUpdateCheckResponse(...)`. |

---

#### `backend/controllers/appUpdateController.js`

| Export | Purpose |
|--------|--------|
| **checkUpdateController(req, res)** | Reads `platform`, `current_version`, `build_number` from `req.body` or `req.query`. Calls `checkUpdate(...)` and sends the result as JSON with status 200. On error, uses `handleErrorResponse` (500). |

---

#### `backend/routes/appUpdateRoutes.js`

| Route | Handler | Purpose |
|-------|---------|--------|
| **GET /api/app/check-update** | checkUpdateController | Same as POST; params in query string. |
| **POST /api/app/check-update** | checkUpdateController | Body or query: platform, current_version, build_number. |

---

#### `backend/index.js` (changes)

- Added: `import appUpdateRoutes from "./routes/appUpdateRoutes.js"` and `app.use('/', appUpdateRoutes);` so `/api/app/check-update` is served.

---

### Flutter

---

#### `lib/core/update/models/app_update_response.dart`

| Item | Purpose |
|------|--------|
| **Class AppUpdateResponse** | Immutable model for the check-update API response. |
| **Fields** | success, updateAvailable, blockApp, reason, latestVersion, minimumSupportedVersion, updateMode, isMandatory, isOptional, title, message, changelog, updateUrl, releaseDate, maintenanceMode, maintenanceMessage, currentVersion, buildNumber. |
| **fromJson(Map)** | Factory that maps snake_case API keys to the class fields. |
| **shouldBlock** | Getter: `blockApp` (maintenance or mandatory). |
| **canDefer** | Getter: optional update and not blocking. |
| **upToDate** | Getter: no update and not blocking. |

---

#### `lib/core/update/update_platform_io.dart`

| Item | Purpose |
|------|--------|
| **currentUpdatePlatform** | Getter. Uses `Platform.isWindows` / `Platform.isAndroid` and returns `'windows'`, `'android'`, or `'web'`. Used on non-web builds (has `dart:io`). |

---

#### `lib/core/update/update_platform_stub.dart`

| Item | Purpose |
|------|--------|
| **currentUpdatePlatform** | Getter. Returns `'web'`. Used when compiled for web so we don’t import `dart:io`. |

---

#### `lib/services/update_service.dart`

| Item | Purpose |
|------|--------|
| **currentUpdatePlatform** | Re-export of the platform getter from the conditional import (io vs stub). |
| **UpdateService** | Uses `baseURL` from api_config. |
| **checkUpdate({ currentVersion, buildNumber, platformOverride })** | POSTs to `$baseUrl/api/app/check-update` with JSON body platform, current_version, build_number. 10s timeout. On 200, parses body and returns `AppUpdateResponse.fromJson(...)`. On non-200 or parse error, throws. |

---

#### `lib/core/providers/update_provider.dart`

| Provider | Type | Purpose |
|----------|------|--------|
| **updateServiceProvider** | Provider<UpdateService> | Single instance of UpdateService. |
| **appPackageInfoProvider** | FutureProvider<PackageInfo> | Gets app version and build from `PackageInfo.fromPlatform()` (package_info_plus). |
| **updateCheckResultProvider** | FutureProvider.autoDispose<AppUpdateResponse> | Depends on appPackageInfoProvider. Calls `updateService.checkUpdate(version, buildNumber)` and exposes the result. Runs when the UpdateGate first watches it. |

---

#### `lib/core/update/update_ui/update_ui.dart`

| Function / Class | Purpose |
|------------------|--------|
| **buildUpdateUi({ context, response, onUpdate, onLater, onRetry })** | Chooses which UI to show: maintenance → _MaintenanceScreen; mandatory block → _MandatoryUpdateScreen; optional + web → _WebUpdatePrompt; optional + desktop/Android → _OptionalUpdateDialog (compact on Windows); upToDate/ok → _NoUpdateView; error + onRetry → _UpdateFailedView. |
| **_MaintenanceScreen** | Full-screen: icon, “Maintenance”, message, optional Retry button. |
| **_MandatoryUpdateScreen** | Full-screen: icon, title, latest version, message, scrollable changelog, “Update now” button, optional Retry. |
| **_OptionalUpdateDialog** | Dialog: title, version, message, changelog, “Later” and “Update”. `compact` true for Windows (smaller padding/fonts). |
| **_WebUpdatePrompt** | Horizontal bar: icon, message, “Later” and “Refresh” buttons. |
| **_NoUpdateView** | SizedBox.shrink(). |
| **_UpdateFailedView** | Small banner with warning icon, “Could not check for updates.” and “Retry” button. |

---

#### `lib/core/update/update_launcher.dart`

| Function | Purpose |
|----------|--------|
| **openUpdateUrl(url)** | If url is non-null and non-empty, parses it and opens with `url_launcher` (external browser/app). |
| **performUpdateAction(context, updateUrl)** | On **web**: calls `reloadPage()` (see below). On **Windows/Android**: calls `openUpdateUrl(updateUrl)`. Used when user taps “Update” / “Refresh” / “Update now”. |

---

#### `lib/core/update/update_launcher_web.dart`

| Function | Purpose |
|----------|--------|
| **reloadPage()** | Uses `dart:html` to run `window.location.reload()`. Only compiled for web. |

---

#### `lib/core/update/update_launcher_stub.dart`

| Function | Purpose |
|----------|--------|
| **reloadPage()** | No-op. Used on non-web so we don’t import `dart:html`. |

---

#### `lib/core/update/update_gate.dart`

| Item | Purpose |
|------|--------|
| **UpdateGate(child)** | ConsumerStatefulWidget. Watches `updateCheckResultProvider`. |
| **_UpdateGateState._optionalLaterChosen** | Remembers if user chose “Later” for an optional update so we don’t show the dialog/bar again. |
| **build()** | asyncResult.when: **loading** → _UpdateCheckLoadingScreen (“Checking for updates...”); **error** → _buildProceedWithRetry (banner + child); **data** → _buildWithResult(response). |
| **_buildProceedWithRetry** | Shows buildUpdateUi with a fake “error” response (so _UpdateFailedView appears) with onRetry that invalidates updateCheckResultProvider. Renders widget.child below so app is not blocked. |
| **_buildWithResult** | If response.shouldBlock → full-screen update/maintenance UI (no child). If optional and !_optionalLaterChosen: on **web** → Column(bar, child); on **desktop/Android** → Stack(child + centered dialog overlay). “Later” sets _optionalLaterChosen = true. Otherwise → just widget.child. |
| **_UpdateCheckLoadingScreen** | Scaffold with spinner and “Checking for updates...”. |

---

#### `lib/main.dart` (changes)

- Import `UpdateGate`.
- **home:** changed from `hasValidSession ? SessionBootstrapWrapper() : MainLoginPage()` to `UpdateGate(child: hasValidSession ? SessionBootstrapWrapper() : MainLoginPage())`. So the first screen the user sees is always behind the update gate; the gate runs the check once and then shows loading, block screen, optional UI, or the child.

---

#### `pubspec.yaml` (changes)

- Added dependencies: `package_info_plus: ^8.0.0`, `url_launcher: ^6.0.0`.

---

## Part 4: Data flow (short)

1. App starts → `UpdateGate` is built → it watches `updateCheckResultProvider`.
2. Provider runs: gets `PackageInfo` (version from pubspec), then `UpdateService.checkUpdate(version, buildNumber)` → POST to backend `/api/app/check-update`.
3. Backend: reads platform (from body/query), loads `app_update_config` row, compares versions with versionCompare, returns JSON.
4. Flutter: parses JSON into `AppUpdateResponse`. UpdateGate shows loading → then block screen, optional dialog/bar, or child (login/bootstrap).
5. “Update” / “Refresh” / “Update now” → performUpdateAction (open URL or reload page). “Later” (optional) → set _optionalLaterChosen and show child.

This is the full picture of what was done, how to test it, and what each file and function does.
