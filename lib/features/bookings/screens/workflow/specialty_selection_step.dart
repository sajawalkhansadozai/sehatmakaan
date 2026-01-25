import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/core/constants/types.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';

class SpecialtySelectionStep extends StatelessWidget {
  final SuiteType? selectedSuite;
  final String? selectedSpecialty;
  final Function(String) onSpecialtySelected;

  const SpecialtySelectionStep({
    super.key,
    required this.selectedSuite,
    required this.selectedSpecialty,
    required this.onSpecialtySelected,
  });

  static const Map<SuiteType, List<String>> suiteSpecialties = {
    SuiteType.dental: ['General Dentist', 'Endodontist', 'Orthodontist'],
    SuiteType.medical: ['General Medical'],
    SuiteType.aesthetic: ['Aesthetic Dermatology'],
  };

  List<String> get _filteredSpecialties {
    if (selectedSuite == null) return [];
    return suiteSpecialties[selectedSuite] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Select Your Specialty',
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
            'Choose your specialty for hourly booking',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: Colors.grey,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
          ..._filteredSpecialties.map(
            (specialty) => _buildSpecialtyCard(specialty),
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
