import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';
import 'package:sehat_makaan_flutter/core/constants/types.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';

class BookingSummaryWidget extends StatelessWidget {
  final SuiteType? selectedSuite;
  final String? bookingType;
  final PackageType? selectedPackage;
  final String? selectedSpecialty;
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final int selectedHours;
  final List<Map<String, dynamic>> selectedAddons;

  const BookingSummaryWidget({
    super.key,
    required this.selectedSuite,
    required this.bookingType,
    required this.selectedPackage,
    required this.selectedSpecialty,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.selectedHours,
    required this.selectedAddons,
  });

  @override
  Widget build(BuildContext context) {
    double total = 0;
    double basePrice = 0;

    if (bookingType == 'monthly' && selectedPackage != null) {
      final packages = AppConstants.packages[selectedSuite?.value] ?? [];
      if (packages.isNotEmpty) {
        final pkg = packages.firstWhere((p) => p.type == selectedPackage);
        total += pkg.price;
        basePrice = pkg.price;
      }
    } else if (bookingType == 'hourly' && selectedSuite != null) {
      final suite = AppConstants.suites.firstWhere(
        (s) => s.type == selectedSuite,
      );
      var rate = suite.baseRate.toDouble();

      // Priority Booking addon grants access without additional rate charges
      // Users pay PKR 5,000 for addon, then use priority slots at base rate

      basePrice = rate * selectedHours;
      total += basePrice;
    }

    for (final addon in selectedAddons) {
      total += addon['price'] as double;
    }

    // Check if this is a priority slot for display
    bool isPrioritySlot = false;
    if (bookingType == 'hourly' && selectedTimeSlot != null) {
      final slotParts = selectedTimeSlot!.split(':');
      final slotHour = int.parse(slotParts[0]);
      final isWeekend =
          selectedDate.weekday == DateTime.saturday ||
          selectedDate.weekday == DateTime.sunday;
      final isPriorityTime = (slotHour >= 18 && slotHour <= 22);
      isPrioritySlot = isWeekend || isPriorityTime;
    }

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: const Color(0xFF006876).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006876),
            ),
          ),
          const Divider(),
          _buildSummaryRow('Suite', selectedSuite?.value ?? 'Not selected'),
          _buildSummaryRow('Type', bookingType ?? 'Not selected'),
          if (bookingType == 'monthly')
            _buildSummaryRow(
              'Package',
              selectedPackage?.value ?? 'Not selected',
            ),
          if (bookingType == 'hourly') ...[
            _buildSummaryRow('Specialty', selectedSpecialty ?? 'Not selected'),
            _buildSummaryRow(
              'Date',
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            ),
            if (selectedTimeSlot != null) ...[
              _buildSummaryRow('Time Slot', selectedTimeSlot!),
              if (isPrioritySlot)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFC107)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          size: 14,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Priority Slot - Addon Required',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            () {
              // Calculate actual booked hours (excluding Extended Hours bonus)
              final hasExtendedHours = selectedAddons.any(
                (a) => a['code'] == 'extended_hours',
              );
              final displayHours = hasExtendedHours
                  ? selectedHours -
                        0.5 // Subtract 30 min bonus
                  : selectedHours.toDouble();

              // Format hours display
              String hoursText;
              if (displayHours == displayHours.floor()) {
                hoursText =
                    '${displayHours.toInt()} hour${displayHours.toInt() > 1 ? 's' : ''}';
              } else {
                final hours = displayHours.floor();
                final minutes = ((displayHours - hours) * 60).round();
                hoursText = '${hours}h ${minutes}m';
              }

              return _buildSummaryRow(
                'Duration',
                hoursText,
                valueStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                  fontSize: 16,
                ),
              );
            }(),
            // Show Extended Hours bonus if addon is added
            if (selectedAddons.any((a) => a['code'] == 'extended_hours'))
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        size: 14,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '🎁 +30 min Bonus (Extended Hours addon)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (basePrice > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base Price:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'PKR ${basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006876),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (selectedAddons.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Add-ons:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...selectedAddons.map(
              (addon) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('• ${addon['name']}'),
                    Text(
                      'PKR ${(addon['price'] as double).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Divider(),
          Text(
            'Total: PKR ${total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
