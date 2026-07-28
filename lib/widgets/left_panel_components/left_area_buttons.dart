import 'package:flutter/material.dart';

/// No glow and no scrollbar — avoids white track on desktop.
class _AreaScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class LeftAreaButtons extends StatefulWidget {
  final Future<List<dynamic>> futureAreas;
  final Color Function(String supplyType) getAreaColor;
  final void Function(dynamic area) onPressed;
  final bool compact;

  /// Current area ID – selected area is highlighted for clarity
  final String? selectedAreaId;

  const LeftAreaButtons({
    super.key,
    required this.futureAreas,
    required this.getAreaColor,
    required this.onPressed,
    this.compact = false,
    this.selectedAreaId,
  });

  @override
  State<LeftAreaButtons> createState() => _LeftAreaButtonsState();
}

class _LeftAreaButtonsState extends State<LeftAreaButtons> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maroon = const Color(0xFF521C1D);
    final compact = widget.compact;

    return Padding(
      padding: EdgeInsets.all(compact ? 6 : 8),
      child: FutureBuilder<List<dynamic>>(
        future: widget.futureAreas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF521C1D)),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return const SizedBox.shrink();
          } else if (snapshot.hasData) {
            final areas = snapshot.data!;
            if (areas.isEmpty) return const SizedBox.shrink();
            final selectedId = widget.selectedAreaId?.toString();

            // Height for 2 full rows so second row isn't covered; scroll when more.
            final twoRowHeight = compact ? 88.0 : 108.0;
            final panelBg = Colors.grey.shade50;
            const scrollbarCoverWidth = 14.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: twoRowHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: panelBg,
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: ScrollConfiguration(
                          behavior: _AreaScrollBehavior(),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.only(top: 2, bottom: 2, right: scrollbarCoverWidth),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: twoRowHeight - 4),
                              child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: areas.map((area) {
                        final areaId = area['AreaID']?.toString();
                        final areaName = area['AreaName']?.toString().trim() ?? '';
                        final areaNameUpper = areaName.toUpperCase();
                        final isSelected = selectedId != null &&
                            areaId != null &&
                            selectedId == areaId;

                        Color bgColor;
                        if (areaNameUpper == 'TAKE AWAY' ||
                            areaNameUpper == 'TAKEAWAY' ||
                            areaNameUpper == 'DELIVERY') {
                          bgColor = isSelected
                              ? maroon.withValues(alpha: 0.1)
                              : const Color(0xFFFFF5F5);
                        } else {
                          final base =
                              widget.getAreaColor(area['SupplyType'] ?? 'Unknown');
                          bgColor = isSelected
                              ? base.withValues(alpha: 0.45)
                              : base.withValues(alpha: 0.3);
                        }

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onPressed(area),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 14 : 18,
                                vertical: compact ? 10 : 12,
                              ),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? maroon
                                      : Colors.grey.shade400,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                area['AreaName']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: compact ? 12 : 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ),
                        );
                            }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Cover right edge so any platform scrollbar track is hidden by grey
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Material(
                          color: panelBg,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          child: SizedBox(width: scrollbarCoverWidth),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('No areas found.'));
          }
        },
      ),
    );
  }
}
