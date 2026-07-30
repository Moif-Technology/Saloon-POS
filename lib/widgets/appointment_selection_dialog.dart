import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/services/api_service.dart';
import 'package:intl/intl.dart';

class AppointmentSelectionDialog extends ConsumerStatefulWidget {
  final Function(String appointmentId, String customerId, String stylistId) onAppointmentSelected;
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
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _fetchAppointments();
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

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _fetchAppointments();
  }

  void _onAppointmentTap(Map<String, dynamic> appointment) {
    widget.onAppointmentSelected(
      appointment['appointmentId'] as String,
      appointment['customerId'].toString(),
      appointment['stylistId'].toString(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Appointment or Create Walk-In',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onNewWalkIn,
                    icon: const Icon(Icons.add),
                    label: const Text('New Walk-In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      _onDateSelected(picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(),
            const SizedBox(height: 12),
            const Text('Appointments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: _buildAppointmentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (appointments.isEmpty) {
      return Center(
        child: Text(
          'No appointments on ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final time = appt['appointmentTime'] ?? 'N/A';
        final customerName = appt['customerName'] ?? 'Unknown';
        final stylistName = appt['stylistName'] ?? 'Unknown';
        final duration = appt['durationMinutes'] ?? 60;
        final services = appt['serviceNames'] ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            onTap: () => _onAppointmentTap(appt),
            title: Text('$time — $customerName'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stylist: $stylistName'),
                Text('Duration: ${duration}min'),
                if (services.isNotEmpty)
                  Text('Services: ${services.join(', ')}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward),
          ),
        );
      },
    );
  }
}
