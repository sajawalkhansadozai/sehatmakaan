import 'package:flutter/material.dart';

class AgreementPage extends StatelessWidget {
  const AgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006876)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Agreement',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF90D26D),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.description,
                    size: 40,
                    color: Color(0xFF006876),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'User Agreement',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please review and accept the terms to continue with your registration',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildAgreementItem(
                        icon: Icons.person_outline,
                        title: 'Patient Ownership',
                        description:
                            'You maintain complete ownership and responsibility for your patient relationships, medical records, and treatment decisions.',
                      ),
                      const SizedBox(height: 24),
                      _buildAgreementItem(
                        icon: Icons.shield_outlined,
                        title: 'Data Privacy',
                        description:
                            'All patient data remains confidential and under your control. We do not access or store patient medical information.',
                      ),
                      const SizedBox(height: 24),
                      _buildAgreementItem(
                        icon: Icons.handshake_outlined,
                        title: 'Independent Practice',
                        description:
                            'You practice independently with full autonomy over your clinical decisions and patient care protocols.',
                      ),
                      const SizedBox(height: 24),
                      _buildAgreementItem(
                        icon: Icons.home_outlined,
                        title: 'Fair Use of Space',
                        description:
                            'Maintain cleanliness, respect booking times, and follow facility guidelines for shared spaces and equipment.',
                      ),
                      const SizedBox(height: 24),
                      _buildAgreementItem(
                        icon: Icons.favorite_border,
                        title: 'Trust & Integrity',
                        description:
                            'Uphold the highest standards of medical ethics and professional conduct in alignment with PMDC guidelines.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/registration');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'I Agree to Terms & Conditions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B35),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF006876),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF006876).withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
