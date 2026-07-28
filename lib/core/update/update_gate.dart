import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/update_provider.dart';
import 'package:my_app/core/update/models/app_update_response.dart';
import 'package:my_app/core/update/update_ui/update_ui.dart';
import 'package:my_app/core/update/update_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Runs update check at startup; blocks on maintenance/mandatory, shows optional dialog with Later,
/// or proceeds to [child]. Does not interrupt once user is past the gate (POS-safe).
class UpdateGate extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateGate({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  bool _optionalLaterChosen = false;

  @override
  Widget build(BuildContext context) {
    // TODO: When adding subscription logic, run subscription check after update check
  // and combine block_app (e.g. subscription expired) with update block; keep gate order: update first, then subscription.
  final asyncResult = ref.watch(updateCheckResultProvider);

    return asyncResult.when(
      loading: () => const _UpdateCheckLoadingScreen(),
      error: (err, _) => _buildProceedWithRetry(context, err),
      data: (response) => _buildWithResult(context, response),
    );
  }

  Widget _buildProceedWithRetry(BuildContext context, Object error) {
    // Do not block on network error; allow POS to run. Show retry option.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildUpdateUi(
          context: context,
          response: const AppUpdateResponse(
            success: false,
            updateAvailable: false,
            blockApp: false,
            reason: 'error',
          ),
          onUpdate: () {},
          onLater: null,
          onRetry: () => ref.invalidate(updateCheckResultProvider),
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildWithResult(BuildContext context, AppUpdateResponse response) {
    // Block: maintenance or mandatory update
    if (response.shouldBlock) {
      return buildUpdateUi(
        context: context,
        response: response,
        onUpdate: () => performUpdateAction(context, response.updateUrl),
        onRetry: () => ref.invalidate(updateCheckResultProvider),
      );
    }

    // Optional update: show overlay/dialog until "Later" or "Update"
    if (response.isOptional && !_optionalLaterChosen) {
      if (kIsWeb) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildUpdateUi(
              context: context,
              response: response,
              onUpdate: () =>
                  performUpdateAction(context, response.updateUrl),
              onLater: () => setState(() => _optionalLaterChosen = true),
            ),
            Expanded(child: widget.child),
          ],
        );
      }
      return Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: Material(
              color: Colors.black54,
              child: Center(
                child: buildUpdateUi(
                  context: context,
                  response: response,
                  onUpdate: () =>
                      performUpdateAction(context, response.updateUrl),
                  onLater: () => setState(() => _optionalLaterChosen = true),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Optional on web returns a bar; we need to show child below the bar
    if (response.isOptional &&
        _optionalLaterChosen &&
        response.updateMode == 'optional') {
      return widget.child;
    }

    // No update or later chosen: show child. If check failed (reason != ok) we already proceeded in error.
    return widget.child;
  }
}

class _UpdateCheckLoadingScreen extends StatelessWidget {
  const _UpdateCheckLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8ff),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF521C1D),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Checking for updates...',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
