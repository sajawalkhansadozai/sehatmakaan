import 'package:flutter/material.dart';
import '../../features/bookings/widgets/live_slot_booking_widget.dart';

class LiveSlotBookingPage extends StatelessWidget {
  final Map<String, dynamic> userSession;

  const LiveSlotBookingPage({super.key, required this.userSession});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006876),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Live Slot',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: LiveSlotBookingWidget(
        userSession: userSession,
        onBooked: () {
          // Refresh dashboard after booking
          Navigator.pop(context);
        },
      ),
    );
  }
}
