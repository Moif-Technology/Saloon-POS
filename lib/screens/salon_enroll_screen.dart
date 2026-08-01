import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/config/business_config.dart';
import 'package:my_app/core/providers/business_provider.dart';
import 'package:my_app/widgets/brand_logo.dart';

import '../services/salon_device_service.dart';

/// Device enrollment — the first thing a new salon till shows.
///
/// Two steps in one screen so the admin never loses context:
///   1. enter admin email + password  -> the company's SALON_POS stations load
///   2. tap a station                 -> the device is paired and we move on
///
/// The company is derived from the admin's own record on the server; it is never
/// typed in here. Once paired, the device token is persisted and this screen is
/// not shown again unless the till is unpaired.
class SalonEnrollScreen extends ConsumerStatefulWidget {
  const SalonEnrollScreen({super.key, required this.onEnrolled});

  /// Called after a successful pairing so the app can move to the PIN screen.
  final VoidCallback onEnrolled;

  @override
  ConsumerState<SalonEnrollScreen> createState() => _SalonEnrollScreenState();
}

class _SalonEnrollScreenState extends ConsumerState<SalonEnrollScreen> {
  final _service = SalonDeviceService();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _passFocus = FocusNode();

  List<SalonStation>? _stations;
  bool _busy = false;
  String? _error;
  String _deviceToken = '';

  @override
  void initState() {
    super.initState();
    // Show the token so a support call can identify this till.
    SalonDeviceService.deviceToken().then((t) {
      if (mounted) setState(() => _deviceToken = t);
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _labelCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Enter the admin email and password.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _stations = null;
    });

    try {
      final stations =
          await _service.fetchStations(username: user, password: pass);
      if (!mounted) return;
      setState(() => _stations = stations);
    } on SalonApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enroll(SalonStation station) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final enrollment = await _service.enrollDevice(
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        stationId: station.stationId,
        label: _labelCtrl.text.trim(),
      );
      if (!mounted) return;
      ref.read(appBrandProvider.notifier).state = brandFromSession(
        businessType:
            (enrollment['business_type'] ?? enrollment['businessType'])
                ?.toString(),
        branding: enrollment['branding'] is Map
            ? Map<String, dynamic>.from(enrollment['branding'] as Map)
            : null,
      );
      // Clear the admin password from memory as soon as it is no longer needed.
      _passCtrl.clear();
      widget.onEnrolled();
    } on SalonApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(appBrandProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1F0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: BrandLogo(brand: brand, size: 46)),
                    const SizedBox(height: 12),
                    Text(
                      'Set up this ${brand.appName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _stations == null
                          ? 'Sign in as an admin to pair this device with a station.'
                          : 'Choose which station this device is.',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    if (_stations == null)
                      ..._credentialFields()
                    else
                      ..._stationList(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF5C6C2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 18, color: Color(0xFFB3261E)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                    color: Color(0xFFB3261E), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Device ID: ${_deviceToken.isEmpty ? '…' : _deviceToken}',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _credentialFields() => [
        TextField(
          controller: _userCtrl,
          enabled: !_busy,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passFocus.requestFocus(),
          decoration: const InputDecoration(
            labelText: 'Admin email',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passCtrl,
          focusNode: _passFocus,
          enabled: !_busy,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _busy ? null : _loadStations(),
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _labelCtrl,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Device name (optional)',
            hintText: 'e.g. Front desk',
            prefixIcon: Icon(Icons.label_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ref.watch(appBrandProvider).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: _busy ? null : _loadStations,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Continue',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ];

  List<Widget> _stationList() {
    final stations = _stations!;
    if (stations.isEmpty) {
      // The server already refuses this case, but handle it so the screen never
      // shows an empty void with no way forward.
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No station exists for this company yet.\n'
            'Create one in Backoffice > Stations, then try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _stations = null),
          child: const Text('Back'),
        ),
      ];
    }

    return [
      ...stations.map(
        (s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: _busy ? null : () => _enroll(s),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDD8D6)),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.desktop_windows_outlined,
                    color: ref.watch(appBrandProvider).primaryColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.stationName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (s.stationCode != null) s.stationCode,
                            if (s.branchName != null) s.branchName,
                          ].whereType<String>().join(' · '),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: _busy ? null : () => setState(() => _stations = null),
        child: const Text('Use a different account'),
      ),
    ];
  }
}
