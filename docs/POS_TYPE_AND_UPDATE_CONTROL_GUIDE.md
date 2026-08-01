# POS Type, Branding, and Update Control

This app supports one codebase for multiple POS products. The selected POS type
can come from build flags, device enrollment, staff login, or backend company
settings.

## Local Type Testing

Salon:

```powershell
flutter run -d windows --dart-define=DEFAULT_BUSINESS_TYPE=salon --dart-define=POS_BASE_PATH=/api/salon-pos
```

Laundry:

```powershell
flutter run -d windows --dart-define=DEFAULT_BUSINESS_TYPE=laundry --dart-define=POS_BASE_PATH=/api/laundry-pos
```

If the backend returns `business_type`, it overrides the default and is saved in
the local session.

## Backend Type Payload

Return this from device enrollment, staff-list, and PIN login where available:

```json
{
  "business_type": "laundry",
  "branding": {
    "app_name": "Laundry POS",
    "login_title": "Laundry Login",
    "receipt_title": "Laundry Receipt",
    "primary_color": "#145C72",
    "logo_url": "https://api.example.com/uploads/company-logo.png"
  }
}
```

Supported `business_type` values:

- `salon`
- `laundry`

The app also accepts camelCase keys like `businessType`, `appName`, `logoUrl`,
and `primaryColor`.

## Logo Rules

Default local paths are already configured:

- `assets/branding/salon/logo.png`
- `assets/branding/laundry/logo.png`

Because `pubspec.yaml` already includes `assets/`, adding those files is enough.
If a logo file is missing, the app shows a clean generated icon fallback. If the
backend sends `branding.logo_url`, the company logo is shown instead.

## Super Admin Setting

Add a company-level setting in Super Admin:

```text
POS Type: Salon | Laundry
```

Save it as:

```json
{
  "business_type": "salon"
}
```

When a device enrolls or logs in, return that value to the POS. Do not rely on
the user typing it at the till.

## Update UI Local Testing

Optional update prompt:

```powershell
flutter run -d windows --dart-define=MOCK_UPDATE=optional
```

Expected result:

- POS opens normally.
- Small update prompt appears at bottom-right.
- `Later` hides it for the current session.
- `Download` opens the test URL in the browser.

Mandatory update:

```powershell
flutter run -d windows --dart-define=MOCK_UPDATE=mandatory
```

Expected result:

- App is blocked.
- User must click update/download.

Maintenance:

```powershell
flutter run -d windows --dart-define=MOCK_UPDATE=maintenance
```

No update:

```powershell
flutter run -d windows --dart-define=MOCK_UPDATE=none
```

## Backend Update API

The app posts to:

```text
POST /api/app/check-update
```

Request:

```json
{
  "platform": "windows",
  "current_version": "1.0.0",
  "build_number": 10
}
```

Optional response:

```json
{
  "success": true,
  "update_available": true,
  "block_app": false,
  "reason": "optional_update",
  "latest_version": "1.0.2",
  "update_mode": "optional",
  "is_optional": true,
  "title": "New update available",
  "message": "A new version is ready to download.",
  "update_url": "https://api.example.com/downloads/SalonPOSSetup.exe"
}
```

Mandatory response:

```json
{
  "success": true,
  "update_available": true,
  "block_app": true,
  "reason": "mandatory_update",
  "latest_version": "1.0.2",
  "minimum_supported_version": "1.0.2",
  "update_mode": "mandatory",
  "is_mandatory": true,
  "title": "Update required",
  "message": "Please update to continue.",
  "update_url": "https://api.example.com/downloads/SalonPOSSetup.exe"
}
```

No update response:

```json
{
  "success": true,
  "update_available": false,
  "block_app": false,
  "reason": "ok"
}
```
