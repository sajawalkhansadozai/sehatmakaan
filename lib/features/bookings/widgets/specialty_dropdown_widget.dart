import 'package:flutter/material.dart';

class SpecialtyDropdownWidget extends StatelessWidget {
  final String? selectedSpecialty;
  final String? selectedSubscriptionId;
  final List<Map<String, dynamic>> subscriptions;
  final ValueChanged<String?> onChanged;

  const SpecialtyDropdownWidget({
    super.key,
    required this.selectedSpecialty,
    required this.selectedSubscriptionId,
    required this.subscriptions,
    required this.onChanged,
  });

  List<Map<String, String>> _getAvailableSpecialties() {
    if (selectedSubscriptionId == null || subscriptions.isEmpty) {
      return [];
    }

    try {
      final subscription = subscriptions.firstWhere(
        (s) => s['id'] == selectedSubscriptionId,
      );

      final suiteType = subscription['suiteType'] as String?;

      switch (suiteType?.toLowerCase()) {
        case 'dental':
          return [
            {'value': 'general-dentist', 'label': 'General Dentist'},
            {'value': 'specialist-package', 'label': 'Specialist Package'},
          ];
        case 'medical':
          return [
            {'value': 'general-medical', 'label': 'General Medical'},
          ];
        case 'aesthetic':
          return [
            {
              'value': 'aesthetic-dermatology',
              'label': 'Aesthetic Dermatology',
            },
          ];
        default:
          return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting available specialties: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Specialty',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006876),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedSpecialty,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _getAvailableSpecialties().map((specialty) {
            return DropdownMenuItem(
              value: specialty['value'],
              child: Text(specialty['label']!),
            );
          }).toList(),
          onChanged: _getAvailableSpecialties().isEmpty ? null : onChanged,
        ),
      ],
    );
  }
}
