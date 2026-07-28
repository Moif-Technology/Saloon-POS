import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Footer extends StatefulWidget {
  @override
  _FooterState createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  String _timeString = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime(); // Initial update
    // Update time every second
    _timer =
        Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime =
        DateFormat('dd-MM-yyyy      hh:mm:ss a').format(now);
    setState(() {
      _timeString = formattedTime;
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(52, 5, 15, 1),
            Color.fromRGBO(128, 0, 0, 1),
            Color.fromRGBO(52, 5, 15, 1),
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Counter No: 1  ADMIN: ADMIN",
              style: TextStyle(color: Colors.white)),
          Text(_timeString, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
