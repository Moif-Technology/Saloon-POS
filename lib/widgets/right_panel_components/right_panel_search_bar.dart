import 'package:flutter/material.dart';

class RightPanelSearchBar extends StatelessWidget {
  final bool isSearchingByName;
  final bool isSearching;
  final TextEditingController controller;
  final FocusNode focusNode;

  final VoidCallback onToggleNameCode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  final bool hasActiveKOT;
  final Map<String, dynamic>? kotRow;
  final bool isReturnBillAvailable;
  final Map<String, dynamic>? returnHeader;
  final String areaLabelFallback;

  final int selectedSearchIndex;
  final int searchResultsCount;
  final VoidCallback onArrowDown;
  final VoidCallback onArrowUp;
  final VoidCallback onEnterSelect;

  const RightPanelSearchBar({
    super.key,
    required this.isSearchingByName,
    required this.isSearching,
    required this.controller,
    required this.focusNode,
    required this.onToggleNameCode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.hasActiveKOT,
    required this.kotRow,
    required this.isReturnBillAvailable,
    required this.returnHeader,
    required this.areaLabelFallback,
    required this.selectedSearchIndex,
    required this.searchResultsCount,
    required this.onArrowDown,
    required this.onArrowUp,
    required this.onEnterSelect,
  });

  double _h(double w) {
    if (w < 700) return 34;
    if (w < 1100) return 36;
    return 38;
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('·',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
    );
  }

  Widget _info(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: _h(w),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF800000),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onToggleNameCode,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isSearchingByName
                            ? Icons.text_fields
                            : Icons.qr_code_2,
                        size: 14,
                        color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      isSearchingByName ? 'Item Name' : 'Item Code',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.0),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.swap_horiz,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                focusNode: focusNode,
                controller: controller,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: isSearchingByName
                      ? 'Search by name'
                      : 'Scan / type code then Enter',
                  hintStyle:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                        const BorderSide(color: Colors.white54, width: 1),
                  ),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF800000)),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.clear,
                              size: 18, color: Colors.grey.shade600),
                          onPressed: onClear,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                        ),
                ),
                style: const TextStyle(fontSize: 12, height: 1.0),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: hasActiveKOT
                      ? [
                          _info('Area',
                              kotRow?['AreaName']?.toString() ?? 'ORDER'),
                          _dot(),
                          _info('Chair',
                              kotRow?['TableName']?.toString() ??
                                  kotRow?['ChairNo']?.toString() ??
                                  '-'),
                        ]
                      : isReturnBillAvailable
                          ? [
                              _info(
                                  'Area',
                                  returnHeader?['areaName']?.toString() ??
                                      'RETURN'),
                              _dot(),
                              _info(
                                  'Chair',
                                  returnHeader?['tableName']?.toString() ??
                                      '-'),
                            ]
                          : [
                              Text(
                                areaLabelFallback,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                ),
                              ),
                            ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
