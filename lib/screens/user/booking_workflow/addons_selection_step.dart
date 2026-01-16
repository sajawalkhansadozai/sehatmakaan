import 'package:flutter/material.dart';

class AddonsSelectionStep extends StatelessWidget {
  final List<Map<String, dynamic>> selectedAddons;
  final Function(Map<String, dynamic>) onAddonToggle;
  final bool isHourlyBooking;

  const AddonsSelectionStep({
    super.key,
    required this.selectedAddons,
    required this.onAddonToggle,
    required this.isHourlyBooking,
  });

  static const List<Map<String, dynamic>> availableAddons = [
    {
      'name': 'Extra 10 Hour Block',
      'description': 'Add 10 additional hours (Monthly only)',
      'price': 15000.0,
      'code': 'extra_10_hours',
      'forMonthlyOnly': true,
    },
    {
      'name': 'Priority Booking',
      'description': 'Access weekends and 6PM-10PM slots (1.5x rate)',
      'price': 5000.0,
      'code': 'priority_booking',
      'forMonthlyOnly': false,
    },
    {
      'name': 'Extended Hours',
      'description': 'Unlock 11PM-12AM slots + 30 mins per booking',
      'price': 8000.0,
      'code': 'extended_hours',
      'forMonthlyOnly': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter add-ons based on booking type
    final filteredAddons = availableAddons.where((addon) {
      if (isHourlyBooking) {
        // For hourly bookings, exclude monthly-only add-ons
        return addon['forMonthlyOnly'] != true;
      }
      // For monthly bookings, show all add-ons
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHourlyBooking
                ? 'Step 3: Add-ons (Optional)'
                : 'Step 4: Add-ons (Optional)',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enhance your booking with optional add-ons',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...filteredAddons.map(
            (addon) => _buildAddonItem(
              addon['name'] as String,
              addon['description'] as String,
              addon['price'] as double,
              addon['code'] as String,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonItem(
    String name,
    String description,
    double price,
    String code,
  ) {
    final isSelected = selectedAddons.any((addon) => addon['code'] == code);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          onAddonToggle({'name': name, 'code': code, 'price': price});
        },
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF006876),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              'PKR ${price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF006876),
      ),
    );
  }
}
