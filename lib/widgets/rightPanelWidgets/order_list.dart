import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/services/api_service.dart';

/// Global function to format KotTime to `dd-MM-yy hh:mm a`
String formatKotTime(String isoDate) {
  try {
    DateTime dateTime = DateTime.parse(isoDate);
    String formattedDate = DateFormat('dd-MM-yy').format(dateTime);
    String formattedTime = DateFormat('hh:mm a').format(dateTime);
    return '$formattedDate $formattedTime';
  } catch (e) {
    return 'Invalid Date';
  }
}

// ✅ Convert OrderList to ConsumerStatefulWidget
class OrderList extends ConsumerStatefulWidget {
  @override
  _OrderListState createState() => _OrderListState();
}

class _OrderListState extends ConsumerState<OrderList> {
  List<Map<String, dynamic>> orders = []; // Orders list from API response
  String selectedArea = "All"; // Default to showing all orders
  List<String> allAreas = ["All"]; // Default value includes "All"

  String searchQuery = ""; // To store the search query
  Timer? _debounce; // Timer for debouncing search
  String selectedSupplyType = "All"; // To filter by SupplyType

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final fetched = await ApiService().fetchOrderList(
        search: searchQuery.isEmpty ? null : searchQuery,
      );
      if (!mounted) return;
      final areas = fetched.map((o) => o['AreaName'] as String? ?? '').toSet().toList();
      setState(() {
        orders = fetched;
        allAreas = ['All', ...areas];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load orders: $e')),
      );
    }
  }

  void _fetchKotDetails(int kotMasterID) async {
    try {
      final kotDetails = await ApiService().fetchKotDetails('$kotMasterID');
      if (!mounted) return;

      if ((kotDetails['data'] as List?)?.isNotEmpty ?? false) {
        ref.read(isUpdatingFromOrderListProvider.notifier).state = true;
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 300), () {
          ref.read(kotDetailsProvider.notifier).state = kotDetails;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KOT has no items')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load KOT details: $e')),
      );
    }
  }

  /// Debounce the search to avoid multiple API calls
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = query;
      });
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel debounce timer if widget is disposed
    super.dispose();
  }

  /// Generates a consistent color for each area name
  Color _getDynamicColor(String area) {
    final int hash = area.hashCode; // Generate a hash from the area name
    final int r = (hash & 0xFF0000) >> 16; // Extract red from the hash
    final int g = (hash & 0x00FF00) >> 8; // Extract green from the hash
    final int b = (hash & 0x0000FF); // Extract blue from the hash
    return Color.fromARGB(255, r, g, b);
  }

  /// List of available icons to use dynamically for the area
  final List<IconData> _availableIcons = [
    Icons.shopping_bag,
    Icons.restaurant,
    Icons.delivery_dining,
    Icons.meeting_room,
    Icons.home,
    Icons.storefront,
    Icons.local_cafe,
    Icons.fastfood,
  ];

  /// Generates a consistent icon for each area name
  IconData _getDynamicIcon(String area) {
    final int index =
        area.hashCode % _availableIcons.length; // Use hash to get index
    return _availableIcons[index];
  }

  @override
  Widget build(BuildContext context) {
    List<String> uniqueAreas = orders
        .map((order) =>
            (order["AreaName"] ?? order["areaName"] ?? '').toString())
        .toSet()
        .toList();
    uniqueAreas.insert(0, "All"); // Add "All" option to the top

    List<Map<String, dynamic>> filteredOrders = orders.where((o) {
      final areaName = (o['AreaName'] ?? o['areaName'] ?? '').toString();
      if (selectedArea != 'All' && areaName != selectedArea) return false;
      if (selectedSupplyType != 'All' && o['SupplyType'] != selectedSupplyType) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF800000),
        toolbarHeight: 65,
        titleSpacing: 0,
        title: _buildHeader(uniqueAreas),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double itemHeight = 200;
          int crossAxisCount = (screenWidth ~/ 150).clamp(2, 9);

          return Row(
            children: [
              _buildSidebar(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent:
                          160, // Sets the maximum width of each grid tile
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent:
                          180, // Requires Flutter 2.5+ to set a fixed height
                    ),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredOrders[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Header with colored buttons
  Widget _buildHeader(List<String> areas) {
    return Container(
      color: const Color(0xFF800000),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: allAreas.map((area) {
          Color dynamicColor = _getDynamicColor(area);
          return _buildHeaderButton(area, dynamicColor);
        }).toList(),
      ),
    );
  }

  // Header Button with Custom Colors
  Widget _buildHeaderButton(String label, Color color) {
    bool isSelected =
        selectedArea == label; // Check if the current area is selected
    if (selectedArea == "All") {
      isSelected = label == "All"; // Highlight "All" if no area is selected
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0, top: 7),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (label == "All") {
              selectedArea = "All"; // Reset area filter
              selectedSupplyType = "All"; // Reset supply type filter
              searchQuery = ""; // Clear search query
            } else {
              selectedArea = label;
            }
          });
          _loadOrders(); // Fetch updated orders
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: isSelected ? 10 : 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static const _supplyMeta = {
    'DINE_IN':  (Icons.restaurant,     'Dine In'),
    'PARCEL':   (Icons.shopping_bag,   'Take Away'),
    'DELIVERY': (Icons.delivery_dining,'Delivery'),
    'TAKEAWAY': (Icons.shopping_bag,   'Takeaway'),
    'GENERAL':  (Icons.store,          'General'),
  };

  Widget _buildSidebar(BuildContext context) {
    final uniqueSupplyTypes = orders
        .map((o) => (o['SupplyType'] as String? ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Container(
      width: 100,
      color: const Color(0xFF800000),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              "KOT NO.",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              ),
            ),
          ),
          _buildSidebarButton(Icons.list, "All", selectedSupplyType == "All", () {
            setState(() {
              selectedArea = "All";
              selectedSupplyType = "All";
            });
          }),
          ...uniqueSupplyTypes.map((type) {
            final meta = _supplyMeta[type];
            final icon  = meta?.$1 ?? Icons.label;
            final label = meta?.$2 ?? type;
            return _buildSidebarButton(icon, label, selectedSupplyType == type, () {
              setState(() => selectedSupplyType = type);
            });
          }),
          const Spacer(),
          _buildSidebarButton(Icons.home, "Home", false, () {
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(IconData icon, String label, bool isSelected, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Order Card with Dynamic Colors and Icons
  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Extracting relevant data from the order
    String kotNumber = order['KotNumber'] ?? 'N/A';
    print('${kotNumber}: Kot Number');
    String kotPrefix = order['KotPrefix'] ?? 'N/A';
    String amount = order['Amount']?.toString() ?? '0.00';
    String tableID = order['TableName'] ?? 'N/A';
    String chairNo = order['ChairNo'] ?? 'N/A';
    String kotTime = formatKotTime(order['KotTime'] ?? 'N/A');

    String AreaName = order['AreaName'] ?? 'Unknown';

    Color dynamicColor = _getDynamicColor(AreaName);
    IconData dynamicIcon = _getDynamicIcon(AreaName);

    String combinedKotNo = "$kotPrefix$kotNumber"; // Combined KOT No

    return Container(
      decoration: BoxDecoration(
        color: dynamicColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(dynamicIcon, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    AreaName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.black54, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    kotTime,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              "Table: $tableID - Chair: $chairNo",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              "Supply Type: ${order['SupplyType'] ?? 'N/A'}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: Container(
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Text(
                "Amount: ${amount}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17359B),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF0C00), Color(0xFFFF9B00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 6.0),
            child: InkWell(
              onTap: () {
                int? kotMasterID =
                    int.tryParse(order['kotMasterID'].toString());
                if (kotMasterID != null) {
                  _fetchKotDetails(kotMasterID);
                } else {
                  print("❌ Error: kotMasterID is not a valid integer");
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_right_alt, color: Colors.white, size: 20),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "KOT No: ${order['KotPrefix']}${order['KotNumber']}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
