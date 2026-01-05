import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_footer.dart';

class TermsConditionsPage extends StatelessWidget {
  final Function(int)? onNavigate;

  const TermsConditionsPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildContentSection(context),
          AppFooter(onNavigate: onNavigate),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Policy Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terms & Conditions',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Service Agreement & Usage Terms',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Please read these terms carefully before using our services.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.secondaryDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Terms & Conditions Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '1. Introduction\n\nThese Terms and Conditions ("Terms") govern the use of Sehat Makaan\'s ("Company", "we", "our", "us") digital booking platform, website, mobile applications, and physical clinical co‑working facilities (collectively, the "Services"). By using the Services, creating an account, making a booking, or processing a payment, you fully accept these Terms. If you do not agree with these Terms, you are not permitted to use the Services.\n\n2. Definitions\n\n"Practitioner": Any licensed doctor, dentist, medical specialist, or healthcare provider who registers on Sehat Makaan and uses the clinical space. "Patient" / "User": Any individual who books an appointment, visits the facility, or uses the Services. "Platform": Sehat Makaan\'s website, mobile applications, online booking system, and related digital tools. "Booking": The scheduled reservation of any clinical slot, room, package, or add‑on service.\n\n3. Eligibility and Registration\n\nA Practitioner must be fully qualified and licensed in accordance with applicable local laws and must be registered with PMDC or the relevant regulatory authority. The Practitioner is responsible for providing correct and complete information at the time of registration. The Platform is generally intended for users aged 18 and above; for minors, appointments should be booked by a parent or legal guardian. You are responsible for maintaining the confidentiality of your login credentials.\n\n4. Nature of Services\n\nSehat Makaan only provides clinical co‑working space, infrastructure, and a digital booking platform. Practitioners are independent professionals; they are not employees or agents of Sehat Makaan. All responsibility for clinical diagnosis, treatment, prescriptions, procedures, and patient care lies solely with the Practitioner. Any content on the Platform is provided for general informational purposes only and does not constitute medical advice.\n\n5. Bookings, Packages, and Usage\n\nPractitioners may book rooms and facilities through hourly slots, subscription packages, or custom arrangements. Patients are free to choose Practitioners, and the Platform digitally manages their bookings. Sehat Makaan does not guarantee any clinical outcome, treatment result, or recovery.\n\n6. Payments, Fees and Billing\n\nAccepted payment methods will be clearly stated. By submitting your payment details, you authorize us to deduct applicable fees, charges, taxes, and dues. Hourly rates, subscription packages, add‑ons, and booking charges will be clearly specified. Prices may update with reasonable notice. Where applicable, local taxes may be added to prices.\n\n7. Cancellations, No‑Show, and Refunds\n\nBooking cancellation and modification are governed by the applicable booking policy. Late cancellations may incur a fee or penalty. If a Practitioner or Patient does not appear at the scheduled time, the booking may be treated as a "no‑show" and fees may be forfeited. Refunds are subject to the applicable refund policy and case‑by‑case review.\n\n8. Practitioner Responsibilities\n\nPractitioners must comply with all legal, regulatory, and ethical obligations, including PMDC guidelines. Confidentiality of patient data, record keeping, informed consent, and documentation are the Practitioner\'s responsibility. Sehat Makaan will not be liable for any malpractice or negligence; liability rests with the Practitioner.\n\n9. User / Patient Responsibilities\n\nUsers must provide accurate personal and medical information. In emergencies, contact emergency services directly. Patients must follow facility rules and staff instructions.\n\n10. Data Protection and Privacy\n\nThe processing of personal and health information is governed by Sehat Makaan\'s Privacy Policy. Payment information is processed through secure third‑party processors.\n\n11. Intellectual Property\n\nThe design, logo, branding, content, and software of the Platform are Sehat Makaan\'s intellectual property. You may not copy, reverse‑engineer, modify, or exploit the Platform without permission.\n\n12. Prohibited Conduct\n\nUsers may not violate laws, commit fraud, attempt unauthorized access, misuse patient data, or damage facility property. Violations may result in suspension, termination, and legal action.\n\n13. Limitation of Liability\n\nSehat Makaan does not provide direct medical care and is not liable for clinical outcomes. We are not responsible for indirect, incidental, or consequential damages except where law prohibits such limitation.\n\n14. Indemnity\n\nYou agree to indemnify Sehat Makaan from any claim arising from your breach of Terms, violation of law, or infringement of third‑party rights.\n\n15. Suspension and Termination\n\nSehat Makaan may suspend or terminate your access for policy violations, fraud, non‑payment, or misuse. Certain clauses remain in effect after termination.\n\n16. Changes to Services and Terms\n\nWe may modify the Services and Terms from time to time. Updated Terms will be published on the Platform. Continued use constitutes acceptance.\n\n17. Governing Law and Dispute Resolution\n\nThese Terms are governed by the laws of Pakistan. Disputes will first be resolved amicably, then through arbitration or competent courts in Lahore, Pakistan.\n\n18. Severability\n\nIf any provision is invalid, the remaining provisions remain enforceable.\n\n19. Entire Agreement\n\nThese Terms, together with the Privacy Policy and other policies, constitute the entire agreement.\n\n20. Contact Us\n\nFor questions or complaints, contact us at support@sehatmakaan.com or +92 324 9043006.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Contact Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.contact_support,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Need Help?',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'If you have any questions or concerns about our terms, please feel free to contact us:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        _buildEnhancedContactItem(
                          context,
                          Icons.location_on,
                          'DHA Phase 5, Lahore, Pakistan',
                          AppColors.primary,
                        ),
                        _buildEnhancedContactItem(
                          context,
                          Icons.phone,
                          '+92 324 9043006',
                          AppColors.secondary,
                        ),
                        _buildEnhancedContactItem(
                          context,
                          Icons.email,
                          'support@sehatmakaan.com',
                          AppColors.accent,
                        ),
                        _buildEnhancedContactItem(
                          context,
                          Icons.access_time,
                          'Available 24/7',
                          AppColors.primaryDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedContactItem(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
