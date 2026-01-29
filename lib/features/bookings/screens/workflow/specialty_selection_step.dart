import 'package:flutter/material.dart';
import 'package:sehatmakaan/core/constants/types.dart';
import 'package:sehatmakaan/core/utils/responsive_helper.dart';
import 'package:sehatmakaan/core/utils/price_helper.dart';

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
    SuiteType.dental: ['General Dentist', 'Specialist'],
    SuiteType.medical: ['General Medical'],
    SuiteType.aesthetic: ['Aesthetic Dermatology'],
  };

  List<String> get _filteredSpecialties {
    if (selectedSuite == null) return [];
    return suiteSpecialties[selectedSuite] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (selectedSuite == null) {
      return Center(
        child: Text(
          'Please select a suite first',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: Colors.grey,
          ),
        ),
      );
    }

    // Real-time pricing with StreamBuilder
    return StreamBuilder<Suite>(
      stream: PriceHelper.getSuiteStream(selectedSuite!.value),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006876)),
            ),
          );
        }

        // Get suite with live prices or use defaults
        final suite = snapshot.data;
        final baseRate = suite?.baseRate ?? 1500.0;
        final specialistRate = suite?.specialistRate ?? 3000.0;

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
                (specialty) =>
                    _buildSpecialtyCard(specialty, baseRate, specialistRate),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecialtyCard(
    String specialty,
    double baseRate,
    double specialistRate,
  ) {
    final isSelected = selectedSpecialty == specialty;

    // Get price based on specialty with dynamic rates
    String priceText = '';
    if (specialty == 'General Dentist' || specialty == 'General Medical') {
      priceText = '(PKR ${baseRate.toStringAsFixed(0)}/hour)';
    } else if (specialty == 'Specialist' ||
        specialty == 'Aesthetic Dermatology') {
      priceText = '(PKR ${specialistRate.toStringAsFixed(0)}/hour)';
    }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              specialty,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF006876),
                fontSize: 16,
              ),
            ),
            if (priceText.isNotEmpty)
              Text(
                priceText,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFFFF6B35),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF006876))
            : null,
      ),
    );
  }
}
