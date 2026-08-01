import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/config/business_config.dart';
import 'package:my_app/utils/sessionManager.dart';

final appBrandProvider = StateProvider<AppBrand>((ref) {
  final session = SessionManager();
  return brandFromSession(
    businessType: session.businessType,
    branding: session.branding,
  );
});
