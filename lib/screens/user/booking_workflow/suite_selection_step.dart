import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/utils/constants.dart';
import 'package:sehat_makaan_flutter/utils/types.dart';

class SuiteSelectionStep extends StatelessWidget {
  final SuiteType? selectedSuite;
  final Function(SuiteType) onSuiteSelected;

  const SuiteSelectionStep({
    super.key,
    required this.selectedSuite,
    required this.onSuiteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Choose Your Suite Type',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the type of medical suite for your practice',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...AppConstants.suites.map(
            (suite) => _buildSuiteCard(
              suite.type,
              suite.name,
              suite.description,
              suite.baseRate.toDouble(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuiteCard(
    SuiteType type,
    String name,
    String description,
    double baseRate,
  ) {
    final isSelected = selectedSuite == type;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF006876) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => onSuiteSelected(type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF006876).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSuiteIcon(type),
                  size: 32,
                  color: const Color(0xFF006876),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006876),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF006876).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PKR ${baseRate.toStringAsFixed(0)}/hour',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF006876),
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSuiteIcon(SuiteType suiteType) {
    switch (suiteType) {
      case SuiteType.dental:
        return Icons.medical_services;
      case SuiteType.medical:
        return Icons.local_hospital;
      case SuiteType.aesthetic:
        return Icons.spa;
    }
  }
}
