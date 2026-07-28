import 'package:flutter/material.dart';

/// POS action button.
/// Base version  (isBaseVersion=true): modern maroon gradient, icon+label stacked.
/// Full version  (isBaseVersion=false): original HMS style — white bg, maroon border, text-only or icon+label.
class PosButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? filledColor;
  final Color textColor;
  final bool expanded;
  final bool compact;
  final bool isBaseVersion;

  const PosButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filledColor,
    this.textColor = Colors.black,
    this.expanded = true,
    this.compact = false,
    this.isBaseVersion = false,
  });

  @override
  State<PosButton> createState() => _PosButtonState();
}

class _PosButtonState extends State<PosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Base version helpers ──────────────────────────────────────────────────
  static Color _darken(Color c, [double amount = 0.10]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _lighten(Color c, [double amount = 0.10]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static const Color _defaultBase = Color(0xFF7B1C1C);
  Color get _base => widget.filledColor ?? _defaultBase;

  // ── Full version helpers (original) ──────────────────────────────────────
  double _posHeight(double w) {
    if (widget.compact) return 24;
    if (w < 400) return 26;
    if (w < 520) return 30;
    if (w < 700) return 34;
    if (w < 900) return 36;
    return 40;
  }

  double _posScale(double w) {
    if (widget.compact) return 0.58;
    if (w < 400) return 0.65;
    if (w < 600) return 0.75;
    if (w < 900) return 0.85;
    if (w < 1100) return 0.92;
    return 1.0;
  }

  TextStyle _txt(double s, Color c) => TextStyle(
        fontSize: 12.0 * s,
        fontWeight: FontWeight.w700,
        color: c,
        height: 1.0,
      );

  ButtonStyle _btnStyle() => TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      );

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    Widget tile;

    if (widget.isBaseVersion) {
      // ── Modern maroon gradient (base version) ─────────────────────────────
      final double iconSz = widget.compact ? 12.0 : 14.0;
      final double fontSize = widget.compact ? 8.5 : 10.0;

      tile = GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onPressed?.call();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_lighten(_base, 0.08), _darken(_base, 0.06)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _base.withOpacity(0.30),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: iconSz, color: Colors.white),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // ── Original HMS style (full version) ────────────────────────────────
      final h = _posHeight(screenW);
      final s = _posScale(screenW);

      tile = LayoutBuilder(
        builder: (context, c) {
          final textOnly = c.maxWidth < 120;
          return Container(
            height: h,
            margin: EdgeInsets.all(widget.compact ? 0.25 : 0.5),
            decoration: BoxDecoration(
              color: widget.filledColor ?? Colors.white,
              border: Border.all(color: const Color(0xFF521C1D), width: 0.5),
            ),
            child: TextButton(
              style: _btnStyle(),
              onPressed: widget.onPressed,
              child: Center(
                child: textOnly
                    ? Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        style: _txt(s, widget.textColor),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4 * s),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.icon,
                                size: widget.compact ? 14 : 16 * s,
                                color: widget.textColor),
                            SizedBox(width: 4 * s),
                            Flexible(
                              child: Text(
                                widget.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.clip,
                                style: _txt(s, widget.textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      );
    }

    return widget.expanded ? Expanded(child: tile) : tile;
  }
}
