import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/services/api_service.dart';
import 'package:intl/intl.dart';

class AppointmentSelectionDialog extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic> appointmentData) onAppointmentSelected;
  final Function() onNewWalkIn;

  const AppointmentSelectionDialog({
    super.key,
    required this.onAppointmentSelected,
    required this.onNewWalkIn,
  });

  @override
  ConsumerState<AppointmentSelectionDialog> createState() => _AppointmentSelectionDialogState();
}

class _AppointmentSelectionDialogState extends ConsumerState<AppointmentSelectionDialog> {
  late DateTime selectedDate;
  TimeOfDay selectedTime = const TimeOfDay(hour: 12, minute: 0);
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _fetchAppointments();
    _fetchCustomers();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final response = await ApiService().fetchAppointmentsByDate(formattedDate);
      setState(() {
        appointments = response.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load appointments: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      final response = await ApiService().fetchCustomers();
      setState(() {
        customers = response.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Failed to fetch customers: $e');
    }
  }

  void _selectAppointment(Map<String, dynamic> appointment) {
    widget.onAppointmentSelected({
      'appointmentId': appointment['AppointmentID']?.toString() ?? appointment['appointmentId']?.toString() ?? '',
      'customerId': appointment['CustomerID']?.toString() ?? appointment['customerId']?.toString() ?? '',
      'stylistId': appointment['StylistID']?.toString() ?? appointment['stylistId']?.toString() ?? '',
      'customerName': appointment['customerName'] ?? appointment['CustomerName'] ?? 'Customer',
      'stylistName': appointment['stylistName'] ?? appointment['StylistName'] ?? 'Stylist',
      'appointmentDate': appointment['appointmentDate'] ?? appointment['AppointmentDate'] ?? '',
      'appointmentTime': appointment['appointmentTime'] ?? appointment['AppointmentTime'] ?? '',
      'durationMinutes': appointment['durationMinutes'] ?? appointment['DurationMinutes'] ?? 60,
      'serviceIds': appointment['serviceIds'] ?? [],
      'serviceNames': appointment['serviceNames'] ?? [],
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) Navigator.pop(context);
    });
  }

  void _showCustomerSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF7B1C1C), const Color(0xFF521C1D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Customer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: customers.isEmpty
                    ? Center(
                        child: Text(
                          'No customers found',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: customers.length,
                        itemBuilder: (context, i) {
                          final cust = customers[i];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              widget.onAppointmentSelected({
                                'isWalkIn': true,
                                'customerName': cust['CustomerName'] ?? 'Walk-In',
                                'customerId': cust['CustomerID'],
                                'customerPhone': cust['ContactNumber'] ?? '',
                                'appointmentId': '',
                                'stylistId': '',
                                'stylistName': 'Stylist',
                                'appointmentDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                                'appointmentTime': selectedTime.format(context),
                                'durationMinutes': 60,
                                'serviceIds': [],
                                'serviceNames': [],
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && context.mounted) Navigator.pop(context);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cust['CustomerName'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    cust['ContactNumber'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.55,
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            _buildHeader(),
            _buildDateSection(),
            _buildQuickDateButtons(),
            Expanded(child: _buildAppointmentList()),
            _buildFooterButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF7B1C1C), const Color(0xFF521C1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Text(
                'Appointments',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.grey.shade600, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMM dd').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF521C1D),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                    _fetchAppointments();
                  }
                },
                child: const Text('Change', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          _quickBtn('Today', 0),
          const SizedBox(width: 6),
          _quickBtn('Tomorrow', 1),
          const SizedBox(width: 6),
          Expanded(child: _quickBtn('Next 7', 7)),
        ],
      ),
    );
  }

  Widget _quickBtn(String label, int days) {
    final target = DateTime.now().add(Duration(days: days));
    final isSelected = selectedDate.day == target.day;

    return OutlinedButton(
      onPressed: () {
        setState(() => selectedDate = target);
        _fetchAppointments();
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF521C1D) : Colors.transparent,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF521C1D),
        side: BorderSide(
          color: isSelected ? const Color(0xFF521C1D) : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildAppointmentList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF521C1D)),
      );
    }

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, color: Colors.grey.shade300, size: 64),
            const SizedBox(height: 12),
            Text(
              'No Appointments',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: appointments.length,
      itemBuilder: (context, i) => _appointmentTile(appointments[i]),
    );
  }

  Widget _appointmentTile(Map<String, dynamic> appt) {
    return GestureDetector(
      onTap: () => _selectAppointment(appt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(color: Color(0xFF521C1D), shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt['appointmentTime'] ?? 'N/A',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF521C1D)),
                      ),
                      Text(
                        appt['customerName'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: _showCustomerSelectionDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Create Walk-In'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
