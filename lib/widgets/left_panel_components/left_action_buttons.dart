import 'package:flutter/material.dart';

class LeftActionButtons extends StatelessWidget {
  final VoidCallback onNewKot;
  final VoidCallback onQtyChange;
  final VoidCallback onPriceChange;
  final bool compact;
  final bool isBaseVersion;
  final bool showNewKot;
  final bool showQtyChange;
  final bool showPriceChange;

  const LeftActionButtons({
    super.key,
    required this.onNewKot,
    required this.onQtyChange,
    required this.onPriceChange,
    this.compact = false,
    this.isBaseVersion = false,
    this.showNewKot = true,
    this.showQtyChange = true,
    this.showPriceChange = true,
  });

  @override
  Widget build(BuildContext context) {
    final labelNew = compact ? "New" : "New Job";
    final labelQty = compact ? "Qty" : "Qty Change";
    final labelPrice = compact ? "Price" : "Price Change";
    return Row(
      children: [
        if (showNewKot)
          _Btn(
            label: labelNew,
            icon: Icons.add_circle,
            color: const Color(0xFF521C1D),
            compact: compact,
            onTap: onNewKot,
          ),
        if (!isBaseVersion && showQtyChange) ...[
          SizedBox(width: compact ? 5 : 6),
          _Btn(
            label: labelQty,
            icon: Icons.edit,
            color: const Color(0xFF5D6B7A),
            compact: compact,
            onTap: onQtyChange,
          ),
        ],
        if (!isBaseVersion && showPriceChange) ...[
          SizedBox(width: compact ? 5 : 6),
          _Btn(
            label: labelPrice,
            icon: Icons.price_change,
            color: const Color(0xFF795548),
            compact: compact,
            onTap: onPriceChange,
          ),
        ],
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.icon,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 9 : 11,
              horizontal: 6,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: compact ? 16 : 18, color: Colors.white),
                SizedBox(width: compact ? 5 : 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
