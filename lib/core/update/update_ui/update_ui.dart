import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:my_app/core/update/models/app_update_response.dart';

/// Platform-specific update UI factory.
/// Windows: compact modal; Android: touch-friendly dialog; Web: lightweight prompt.
Widget buildUpdateUi({
  required BuildContext context,
  required AppUpdateResponse response,
  required VoidCallback onUpdate,
  VoidCallback? onLater,
  VoidCallback? onRetry,
}) {
  if (response.maintenanceMode) {
    return _MaintenanceScreen(
      message: response.maintenanceMessage ?? 'System under maintenance.',
      onRetry: onRetry,
    );
  }
  if (response.shouldBlock && response.isMandatory) {
    return _MandatoryUpdateScreen(
      response: response,
      onUpdate: onUpdate,
      onRetry: onRetry,
    );
  }
  if (response.isOptional) {
    if (kIsWeb) {
      return _WebUpdatePrompt(
        response: response,
        onRefresh: onUpdate,
        onLater: onLater!,
      );
    }
    return _OptionalUpdateDialog(
      response: response,
      onUpdate: onUpdate,
      onLater: onLater!,
      compact: defaultTargetPlatform == TargetPlatform.windows,
    );
  }
  if (response.reason == 'ok' || response.upToDate) {
    return const _NoUpdateView();
  }
  if (onRetry != null) {
    return _UpdateFailedView(onRetry: onRetry);
  }
  return const _NoUpdateView();
}

/// Full-screen maintenance mode.
class _MaintenanceScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _MaintenanceScreen({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.orange[700]),
              const SizedBox(height: 24),
              Text(
                'Maintenance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen mandatory update (blocks app).
class _MandatoryUpdateScreen extends StatelessWidget {
  final AppUpdateResponse response;
  final VoidCallback onUpdate;
  final VoidCallback? onRetry;

  const _MandatoryUpdateScreen({
    required this.response,
    required this.onUpdate,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.system_update, size: 64, color: Colors.blue[700]),
              const SizedBox(height: 24),
              Text(
                response.title ?? 'Update required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              if (response.latestVersion != null)
                Text(
                  'Version ${response.latestVersion}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              const SizedBox(height: 12),
              Text(
                response.message ?? 'Please update to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              if (response.changelog != null &&
                  response.changelog!.isNotEmpty) ...[
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      response.changelog!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onUpdate,
                icon: const Icon(Icons.download),
                label: const Text('Update now'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF521C1D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: const Text('Retry check')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional update: dialog with Update / Later. Compact on Windows.
class _OptionalUpdateDialog extends StatelessWidget {
  final AppUpdateResponse response;
  final VoidCallback onUpdate;
  final VoidCallback onLater;
  final bool compact;

  const _OptionalUpdateDialog({
    required this.response,
    required this.onUpdate,
    required this.onLater,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWindows = compact;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWindows ? 420 : 400,
          maxHeight: isWindows ? 380 : 440,
        ),
        padding: EdgeInsets.all(isWindows ? 20 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isWindows ? 28 : 32,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    response.title ?? 'Update available',
                    style: TextStyle(
                      fontSize: isWindows ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (response.latestVersion != null)
              Text(
                'Version ${response.latestVersion}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            const SizedBox(height: 8),
            Text(
              response.message ?? 'A new version is available.',
              style: TextStyle(fontSize: isWindows ? 13 : 14, color: Colors.grey[700]),
            ),
            if (response.changelog != null &&
                response.changelog!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    response.changelog!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onLater,
                  child: const Text('Later'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onUpdate,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF521C1D),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Web: lightweight bar or snackbar-style prompt with Refresh / Later.
class _WebUpdatePrompt extends StatelessWidget {
  final AppUpdateResponse response;
  final VoidCallback onRefresh;
  final VoidCallback onLater;

  const _WebUpdatePrompt({
    required this.response,
    required this.onRefresh,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
        ),
        child: Row(
          children: [
            Icon(Icons.refresh, size: 20, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                response.message ?? 'A new version is available. Refresh to update.',
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              ),
            ),
            TextButton(
              onPressed: onLater,
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: onRefresh,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF521C1D),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoUpdateView extends StatelessWidget {
  const _NoUpdateView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _UpdateFailedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _UpdateFailedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Material(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700], size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Could not check for updates.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
