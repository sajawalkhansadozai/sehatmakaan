import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';

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
    // Monthly package addons
    {
      'name': 'Extra 10 Hour Block',
      'description': 'Add 10 additional hours',
      'price': 10000.0,
      'code': 'extra_10_hours',
      'forMonthlyOnly': true,
    },
    {
      'name': 'Dedicated Locker',
      'description': 'Store your equipment securely',
      'price': 2000.0,
      'code': 'dedicated_locker',
      'forMonthlyOnly': true,
    },
    {
      'name': 'Clinical Assistant',
      'description': 'Professional assistant support',
      'price': 5000.0,
      'code': 'clinical_assistant',
      'forMonthlyOnly': true,
    },
    {
      'name': 'Social Media Highlight',
      'description': 'Featured on our social media',
      'price': 3000.0,
      'code': 'social_media_highlight',
      'forMonthlyOnly': true,
    },
    {
      'name': 'Laboratory Access',
      'description': 'Access to laboratory facilities',
      'price': 1000.0,
      'code': 'laboratory_access',
      'forMonthlyOnly': true,
    },
    {
      'name': 'Priority Booking',
      'description': 'Priority access to time slots',
      'price': 2500.0,
      'code': 'priority_booking',
      'forMonthlyOnly': true,
    },
    // Hourly booking addons
    {
      'name': 'Dental assistant (30 mins)',
      'description': 'Professional dental assistant support',
      'price': 500.0,
      'code': 'dental_assistant',
      'forMonthlyOnly': false,
    },
    {
      'name': 'Medical nurse (30 mins)',
      'description': 'Professional medical nurse support',
      'price': 500.0,
      'code': 'medical_nurse',
      'forMonthlyOnly': false,
    },
    {
      'name': 'Intraoral x-ray use',
      'description': 'Access to intraoral x-ray equipment',
      'price': 300.0,
      'code': 'intraoral_xray',
      'forMonthlyOnly': false,
    },
    {
      'name': 'Priority booking',
      'description': 'Access weekends and 6PM-10PM slots',
      'price': 500.0,
      'code': 'priority_booking',
      'forMonthlyOnly': false,
    },
    {
      'name': 'Extended hours (get 30 mins extra)',
      'description': 'Get 30 minutes bonus per booking',
      'price': 500.0,
      'code': 'extended_hours',
      'forMonthlyOnly': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter add-ons based on booking type
    final filteredAddons = availableAddons.where((addon) {
      if (isHourlyBooking) {
        // For hourly bookings, show only hourly add-ons
        return addon['forMonthlyOnly'] != true;
      } else {
        // For monthly bookings, show only monthly add-ons
        return addon['forMonthlyOnly'] == true;
      }
    }).toList();

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHourlyBooking
                ? 'Step 3: Add-ons (Optional)'
                : 'Step 4: Add-ons (Optional)',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006876),
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(context) * 0.3,
          ),
          Text(
            'Enhance your booking with optional add-ons',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: Colors.grey,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
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
