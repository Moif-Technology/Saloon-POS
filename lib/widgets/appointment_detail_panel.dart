import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';

class AppointmentDetailPanel extends StatefulWidget {
  final String appointmentId;
  final String customerId;
  final String stylistId;
  final Function(Map<String, dynamic>) onCheckIn;

  const AppointmentDetailPanel({
    super.key,
    required this.appointmentId,
    required this.customerId,
    required this.stylistId,
    required this.onCheckIn,
  });

  @override
  State<AppointmentDetailPanel> createState() => _AppointmentDetailPanelState();
}

class _AppointmentDetailPanelState extends State<AppointmentDetailPanel> {
  late Future<Map<String, dynamic>> appointmentFuture;

  @override
  void initState() {
    super.initState();
    appointmentFuture = ApiService().fetchAppointmentDetail(widget.appointmentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: appointmentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }

        final appointment = snapshot.data ?? {};
        final customerName = appointment['customerName'] ?? 'Unknown';
        final customerPhone = appointment['customerPhone'] ?? 'N/A';
        final customerEmail = appointment['customerEmail'] ?? 'N/A';
        final stylistName = appointment['stylistName'] ?? 'Unknown';
        final appointmentTime = appointment['appointmentTime'] ?? 'N/A';
        final durationMinutes = appointment['durationMinutes'] ?? 60;
        final services = appointment['serviceNames'] ?? [];
        final notes = appointment['notes'] ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$customerName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Time: $appointmentTime', style: const TextStyle(fontSize: 14)),
                  Text('Duration: ${durationMinutes}min', style: const TextStyle(fontSize: 14)),
                  Text('Stylist: $stylistName', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Phone: $customerPhone'),
                  Text('Email: $customerEmail'),
                  const SizedBox(height: 16),
                  const Text('Booked Services', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (services.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: services
                          .map((service) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text('• $service'),
                              ))
                          .toList(),
                    )
                  else
                    const Text('No services specified'),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(notes, style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _checkIn(appointment),
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirm Check-In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkIn(Map<String, dynamic> appointment) async {
    try {
      // In real flow, jobId is generated by job.save(). For now, use appointmentId as placeholder.
      final jobId = 'temp-job-${DateTime.now().millisecondsSinceEpoch}';
      await ApiService().checkInAppointment(widget.appointmentId, jobId);
      widget.onCheckIn(appointment);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in failed: $e')),
      );
    }
  }
}
