import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/providers/providers.dart';
import 'package:my_app/utils/empty_kot_response.dart';
import 'package:my_app/widgets/common/responsive_scaler.dart';
import 'package:timelines_plus/timelines_plus.dart';

class DeliveryManagementDesktopPage extends ConsumerStatefulWidget {
  const DeliveryManagementDesktopPage({super.key});

  @override
  ConsumerState<DeliveryManagementDesktopPage> createState() =>
      _DeliveryManagementDesktopPageState();
}

class _DeliveryManagementDesktopPageState
    extends ConsumerState<DeliveryManagementDesktopPage> {
  List<Map<String, dynamic>> deliveryBoys = [];

  String selectedStatusFilter = 'All';
  bool isAscending = true;
  Map<String, dynamic>? selectedKot;
  String searchQuery = '';
  Set<Map<String, dynamic>> selectedPendingKots = {};
  Map<String, dynamic>? activeKot;

  final List<String> statusOrder = [
    'HOLD', // 🔁 Changed from 'Pending'
    'Accepted',
    'Preparing',
    'Ready for Pickup',
    'Out for Delivery',
    'Delivered'
  ];

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0.0;
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  // Updated color palette to match TopBar
  final Color appBarColor =
      const Color.fromRGBO(82, 28, 29, 1); // Primary dark maroon
  final Color leftPanelColor =
      const Color.fromRGBO(82, 28, 29, 1); // Same as top bar
  final Color searchBoxFill =
      const Color.fromRGBO(128, 0, 0, 1); // Mid maroon tone
  final Color statusColor = Colors.orange.shade100;

  String? getNextStatus(String currentStatus) {
    final index = statusOrder.indexOf(currentStatus);
    if (index != -1 && index < statusOrder.length - 1) {
      return statusOrder[index + 1];
    }
    return null;
  }

  bool _isStepReached(String currentStatus, String step) {
    const statusOrder = [
      'HOLD', // 🔁 Changed from 'Pending'
      'Accepted',
      'Preparing',
      'Ready for Pickup',
      'Out for Delivery',
      'Delivered'
    ];

    return statusOrder.indexOf(currentStatus) >= statusOrder.indexOf(step);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'HOLD':
        return Colors.grey;
      case 'Accepted':
        return Colors.blue;
      case 'Preparing':
        return Colors.black87;
      case 'Ready for Pickup':
        return Colors.black;
      case 'Out for Delivery':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return DateFormat('hh:mm a').format(time);
    }
  }

  void updateDeliveryBoy(String? newDeliveryBoy) {
    setState(() {
      selectedKot!['deliveryBoy'] = newDeliveryBoy;
    });
  }

  void updateStatus(String newStatus) {
    setState(() {
      selectedKot!['status'] = newStatus;
    });
  }

  Widget buildImprovedTimeline(String currentStatus) {
    final steps = [
      {
        'label': 'Order Placed',
        'icon': Icons.shopping_cart,
        'time': '9:15 AM',
        'staff': 'System'
      },
      {
        'label': 'Preparing',
        'icon': Icons.kitchen,
        'time': '9:30 AM',
        'staff': 'Chef Ali'
      },
      {
        'label': 'Ready for Pickup',
        'icon': Icons.outbox,
        'time': '9:50 AM',
        'staff': 'Packing Team'
      },
      {
        'label': 'Out for Delivery',
        'icon': Icons.delivery_dining,
        'time': '10:10 AM',
        'staff': 'Rashid'
      },
      {
        'label': 'Delivered',
        'icon': Icons.check_circle,
        'time': '—',
        'staff': 'Customer'
      },
    ];

    int currentStep = steps.indexWhere((s) => s['label'] == currentStatus);
    if (currentStep == -1) currentStep = 0;

    Color getColor(int index) {
      if (index < currentStep) return Colors.green;
      if (index == currentStep) return Colors.orange;
      return Colors.grey.shade300;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🔥 FIX: SizedBox to define height
        SizedBox(
          height: 180,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stepWidth = constraints.maxWidth / steps.length;

              return Timeline.tileBuilder(
                theme: TimelineThemeData(
                  direction: Axis.horizontal,
                  connectorTheme: const ConnectorThemeData(
                    thickness: 5,
                    space: 30,
                  ),
                ),
                builder: TimelineTileBuilder.connected(
                  itemCount: steps.length,
                  itemExtentBuilder: (_, __) => stepWidth,
                  connectionDirection: ConnectionDirection.before,
                  indicatorBuilder: (_, index) {
                    final reached = index <= currentStep;
                    final isActive = index == currentStep;

                    return DotIndicator(
                      size: 30,
                      color: getColor(index),
                      child: reached
                          ? Icon(
                              index == currentStep
                                  ? steps[index]['icon'] as IconData
                                  : Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    );
                  },
                  connectorBuilder: (_, index, __) {
                    final from = getColor(index);
                    final to = getColor(index + 1);
                    return DecoratedLineConnector(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [from, to]),
                      ),
                    );
                  },
                  oppositeContentsBuilder: (_, index) {
                    final icon = steps[index]['icon'] as IconData;
                    final color = getColor(index);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 24, color: color),
                        const SizedBox(height: 4),
                      ],
                    );
                  },
                  contentsBuilder: (_, index) {
                    final label = steps[index]['label'] as String;
                    final time = steps[index]['time'] as String;
                    final staff = steps[index]['staff'] as String;
                    final color = getColor(index);
                    final isCurrent = index == currentStep;
                    final isDone = index < currentStep;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Time: $time',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        if (isCurrent)
                          Text(
                            'By: $staff',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.brown),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDone
                                ? Colors.green.shade100
                                : isCurrent
                                    ? Colors.orange.shade100
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isDone
                                ? 'Done'
                                : isCurrent
                                    ? 'In Progress'
                                    : 'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDone
                                  ? Colors.green
                                  : isCurrent
                                      ? Colors.orange
                                      : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),

        // ✅ Delivery Complete Message
        if (currentStep == steps.length - 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '🎉 Delivery Completed',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          )
      ],
    );
  }

  String _mapLabel(String short) {
    switch (short) {
      case 'Ready':
        return 'Ready for Pickup';
      case 'Delivering':
        return 'Out for Delivery';
      case 'Completed':
        return 'Delivered';
      default:
        return short;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDeliveryKots();
    fetchDeliveryBoyList(); // ← NEW
  }

  void fetchDeliveryBoyList() async {
    try {
      final list = <Map<String, dynamic>>[];
      setState(() {
        deliveryBoys = list;
      });
    } catch (e) {
      print("❌ Error fetching delivery boys: $e");
    }
  }

  void fetchDeliveryKots() async {
    try {
      final deliveryList = <Map<String, dynamic>>[];
      print(deliveryList);
      setState(() {
        ref.read(deliveryKotsProvider.notifier).state = deliveryList.map((kot) {
          return {
            'kotMasterID': kot['kotMasterID'],
            'kotNo': 'Job - ${kot['KotPrefix']}${kot['KotNumber']}',
            'customer': kot['CustomerName'] ?? 'Unknown Customer',
            'status': kot['KOTStatus'].toString().trim(),
            'time': DateTime.tryParse((kot['KotTime'] ?? '').toString()) ??
                DateTime.now(),
            'total': _asDouble(kot['total']), // if ever present

            // ✅ Add these dummy/defaults to avoid null error
            'items': [],
            'address': '',
            'customerInfo': '',
            'deliveryBoy': '',
            'deliveryBoyInfo': '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching delivery List: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveScaler.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Delivery Jobs",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 900;
          return isSmall
              ? Column(
                  children: [
                    Expanded(child: _buildLeftPanel()),
                    if (selectedKot != null)
                      Expanded(child: _buildMainDetails())
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 250, child: _buildLeftPanel()),
                    Expanded(flex: 3, child: _buildMainDetails()),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildLeftPanel() {
    final TextEditingController _searchController = TextEditingController();

    final kotList = ref.watch(deliveryKotsProvider);
    final filteredKots = searchQuery.trim().isEmpty
        ? kotList
        : kotList
            .where((kot) => kot['kotNo']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();

    return Container(
      color: leftPanelColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Search job number...",
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Colors.white54),
                filled: true,
                fillColor: Colors.brown.shade700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 2),
              itemCount: filteredKots.length,
              itemBuilder: (context, index) {
                final kot = filteredKots[index];
                final isSelected =
                    selectedKot == kot || selectedPendingKots.contains(kot);

                return InkWell(
                  onTap: () async {
                    print(
                        "👉 Tapped on KOT: ${kot['kotNo']} with status: ${kot['status']}");

                    try {
                      final response = await emptyKotDetails();

                      final List<dynamic> data = response['data'] ?? [];
                      if (data.isEmpty) return;

                      final kotItems = data
                          .map((e) => {
                                'name': e['ShortDescription'] ?? '',
                                'quantity': _asDouble(e['Qty']),
                                'price': _asDouble(e['UnitPrice']),
                              })
                          .toList();

                      final enrichedKot = {
                        ...kot,
                        'items': kotItems,
                        'total': data.fold<double>(0.0,
                            (sum, item) => sum + _asDouble(item['LineTotal'])),
                        'customer': data[0]['CustName'] ?? '',
                        'address': data[0]['CustAddress'] ?? '',
                        'customerInfo': data[0]['CustMobile'] ?? '',
                      };

                      if (kot['status'].toString().toUpperCase() == 'HOLD') {
                        print(
                            "🟡 HOLD KOT — toggling selection after data fetch");

                        setState(() {
                          if (selectedPendingKots.containsWhere(
                              (e) => e['kotNo'] == kot['kotNo'])) {
                            selectedPendingKots
                                .removeWhere((e) => e['kotNo'] == kot['kotNo']);
                            print("❌ Removed from pending selection");
                          } else {
                            selectedPendingKots.add(enrichedKot);
                            print("✅ Added to pending selection with details");
                          }
                        });
                      } else {
                        print("🔵 Not HOLD — setting selectedKot");

                        setState(() {
                          selectedKot = enrichedKot;
                          selectedPendingKots
                              .clear(); // clear hold selection if navigating to single view
                        });
                      }
                    } catch (e) {
                      print("❌ Error during API call: $e");
                    }
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 1),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long,
                            size: 16, color: Colors.brown),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kot['kotNo'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 11),
                              ),
                              Text(
                                kot['customer'],
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getStatusColor(kot['status']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                kot['status'],
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              formatTime(kot['time']),
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMainDetails() {
    if (selectedPendingKots.length > 1) {
      String? selectedBoy;

      return Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox.expand(
          child: Align(
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Multiple Pending Jobs Selected",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // ✅ KOT Summary Cards
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: selectedPendingKots.map((kot) {
                      final itemNames =
                          kot['items'].map((e) => e['name']).join(', ');
                      return Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                          border: Border(
                            left: BorderSide(
                              color: _getStatusColor(kot['status']),
                              width: 5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    kot['kotNo'],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatTime(kot['time']),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        selectedPendingKots.remove(kot);
                                      });
                                    },
                                    color: Colors.redAccent,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                kot['customer'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 14, color: Colors.deepPurple),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      kot['address'],
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.fastfood,
                                      size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      itemNames,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.shopping_basket,
                                      size: 14, color: Colors.brown),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Items: ${kot['items'].length}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const Spacer(),
                                  Image.asset(
                                    'assets/dirhams.png',
                                    width: 14,
                                    height: 14,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _asDouble(kot['total']).toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // ✅ Delivery Boy Quick Assignment
                  const Text(
                    "Assign to Delivery Boy",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: deliveryBoys.map((boy) {
                      final name = boy['StaffName'] ?? '';
                      final contact = boy['ContactNo'] ?? '';

                      return ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            for (var kot in selectedPendingKots) {
                              kot['deliveryBoy'] = name;
                              kot['deliveryBoyInfo'] = 'Contact: $contact';
                              kot['status'] = 'Out for Delivery';
                            }
                            selectedPendingKots.clear();
                          });

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "Assigned $name to selected jobs successfully"),
                            backgroundColor: Colors.green.shade700,
                          ));
                        },
                        icon: const Icon(Icons.delivery_dining),
                        label: Text(name),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (selectedPendingKots.length == 1) {
      return _buildKotCard(selectedPendingKots.first);
    }

    if (selectedKot == null) {
      return const Center(
        child: Text("Select a job to view details",
            style: TextStyle(fontSize: 20)),
      );
    }

    return _buildKotCard(selectedKot!);
  }

  Widget _buildKotCard(Map<String, dynamic> kot) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveScaler.scale(20)),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveScaler.scale(12)),
                child: Column(
                  children: [
                    buildImprovedTimeline(kot['status']),
                    SizedBox(height: ResponsiveScaler.scale(10)),
                    Wrap(
                      spacing: ResponsiveScaler.scale(8),
                      runSpacing: ResponsiveScaler.scale(6),
                      children: statusOrder.map((status) {
                        final isCurrent = kot['status'] == status;
                        final isReached = _isStepReached(kot['status'], status);
                        return ElevatedButton.icon(
                          onPressed: isCurrent
                              ? null
                              : () => setState(() => kot['status'] = status),
                          icon: Icon(
                            status == 'Accepted'
                                ? Icons.task_alt
                                : status == 'Preparing'
                                    ? Icons.kitchen
                                    : status == 'Ready for Pickup'
                                        ? Icons.outbox
                                        : status == 'Out for Delivery'
                                            ? Icons.delivery_dining
                                            : status == 'Delivered'
                                                ? Icons.check_circle
                                                : Icons.timelapse,
                            size: ResponsiveScaler.font(14),
                          ),
                          label: Text(status,
                              style: TextStyle(
                                  fontSize: ResponsiveScaler.font(11))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrent
                                ? Colors.green.shade700
                                : isReached
                                    ? Colors.green.shade300
                                    : Colors.grey.shade300,
                            foregroundColor: isCurrent || isReached
                                ? Colors.white
                                : Colors.black87,
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveScaler.scale(10),
                              vertical: ResponsiveScaler.scale(8),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveScaler.scale(12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Job #: ${kot['kotNo']}",
                  style: TextStyle(
                    fontSize: ResponsiveScaler.font(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Image.asset(
                      'assets/dirhams.png',
                      width: ResponsiveScaler.scale(14),
                      height: ResponsiveScaler.scale(14),
                      color: Colors.green.shade700,
                    ),
                    SizedBox(width: ResponsiveScaler.scale(4)),
                    Text(
                      (kot['total'] ?? 0.0).toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: ResponsiveScaler.font(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: ResponsiveScaler.scale(8)),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveScaler.scale(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Items",
                        style: TextStyle(
                            fontSize: ResponsiveScaler.font(14),
                            fontWeight: FontWeight.bold)),
                    const Divider(),
                    Column(
                      children: List.generate(
                        kot['items'].length > 5 ? 5 : kot['items'].length,
                        (index) {
                          final item = kot['items'][index];
                          final qty = _asDouble(item['quantity']);
                          final price = _asDouble(item['price']);
                          final total = qty * price;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: ResponsiveScaler.scale(4)),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveScaler.scale(6),
                                      vertical: ResponsiveScaler.scale(2)),
                                  decoration: BoxDecoration(
                                    color: Colors.brown.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                      "x${_asDouble(item['quantity']).toStringAsFixed(0)}",
                                      style: TextStyle(
                                          fontSize: ResponsiveScaler.font(11))),
                                ),
                                SizedBox(width: ResponsiveScaler.scale(8)),
                                Expanded(
                                  child: Text(item['name'],
                                      style: TextStyle(
                                          fontSize: ResponsiveScaler.font(12))),
                                ),
                                Text("AED ${total.toStringAsFixed(2)}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: ResponsiveScaler.font(11))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveScaler.scale(12)),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(ResponsiveScaler.scale(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Customer Info",
                              style: TextStyle(
                                  fontSize: ResponsiveScaler.font(14),
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: ResponsiveScaler.scale(8)),
                          TextFormField(
                            initialValue: kot['customer'],
                            decoration: const InputDecoration(
                              labelText: "Name",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) =>
                                setState(() => kot['customer'] = val),
                          ),
                          SizedBox(height: ResponsiveScaler.scale(8)),
                          TextFormField(
                            initialValue: kot['address'],
                            decoration: const InputDecoration(
                              labelText: "Address",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) =>
                                setState(() => kot['address'] = val),
                          ),
                          SizedBox(height: ResponsiveScaler.scale(8)),
                          TextFormField(
                            initialValue: kot['customerInfo'],
                            decoration: const InputDecoration(
                              labelText: "Contact",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) =>
                                setState(() => kot['customerInfo'] = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveScaler.scale(12)),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(ResponsiveScaler.scale(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Delivery Assignment",
                              style: TextStyle(
                                  fontSize: ResponsiveScaler.font(14),
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: ResponsiveScaler.scale(8)),
                          DropdownButtonFormField<String>(
                            value: kot['deliveryBoy'].toString().isEmpty
                                ? null
                                : kot['deliveryBoy'],
                            decoration: const InputDecoration(
                              labelText: "Delivery Boy",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: deliveryBoys.map((boy) {
                              final name = boy['StaffName'];
                              return DropdownMenuItem<String>(
                                value: name as String,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              final selected = deliveryBoys.firstWhere(
                                (b) => b['StaffName'] == val,
                                orElse: () => {},
                              );
                              setState(() {
                                kot['deliveryBoy'] = val ?? '';
                                kot['deliveryBoyInfo'] =
                                    selected['ContactNo']?.toString() ?? '';
                              });
                            },
                          ),
                          SizedBox(height: ResponsiveScaler.scale(8)),
                          Text(
                            "Contact: ${kot['deliveryBoyInfo']}",
                            style:
                                TextStyle(fontSize: ResponsiveScaler.font(12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveScaler.scale(14)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.save, size: ResponsiveScaler.font(14)),
                  label: Text("Save",
                      style: TextStyle(fontSize: ResponsiveScaler.font(13))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveScaler.scale(14),
                      vertical: ResponsiveScaler.scale(10),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveScaler.scale(10)),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.print, size: ResponsiveScaler.font(14)),
                  label: Text("Print",
                      style: TextStyle(fontSize: ResponsiveScaler.font(13))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveScaler.scale(14),
                      vertical: ResponsiveScaler.scale(10),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildKotDetails(Map<String, dynamic> kot) {
    final currentStatus = kot['status'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade300, blurRadius: 10)
              ],
            ),
            constraints: const BoxConstraints(minHeight: 200, maxHeight: 280),
            child: buildImprovedTimeline(currentStatus),
          ),
          const SizedBox(height: 20),
          // Optional: reuse existing layout logic for kot
          // You may copy content from _buildMainDetails and replace selectedKot with kot
        ],
      ),
    );
  }
}

// 🔁 Custom Set extension for comparing KOTs based on condition
extension SetKotHelper on Set<Map<String, dynamic>> {
  bool containsWhere(bool Function(Map<String, dynamic>) test) {
    for (final element in this) {
      if (test(element)) return true;
    }
    return false;
  }

  void removeWhere(bool Function(Map<String, dynamic>) test) {
    final toRemove = where(test).toList();
    for (final item in toRemove) {
      remove(item);
    }
  }
}
