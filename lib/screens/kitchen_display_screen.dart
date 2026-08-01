import 'package:flutter/material.dart';

class BlinkingKDS extends StatefulWidget {
  const BlinkingKDS({super.key});

  @override
  State<BlinkingKDS> createState() => _BlinkingKDSState();
}

class _BlinkingKDSState extends State<BlinkingKDS>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    orders = [
      {
        'kot': 'JOB-101',
        'status': 'New',
        'type': 'Dine-In',
        'location': 'Table 1',
        'time': now.subtract(const Duration(minutes: 2)),
        'items': ['Biryani', 'Raita', 'Salad', 'Water'],
      },
      {
        'kot': 'JOB-102',
        'status': 'Preparing',
        'type': 'Takeaway',
        'location': 'Token 5',
        'time': now.subtract(const Duration(minutes: 6)),
        'items': ['Burger', 'Fries'],
      },
      {
        'kot': 'JOB-103',
        'status': 'New',
        'type': 'Delivery',
        'location': 'Zone A',
        'time': now.subtract(const Duration(minutes: 11)),
        'items': ['Pizza', 'Juice', 'Garlic Bread'],
      },
    ];

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void updateStatus(int index) {
    setState(() {
      if (orders[index]['status'] == 'New') {
        orders[index]['status'] = 'Preparing';
      } else if (orders[index]['status'] == 'Preparing') {
        orders[index]['status'] = 'Ready';
      }
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.redAccent;
      case 'Preparing':
        return Colors.orange;
      case 'Ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth ~/ 260;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: orders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount > 0 ? crossCount : 1,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final order = orders[index];
            final items = List<String>.from(order['items']);
            final status = order['status'];
            final color = getStatusColor(status);
            final waitMinutes =
                DateTime.now().difference(order['time']).inMinutes;

            final isBlinking = waitMinutes >= 10;

            return AnimatedBuilder(
              animation: _blinkController,
              builder: (_, __) {
                final bgColor = isBlinking
                    ? Color.lerp(
                        Colors.white, Colors.red.shade100, _blinkController.value)
                    : Colors.white;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(left: BorderSide(color: color, width: 5)),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text('${order['type']} • ${order['location']}',
                          style: const TextStyle(fontSize: 13)),
                      const Divider(height: 20),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• $item',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          )),
                      const Spacer(),
                      Text('$waitMinutes min ago',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54)),
                      if (status != 'Ready')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => updateStatus(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              textStyle: const TextStyle(fontSize: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(status == 'New'
                                ? 'Start Preparing'
                                : 'Mark Ready'),
                          ),
                        )
                      else
                        Center(
                          child: Text('✓ Ready',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: color)),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
