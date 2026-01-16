import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sehat_makaan_flutter/utils/constants.dart';

/// Recent Bookings Widget
/// Displays last 5 bookings/subscriptions with "Repeat Booking" feature
class RecentBookingsWidget extends StatefulWidget {
  final Map<String, dynamic> userSession;
  final VoidCallback? onRepeatBooking;

  const RecentBookingsWidget({
    super.key,
    required this.userSession,
    this.onRepeatBooking,
  });

  @override
  State<RecentBookingsWidget> createState() => _RecentBookingsWidgetState();
}

class _RecentBookingsWidgetState extends State<RecentBookingsWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentBookings = [];

  @override
  void initState() {
    super.initState();
    _loadRecentBookings();
  }

  Future<void> _loadRecentBookings() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) return;

      // Load recent subscriptions (last 5)
      final subscriptionsSnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final bookings = subscriptionsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'hourly',
          'specialty': data['specialty'],
          'suiteType': data['suiteType'],
          'hours': data['hoursIncluded'] ?? data['hours'] ?? 0,
          'price': data['price']?.toString() ?? '0',
          'createdAt': data['createdAt'],
          'roomType': data['roomType'],
          'details': data['details'],
          'packageType': data['packageType'],
        };
      }).toList();

      setState(() {
        _recentBookings = bookings;
      });
    } catch (e) {
      debugPrint('Error loading recent bookings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleRepeatBooking(Map<String, dynamic> booking) {
    // Create cart item for repeat booking
    final specialty = AppConstants.hourlySpecialties.firstWhere(
      (s) => s['id'] == booking['specialty'],
      orElse: () => {},
    );

    final hours = booking['hours'] as int? ?? 1;
    final price = double.tryParse(booking['price'].toString()) ?? 0.0;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repeat this booking:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    specialty['name']?.toString() ??
                        booking['specialty'].toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$hours Hour${hours > 1 ? 's' : ''}'),
                  Text('Suite: ${booking['suiteType']}'),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.formatCurrency(price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14B8A6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _addToCart(booking);
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> booking) {
    // TODO: Implement actual cart addition
    // For now, show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Added to cart! Proceed to checkout to complete booking.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            widget.onRepeatBooking?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF14B8A6), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              ...List.generate(3, (index) => _buildLoadingSkeleton())
            else if (_recentBookings.isEmpty)
              _buildEmptyState()
            else
              ..._recentBookings.map((booking) => _buildBookingCard(booking)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final specialty = AppConstants.hourlySpecialties.firstWhere(
      (s) => s['id'] == booking['specialty'],
      orElse: () => {'name': booking['specialty'], 'icon': '🏥'},
    );

    final hours = booking['hours'] as int? ?? 1;
    final price = double.tryParse(booking['price'].toString()) ?? 0.0;
    final createdAt = booking['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF14B8A6).withValues(alpha: 0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleRepeatBooking(booking),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      specialty['icon']?.toString() ?? '🏥',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialty['name']?.toString() ??
                            booking['specialty'].toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$hours Hour${hours > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.apartment,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking['suiteType'].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price and Action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppConstants.formatCurrency(price),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _handleRepeatBooking(booking),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Repeat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.grey[400],
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No recent bookings',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
