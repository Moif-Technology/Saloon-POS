import 'package:flutter/material.dart';

class ResponsiveScaler {
  static late double _scaleFactor;

  /// Call this once at app start or in build method of main screen
  static void init(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // You can fine-tune the base width as per your design
    _scaleFactor = width / 1440.0;
  }

  static double scale(double value) => value * _scaleFactor;

  static double font(double size) => valueWithMinimum(size, 10);

  static double valueWithMinimum(double value, double min) {
    final scaled = value * _scaleFactor;
    return scaled < min ? min : scaled;
  }

  // Optional helpers
  static EdgeInsets padding(double all) => EdgeInsets.all(scale(all));

  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(
        horizontal: scale(horizontal),
        vertical: scale(vertical),
      );
}
