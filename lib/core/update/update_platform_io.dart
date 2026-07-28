import 'dart:io' show Platform;

/// Platform detection for update check when dart:io is available (Windows, Android).
String get currentUpdatePlatform {
  if (Platform.isWindows) return 'windows';
  if (Platform.isAndroid) return 'android';
  return 'web';
}
