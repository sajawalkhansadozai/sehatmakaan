import 'package:flutter/material.dart';
import 'package:sehatmakaan/core/utils/responsive_helper.dart';
import 'package:sehatmakaan/core/utils/price_helper.dart';
import 'package:sehatmakaan/core/constants/types.dart';

class AddonsSelectionStep extends StatefulWidget {
  final List<Map<String, dynamic>> selectedAddons;
  final Function(Map<String, dynamic>) onAddonToggle;
  final bool isHourlyBooking;

  const AddonsSelectionStep({
    super.key,
    required this.selectedAddons,
    required this.onAddonToggle,
    required this.isHourlyBooking,
  });

  @override
  State<AddonsSelectionStep> createState() => _AddonsSelectionStepState();
}

class _AddonsSelectionStepState extends State<AddonsSelectionStep> {
  static const List<Map<String, dynamic>> availableAddons = [
    // Monthly package addons
    {
      'name': 'Extra 10 Hour Block',
      'description': 'Add 10 additional hours',
      'code': 'extra_10_hours',
      'forMonthlyOnly': true,
    },
    {
      'name': 'Dedicated Locker',
      'description': 'Store your equipment securely',
      'code': 'dedicated_locker',
      'forMonthlyOnly': true,
    },
    {
      'name': 'Clinical Assistant',
      'description': 'Professional assistant support',
      'code': 'clinical_assistant',
      'forMonthlyOnly': true,
    },
    {
      'name': 'Social Media Highlight',
      'description': 'Featured on our social media',
      'code': 'social_media',
      'forMonthlyOnly': true,
    },
    // Hourly booking addons
    {
      'name': 'Dental assistant (30 mins)',
      'description': 'Professional dental assistant support',
      'code': 'dental_assistant',
      'forMonthlyOnly': false,
    },
    {
      'name': 'Medical nurse (30 mins)',
      'description': 'Professional medical nurse support',
      'code': 'medical_nurse',
      'forMonthlyOnly': false,
    },
    {
      'name': 'Intraoral x-ray use',
      'description': 'Access to intraoral x-ray equipment',
      'code': 'intraoral_xray',
      'forMonthlyOnly': false,
    },
    {
      'name': 'Priority booking',
      'description': 'Access weekends and 6PM-10PM slots',
      'code': 'priority_booking',
      'forMonthlyOnly': false,
    },
    {
      'name': 'Extended hours (get 30 mins extra)',
      'description': 'Get 30 minutes bonus per booking',
      'code': 'extended_hours',
      'forMonthlyOnly': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Real-time pricing with StreamBuilder
    return StreamBuilder<List<Addon>>(
      stream: widget.isHourlyBooking
          ? PriceHelper.getHourlyAddonsStream()
          : PriceHelper.getMonthlyAddonsStream(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006876)),
            ),
          );
        }

        // Get live addons or fallback to empty list
        final liveAddons = snapshot.data ?? [];

        // Merge with metadata
        final displayAddons = availableAddons
            .where((addon) {
              if (widget.isHourlyBooking) {
                return addon['forMonthlyOnly'] != true;
              } else {
                return addon['forMonthlyOnly'] == true;
              }
            })
            .map((addon) {
              // Find matching live price
              final liveAddon = liveAddons.firstWhere(
                (la) => la.code == addon['code'],
                orElse: () => Addon(
                  name: addon['name'] as String,
                  description: addon['description'] as String,
                  price: 0,
                  code: addon['code'] as String,
                ),
              );

              return {
                'name': addon['name'],
                'description': addon['description'],
                'price': liveAddon.price,
                'code': addon['code'],
              };
            })
            .toList();

        return _buildAddonsList(displayAddons);
      },
    );
  }

  Widget _buildAddonsList(List<Map<String, dynamic>> addons) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isHourlyBooking
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
          ...addons.map(
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
    final isSelected = widget.selectedAddons.any(
      (addon) => addon['code'] == code,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          widget.onAddonToggle({'name': name, 'code': code, 'price': price});
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
