import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helpers/email_helper.dart';

class MarketingTab extends StatefulWidget {
  const MarketingTab({super.key});

  @override
  State<MarketingTab> createState() => _MarketingTabState();
}

class _MarketingTabState extends State<MarketingTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;
  bool _isSending = false;
  int _totalUsers = 0;
  int _marketingEnabledUsers = 0;
  List<Map<String, dynamic>> _recentCampaigns = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadRecentCampaigns();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Get total users (doctors)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'doctor')
          .where('status', isEqualTo: 'approved')
          .get();

      // Count users with marketing emails enabled
      int marketingCount = 0;
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final marketingEnabled = data['marketingEmails'] ?? false;
        if (marketingEnabled) {
          marketingCount++;
        }
      }

      if (mounted) {
        setState(() {
          _totalUsers = usersSnapshot.docs.length;
          _marketingEnabledUsers = marketingCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecentCampaigns() async {
    try {
      final campaignsSnapshot = await _firestore
          .collection('marketing_campaigns')
          .orderBy('sentAt', descending: true)
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          _recentCampaigns = campaignsSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading campaigns: $e');
    }
  }

  Future<void> _sendMarketingEmail() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email subject'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Marketing Email'),
        content: Text(
          'Send email to $_marketingEnabledUsers users who have enabled marketing emails?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006876),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);

    try {
      // Get all approved doctors with marketing emails enabled
      final usersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'doctor')
          .where('status', isEqualTo: 'approved')
          .where('marketingEmails', isEqualTo: true)
          .get();

      final subject = _subjectController.text.trim();
      final message = _messageController.text.trim();

      // Generate HTML email
      final htmlContent = _generateMarketingEmailHtml(subject, message);

      int emailsSent = 0;

      // Send email to each user
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final email = userData['email'] as String?;
        final userId = doc.id;

        if (email != null && email.isNotEmpty) {
          await EmailQueueHelper.queueEmail(
            firestore: _firestore,
            to: email,
            subject: subject,
            htmlContent: htmlContent,
            userId: userId,
            data: {
              'type': 'marketing',
              'campaignId': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
          emailsSent++;
        }
      }

      // Save campaign record
      await _firestore.collection('marketing_campaigns').add({
        'subject': subject,
        'message': message,
        'recipientCount': emailsSent,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': 'admin',
      });

      // Clear form
      _subjectController.clear();
      _messageController.clear();

      // Reload campaigns
      await _loadRecentCampaigns();

      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Marketing email sent to $emailsSent users'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send emails: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // GOD MODE: PUSH NOTIFICATION
  // ============================================================================

  Future<void> _showPushNotificationDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Send Push Notification'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '\u26a0\ufe0f This will send a push notification to ALL active users immediately.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Notification Title',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., System Maintenance',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Notification Message',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., App will be down for 30 minutes',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final title = titleController.text.trim();
      final message = messageController.text.trim();

      if (title.isEmpty || message.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all fields'),
            backgroundColor: Colors.red,
          ),
        );
        titleController.dispose();
        messageController.dispose();
        return;
      }

      try {
        // Get all active users
        final usersSnapshot = await _firestore
            .collection('users')
            .where('userType', isEqualTo: 'doctor')
            .where('status', isEqualTo: 'approved')
            .get();

        int notificationsSent = 0;

        // Create notification for each user
        for (var doc in usersSnapshot.docs) {
          await _firestore.collection('notifications').add({
            'userId': doc.id,
            'type': 'admin_broadcast',
            'title': title,
            'message': message,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          notificationsSent++;
        }

        // Log broadcast
        await _firestore.collection('admin_audit_log').add({
          'action': 'push_notification_broadcast',
          'title': title,
          'message': message,
          'recipientCount': notificationsSent,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '\u2705 Push notification sent to $notificationsSent users',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send notifications: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    titleController.dispose();
    messageController.dispose();
  }

  String _generateMarketingEmailHtml(String subject, String message) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { 
      font-family: Arial, sans-serif; 
      line-height: 1.6; 
      color: #333; 
      margin: 0;
      padding: 0;
    }
    .container { 
      max-width: 600px; 
      margin: 0 auto; 
      padding: 20px; 
    }
    .header { 
      background: linear-gradient(135deg, #006876 0%, #004d57 100%); 
      color: white; 
      padding: 30px; 
      text-align: center; 
      border-radius: 10px 10px 0 0; 
    }
    .content { 
      background: #f9f9f9; 
      padding: 30px; 
      border-radius: 0 0 10px 10px; 
    }
    .message-box {
      background: white;
      border-left: 4px solid #006876;
      padding: 20px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .footer { 
      text-align: center; 
      margin-top: 20px; 
      padding: 20px;
      color: #666; 
      font-size: 12px; 
      border-top: 1px solid #ddd;
    }
    .unsubscribe {
      margin-top: 20px;
      padding-top: 20px;
      border-top: 1px solid #ddd;
      font-size: 11px;
      color: #999;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Sehat Makaan</h1>
      <p style="margin: 0; opacity: 0.9;">Healthcare Platform</p>
    </div>
    <div class="content">
      <h2 style="color: #006876; margin-top: 0;">$subject</h2>
      
      <div class="message-box">
        <p>\${message.replaceAll('\\n', '<br>')}</p>
      </div>
      
      <div class="unsubscribe">
        <p>You are receiving this email because you opted in to receive marketing emails from Sehat Makaan.</p>
        <p>To stop receiving marketing emails, please update your notification preferences in the Settings page of your account.</p>
      </div>
    </div>
    <div class="footer">
      <p><strong>Sehat Makaan</strong></p>
      <p>Your Health, Our Priority</p>
      <p>📧 support@sehatmakaan.com</p>
      <p style="margin-top: 10px;">© \${DateTime.now().year} Sehat Makaan. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    ''';
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadStatistics();
                await _loadRecentCampaigns();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Doctors',
                            _totalUsers.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Marketing Enabled',
                            _marketingEnabledUsers.toString(),
                            Icons.mark_email_read,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Email Composer Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.campaign,
                                  color: Color(0xFF006876),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Send Marketing Email',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF006876),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            TextField(
                              controller: _subjectController,
                              decoration: const InputDecoration(
                                labelText: 'Email Subject',
                                hintText: 'e.g., New Features Update',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.subject),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // GOD MODE: Push Notification Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_active,
                                        color: Colors.orange.shade700,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '⚡ GOD MODE: Push Notification',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Send instant push notifications to ALL active users. Use for critical announcements.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _showPushNotificationDialog,
                                    icon: const Icon(Icons.send, size: 18),
                                    label: const Text('Send Push Notification'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // GOD MODE: Push Notification Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_active,
                                        color: Colors.orange.shade700,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '\u26a1 GOD MODE: Push Notification',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Send instant push notifications to ALL active users. Use for critical announcements.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _showPushNotificationDialog,
                                    icon: const Icon(Icons.send, size: 18),
                                    label: const Text('Send Push Notification'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            TextField(
                              controller: _messageController,
                              maxLines: 8,
                              decoration: const InputDecoration(
                                labelText: 'Email Message',
                                hintText:
                                    'Write your marketing message here...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.message),
                                alignLabelWithHint: true,
                              ),
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSending
                                    ? null
                                    : _sendMarketingEmail,
                                icon: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                label: Text(
                                  _isSending
                                      ? 'Sending...'
                                      : 'Send to $_marketingEnabledUsers Users',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006876),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Emails will only be sent to users who have enabled marketing emails in their settings.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Campaigns
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.history,
                                  color: Color(0xFF006876),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Recent Campaigns',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF006876),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_recentCampaigns.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    'No campaigns sent yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentCampaigns.length,
                                separatorBuilder: (_, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final campaign = _recentCampaigns[index];
                                  final sentAt =
                                      (campaign['sentAt'] as Timestamp?)
                                          ?.toDate();

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green.shade100,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    title: Text(
                                      campaign['subject'] ?? 'No Subject',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sent to ${campaign['recipientCount']} users',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        if (sentAt != null)
                                          Text(
                                            _formatDate(sentAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} minutes ago';
      }
      return '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
