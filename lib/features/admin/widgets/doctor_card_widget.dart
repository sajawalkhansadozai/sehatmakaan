import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/admin_formatters.dart';
import '../utils/admin_styles.dart';

class DoctorCardWidget extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final bool isExpanded;
  final bool isApprovingDoctor;
  final bool isRejectingDoctor;
  final bool isDeletingDoctor;
  final bool isSuspendingDoctor;
  final VoidCallback onToggleExpand;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;
  final VoidCallback onSuspend;

  const DoctorCardWidget({
    super.key,
    required this.doctor,
    required this.isExpanded,
    required this.isApprovingDoctor,
    required this.isRejectingDoctor,
    required this.isDeletingDoctor,
    required this.isSuspendingDoctor,
    required this.onToggleExpand,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
    required this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    final status = doctor['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final rejectionReason = doctor['rejectionReason'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: AdminStyles.primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AdminStyles.primaryColor.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar, name, and expand button
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AdminStyles.primaryColor.withValues(alpha: 0.2),
                          AdminStyles.primaryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AdminStyles.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.transparent,
                      child: Text(
                        (doctor['fullName'] as String? ?? 'D')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AdminStyles.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doctor['fullName'] as String? ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AdminStyles.primaryColor,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AdminStyles.primaryColor.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: onToggleExpand,
                                icon: Icon(
                                  isExpanded
                                      ? Icons.remove_circle
                                      : Icons.add_circle,
                                  size: 24,
                                  color: AdminStyles.primaryColor,
                                ),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_hospital,
                                    size: 12,
                                    color: Colors.teal.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    doctor['specialty'] as String? ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Last Active Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getActivityColor(
                                  doctor,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: _getActivityColor(doctor),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getActivityText(doctor),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _getActivityColor(doctor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AdminStyles.getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AdminStyles.getStatusColor(
                            status,
                          ).withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Basic contact info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDoctorInfoChip(
                            Icons.email_outlined,
                            doctor['email'] as String? ?? '',
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDoctorInfoChip(
                            Icons.phone_outlined,
                            doctor['phoneNumber'] as String? ?? '',
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 16,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'PMDC: ${doctor['pmdcNumber'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timeline,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Exp: ${doctor['yearsOfExperience'] ?? 0} yrs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (doctor['createdAt'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Applied: ${AdminFormatters.formatDate(doctor['createdAt'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Rejection reason if exists
              if (rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejection reason: $rejectionReason',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Expanded details
              if (isExpanded) ...[
                const Divider(height: 24),
                Text(
                  'Complete Application Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Age',
                            '${doctor['age'] ?? 'N/A'} years',
                            Colors.grey.shade800,
                          ),
                          _buildDetailRow(
                            'Gender',
                            doctor['gender'] ?? 'N/A',
                            Colors.grey.shade800,
                          ),
                          _buildDetailRow(
                            'CNIC',
                            doctor['cnicNumber'] ?? 'N/A',
                            Colors.grey.shade800,
                          ),
                          Row(
                            children: [
                              const Text(
                                'Verification: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: status == 'approved'
                                      ? Colors.green.shade100
                                      : (status == 'rejected'
                                            ? Colors.red.shade100
                                            : Colors.orange.shade100),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status == 'approved'
                                      ? 'Verified'
                                      : (status == 'rejected'
                                            ? 'Rejected'
                                            : 'Pending'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: status == 'approved'
                                        ? Colors.green.shade800
                                        : (status == 'rejected'
                                              ? Colors.red.shade800
                                              : Colors.orange.shade800),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Application ID',
                            doctor['id'] as String? ?? 'N/A',
                            Colors.grey.shade800,
                          ),
                          _buildDetailRow(
                            'Full Name',
                            doctor['fullName'] ?? 'N/A',
                            Colors.grey.shade800,
                          ),
                          _buildDetailRow(
                            'Specialty',
                            doctor['specialty'] ?? 'N/A',
                            Colors.grey.shade800,
                          ),
                          if (doctor['approvedAt'] != null)
                            _buildDetailRow(
                              'Approved',
                              AdminFormatters.formatDateTime(
                                doctor['approvedAt'],
                              ),
                              Colors.grey.shade800,
                            ),
                          if (doctor['rejectedAt'] != null)
                            _buildDetailRow(
                              'Rejected',
                              AdminFormatters.formatDateTime(
                                doctor['rejectedAt'],
                              ),
                              Colors.grey.shade800,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Stats section
                if (doctor['stats'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Activity Statistics',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActivityStatCard(
                          'Total Bookings',
                          doctor['stats']['totalBookings'] ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActivityStatCard(
                          'Active Bookings',
                          doctor['stats']['activeBookings'] ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActivityStatCard(
                          'Subscriptions',
                          doctor['stats']['totalSubscriptions'] ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActivityStatCard(
                          'Active Subs',
                          doctor['stats']['activeSubscriptions'] ?? 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              // Action buttons based on status
              if (isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isApprovingDoctor ? null : onApprove,
                        icon: isApprovingDoctor
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          isApprovingDoctor ? 'Approving...' : 'Approve',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminStyles.successColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isRejectingDoctor ? null : onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (status == 'approved' || status == 'rejected') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isDeletingDoctor ? null : onDelete,
                    icon: isDeletingDoctor
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline, size: 18),
                    label: Text(
                      isDeletingDoctor ? 'Deleting...' : 'Delete Doctor',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],

              if (status == 'approved' || status == 'suspended') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isSuspendingDoctor ? null : onSuspend,
                    icon: isSuspendingDoctor
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            status == 'suspended'
                                ? Icons.check_circle
                                : Icons.block,
                            size: 18,
                          ),
                    label: Text(
                      isSuspendingDoctor
                          ? (status == 'suspended'
                                ? 'Removing Suspension...'
                                : 'Suspending...')
                          : (status == 'suspended'
                                ? 'Remove Suspension'
                                : 'Suspend Doctor'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: status == 'suspended'
                          ? Colors.green
                          : Colors.orange,
                      side: BorderSide(
                        color: status == 'suspended'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfoChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStatCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AdminStyles.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 11, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(Map<String, dynamic> doctor) {
    final lastLogin = doctor['lastLoginAt'];
    if (lastLogin == null) return Colors.grey;

    final lastLoginDate = (lastLogin as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(lastLoginDate);

    if (difference.inHours < 24) {
      return Colors.green;
    } else if (difference.inDays < 7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getActivityText(Map<String, dynamic> doctor) {
    final lastLogin = doctor['lastLoginAt'];
    if (lastLogin == null) return 'Never';

    final lastLoginDate = (lastLogin as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(lastLoginDate);

    if (difference.inHours < 1) {
      return 'Just now';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }
}

// NavigationService for global context access
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
