import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

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
          'Terms & Conditions',
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
                      'Please read these terms carefully before using our services.',
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
            SizedBox(height: 24),
            Text(
              'Last Updated: January 6, 2026',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            Text(
              '1. Introduction\n\nThese Terms and Conditions ("Terms") govern the use of Sehat Makaan\'s ("Company", "we", "our", "us") digital booking platform, website, mobile applications, and physical clinical co‑working facilities (collectively, the "Services"). Sehat Makaan only provides clinical co‑working space, infrastructure, and a digital booking platform for Practitioners to manage their own clinical practice and facility usage; the Company does not provide medical or healthcare services to patients in its own name.\n\nBy using the Services, creating an account, making a booking, or processing a payment, you fully accept these Terms. If you do not agree with these Terms, you are not permitted to use the Services.\n\n2. Definitions\n\n"Practitioner": Any licensed doctor, dentist, medical specialist, or healthcare provider who registers on Sehat Makaan and uses the clinical space.\n\n"User": Any Practitioner using the Platform and, where applicable, any individual who visits the facility in connection with a Practitioner\'s independently provided medical services. Patients remain under the sole care and responsibility of the Practitioner, not Sehat Makaan.\n\n"Platform": Sehat Makaan\'s website, mobile applications, online booking system, and related digital tools.\n\n"Booking": The scheduled reservation of any clinical slot, room, package, or add‑on service.\n\n3. Eligibility and Registration\n\nA Practitioner must be fully qualified and licensed in accordance with applicable local laws and must be registered with PMDC or the relevant regulatory authority. The Practitioner is responsible for providing correct and complete information at the time of registration, including name, registration number, and contact details.\n\nThe Platform is generally intended for adult users; where minors are seen, any appointment for them should be arranged and managed by the responsible Practitioner in line with applicable law and professional standards.\n\nUsers are responsible for maintaining the confidentiality of their login credentials, and all activity under their account will be treated as their own. Any suspected unauthorized access must be reported to Sehat Makaan promptly.\n\n4. Nature of Services\n\nSehat Makaan only provides clinical co‑working space, infrastructure, and a digital booking platform. Practitioners are independent professionals; they are not employees, partners, or agents of Sehat Makaan.\n\nAll responsibility for clinical diagnosis, treatment, prescriptions, procedures, and patient care lies solely with the Practitioner. Sehat Makaan is not a party to the clinical relationship between a Practitioner and any patient.\n\nAny content on the Platform (including informational material or listings) is provided for general informational purposes only and does not constitute medical advice, diagnosis, or treatment.\n\n5. Bookings, Packages, and Usage\n\nPractitioners may book rooms and facilities through hourly slots, subscription packages, or custom arrangements, in accordance with the applicable booking policy and rental agreement.\n\nPatients are free to choose Practitioners, and the Platform digitally manages bookings and space allocation only as a facilitation tool. Sehat Makaan\'s role in any booking is limited to providing space and scheduling tools; it is not responsible for clinical decision‑making or outcomes.\n\nSehat Makaan does not guarantee any clinical outcome, treatment result, or recovery, and does not guarantee the availability of any specific Practitioner.\n\n6. Payments, Fees and Billing\n\nAccepted payment methods (such as card, bank transfer, wallet, or other methods) will be clearly stated on the Platform.\n\nBy submitting your payment details, you authorize Sehat Makaan and its payment processors to deduct applicable fees, charges, taxes, and dues associated with your bookings, packages, or add‑on services.\n\nHourly rates, subscription packages, add‑ons, and booking charges will be clearly specified on the Platform or in separate agreements. Prices may be updated with reasonable notice, and new prices will apply to future bookings only.\n\nWhere applicable, local taxes, duties, or levies may be added to the prices, and Users are responsible for such amounts.\n\n7. Cancellations, No‑Show, and Refunds\n\nBooking cancellation and modification are governed by the applicable booking policy and Refund Policy.\n\nLate cancellations or cancellations made within the minimum notice period may incur a fee or penalty, or may result in forfeiture of the booking fee.\n\nIf a Practitioner or User does not appear at the scheduled time without required prior notice, the booking may be treated as a "no‑show" and fees may be forfeited in accordance with the Refund Policy.\n\nRefunds, where applicable, are subject to the Refund Policy and are assessed on a case‑by‑case basis.\n\n8. Practitioner Responsibilities\n\nPractitioners must comply with all legal, regulatory, and ethical obligations, including guidelines issued by PMDC or any relevant authority.\n\nConfidentiality of patient data, record keeping, informed consent, documentation, and communication with patients are the Practitioner\'s responsibility. Practitioners are expected to maintain appropriate professional indemnity insurance and all licenses required to practice independently.\n\nSehat Makaan will not be liable for any malpractice, negligence, misconduct, or breach of professional obligations by Practitioners; all such liability rests solely with the Practitioner.\n\nPractitioners must follow Sehat Makaan\'s operational rules, hygiene standards, safety procedures, and facilities use policies described in the Operational Handbook and Rental Agreement.\n\n9. User Responsibilities\n\nUsers must provide accurate and up‑to‑date personal and, where applicable, medical information to the relevant Practitioner.\n\nIn emergencies or life‑threatening situations, Users and patients should directly contact emergency services or an appropriate hospital; the Platform is not designed or intended for emergency medical care.\n\nAll Users must follow facility rules, workplace etiquette, and staff instructions, including policies on cleanliness, security, and the smoke‑free workplace.\n\n10. Data Protection and Privacy\n\nThe processing of personal and health information is governed by Sehat Makaan\'s Privacy Policy, which forms an integral part of these Terms.\n\nPayment information is processed through secure third‑party payment processors that maintain their own security and compliance frameworks; Sehat Makaan does not store full card details.\n\nBy using the Services, you acknowledge that you have read and understood the Privacy Policy and consent to the collection and use of data as described therein.\n\n11. Intellectual Property\n\nThe design, logo, branding, content, workflows, and software of the Platform are the intellectual property of Sehat Makaan or its licensors.\n\nYou are granted a limited, non‑exclusive, non‑transferable license to use the Platform solely for lawful purposes in connection with the Services.\n\nYou may not copy, reproduce, reverse‑engineer, decompile, modify, distribute, or exploit the Platform or its code for any commercial or unauthorized purpose without Sehat Makaan\'s prior written consent.\n\n12. Prohibited Conduct\n\nUsers may not use the Services to:\n\n• Violate any applicable law, regulation, or medical ethical standard.\n\n• Commit fraud, misrepresentation, or impersonate any person or entity.\n\n• Attempt unauthorized access, hacking, probing, or interfere with system security or integrity.\n\n• Misuse, disclose without authorization, or sell patient data, images, or records.\n\n• Damage, misuse, or remove facility property, equipment, or branding.\n\nViolations may result in suspension or termination of access, cancellation of bookings, and, where appropriate, legal action or claims for damages.\n\n13. Limitation of Liability\n\nSehat Makaan does not provide direct medical care and is not involved in clinical decision‑making; therefore, it is not liable for clinical outcomes, diagnosis, treatment, or procedures performed by Practitioners.\n\nTo the maximum extent permitted by law, Sehat Makaan is not responsible for indirect, incidental, consequential, special, or punitive damages (including loss of data, business, revenue, or reputation) arising out of or related to the use of the Services, except where such limitation is prohibited by law.\n\nIn the event of temporary unavailability of the Platform or facilities (for example, due to maintenance, outages, or technical issues), Sehat Makaan\'s liability is limited to reasonable efforts to restore services or, where applicable, to remedies set out in the Refund Policy.\n\n14. Indemnity\n\nYou agree to indemnify and hold harmless Sehat Makaan, its directors, employees, and affiliates from any claim, damage, loss, cost, or expense (including legal fees) arising from:\n\n• Your breach of these Terms.\n\n• Your violation of any applicable law or regulation.\n\n• Your infringement of any third‑party rights, including privacy, data protection, or intellectual property rights.\n\n• Your acts or omissions, including any clinical malpractice if you are a Practitioner.\n\n15. Suspension and Termination\n\nSehat Makaan may, at its discretion and with reasonable grounds, suspend or terminate your access to the Services, including but not limited to cases of policy violations, suspected fraud, non‑payment, abuse, or security risks.\n\nUpon termination, your right to use the Services will cease immediately, but provisions relating to limitation of liability, indemnity, data protection, and dispute resolution will continue to remain in effect.\n\n16. Changes to Services and Terms\n\nSehat Makaan may modify, enhance, or discontinue parts of the Services from time to time, including adding or removing features or updating interfaces.\n\nThese Terms may also be updated periodically. The updated version will be published on the Platform with a revised "Last Updated" date. Continued use of the Services after such updates constitutes your acceptance of the revised Terms.\n\n17. Governing Law and Dispute Resolution\n\nThese Terms are governed by and interpreted in accordance with the laws of the Islamic Republic of Pakistan.\n\nParties will first seek to resolve disputes amicably. If a dispute cannot be resolved informally, it may be referred to arbitration or the competent courts in Lahore, Pakistan, as permitted by law and any applicable arbitration clause in the Rental Agreement.\n\n18. Severability\n\nIf any provision of these Terms is found to be invalid or unenforceable by a competent authority, the remaining provisions will remain valid and enforceable, and the invalid provision will be interpreted in a manner that best reflects the original intent while remaining lawful.\n\n19. Entire Agreement\n\nThese Terms, together with the Privacy Policy, Refund Policy, Rental Agreement, Digital Booking Policy, and any specific package or add‑on terms, constitute the entire agreement between you and Sehat Makaan regarding the use of the Services and supersede all prior oral or written understandings.\n\n20. Contact Us\n\nIf you have any questions, complaints, or requests regarding these Terms or the Services, you may contact:\n\nSehat Makaan\nEmail: support@sehatmakaan.com\nPhone: +92 324 9043006',
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
                'Need Help?',
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
