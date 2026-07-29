import 'package:flutter/material.dart';

import '../services/salon_device_service.dart';

/// Staff picker + PIN pad for an enrolled salon till.
///
/// Two panes: staff tiles on the left, a numeric pad on the right. Picking a
/// staff member first means the server verifies exactly one PIN (one bcrypt op)
/// instead of scanning every staff in the company.
class SalonPinLoginScreen extends StatefulWidget {
  const SalonPinLoginScreen({
    super.key,
    required this.onLoggedIn,
    required this.onNeedsEnrollment,
  });

  /// Receives the session payload from /pin-login.
  final void Function(Map<String, dynamic> session) onLoggedIn;

  /// Called when the server says this device is no longer paired.
  final VoidCallback onNeedsEnrollment;

  @override
  State<SalonPinLoginScreen> createState() => _SalonPinLoginScreenState();
}

class _SalonPinLoginScreenState extends State<SalonPinLoginScreen> {
  static const _pinMaxLength = 6;
  static const _pinMinLength = 4;

  final _service = SalonDeviceService();

  List<SalonStaff>? _staff;
  SalonStaff? _selected;
  String _pin = '';
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String _stationName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final staff = await _service.fetchStaff();
      final enrollment = await SalonDeviceService.enrollment();
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _stationName = (enrollment['stationName'] ?? '').toString();
        // Skip the picker when there is only one option.
        if (staff.length == 1) _selected = staff.first;
      });
    } on SalonApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'NOT_ENROLLED') {
        widget.onNeedsEnrollment();
        return;
      }
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _tapDigit(String d) {
    if (_submitting || _pin.length >= _pinMaxLength) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    // Auto-submit is deliberately NOT done at 4 digits: PINs may be 4-6, and
    // submitting early would lock a 6-digit user out on every attempt.
  }

  void _backspace() {
    if (_submitting || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _clear() {
    if (_submitting) return;
    setState(() {
      _pin = '';
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_selected == null) {
      setState(() => _error = 'Pick who you are first.');
      return;
    }
    if (_pin.length < _pinMinLength) {
      setState(() => _error = 'PIN must be at least $_pinMinLength digits.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final session = await _service.pinLogin(staffPk: _selected!.staffPk, pin: _pin);
      if (!mounted) return;
      widget.onLoggedIn(session);
    } on SalonApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'NOT_ENROLLED' || e.code == 'WRONG_COMPANY') {
        widget.onNeedsEnrollment();
        return;
      }
      setState(() {
        _error = e.message;
        _pin = ''; // never leave a rejected PIN on screen
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1F0),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _header(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        // Stack the panes on a narrow till instead of squeezing them.
                        final wide = c.maxWidth >= 760;
                        final staffPane = _staffPane();
                        final padPane = _pinPane();
                        return wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 5, child: staffPane),
                                  const VerticalDivider(width: 1),
                                  Expanded(flex: 4, child: padPane),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    SizedBox(height: 240, child: staffPane),
                                    const Divider(height: 1),
                                    padPane,
                                  ],
                                ),
                              );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header() => Container(
        width: double.infinity,
        color: const Color(0xFF800000),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.content_cut, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Text(
              'Salon POS',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_stationName.isNotEmpty)
              Text(_stationName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );

  Widget _staffPane() {
    final staff = _staff ?? const <SalonStaff>[];

    if (staff.isEmpty) {
      // Distinct from a failed fetch: nobody has a PIN set. Say what to do.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline, size: 40, color: Colors.black26),
              const SizedBox(height: 12),
              const Text(
                'No staff have a PIN yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set a PIN for each stylist in Backoffice > Staff,\nthen reload.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reload'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Who are you?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisExtent: 92,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: staff.length,
              itemBuilder: (context, i) => _staffTile(staff[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffTile(SalonStaff s) {
    final selected = _selected?.staffPk == s.staffPk;
    return InkWell(
      onTap: _submitting
          ? null
          : () => setState(() {
                _selected = s;
                _pin = '';
                _error = null;
              }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF800000) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF800000) : const Color(0xFFDDD8D6),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  selected ? Colors.white24 : const Color(0xFF800000).withValues(alpha: 0.10),
              child: Text(
                s.initials,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF800000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.staffName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (s.roleName != null)
                    Text(
                      s.roleName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white70 : Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinPane() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selected == null ? 'Select your name' : 'Hello, ${_selected!.staffName}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _pinDots(),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          _keypad(),
        ],
      ),
    );
  }

  Widget _pinDots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinMaxLength, (i) {
          final filled = i < _pin.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? const Color(0xFF800000) : Colors.transparent,
              border: Border.all(
                color: filled ? const Color(0xFF800000) : const Color(0xFFBDB6B3),
                width: 1.5,
              ),
            ),
          );
        }),
      );

  Widget _keypad() {
    Widget key(String label, {VoidCallback? onTap, Color? fg, Color? bg, IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: SizedBox(
          // 64px: comfortably above the 44px touch-target floor for a till.
          height: 64,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bg ?? Colors.white,
              foregroundColor: fg ?? Colors.black87,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onTap,
            child: icon != null
                ? Icon(icon, size: 22)
                : Text(label,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    Widget row(List<Widget> children) =>
        Row(children: children.map((c) => Expanded(child: c)).toList());

    final disabled = _submitting;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row([
            key('1', onTap: disabled ? null : () => _tapDigit('1')),
            key('2', onTap: disabled ? null : () => _tapDigit('2')),
            key('3', onTap: disabled ? null : () => _tapDigit('3')),
          ]),
          row([
            key('4', onTap: disabled ? null : () => _tapDigit('4')),
            key('5', onTap: disabled ? null : () => _tapDigit('5')),
            key('6', onTap: disabled ? null : () => _tapDigit('6')),
          ]),
          row([
            key('7', onTap: disabled ? null : () => _tapDigit('7')),
            key('8', onTap: disabled ? null : () => _tapDigit('8')),
            key('9', onTap: disabled ? null : () => _tapDigit('9')),
          ]),
          row([
            key('C', onTap: disabled ? null : _clear, fg: const Color(0xFFB3261E)),
            key('0', onTap: disabled ? null : () => _tapDigit('0')),
            key('', icon: Icons.backspace_outlined, onTap: disabled ? null : _backspace),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF800000),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBDB6B3),
              ),
              onPressed:
                  (_submitting || _selected == null || _pin.length < _pinMinLength)
                      ? null
                      : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Sign in',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
