import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:my_app/utils/sessionManager.dart';
import 'package:my_app/utils/sessionStorage.dart';
import 'screens/login_screen.dart';
import 'package:my_app/screens/session_bootstrap_wrapper.dart';
import 'package:my_app/core/update/update_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WindowManager is desktop-only; on web it throws MissingPluginException.
  if (!kIsWeb) {
    await WindowManager.instance.ensureInitialized();
  }

  // Suppress known Flutter keyboard assertion (Alt pressed during hot restart)
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exception.toString();
    if (msg.contains('physical key is already pressed') ||
        msg.contains('_pressedKeys.containsKey') ||
        msg.contains(
            'Attempted to send a key down event when no keys are in keysPressed') ||
        msg.contains('_keysPressed.isNotEmpty')) {
      debugPrint(
        'Ignoring known Flutter keyboard state bug '
        '(release Alt before hot restart to avoid this).',
      );
      return;
    }
    FlutterError.presentError(details);
  };

  await Hive.initFlutter();
  await restoreSession();

  runApp(const ProviderScope(child: MyApp()));

  // After the first frame, try to reclaim window focus from the IDE.
  // Hot restart on Windows lets the IDE steal focus; without this the
  // window appears full-screen but does not process user input.
  if (!kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _forceWindowFocus());
  }
}

/// Re-focuses the native window at staggered intervals to handle the
/// race where the IDE reclaims focus immediately after hot restart.
void _forceWindowFocus() {
  _focusOnce();
  Future.delayed(const Duration(milliseconds: 200), _focusOnce);
  Future.delayed(const Duration(milliseconds: 500), _focusOnce);
  Future.delayed(const Duration(seconds: 1), _focusOnce);
}

void _focusOnce() {
  try {
    WindowManager.instance.focus();
  } catch (_) {
    // window_manager not available (web / test)
  }
}

Future<void> restoreSession() async {
  final session = await SessionStorage.loadSession();

  final stationId = session['stationId']?.toString().trim();
  final staffName = session['staffName']?.toString().trim();
  final staffID = session['staffID']?.toString().trim();
  final accessToken = session['accessToken']?.toString().trim();
  final refreshToken = session['refreshToken']?.toString().trim();
  final subscription = session['subscription'] is Map
      ? Map<String, dynamic>.from(session['subscription'] as Map)
      : null;
  final features = session['features'] is Map
      ? Map<String, dynamic>.from(session['features'] as Map)
      : null;
  final limits = session['limits'] is Map
      ? Map<String, dynamic>.from(session['limits'] as Map)
      : null;
  final permissions = session['permissions'] is List
      ? List<dynamic>.from(session['permissions'] as List)
      : null;

  // Only restore if all values are non-null and non-empty (fixes new device showing "Restoring session" forever).
  if (stationId != null &&
      stationId.isNotEmpty &&
      staffName != null &&
      staffName.isNotEmpty &&
      staffID != null &&
      staffID.isNotEmpty) {
    SessionManager().setSession(
      stationId: stationId,
      staffName: staffName,
      staffID: staffID,
      accessToken:
          (accessToken != null && accessToken.isNotEmpty) ? accessToken : null,
      refreshToken: (refreshToken != null && refreshToken.isNotEmpty)
          ? refreshToken
          : null,
      subscription: subscription,
      features: features,
      limits: limits,
      permissions: permissions,
    );
    print(
        "Session restored: Station ID - $stationId, Staff Name - $staffName, StaffID - $staffID");
  } else {
    SessionManager().clearSession();
    print("No valid session found. Showing login.");
  }
}

/// True only when we have real session data (non-null and non-empty). Avoids showing "Restoring session" on new device.
bool get hasValidSession {
  final s = SessionManager();
  final sid = s.stationId?.trim() ?? '';
  final name = s.staffName?.trim() ?? '';
  final staffId = s.staffID?.trim() ?? '';
  return sid.isNotEmpty && name.isNotEmpty && staffId.isNotEmpty;
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app becomes active after hot restart (IDE released focus),
    // reclaim window focus so input events work again.
    if (!kIsWeb && state == AppLifecycleState.resumed) {
      _focusOnce();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Application',
      theme: ThemeData(primarySwatch: Colors.brown),

      // ✅ IMPORTANT FIX:
      // - keep text scaler stable
      // - DO NOT force devicePixelRatio = 1.0 (it breaks Windows scaling)
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },

      home: UpdateGate(
        child:
            hasValidSession ? const SessionBootstrapWrapper() : MainLoginPage(),
      ),
    );
  }
}
