import 'package:flutter/material.dart';

class CustomSearchableDropdown extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final String displayKey;
  final Function(Map<String, dynamic>?) onSelected;
  final bool enableDynamicFiltering;
  final Map<String, dynamic>? initialSelectedItem;
  final VoidCallback? onScrollEnd;

  const CustomSearchableDropdown({
    Key? key,
    required this.label,
    required this.items,
    required this.displayKey,
    required this.onSelected,
    this.onScrollEnd,
    this.enableDynamicFiltering = true,
    this.initialSelectedItem,
    Map<String, dynamic>? selectedItem,
  }) : super(key: key);

  @override
  _CustomSearchableDropdownState createState() =>
      _CustomSearchableDropdownState();
}

class _CustomSearchableDropdownState extends State<CustomSearchableDropdown> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredItems = [];
  Map<String, dynamic>? _selectedItem;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    // Debug print
    print("🔍 Initialization Started");
    print("🔍 Total Items: ${widget.items.length}");
    print("🔍 Display Key: ${widget.displayKey}");
    print("🔍 Initial Selected Item: ${widget.initialSelectedItem}");

    // Initialize filtered items with all items
    _filteredItems = widget.items;

    // Pre-filling logic with robust matching
    if (widget.initialSelectedItem != null) {
      final matchedItem = _findMatchingItem(widget.initialSelectedItem!);

      if (matchedItem != null) {
        _selectedItem = matchedItem;
        print("✅ Pre-selected Item: $matchedItem");
      } else {
        print("❌ No matching item found for pre-selection");
      }
    }

    print("Initial Selected Item in Dropdown: $_selectedItem");

    // Dynamic filtering setup
    if (widget.enableDynamicFiltering) {
      _searchController.addListener(() {
        _filterItems(_searchController.text);
      });
    }
  }

  // Robust item matching method with explicit return type
  Map<String, dynamic>? _findMatchingItem(Map<String, dynamic> initialItem) {
    try {
      // Validate display key exists
      if (!initialItem.containsKey(widget.displayKey)) {
        print(
            "❌ Initial item does not contain the display key: ${widget.displayKey}");
        return null;
      }

      // Get the initial value to match
      final initialValue = initialItem[widget.displayKey];

      // Strategy 1: Exact match (case-insensitive, trimmed)
      final exactMatch = widget.items.firstWhere(
        (item) => _compareValues(item[widget.displayKey], initialValue),
        orElse: () => <String, dynamic>{},
      );

      if (exactMatch.isNotEmpty) {
        print("✅ Exact match found: $exactMatch");
        return exactMatch;
      }

      // Strategy 2: Partial match
      final partialMatch = widget.items.firstWhere(
        (item) => item[widget.displayKey]
            .toString()
            .toLowerCase()
            .contains(initialValue.toString().toLowerCase()),
        orElse: () => <String, dynamic>{},
      );

      if (partialMatch.isNotEmpty) {
        print("✅ Partial match found: $partialMatch");
        return partialMatch;
      }

      // Strategy 3: First item as fallback
      if (widget.items.isNotEmpty) {
        print("⚠️ Fallback to first item");
        return widget.items.first;
      }

      return null;
    } catch (e) {
      print("❌ Error in finding matching item: $e");
      return null;
    }
  }

  // Helper method for robust comparison
  bool _compareValues(dynamic value1, dynamic value2) {
    if (value1 == null || value2 == null) return false;

    return value1.toString().trim().toLowerCase() ==
        value2.toString().trim().toLowerCase();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    setState(() {
      // Ensure `_filteredItems` is re-initialized when dropdown opens
      _filteredItems = widget.items;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    setState(() {
      _isDropdownOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeDropdown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              left: offset.dx,
              top: offset.dy + size.height,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                _filterItems(''); // Reset filter
                              },
                            ),
                            hintText: "Search ${widget.label}",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                          minHeight: 50,
                        ),
                        child: Scrollbar(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return ListTile(
                                title: Text(
                                  item[widget.displayKey]?.toString() ?? '',
                                  style: TextStyle(
                                    color: _selectedItem == item
                                        ? Colors.blue
                                        : Colors.black,
                                  ),
                                ),
                                selected: _selectedItem == item,
                                onTap: () {
                                  setState(() {
                                    _selectedItem = item;
                                  });
                                  widget.onSelected(item);
                                  _closeDropdown();
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        // Reset to full list when search is cleared
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item[widget.displayKey]
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });

    if (_isDropdownOpen) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _clearSelectedItem() {
    setState(() {
      _selectedItem = null; // Clear the selected item
    });
    widget.onSelected(null); // Notify parent that the value is cleared
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
            width: 180,
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedItem == null
                        ? widget.label
                        : (_selectedItem?[widget.displayKey] ?? widget.label),
                    style: TextStyle(
                      color: _selectedItem == null
                          ? Colors.grey.shade800
                          : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_selectedItem !=
                    null) // 🔥 Show clear button only if an item is selected
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _clearSelectedItem, // Call the new clear method
                    constraints: BoxConstraints(maxWidth: 32),
                  ),
                Icon(
                  _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
              ],
            )),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
