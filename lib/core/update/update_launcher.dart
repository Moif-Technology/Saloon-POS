import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_app/core/update/update_launcher_web.dart'
    if (dart.library.io) 'package:my_app/core/update/update_launcher_stub.dart' as web_launcher;

/// Opens [url] in browser or external app. No-op if url is null or empty.
Future<void> openUpdateUrl(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Performs the "Update" action: on web reloads the page, otherwise opens [updateUrl].
void performUpdateAction(BuildContext context, String? updateUrl) {
  if (kIsWeb) {
    web_launcher.reloadPage();
    return;
  }
  openUpdateUrl(updateUrl);
}
