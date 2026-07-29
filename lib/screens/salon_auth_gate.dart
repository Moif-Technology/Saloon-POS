import 'package:flutter/material.dart';

import '../services/salon_device_service.dart';
import 'salon_enroll_screen.dart';
import 'salon_pin_login_screen.dart';

/// Decides what an unauthenticated salon till shows:
///
///   no device pairing  -> [SalonEnrollScreen]
///   paired             -> [SalonPinLoginScreen]
///
/// Kept separate from main.dart so the decision lives in one place: the PIN
/// screen can send the user back to enrollment mid-session (if the server says
/// the device was unpaired) without main.dart knowing anything about it.
class SalonAuthGate extends StatefulWidget {
  const SalonAuthGate({super.key, required this.onLoggedIn});

  /// Receives the /pin-login session payload once a stylist signs in.
  final void Function(Map<String, dynamic> session) onLoggedIn;

  @override
  State<SalonAuthGate> createState() => _SalonAuthGateState();
}

class _SalonAuthGateState extends State<SalonAuthGate> {
  bool? _enrolled;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final enrolled = await SalonDeviceService.isEnrolled();
    if (!mounted) return;
    setState(() => _enrolled = enrolled);
  }

  Future<void> _unpair() async {
    await SalonDeviceService.clearEnrollment();
    if (!mounted) return;
    setState(() => _enrolled = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_enrolled == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F1F0),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_enrolled == false) {
      return SalonEnrollScreen(
        onEnrolled: () => setState(() => _enrolled = true),
      );
    }

    return SalonPinLoginScreen(
      onLoggedIn: widget.onLoggedIn,
      // The server rejected our device token; drop local pairing and re-enroll.
      onNeedsEnrollment: _unpair,
    );
  }
}
