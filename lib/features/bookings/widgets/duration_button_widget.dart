import 'package:flutter/material.dart';

class DurationButtonWidget extends StatelessWidget {
  final double hours;
  final String label;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final DateTime selectedDate;
  final String? selectedSubscriptionId;
  final List<Map<String, dynamic>> subscriptions;
  final int maxPossibleDuration; // NEW: Max duration from slot service
  final VoidCallback onPressed;

  const DurationButtonWidget({
    super.key,
    required this.hours,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.selectedDate,
    required this.selectedSubscriptionId,
    required this.subscriptions,
    required this.maxPossibleDuration,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Check if selected subscription has Extended Hours addon
    bool hasExtendedHours = false;

    final subscriptionToCheck =
        selectedSubscriptionId ??
        (subscriptions.isNotEmpty ? subscriptions[0]['id'] as String? : null);

    if (subscriptionToCheck != null) {
      final selectedSub = subscriptions.firstWhere(
        (sub) => sub['id'] == subscriptionToCheck,
        orElse: () => {},
      );

      if (selectedSub.isNotEmpty) {
        final addons = selectedSub['selectedAddons'] as List?;
        if (addons != null) {
          hasExtendedHours = addons.any(
            (addon) => addon['code'] == 'extended_hours',
          );
        }
      }
    }

    final extraMinutes = hasExtendedHours ? 30 : 0;
    final expectedDuration = (hours * 60).toInt() + extraMinutes;

    final isSelected =
        startTime != null &&
        endTime != null &&
        ((endTime!.hour * 60 + endTime!.minute) -
                (startTime!.hour * 60 + startTime!.minute)) ==
            expectedDuration;

    // Disable if requested duration exceeds maxPossibleDuration from slot service
    final isDisabled = hours.toInt() > maxPossibleDuration;

    return InkWell(
      onTap: isDisabled ? null : onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF006876), Color(0xFF008C9E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF006876)
                  : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF006876).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: isSelected ? Colors.white : const Color(0xFF006876),
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF006876),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
