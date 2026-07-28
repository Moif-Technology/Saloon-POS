import 'package:flutter/material.dart';

/// Uniformly scales content to fill the available space.
/// Uses FittedBox so the UI always fills the window on any screen size.
/// Zooms out on smaller screens, zooms in on larger screens.
class ScaledLayout extends StatelessWidget {
  final Widget child;

  /// Design dimensions the layout was built for (logical pixels).
  static const double designWidth = 1280;
  static const double designHeight = 720;

  const ScaledLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w <= 0 || h <= 0) return const SizedBox.shrink();

        return SizedBox(
          width: w,
          height: h,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
