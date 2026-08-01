import 'package:flutter/material.dart';
import 'package:my_app/config/business_config.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.brand,
    this.size = 44,
    this.foregroundColor,
    this.backgroundColor,
  });

  final AppBrand brand;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? brand.primaryColor;
    final bg = backgroundColor ?? brand.primaryColor.withValues(alpha: 0.10);

    final url = brand.logoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.18),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallback(fg, bg),
        ),
      );
    }

    final asset = brand.logoAssetPath?.trim();
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(fg, bg),
      );
    }

    return _fallback(fg, bg);
  }

  Widget _fallback(Color fg, Color bg) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: Icon(brand.icon, color: fg, size: size * 0.56),
    );
  }
}
