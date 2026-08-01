import 'package:flutter/material.dart';
import 'package:my_app/widgets/common/supervisor_approval_dialog.dart';

/// Compliment requires supervisor approval. Returns staff name on success.
Future<String?> showComplimentApprovalDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Compliment(),
  );
}

class Compliment extends StatefulWidget {
  const Compliment({super.key});

  @override
  State<Compliment> createState() => _ComplimentState();
}

class _ComplimentState extends State<Compliment> {
  static const _accent = Color(0xFF521C1D);
  bool _busy = false;

  Future<void> _approve() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await showSupervisorApprovalDialog(
      context,
      title: 'Compliment Approval',
      reason: 'Approve complimentary (free) settlement for this bill',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result != null) {
      Navigator.of(context).pop(result.staffName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Compliment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This bill will be settled as complimentary (no payment collected). '
              'Supervisor approval is required.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _approve,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Approve with Supervisor',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(null),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
