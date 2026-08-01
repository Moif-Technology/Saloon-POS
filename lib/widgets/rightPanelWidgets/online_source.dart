import 'package:flutter/material.dart';

/// Pick an online payment source; returns the selected label or null.
Future<String?> showOnlineSourcesDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const OnlineSourcesDialog(),
  );
}

class OnlineSourcesDialog extends StatelessWidget {
  const OnlineSourcesDialog({super.key});

  static const _sources = ['GHAYATHA', 'ONLINE', 'TALABAT', 'TM DONE'];
  static const _accent = Color(0xFF521C1D);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 420,
        height: 320,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Online Sources',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _accent,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.7,
                  children: _sources
                      .map((s) => _buildSourceButton(context, s))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(BuildContext context, String label) {
    return Material(
      color: _accent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(label),
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
