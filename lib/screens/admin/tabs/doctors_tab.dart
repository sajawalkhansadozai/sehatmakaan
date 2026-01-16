import 'package:flutter/material.dart';
import '../widgets/doctor_card_widget.dart';
import '../utils/admin_styles.dart';

class DoctorsTab extends StatelessWidget {
  final TextEditingController searchController;
  final String filterStatus;
  final List<Map<String, dynamic>> filteredDoctors;
  final List<Map<String, dynamic>> allDoctors;
  final Set<String> expandedDoctors;
  final bool isApprovingDoctor;
  final bool isRejectingDoctor;
  final bool isDeletingDoctor;
  final bool isSuspendingDoctor;
  final Function(String) onSearchChanged;
  final Function(String) onFilterChanged;
  final VoidCallback onRefresh;
  final Function(String) onToggleExpand;
  final Function(Map<String, dynamic>) onApprove;
  final Function(Map<String, dynamic>) onReject;
  final Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>) onSuspend;

  const DoctorsTab({
    super.key,
    required this.searchController,
    required this.filterStatus,
    required this.filteredDoctors,
    required this.allDoctors,
    required this.expandedDoctors,
    required this.isApprovingDoctor,
    required this.isRejectingDoctor,
    required this.isDeletingDoctor,
    required this.isSuspendingDoctor,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onToggleExpand,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
    required this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search doctors...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<String>(
                  value: filterStatus,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onFilterChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: AdminStyles.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredDoctors.isEmpty
              ? Center(
                  child: Text(
                    allDoctors.isEmpty
                        ? 'No doctors found'
                        : 'No doctors match your search criteria',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = filteredDoctors[index];
                    final doctorId = doctor['id'] as String? ?? '';

                    return DoctorCardWidget(
                      doctor: doctor,
                      isExpanded: expandedDoctors.contains(doctorId),
                      isApprovingDoctor: isApprovingDoctor,
                      isRejectingDoctor: isRejectingDoctor,
                      isDeletingDoctor: isDeletingDoctor,
                      isSuspendingDoctor: isSuspendingDoctor,
                      onToggleExpand: () => onToggleExpand(doctorId),
                      onApprove: () => onApprove(doctor),
                      onReject: () => onReject(doctor),
                      onDelete: () => onDelete(doctor),
                      onSuspend: () => onSuspend(doctor),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
