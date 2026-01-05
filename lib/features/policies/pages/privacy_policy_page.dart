import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_footer.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final Function(int)? onNavigate;

  const PrivacyPolicyPage({super.key, this.onNavigate});

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

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.secondaryDark],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.privacy_tip,
              size: 64,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Privacy Policy',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Last Updated: January 3, 2026',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Policy Card with Enhanced Design
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with decorative accent
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.08),
                            AppColors.secondary.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary.withOpacity(0.15),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
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
                              Icons.article_outlined,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Privacy Policy',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rental Agreement & Terms',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content with enhanced typography
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Introduction highlight
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Please read this agreement carefully before using our services',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
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

                          // Decorative line
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Privacy Policy Details',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Main paragraph with enhanced styling
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Sehat Makaan operates a clinical co-working and digital booking platform that enables licensed medical and dental practitioners to book and use clinical space and related services, and enables patients to schedule consultations and receive care from independent Practitioners. This Privacy Policy explains how we collect, use, store, protect, and disclose Personal Data and Sensitive Personal Data (including health-related information) processed through our website, mobile applications, booking systems, and on-site operations. '
                              'By using our Services, you acknowledge that you have read and understood this Privacy Policy and consent to the processing of your information as described here, in accordance with applicable laws of Pakistan and other relevant regulations. '
                              'This Privacy Policy applies to Practitioners who register with Sehat Makaan and use our facilities and digital platforms, Patients and visitors who book appointments, use our website/app, or otherwise interact with our Services, and any other individuals whose information is processed in connection with the provision of our Services. '
                              'For the purposes of this Policy, "Personal Data" means any information that identifies or can reasonably identify an individual, such as name, CNIC, contact details, and online identifiers. "Sensitive Personal Data" includes medical records, health information, clinical images, and any data relating to an individual\'s physical or mental health. '
                              'We collect Practitioner Information including full name, title, specialty, CNIC, PMDC/medical registration number, license details, contact information, bank or payment information, professional profile content, and usage data relating to booking patterns. We also collect Patient and User Information including identification and contact details, demographic details, appointment details, health-related information, and communication records. '
                              'Payment and Transaction Information includes limited payment details collected during booking or subscription payments. Card details and other sensitive financial data are processed securely by our third-party payment service providers and are not stored in full by Sehat Makaan. We also collect Technical and Usage Data such as log data, IP address, device type, browser type, operating system, timestamps of access, and cookies. '
                              'We process Personal Data to register Practitioners, verify credentials, manage rental agreements and booking entitlements, enable patients to search for, book, manage, and attend appointments, facilitate and confirm payments, maintain accurate clinical and booking records, provide customer support, operate and secure our systems, comply with legal and regulatory obligations, and prevent fraud and misuse. '
                              'Patient information necessary for delivering care is shared with the selected Practitioner and authorized support staff strictly on a need-to-know basis. Practitioners are independent professionals responsible for safeguarding patient data in accordance with professional and ethical guidelines. For online payments, limited user data may be shared with third-party payment processors such as PayFast, solely for the purpose of securely processing transactions. '
                              'We may engage third-party vendors to support IT hosting, data storage, SMS and email services, analytics and platform security. Such service providers only process Personal Data under our instructions and are bound by contractual obligations to maintain confidentiality. We may disclose Personal Data where required to comply with applicable laws, regulations, or lawful requests by public authorities, regulators, or courts. '
                              'Sehat Makaan implements appropriate technical and organizational security measures including encryption of data in transit, access control and authentication mechanisms, regular system monitoring, secure infrastructure and firewalls, and staff training and confidentiality undertakings. However, no system is completely secure, and we cannot guarantee absolute security. '
                              'We retain Personal Data only for as long as necessary to fulfill the purposes described in this Policy or to comply with legal, regulatory, or contractual obligations. Once data is no longer required, it will be securely deleted, anonymized, or otherwise irreversibly de-identified. '
                              'Subject to applicable law, individuals may have rights including the right to access, rectification, deletion, restriction/objection, and withdrawal of consent. To exercise any of these rights, please contact us at support@sehatmakaan.com or +92 324 9043006. '
                              'Our website and applications may use cookies and similar technologies to enable core functionality, improve performance and security, and collect aggregated analytics. You may adjust your browser settings to refuse cookies; however, some features may not function properly. '
                              'Our Services are intended for adults and licensed Practitioners. Patients who are minors should be registered by their parent or legal guardian. We do not knowingly collect Personal Data directly from children without appropriate consent. '
                              'We may update this Privacy Policy from time to time to reflect changes in legal requirements or our practices. When we make material changes, we will update the Effective Date and may notify users via email or on-site notices. Continued use of the Services after such changes constitutes acceptance of the updated Policy.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    height: 1.9,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w400,
                                  ),
                              textAlign: TextAlign.justify,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Agreement acceptance note
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.accent.withOpacity(0.08),
                                  AppColors.primary.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.accent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'By using our services, you acknowledge that you have read, understood, and agree to be bound by these terms and conditions.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.accentDark,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Enhanced Contact Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact header
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withOpacity(0.08),
                            AppColors.secondary.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.accent,
                                  AppColors.accentDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.headset_mic_outlined,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need Help?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppColors.accentDark,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get in touch with us',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contact details
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          _buildEnhancedContactItem(
                            context,
                            Icons.location_on_outlined,
                            'Visit Us',
                            'Office 304, 3rd Floor, Plaza 95, Main Boulevard\nGulberg III, Lahore - 54000, Punjab, Pakistan',
                            AppColors.primary,
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedContactItem(
                            context,
                            Icons.phone_outlined,
                            'Call Us',
                            '+92 324 9043006',
                            AppColors.secondary,
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedContactItem(
                            context,
                            Icons.email_outlined,
                            'Email Us',
                            'support@sehatmakaan.com',
                            AppColors.accent,
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedContactItem(
                            context,
                            Icons.access_time_outlined,
                            'Working Hours',
                            'Monday - Saturday: 9:00 AM - 6:00 PM\nSunday: Closed',
                            AppColors.primaryDark,
                          ),
                        ],
                      ),
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
    String label,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.6,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
