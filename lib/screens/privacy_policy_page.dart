import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF006876)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: Color(0xFF006876),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF006876).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF006876).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF006876), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please read this agreement carefully before using our services',
                      style: TextStyle(
                        color: Color(0xFF006876),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Effective Date: January 6, 2026\n\n'
              'Sehat Makaan operates a clinical co‑working and digital booking platform that enables licensed medical and dental Practitioners to book and use clinical space and related services. Patients, where applicable, may use the Platform only to schedule consultations with these independent Practitioners, who provide care in their own name and at their own professional responsibility.\n\n'
              'This Privacy Policy explains how we collect, use, store, protect, and disclose Personal Data and Sensitive Personal Data (including health‑related information) processed through our website, mobile applications, booking systems, and on‑site operations. By using our Services, you acknowledge that you have read and understood this Privacy Policy and consent to the processing of your information as described here, in accordance with applicable laws of Pakistan and other relevant regulations.\n\n'
              'This Privacy Policy applies to Practitioners who register with Sehat Makaan and use our facilities and digital platforms, Patients and visitors who book appointments, use our website/app, or otherwise interact with our Services, and any other individuals whose information is processed in connection with the provision of our Services. Sehat Makaan does not provide medical diagnosis or treatment directly to patients; it processes data only in connection with facilitating Practitioners\' independent clinical practice and facility use.\n\n'
              'For the purposes of this Policy, "Personal Data" means any information that identifies or can reasonably identify an individual, such as name, CNIC, contact details, and online identifiers. "Sensitive Personal Data" includes medical records, health information, clinical images, and any data relating to an individual\'s physical or mental health.\n\n'
              'We collect Practitioner Information including full name, title, specialty, CNIC, PMDC/medical registration number, license details, contact information, bank or payment information, professional profile content, and usage data relating to booking patterns. We also collect Patient and User Information including identification and contact details, demographic details, appointment details, health‑related information, and communication records.\n\n'
              'Payment and Transaction Information includes limited payment details collected during booking or subscription payments. Card details and other sensitive financial data are processed securely by our third‑party payment service providers and are not stored in full by Sehat Makaan. We also collect Technical and Usage Data such as log data, IP address, device type, browser type, operating system, timestamps of access, and cookies.\n\n'
              'We process Personal Data to register Practitioners, verify credentials, manage rental agreements and booking entitlements, enable patients (where applicable) to search for, book, manage, and attend appointments with independent Practitioners, facilitate and confirm payments, maintain accurate booking and operational records, provide customer support, operate and secure our systems, comply with legal and regulatory obligations, and prevent fraud and misuse.\n\n'
              'Patient information necessary for delivering care is shared with the selected Practitioner and authorized support staff strictly on a need‑to‑know basis. Practitioners are independent professionals responsible for safeguarding patient data in accordance with professional and ethical guidelines. For online payments, limited user data may be shared with third‑party payment processors such as PayFast, solely for the purpose of securely processing transactions.\n\n'
              'We may engage third‑party vendors to support IT hosting, data storage, SMS and email services, analytics, and platform security. Such service providers only process Personal Data under our instructions and are bound by contractual obligations to maintain confidentiality and appropriate security. We may disclose Personal Data where required to comply with applicable laws, regulations, or lawful requests by public authorities, regulators, or courts.\n\n'
              'Sehat Makaan implements appropriate technical and organizational security measures including encryption of data in transit, access control and authentication mechanisms, regular system monitoring, secure infrastructure and firewalls, and staff training and confidentiality undertakings. However, no system is completely secure, and we cannot guarantee absolute security.\n\n'
              'We retain Personal Data only for as long as necessary to fulfill the purposes described in this Policy or to comply with legal, regulatory, or contractual obligations. Once data is no longer required, it will be securely deleted, anonymized, or otherwise irreversibly de‑identified.\n\n'
              'Subject to applicable law, individuals may have rights including the right to access, rectification, deletion, restriction/objection, and withdrawal of consent. To exercise any of these rights, please contact us at support@sehatmakaan.com or +92 324 9043006.\n\n'
              'Our website and applications may use cookies and similar technologies to enable core functionality, improve performance and security, and collect aggregated analytics. You may adjust your browser settings to refuse cookies; however, some features may not function properly if cookies are disabled.\n\n'
              'Our Services are intended for adults and licensed Practitioners. Patients who are minors should be registered and represented by their parent or legal guardian, in accordance with applicable law. We do not knowingly collect Personal Data directly from children without appropriate consent.\n\n'
              'We may update this Privacy Policy from time to time to reflect changes in legal requirements or our practices. When we make material changes, we will update the Effective Date and may notify users via email or on‑site notices. Continued use of the Services after such changes constitutes acceptance of the updated Policy.',
              style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFFF6B35).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFFF6B35).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFFFF6B35),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using our services, you acknowledge that you have read, understood, and agree to be bound by these terms and conditions.',
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_support, color: Color(0xFF006876), size: 28),
              SizedBox(width: 12),
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006876),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildContactItem(
            Icons.location_on_outlined,
            'Office 304, 3rd Floor, Plaza 95, Main Boulevard\nDHA Phase 8, Lahore - 54000, Punjab, Pakistan',
          ),
          SizedBox(height: 16),
          _buildContactItem(Icons.phone_outlined, '+92 324 9043006'),
          SizedBox(height: 16),
          _buildContactItem(Icons.email_outlined, 'support@sehatmakaan.com'),
          SizedBox(height: 16),
          _buildContactItem(
            Icons.access_time_outlined,
            'Monday - Saturday: 9:00 AM - 6:00 PM\nSunday: Closed',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color(0xFF006876), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
