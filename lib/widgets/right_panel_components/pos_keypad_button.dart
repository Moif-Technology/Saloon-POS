import 'package:flutter/material.dart';

/// POS numeric keypad button.
/// Base version  (isBaseVersion=true): modern white card with colour accents.
/// Full version  (isBaseVersion=false): original HMS style — white bg, maroon border, black text.
class PosKeypadButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? bgColor;
  final bool isBaseVersion;

  const PosKeypadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.bgColor,
    this.isBaseVersion = false,
  });

  @override
  State<PosKeypadButton> createState() => _PosKeypadButtonState();
}

class _PosKeypadButtonState extends State<PosKeypadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
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

  bool get _isBackspace => widget.label == 'C';
  bool get _isDot => widget.label == '.';

  // Base version colours
  Color get _bgBase {
    if (widget.bgColor != null) return widget.bgColor!;
    if (_isBackspace) return const Color(0xFFFFECEC);
    if (_isDot) return const Color(0xFFECF0FF);
    return Colors.white;
  }

  Color get _textColorBase {
    if (_isBackspace) return const Color(0xFFC0392B);
    if (_isDot) return const Color(0xFF3D5AFE);
    return const Color(0xFF1A1A2E);
  }

  // Full version size helpers (original)
  double _keyH(double w) {
    if (w < 520) return 34;
    if (w < 700) return 36;
    if (w < 900) return 38;
    return 40;
  }

  double _keyScale(double w) {
    if (w < 600) return 0.85;
    if (w < 900) return 0.95;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: widget.isBaseVersion
              // ── Modern white-card style (base version) ────────────────────
              ? Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _bgBase,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        blurRadius: 1,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isBackspace
                        ? Icon(Icons.backspace_rounded,
                            size: 22, color: _textColorBase)
                        : Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _textColorBase,
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                  ),
                )
              // ── Original HMS style (full version) ─────────────────────────
              : Container(
                  height: _keyH(w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: const Color(0xFF521C1D), width: 0.5),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    onPressed: widget.onPressed,
                    child: Center(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20 * _keyScale(w),
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
