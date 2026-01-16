import 'package:flutter/material.dart';

class BookingTypeSelectionStep extends StatelessWidget {
  final String? bookingType;
  final Function(String) onTypeSelected;

  const BookingTypeSelectionStep({
    super.key,
    required this.bookingType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: Select Booking Type',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose between monthly packages or hourly bookings',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildBookingTypeCard(
            'Monthly Package',
            'Subscribe to a monthly package with fixed hours',
            Icons.calendar_month,
            'monthly',
          ),
          const SizedBox(height: 16),
          _buildBookingTypeCard(
            'Hourly Booking',
            'Book individual hours as needed',
            Icons.schedule,
            'hourly',
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTypeCard(
    String title,
    String description,
    IconData icon,
    String type,
  ) {
    final isSelected = bookingType == type;

    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF006876) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => onTypeSelected(type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF006876).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 32, color: const Color(0xFF006876)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006876),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF006876).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF006876),
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
