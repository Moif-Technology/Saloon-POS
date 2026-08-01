import 'package:flutter/material.dart';
import 'package:my_app/widgets/topPanelWidgets/ReportTab/counterClose.dart';

/// Admin Counter Close — same Counter Close UI, all pending (every cashier).
class CounterCloseAdminDialog extends StatelessWidget {
  const CounterCloseAdminDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const CounterCloseDialog(isAdmin: true);
  }
}
