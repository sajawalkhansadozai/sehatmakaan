import 'package:flutter/material.dart';
import '../widgets/booking_card_widget.dart';
import 'package:sehatmakaan/features/admin/utils/admin_styles.dart';
import 'package:sehatmakaan/features/admin/utils/admin_formatters.dart';
import 'package:sehatmakaan/features/admin/utils/responsive_helper.dart';

class BookingsTab extends StatefulWidget {
  final DateTime selectedBookingDate;
  final List<Map<String, dynamic>> filteredBookings;
  final List<Map<String, dynamic>> allBookings;
  final Function(DateTime) onDateChanged;
  final VoidCallback onRefresh;
  final Function(Map<String, dynamic>) onCancel;

  const BookingsTab({
    super.key,
    required this.selectedBookingDate,
    required this.filteredBookings,
    required this.allBookings,
    required this.onDateChanged,
    required this.onRefresh,
    required this.onCancel,
  });

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _statusFilteredBookings {
    List<Map<String, dynamic>> filtered;

    // First apply status filter
    switch (_selectedFilter) {
      case 'all':
        filtered = widget.filteredBookings;
        break;
      case 'confirmed':
        filtered = widget.filteredBookings
            .where((b) => b['status'] == 'confirmed')
            .toList();
        break;
      case 'in_progress':
        filtered = widget.filteredBookings
            .where((b) => b['status'] == 'in_progress')
            .toList();
        break;
      case 'completed':
        filtered = widget.filteredBookings
            .where((b) => b['status'] == 'completed')
            .toList();
        break;
      case 'cancelled_no_refund':
        filtered = widget.filteredBookings
            .where(
              (b) =>
                  b['status'] == 'cancelled' &&
                  (b['refundIssued'] == false || b['refundIssued'] == null),
            )
            .toList();
        break;
      case 'cancelled_full_refund':
        filtered = widget.filteredBookings
            .where(
              (b) => b['status'] == 'cancelled' && b['refundIssued'] == true,
            )
            .toList();
        break;
      default:
        filtered = widget.filteredBookings;
    }

    // Then apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((booking) {
        final doctorName = (booking['doctorName'] ?? '')
            .toString()
            .toLowerCase();
        final doctorEmail = (booking['doctorEmail'] ?? '')
            .toString()
            .toLowerCase();
        final suiteType = (booking['suiteType'] ?? '').toString().toLowerCase();
        final specialty = (booking['specialty'] ?? '').toString().toLowerCase();
        final timeSlot = (booking['timeSlot'] ?? '').toString().toLowerCase();
        final bookingId = (booking['id'] ?? '').toString().toLowerCase();
        final userId = (booking['userId'] ?? '').toString().toLowerCase();

        return doctorName.contains(query) ||
            doctorEmail.contains(query) ||
            suiteType.contains(query) ||
            specialty.contains(query) ||
            timeSlot.contains(query) ||
            bookingId.contains(query) ||
            userId.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return Column(
      children: [
        Padding(
          padding: padding,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: isMobile
                      ? 'Search bookings...'
                      : 'Search by doctor name, email, suite, specialty...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AdminStyles.primaryColor,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AdminStyles.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Date Picker and Refresh Button
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: widget.selectedBookingDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          widget.onDateChanged(picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              AdminFormatters.formatDateLong(
                                widget.selectedBookingDate,
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh),
                    style: IconButton.styleFrom(
                      backgroundColor: AdminStyles.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All', Icons.list_alt),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'confirmed',
                      'Confirmed',
                      Icons.check_circle,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'in_progress',
                      'In Progress',
                      Icons.play_circle_outline,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('completed', 'Completed', Icons.done_all),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'cancelled_no_refund',
                      'Cancelled (No Refund)',
                      Icons.cancel,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'cancelled_full_refund',
                      'Cancelled (Full Refund)',
                      Icons.money_off,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _statusFilteredBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        widget.allBookings.isEmpty
                            ? 'No bookings found'
                            : _selectedFilter == 'all'
                            ? 'No bookings for ${AdminFormatters.formatDateLong(widget.selectedBookingDate)}'
                            : 'No ${_getFilterLabel(_selectedFilter).toLowerCase()} bookings',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = ResponsiveHelper.getSpacing(context);
                    final horizontalPadding = ResponsiveHelper.isMobile(context)
                        ? 12.0
                        : 16.0;
                    final availableWidth =
                        constraints.maxWidth - (horizontalPadding * 2);
                    final columnCount = ResponsiveHelper.getColumnCountForWidth(
                      availableWidth,
                      minTileWidth: 380,
                      maxColumns: 4,
                    );
                    final itemWidth =
                        (availableWidth - (spacing * (columnCount - 1))) /
                        columnCount;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: spacing,
                      ),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: _statusFilteredBookings.map((booking) {
                          return SizedBox(
                            width: itemWidth,
                            child: BookingCardWidget(
                              booking: booking,
                              onCancel: () => widget.onCancel(booking),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AdminStyles.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AdminStyles.primaryColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AdminStyles.primaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? AdminStyles.primaryColor
            : AdminStyles.primaryColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      showCheckmark: false,
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled_no_refund':
        return 'Cancelled (No Refund)';
      case 'cancelled_full_refund':
        return 'Cancelled (Full Refund)';
      default:
        return 'All';
    }
  }
}
