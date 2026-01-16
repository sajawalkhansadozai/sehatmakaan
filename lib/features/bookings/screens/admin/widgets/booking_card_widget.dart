import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../screens/admin/utils/admin_formatters.dart';
import '../../../../../../screens/admin/utils/admin_styles.dart';

class BookingCardWidget extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onCancel;

  const BookingCardWidget({
    super.key,
    required this.booking,
    required this.onCancel,
  });

  @override
  State<BookingCardWidget> createState() => _BookingCardWidgetState();
}

class _BookingCardWidgetState extends State<BookingCardWidget> {
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = widget.booking['userId'] as String?;
      if (userId != null && userId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _userData = userDoc.data();
            _isLoadingUser = false;
          });
        } else {
          if (mounted) {
            setState(() => _isLoadingUser = false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingUser = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status'] as String? ?? 'confirmed';
    final isCancelled = status == 'cancelled';
    final doctor = widget.booking['doctor'] as Map<String, dynamic>?;
    final subscription =
        widget.booking['subscription'] as Map<String, dynamic>?;
    final durationHours = widget.booking['durationHours'] as int? ?? 0;
    final durationMins = widget.booking['durationMins'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AdminStyles.primaryColor.withValues(alpha: 0.02),
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
                // Header: Suite Type & Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminStyles.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.meeting_room,
                        color: AdminStyles.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.booking['suiteType'] as String? ?? 'Suite',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AdminStyles.primaryColor,
                            ),
                          ),
                          if (doctor != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Dr. ${doctor['fullName'] ?? ''} • ${doctor['specialty'] ?? ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AdminStyles.primaryColor.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.remove_circle : Icons.add_circle,
                      color: AdminStyles.primaryColor,
                      size: 28,
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
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        AdminFormatters.getStatusText(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                if (_isExpanded) ...[
                  const Divider(height: 24, thickness: 1),

                  // Doctor Information Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              size: 16,
                              color: Colors.teal.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Doctor Information',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingUser)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (_userData != null) ...[
                          _buildInfoRow(
                            Icons.person,
                            'Name',
                            _userData!['fullName'] ?? 'N/A',
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            Icons.local_hospital,
                            'Specialty',
                            _userData!['specialty'] ?? 'N/A',
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            Icons.email,
                            'Email',
                            _userData!['email'] ?? 'N/A',
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            Icons.phone,
                            'Phone',
                            _userData!['phoneNumber'] ?? 'N/A',
                          ),
                          if (_userData!['pmdcNumber'] != null) ...[
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              Icons.badge,
                              'PMDC',
                              _userData!['pmdcNumber'],
                            ),
                          ],
                          if (_userData!['cnicNumber'] != null) ...[
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              Icons.credit_card,
                              'CNIC',
                              _userData!['cnicNumber'],
                            ),
                          ],
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Doctor information not available',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Booking Details Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailTile(
                                Icons.access_time,
                                'Time Slot',
                                widget.booking['timeSlot'] as String? ??
                                    'Not set',
                                widget.booking['timeSlot'] != null
                                    ? AdminStyles.primaryColor
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailTile(
                                Icons.timer,
                                'Duration',
                                '${durationHours}h ${durationMins}m',
                                AdminStyles.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailTile(
                                Icons.payment,
                                'Total Amount',
                                'PKR ${widget.booking['totalAmount'] ?? 0}',
                                Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailTile(
                                Icons.calendar_today,
                                'Booked On',
                                widget.booking['createdAt'] != null
                                    ? AdminFormatters.formatDate(
                                        widget.booking['createdAt'],
                                      )
                                    : 'N/A',
                                Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        // Price Breakdown
                        if (widget.booking['baseRate'] != null ||
                            (widget.booking['selectedAddons'] as List?)
                                    ?.isNotEmpty ==
                                true) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Price Breakdown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Divider(),
                                if (widget.booking['baseRate'] != null) ...[
                                  // Show if priority slot pricing was applied
                                  if (widget.booking['isPrioritySlot'] ==
                                          true &&
                                      widget.booking['originalRate'] !=
                                          null) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.workspace_premium,
                                              size: 14,
                                              color: Color(0xFFFFC107),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Original Rate',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'PKR ${(widget.booking['originalRate'] as num).toStringAsFixed(0)}/hr',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.workspace_premium,
                                              size: 14,
                                              color: Color(0xFFFFC107),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Priority Rate (1.5x)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'PKR ${(widget.booking['baseRate'] as num).toStringAsFixed(0)}/hr',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFFC107),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        widget.booking['isPrioritySlot'] == true
                                            ? 'Subtotal (${durationHours}h ${durationMins}m @ priority rate)'
                                            : 'Base Rate (${durationHours}h ${durationMins}m)',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        'PKR ${((widget.booking['baseRate'] as num) * ((durationHours * 60 + durationMins) / 60)).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if ((widget.booking['selectedAddons'] as List?)
                                        ?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Add-ons:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...(widget.booking['selectedAddons'] as List)
                                      .map((addon) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                            top: 2,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '• ${addon['name']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'PKR ${(addon['price'] as num).toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (subscription != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AdminStyles.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.card_membership,
                                  size: 16,
                                  color: AdminStyles.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Package: ${subscription['packageName'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AdminStyles.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Show Priority Booking badge
                        if (widget.booking['hasPriority'] == true) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9C4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFC107),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.workspace_premium,
                                  size: 16,
                                  color: Color(0xFFFFC107),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Priority Booking (Weekends/6pm-10pm)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Show Extended Hours badge
                        if (widget.booking['hasExtendedHours'] == true) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFF9800),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Color(0xFFFF9800),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Extended Hours (+30 mins)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (!isCancelled) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        label: const Text(
                          'Cancel Booking',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.red.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blue.shade700),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
