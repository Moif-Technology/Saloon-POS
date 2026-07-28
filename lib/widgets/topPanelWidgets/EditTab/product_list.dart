import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/widgets/topPanelWidgets/NewEntryTab/product_entry.dart';

/// Product List / Edit dialog.
///
/// Native POS styling: maroon header + maroon table header (matches the rest
/// of RestaurantPOS), neutral body, brand-accented selection and primary
/// action. Self-contained themed filter dropdowns (does not depend on the
/// shared CustomSearchableDropdown, which is styled for other screens).
class ProductListDialog extends StatefulWidget {
  const ProductListDialog({super.key});

  @override
  State<ProductListDialog> createState() => _ProductListDialogState();
}

class _ProductListDialogState extends State<ProductListDialog> {
  static const Color _maroon = Color(0xFF521C1D);
  static const Color _maroonDk = Color(0xFF3E1416);
  static const Color _ink = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _hover = Color(0xFFFAF7F6);
  static const Color _zebra = Color(0xFFFCFBFB);

  final TextEditingController _search = TextEditingController();

  List<Map<String, dynamic>> groupData = [];
  List<Map<String, dynamic>> subGroupData = [];
  Map<String, dynamic>? selectedGroup;
  Map<String, dynamic>? selectedSubGroup;
  int? selectedGroupId;

  List<Map<String, String>> products = [];
  List<Map<String, String>> filtered = [];
  int? selectedIndex;

  bool isLoading = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    fetchGroupData();
    fetchProductData();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---- Data ---------------------------------------------------------------
  void _applySearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      selectedIndex = null;
      filtered = q.isEmpty
          ? products
          : products
              .where((p) => p.values.any((v) => v.toLowerCase().contains(q)))
              .toList();
    });
  }

  Future<void> fetchGroupData() async {
    try {
      final data = await ApiService().fetchGroups();
      setState(() {
        groupData = data
            .map((g) =>
                {"GroupID": g['GroupID'], "GroupCode": g['GroupCode']})
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching group data: $e");
    }
  }

  Future<void> fetchSubGroupData(int? groupId) async {
    if (groupId == null) return;
    try {
      final data =
          await ApiService().fetchSubGroups(groupId: groupId.toString());
      setState(() {
        subGroupData = data
            .where((sg) =>
                sg['GroupID'] != null &&
                int.tryParse(sg['GroupID'].toString()) == groupId)
            .map((sg) => {
                  "SubGroupID": sg['SubGroupID'],
                  "SubGroupDescription": sg['SubGroupDescription'],
                  "GroupID": sg['GroupID'],
                })
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching sub-groups: $e");
    }
  }

  Future<void> fetchProductData() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final data = await ApiService().fetchProducts(
        groupId: selectedGroupId?.toString(),
        subGroupId: selectedSubGroup?['SubGroupID']?.toString(),
      );
      final mapped = data.map<Map<String, String>>((item) {
        return {
          "UniqueMultiProductID": item['UniqueMultiProductID']?.toString() ??
              item['ProductID']?.toString() ??
              '',
          "ProductID": item['ProductID']?.toString() ?? '',
          "barCode": item['Barcode']?.toString() ?? '',
          "description": item['ShortDescription']?.toString() ?? '',
          "Arabicdescription": item['DescriptionArabic']?.toString() ?? '',
          "qty": item['PackQty']?.toString() ?? '',
          "price": item['UnitPrice']?.toString() ?? '',
          "orderNo": item['CounterPOPUP']?.toString() ?? '',
        };
      }).toList();
      final q = _search.text.toLowerCase();
      setState(() {
        products = mapped;
        filtered = q.isEmpty
            ? mapped
            : mapped
                .where((p) => p.values.any((v) => v.toLowerCase().contains(q)))
                .toList();
        selectedIndex = null;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
      setState(() {
        isLoading = false;
        loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onGroupChanged(Map<String, dynamic>? value) {
    setState(() {
      selectedGroup = value;
      selectedGroupId = value?['GroupID'] is String
          ? int.tryParse(value?['GroupID'])
          : value?['GroupID'];
      selectedSubGroup = null;
      subGroupData = [];
    });
    if (selectedGroupId != null) fetchSubGroupData(selectedGroupId!);
    fetchProductData();
  }

  void _onSubGroupChanged(Map<String, dynamic>? value) {
    setState(() => selectedSubGroup = value);
    fetchProductData();
  }

  void _clearFilters() {
    setState(() {
      selectedGroup = null;
      selectedSubGroup = null;
      selectedGroupId = null;
      subGroupData = [];
      _search.clear();
    });
    fetchProductData();
  }

  void _openEditor(String id) {
    showDialog(
      context: context,
      builder: (_) => ProductMasterDetailsDialog(uniqueMultiProductID: id),
    ).then((_) => fetchProductData());
  }

  // ---- Build --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: size.width * 0.74,
        height: size.height * 0.86,
        child: Column(
          children: [
            _header(),
            _toolbar(),
            Expanded(child: _body()),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_maroonDk, _maroon],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 0, 10, 0),
      height: 58,
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: Colors.white, size: 21),
          const SizedBox(width: 11),
          const Text(
            'Product List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 12),
          if (!isLoading && loadError == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${filtered.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: Colors.white70),
            splashRadius: 20,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final hasFilter = selectedGroupId != null ||
        selectedSubGroup != null ||
        _search.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 210,
            child: _FilterDropdown(
              label: 'All Groups',
              icon: Icons.folder_outlined,
              items: groupData,
              displayKey: 'GroupCode',
              value: selectedGroup,
              onChanged: _onGroupChanged,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 210,
            child: _FilterDropdown(
              label: 'All Sub Groups',
              icon: Icons.subdirectory_arrow_right,
              items: subGroupData,
              displayKey: 'SubGroupDescription',
              value: selectedSubGroup,
              enabled: subGroupData.isNotEmpty,
              onChanged: _onSubGroupChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _searchField()),
          if (hasFilter) ...[
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: _muted,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchField() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _search,
        onChanged: _applySearch,
        onSubmitted: _applySearch,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: _ink),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search by barcode, description or price',
          hintStyle: const TextStyle(color: _muted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _muted, size: 19),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 17, color: _muted),
                  splashRadius: 15,
                  onPressed: () {
                    _search.clear();
                    _applySearch('');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _maroon, width: 1.4),
          ),
        ),
      ),
    );
  }

  // ---- Body / table -------------------------------------------------------
  Widget _body() {
    if (isLoading) return const _LoadingState();
    if (loadError != null) {
      return _ErrorState(message: loadError!, onRetry: fetchProductData);
    }
    if (filtered.isEmpty) {
      return _EmptyState(
          hasFilter: _search.text.isNotEmpty || selectedGroupId != null);
    }
    return Column(
      children: [
        _tableHeader(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: filtered.length,
            itemBuilder: (_, i) => _row(i),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader() {
    const s = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.5,
    );
    return Container(
      color: _maroon,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('BARCODE', style: s)),
          Expanded(flex: 4, child: Text('DESCRIPTION', style: s)),
          Expanded(flex: 4, child: Text('ARABIC', style: s)),
          Expanded(
              flex: 2,
              child: Text('QTY', style: s, textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text('PRICE', style: s, textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text('ORDER', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _row(int index) {
    final p = filtered[index];
    final selected = selectedIndex == index;
    final base = index.isOdd ? _zebra : Colors.white;
    return Material(
      color: selected ? _maroon.withOpacity(0.06) : base,
      child: InkWell(
        onTap: () => setState(() => selectedIndex = index),
        onDoubleTap: () => _openEditor(p['UniqueMultiProductID'] ?? ''),
        hoverColor: _hover,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? _maroon : Colors.transparent,
                width: 3,
              ),
              bottom: const BorderSide(color: _border, width: 0.7),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
          child: Row(
            children: [
              Expanded(flex: 3, child: _cell(p['barCode'] ?? '', mono: true)),
              Expanded(
                  flex: 4,
                  child: _cell(p['description'] ?? '',
                      weight: FontWeight.w500, color: _ink)),
              Expanded(flex: 4, child: _cell(p['Arabicdescription'] ?? '')),
              Expanded(flex: 2, child: _num(p['qty'] ?? '')),
              Expanded(flex: 2, child: _num(p['price'] ?? '', strong: true)),
              Expanded(flex: 2, child: _num(p['orderNo'] ?? '')),
              SizedBox(
                width: 40,
                child: IconButton(
                  tooltip: 'Edit',
                  splashRadius: 17,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit_outlined, size: 17, color: _maroon),
                  onPressed: () => _openEditor(p['UniqueMultiProductID'] ?? ''),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text,
      {bool mono = false, FontWeight? weight, Color? color}) {
    final empty = text.isEmpty;
    return Text(
      empty ? '—' : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13.5,
        color:
            empty ? const Color(0xFFB0B6BE) : (color ?? const Color(0xFF374151)),
        fontWeight: weight ?? FontWeight.w400,
        fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
      ),
    );
  }

  Widget _num(String text, {bool strong = false}) {
    final empty = text.isEmpty;
    return Text(
      empty ? '—' : text,
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13.5,
        color: empty ? const Color(0xFFB0B6BE) : _ink,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  // ---- Footer -------------------------------------------------------------
  Widget _footer() {
    final has = selectedIndex != null;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBFB),
        border: Border(top: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 13, 22, 13),
      child: Row(
        children: [
          Text(
            has
                ? '1 selected'
                : '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
          const Spacer(),
         
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: has
                ? () => _openEditor(
                    filtered[selectedIndex!]['UniqueMultiProductID'] ?? '')
                : null,
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Edit Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _maroon,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Themed filter dropdown (self-contained, matches POS maroon theme)
// ===========================================================================

class _FilterDropdown extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final String displayKey;
  final Map<String, dynamic>? value;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final bool enabled;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.items,
    required this.displayKey,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<_FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<_FilterDropdown> {
  static const Color _maroon = Color(0xFF521C1D);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _muted = Color(0xFF6B7280);

  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  final TextEditingController _search = TextEditingController();
  List<Map<String, dynamic>> _view = [];

  bool get _open => _entry != null;

  @override
  void dispose() {
    _removeOverlay();
    _search.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!widget.enabled) return;
    if (_open) {
      _removeOverlay();
    } else {
      _view = widget.items;
      _search.clear();
      _entry = _buildOverlay();
      Overlay.of(context).insert(_entry!);
      setState(() {});
    }
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    _view = q.isEmpty
        ? widget.items
        : widget.items
            .where((i) =>
                (i[widget.displayKey] ?? '').toString().toLowerCase().contains(lower))
            .toList();
    _entry?.markNeedsBuild();
  }

  OverlayEntry _buildOverlay() {
    final box = context.findRenderObject() as RenderBox;
    final width = box.size.width;
    final showSearch = widget.items.length > 7;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap-outside catcher.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 6),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showSearch)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                          child: TextField(
                            controller: _search,
                            autofocus: true,
                            onChanged: _filter,
                            style: const TextStyle(fontSize: 13.5),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search ${widget.label}',
                              prefixIcon:
                                  const Icon(Icons.search, size: 18, color: _muted),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 8),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: _maroon, width: 1.4),
                              ),
                            ),
                          ),
                        ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: _view.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No results',
                                    style: TextStyle(
                                        color: _muted, fontSize: 13)),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: _view.length,
                                itemBuilder: (context, i) {
                                  final item = _view[i];
                                  final isSel = widget.value != null &&
                                      widget.value![widget.displayKey] ==
                                          item[widget.displayKey];
                                  return InkWell(
                                    onTap: () {
                                      widget.onChanged(item);
                                      _removeOverlay();
                                    },
                                    child: Container(
                                      color: isSel
                                          ? _maroon.withOpacity(0.07)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 11),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (item[widget.displayKey] ?? '')
                                                  .toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                color: isSel
                                                    ? _maroon
                                                    : const Color(0xFF374151),
                                                fontWeight: isSel
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          if (isSel)
                                            const Icon(Icons.check,
                                                size: 16, color: _maroon),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final text =
        hasValue ? (widget.value![widget.displayKey] ?? '').toString() : widget.label;
    return CompositedTransformTarget(
      link: _link,
      child: Material(
        color: widget.enabled ? Colors.white : const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: _toggle,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _open ? _maroon : _border,
                width: _open ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon,
                    size: 17,
                    color: widget.enabled ? _muted : const Color(0xFFC4C4C4)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: hasValue
                          ? const Color(0xFF1F2937)
                          : (widget.enabled ? _muted : const Color(0xFFB0B0B0)),
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                if (hasValue && widget.enabled)
                  GestureDetector(
                    onTap: () => widget.onChanged(null),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(Icons.close, size: 16, color: _muted),
                    ),
                  ),
                Icon(_open ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// State widgets
// ===========================================================================

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
            strokeWidth: 2.5, color: Color(0xFF521C1D)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasFilter ? Icons.search_off : Icons.inventory_2_outlined,
              size: 44, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 14),
          Text(
            hasFilter ? 'No matching products' : 'No products yet',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151)),
          ),
          const SizedBox(height: 5),
          Text(
            hasFilter
                ? 'Try a different search or category.'
                : 'Products in this branch will appear here.',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44, color: Color(0xFFDC2626)),
          const SizedBox(height: 12),
          const Text(
            'Could not load products',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151)),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF521C1D),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
