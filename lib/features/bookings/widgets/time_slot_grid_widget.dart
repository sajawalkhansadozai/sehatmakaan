import 'package:flutter/material.dart';

class TimeSlotGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> availableSlots;
  final String? selectedTime;
  final bool isLoading;
  final ValueChanged<String> onSlotSelected;

  const TimeSlotGridWidget({
    super.key,
    required this.availableSlots,
    required this.selectedTime,
    required this.isLoading,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time Slot',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006876),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a slot to set your start time',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableSlots.map((slotData) {
                  final slot = slotData['slot'] as String;
                  final maxDuration = slotData['maxPossibleDuration'] as int;
                  final isSelected = selectedTime == slot;
                  return Tooltip(
                    message:
                        'Max: $maxDuration hour${maxDuration > 1 ? 's' : ''}',
                    child: ChoiceChip(
                      label: Text(slot),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          onSlotSelected(slot);
                        }
                      },
                      selectedColor: const Color(0xFF006876),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}
