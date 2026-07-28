import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/providers/parameterProviders.dart';
import 'package:my_app/core/providers/session_bootstrap_provider.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/utils/sessionManager.dart';
import 'package:my_app/utils/sessionStorage.dart';

/// Shows HomeScreen only after Parameters and Privileges are loaded.
/// Used when app opens with a restored session (skipping login).
class SessionBootstrapWrapper extends ConsumerWidget {
  const SessionBootstrapWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionBootstrapProvider, (previous, next) {
      next.whenData((data) {
        if (data == null) return;
        ref.read(subscriptionProvider.notifier).state = data.subscription;
        ref.read(featuresProvider.notifier).state = data.features;
        ref.read(limitsProvider.notifier).state = data.limits;
        ref.read(permissionsProvider.notifier).state = data.permissions;
        ref.read(privilegesProvider.notifier).state = data.privileges;
        ref.read(tax1Provider.notifier).state = data.tax1;
        ref.read(currencyPrecessionProvider.notifier).state =
            data.currencyPrecession;
        ref.read(StartTimeProvider.notifier).state = data.reportStartTime;
        ref.read(EndTimeProvider.notifier).state = data.reportEndTime;
        ref.read(pendingKotCheckProvider.notifier).state = data.pendingKotCheck;
        ref.read(ISWaiterMandotoryProvider.notifier).state =
            data.isWaiterMandatory;
        ref.read(ClearAfterKOTSaveProvider.notifier).state =
            data.clearAfterKotSave;
        ref.read(SaveKOTonSettlementProvider.notifier).state =
            data.saveKotOnSettlement;
        ref.read(companyDetailsProvider.notifier).state = data.companyDetails;
      });
    });

    final bootstrap = ref.watch(sessionBootstrapProvider);

    return bootstrap.when(
      loading: () => const _BootstrapLoadingScreen(),
      data: (_) => HomeScreen(),
      error: (error, stack) => _BootstrapErrorScreen(
        error: error,
        onRetry: () => ref.invalidate(sessionBootstrapProvider),
        onLogout: () {
          SessionManager().clearSession();
          SessionStorage.clearSession().then((_) {
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MainLoginPage()),
                (route) => false,
              );
            }
          });
        },
      ),
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

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
              "Restoring session...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  const _BootstrapErrorScreen({
    required this.error,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8ff),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
                const SizedBox(height: 16),
                Text(
                  "Failed to restore session",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF521C1D),
                      ),
                      child: const Text("Retry"),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: onLogout,
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
