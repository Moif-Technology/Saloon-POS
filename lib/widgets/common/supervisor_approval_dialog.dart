import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';

/// Result of a successful supervisor approval.
class SupervisorApprovalResult {
  final String staffId;
  final String staffName;
  final String roleName;

  const SupervisorApprovalResult({
    required this.staffId,
    required this.staffName,
    required this.roleName,
  });
}

/// Common supervisor approval dialog (username + password).
/// Verifies the user is an Admin / Supervisor / Manager via the API.
///
/// Returns [SupervisorApprovalResult] on success, or `null` if cancelled / failed.
Future<SupervisorApprovalResult?> showSupervisorApprovalDialog(
  BuildContext context, {
  String title = 'Supervisor Approval',
  String? reason,
}) {
  return showDialog<SupervisorApprovalResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => SupervisorApprovalDialog(
      title: title,
      reason: reason,
    ),
  );
}

class SupervisorApprovalDialog extends StatefulWidget {
  final String title;
  final String? reason;

  const SupervisorApprovalDialog({
    super.key,
    this.title = 'Supervisor Approval',
    this.reason,
  });

  @override
  State<SupervisorApprovalDialog> createState() =>
      _SupervisorApprovalDialogState();
}

class _SupervisorApprovalDialogState extends State<SupervisorApprovalDialog> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  static const _accent = Color(0xFF780829);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Enter username and password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ApiService().verifySupervisor(
        username: user,
        password: pass,
      );
      if (!mounted) return;
      if (result['ok'] == true) {
        Navigator.of(context).pop(
          SupervisorApprovalResult(
            staffId: (result['staffId'] ?? '').toString(),
            staffName: (result['staffName'] ?? user).toString(),
            roleName: (result['roleName'] ?? '').toString(),
          ),
        );
        return;
      }
      setState(() {
        _busy = false;
        _error = (result['message'] ?? 'Approval denied').toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Row(
        children: [
          const Icon(Icons.verified_user, color: _accent, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF521C1D),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.reason != null && widget.reason!.trim().isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.reason!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Enter a Supervisor / Admin username and password to continue.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userCtrl,
              focusNode: _userFocus,
              enabled: !_busy,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passCtrl,
              focusNode: _passFocus,
              enabled: !_busy,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Approve',
                  style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
