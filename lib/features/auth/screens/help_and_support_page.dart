import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';

class HelpAndSupportPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const HelpAndSupportPage({super.key, required this.userSession});

  @override
  State<HelpAndSupportPage> createState() => _HelpAndSupportPageState();
}

class _HelpAndSupportPageState extends State<HelpAndSupportPage> {
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _faqCategories = [
    {'id': 'all', 'title': 'All Topics', 'icon': Icons.apps},
    {'id': 'account', 'title': 'Account', 'icon': Icons.person},
    {'id': 'booking', 'title': 'Booking', 'icon': Icons.calendar_today},
    {'id': 'payment', 'title': 'Payment', 'icon': Icons.payment},
    {'id': 'workshops', 'title': 'Workshops', 'icon': Icons.school},
    {'id': 'technical', 'title': 'Technical', 'icon': Icons.bug_report},
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'account',
      'question': 'How do I update my profile information?',
      'answer':
          'Go to Settings from the sidebar menu, then click on "Edit Profile". You can update your name, specialty, PMDC number, and other professional details.',
    },
    {
      'category': 'account',
      'question': 'How do I change my password?',
      'answer':
          'Navigate to Settings > Security, then click on "Change Password". Enter your current password and your new password twice to confirm.',
    },
    {
      'category': 'account',
      'question': 'Why was my account suspended?',
      'answer':
          'Accounts may be suspended for violating Terms and Conditions, unprofessional conduct, or security concerns. Check your email for specific details or contact support@sehatmakaan.com for assistance.',
    },
    {
      'category': 'booking',
      'question': 'How do I book a consultation slot?',
      'answer':
          'From your dashboard, click on "Book Slot" or "Monthly Dashboard". Select your desired date and time slot, choose your suite type, and confirm your booking.',
    },
    {
      'category': 'booking',
      'question': 'Can I cancel or reschedule a booking?',
      'answer':
          'Yes! Go to "My Schedule" from the sidebar, find your booking, and click the cancel or reschedule button. Note that cancellation policies may apply.',
    },
    {
      'category': 'booking',
      'question': 'How do I view my upcoming appointments?',
      'answer':
          'Click on "My Schedule" in the sidebar to see all your upcoming bookings, workshops, and appointments in a calendar view.',
    },
    {
      'category': 'payment',
      'question': 'What payment methods are supported?',
      'answer':
          'We accept PayFast, JazzCash, EasyPaisa, and Bank Transfer. All payments are processed securely through encrypted gateways.',
    },
    {
      'category': 'payment',
      'question': 'How do I upgrade my subscription?',
      'answer':
          'Go to Dashboard > Subscriptions, select a higher tier package (Advanced or Professional), and complete the payment process.',
    },
    {
      'category': 'payment',
      'question': 'Can I get a refund?',
      'answer':
          'Refund eligibility depends on the cancellation policy and timing. Contact support@sehatmakaan.com with your booking ID for refund requests.',
    },
    {
      'category': 'workshops',
      'question': 'How do I register for a workshop?',
      'answer':
          'Browse available workshops from Dashboard > Workshops. Click on any workshop to view details, then click "Register" and complete the payment.',
    },
    {
      'category': 'workshops',
      'question': 'How do I create a workshop?',
      'answer':
          'First, request workshop creator access from your dashboard. Once approved by admin, you\'ll see a "Create Workshop" button. Fill in workshop details including title, description, schedule, and pricing.',
    },
    {
      'category': 'workshops',
      'question': 'Do I get a certificate after completing a workshop?',
      'answer':
          'Yes! Certificates are issued based on the workshop certification type (e.g., CME Credits, Certification). Check the workshop details for specific certification information.',
    },
    {
      'category': 'technical',
      'question': 'The app is not loading properly. What should I do?',
      'answer':
          'Try these steps: 1) Check your internet connection, 2) Clear app cache, 3) Restart the app, 4) Update to the latest version. If issues persist, contact support.',
    },
    {
      'category': 'technical',
      'question': 'I\'m not receiving notifications',
      'answer':
          'Check Settings > Notifications and ensure notifications are enabled. Also verify app permissions in your device settings allow notifications.',
    },
    {
      'category': 'technical',
      'question': 'How do I report a bug?',
      'answer':
          'Click "Report Issue" below or email support@sehatmakaan.com with a description of the bug, screenshots, and your device information.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006876),
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/dashboard',
              arguments: widget.userSession,
            ),
            icon: const Icon(Icons.home),
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildContactSection(),
              _buildCategoryFilter(),
              _buildFAQSection(),
              _buildQuickActions(),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006876), Color(0xFF004D57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: 64,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 16),
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Find answers to common questions or contact our support team',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            Icons.email,
            'Email',
            'support@sehatmakaan.com',
            'mailto:support@sehatmakaan.com',
          ),
          const Divider(height: 24),
          _buildContactItem(
            Icons.phone,
            'Phone',
            '+92 XXX XXX XXXX',
            'tel:+92XXXXXXXXX',
          ),
          const Divider(height: 24),
          _buildContactItem(
            Icons.schedule,
            'Support Hours',
            'Mon-Fri: 9:00 AM - 6:00 PM',
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    String? action,
  ) {
    return InkWell(
      onTap: action != null ? () => _launchUrl(action) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF006876).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF006876), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF006876),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (action != null)
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _faqCategories.length,
        itemBuilder: (context, index) {
          final category = _faqCategories[index];
          final isSelected = _selectedCategory == category['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category['id']),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF006876) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF006876)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'],
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF006876),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category['title'],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF006876),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQSection() {
    final filteredFAQs = _selectedCategory == 'all'
        ? _faqs
        : _faqs.where((faq) => faq['category'] == _selectedCategory).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.question_answer,
                  color: Color(0xFF006876),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006876),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filteredFAQs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No FAQs found in this category',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredFAQs.map((faq) => _buildFAQItem(faq)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Text(
        faq['question'],
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF006876),
        ),
      ),
      children: [
        Text(
          faq['answer'],
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need More Help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            'Report Issue',
            Icons.bug_report,
            Colors.orange,
            () => _showReportIssueDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  void _showReportIssueDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.orange),
            SizedBox(width: 8),
            Text('Report an Issue'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Issue Title',
                  hintText: 'Brief description of the issue',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide details about the issue...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement issue reporting to backend
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Issue reported successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
