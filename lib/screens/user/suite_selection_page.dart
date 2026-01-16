import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/types.dart';

class SuiteSelectionPage extends StatelessWidget {
  final Map<String, dynamic>? userSession;
  final Function(SuiteType)? onSuiteSelected;

  const SuiteSelectionPage({super.key, this.userSession, this.onSuiteSelected});

  void _handleSuiteSelect(BuildContext context, SuiteType suiteType) {
    debugPrint('🔍 Suite Selection - userSession: $userSession');
    debugPrint('🔍 Suite Selection - fullName: ${userSession?['fullName']}');
    onSuiteSelected?.call(suiteType);
    Navigator.pushNamed(
      context,
      '/packages',
      arguments: {'userSession': userSession, 'selectedSuite': suiteType},
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'tooth':
        return Icons.medication;
      case 'stethoscope':
        return Icons.medical_services;
      case 'magic':
        return Icons.auto_awesome;
      default:
        return Icons.local_hospital;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006876)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose Suite',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Choose Your Suite',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Select the specialized workspace that matches your practice',
              style: TextStyle(
                fontSize: 18,
                color: const Color(0xFF006876).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AppConstants.suites.map((suite) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildSuiteCard(context, suite),
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  return Column(
                    children: AppConstants.suites.map((suite) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildSuiteCard(context, suite),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuiteCard(BuildContext context, Suite suite) {
    return InkWell(
      onTap: () => _handleSuiteSelect(context, suite.type),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF90D26D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIconData(suite.icon),
                size: 40,
                color: const Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              suite.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              suite.description,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF006876).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        suite.type == SuiteType.dental
                            ? 'General Dentist'
                            : 'Base Rate',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF006876),
                        ),
                      ),
                      Text(
                        'PKR ${suite.baseRate.toStringAsFixed(0)}/hr',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                  if (suite.specialistRate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Specialists',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF006876),
                          ),
                        ),
                        Text(
                          'PKR ${suite.specialistRate!.toStringAsFixed(0)}/hr',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...suite.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF90D26D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF006876).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleSuiteSelect(context, suite.type),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Select ${suite.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
