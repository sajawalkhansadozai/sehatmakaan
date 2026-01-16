import 'package:flutter/material.dart';

class SpecialtySelectionStep extends StatelessWidget {
  final String? selectedSpecialty;
  final int selectedHours;
  final Function(String) onSpecialtySelected;
  final Function(int) onHoursChanged;

  const SpecialtySelectionStep({
    super.key,
    required this.selectedSpecialty,
    required this.selectedHours,
    required this.onSpecialtySelected,
    required this.onHoursChanged,
  });

  static const List<String> specialties = [
    'General Dentist',
    'Orthodontist',
    'Endodontist',
    'Maxillofacial Surgery',
    'Prosthodontist',
    'Pediatric Dentist',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 3: Select Your Specialty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your specialty for hourly booking',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...specialties.map((specialty) => _buildSpecialtyCard(specialty)),
          const SizedBox(height: 24),
          const Text(
            'Hours to Book',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: selectedHours > 1
                    ? () => onHoursChanged(selectedHours - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 40,
                color: const Color(0xFF006876),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$selectedHours hour${selectedHours > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006876),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: selectedHours < 8
                    ? () => onHoursChanged(selectedHours + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 40,
                color: const Color(0xFF006876),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyCard(String specialty) {
    final isSelected = selectedSpecialty == specialty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF006876) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: () => onSpecialtySelected(specialty),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF006876).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.medical_services, color: Color(0xFF006876)),
        ),
        title: Text(
          specialty,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF006876),
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF006876))
            : null,
      ),
    );
  }
}
