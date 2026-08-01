import 'package:flutter/material.dart';

enum BusinessType {
  salon,
  laundry,
}

extension BusinessTypeX on BusinessType {
  String get value {
    switch (this) {
      case BusinessType.laundry:
        return 'laundry';
      case BusinessType.salon:
        return 'salon';
    }
  }

  static BusinessType fromValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'laundry':
      case 'laundry_pos':
      case 'laundry-pos':
        return BusinessType.laundry;
      case 'salon':
      case 'salon_pos':
      case 'salon-pos':
      default:
        return BusinessType.salon;
    }
  }
}

class AppBrand {
  const AppBrand({
    required this.businessType,
    required this.appName,
    required this.loginTitle,
    required this.receiptTitle,
    required this.primaryColor,
    required this.icon,
    this.logoAssetPath,
    this.logoUrl,
  });

  final BusinessType businessType;
  final String appName;
  final String loginTitle;
  final String receiptTitle;
  final Color primaryColor;
  final IconData icon;
  final String? logoAssetPath;
  final String? logoUrl;

  AppBrand copyWith({
    String? appName,
    String? loginTitle,
    String? receiptTitle,
    Color? primaryColor,
    String? logoAssetPath,
    String? logoUrl,
  }) {
    return AppBrand(
      businessType: businessType,
      appName: appName ?? this.appName,
      loginTitle: loginTitle ?? this.loginTitle,
      receiptTitle: receiptTitle ?? this.receiptTitle,
      primaryColor: primaryColor ?? this.primaryColor,
      icon: icon,
      logoAssetPath: logoAssetPath ?? this.logoAssetPath,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}

const String defaultBusinessTypeName = String.fromEnvironment(
  'DEFAULT_BUSINESS_TYPE',
  defaultValue: 'salon',
);

BusinessType get defaultBusinessType =>
    BusinessTypeX.fromValue(defaultBusinessTypeName);

AppBrand brandForBusinessType(BusinessType type) {
  switch (type) {
    case BusinessType.laundry:
      return const AppBrand(
        businessType: BusinessType.laundry,
        appName: 'Laundry POS',
        loginTitle: 'Laundry Login',
        receiptTitle: 'Laundry Receipt',
        primaryColor: Color(0xFF145C72),
        icon: Icons.local_laundry_service_outlined,
        logoAssetPath: 'assets/branding/laundry/logo.png',
      );
    case BusinessType.salon:
      return const AppBrand(
        businessType: BusinessType.salon,
        appName: 'Salon POS',
        loginTitle: 'Salon Login',
        receiptTitle: 'Salon Receipt',
        primaryColor: Color(0xFF521C1D),
        icon: Icons.content_cut,
        logoAssetPath: 'assets/branding/salon/logo.png',
      );
  }
}

AppBrand brandFromSession({
  required String? businessType,
  Map<String, dynamic>? branding,
}) {
  final type = BusinessTypeX.fromValue(businessType);
  final base = brandForBusinessType(type);
  if (branding == null) return base;

  return base.copyWith(
    appName:
        _stringValue(branding['app_name']) ?? _stringValue(branding['appName']),
    loginTitle: _stringValue(branding['login_title']) ??
        _stringValue(branding['loginTitle']),
    receiptTitle: _stringValue(branding['receipt_title']) ??
        _stringValue(branding['receiptTitle']),
    primaryColor: _colorFromHex(
      _stringValue(branding['primary_color']) ??
          _stringValue(branding['primaryColor']),
    ),
    logoAssetPath: _stringValue(branding['logo_asset_path']) ??
        _stringValue(branding['logoAssetPath']),
    logoUrl:
        _stringValue(branding['logo_url']) ?? _stringValue(branding['logoUrl']),
  );
}

String? _stringValue(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

Color? _colorFromHex(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final cleaned = raw.replaceFirst('#', '').trim();
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(cleaned.length == 6 ? 0xFF000000 | value : value);
}
