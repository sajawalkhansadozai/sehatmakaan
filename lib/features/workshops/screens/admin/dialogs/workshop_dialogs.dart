import 'package:flutter/material.dart';

class WorkshopDialogs {
  /// Show workshop form dialog (create or edit)
  /// Returns workshop data if saved, null if cancelled
  static Future<Map<String, dynamic>?> showWorkshopDialog(
    BuildContext context, {
    Map<String, dynamic>? initialData,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _WorkshopDialogContent(initialData: initialData),
    );
  }

  /// Show delete workshop confirmation dialog
  static Future<bool> showDeleteWorkshopDialog(
    BuildContext context,
    Map<String, dynamic> workshop,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workshop'),
        content: Text('Delete ${workshop['title']}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

/// Stateful dialog content for proper controller lifecycle management
class _WorkshopDialogContent extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const _WorkshopDialogContent({this.initialData});

  @override
  State<_WorkshopDialogContent> createState() => _WorkshopDialogContentState();
}

class _WorkshopDialogContentState extends State<_WorkshopDialogContent> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController providerController;
  late final TextEditingController priceController;
  late final TextEditingController locationController;
  late final TextEditingController maxParticipantsController;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.initialData?['title'] ?? '',
    );
    descriptionController = TextEditingController(
      text: widget.initialData?['description'] ?? '',
    );
    providerController = TextEditingController(
      text: widget.initialData?['provider'] ?? '',
    );
    priceController = TextEditingController(
      text: widget.initialData?['price']?.toString() ?? '',
    );
    locationController = TextEditingController(
      text: widget.initialData?['location'] ?? '',
    );
    maxParticipantsController = TextEditingController(
      text: widget.initialData?['maxParticipants']?.toString() ?? '',
    );

    // Parse existing schedule if editing
    if (widget.initialData != null && widget.initialData!['schedule'] != null) {
      _parseExistingSchedule(widget.initialData!['schedule']);
    }
  }

  void _parseExistingSchedule(String schedule) {
    // Try to parse existing schedule (format: "Jan 15, 2026 - 9:00 AM to 5:00 PM")
    try {
      final parts = schedule.split(' - ');
      if (parts.length >= 2) {
        // Parse date - simplified parser, could be enhanced based on format
        // final datePart = parts[0].trim();

        // Parse times if available
        if (parts[1].contains('to')) {
          final timeParts = parts[1].split(' to ');
          if (timeParts.length == 2) {
            // Set times (simplified - you may need proper parsing)
            _startTime = const TimeOfDay(hour: 9, minute: 0);
            _endTime = const TimeOfDay(hour: 17, minute: 0);
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing schedule: $e');
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    providerController.dispose();
    priceController.dispose();
    locationController.dispose();
    maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    // Admin can select ANY date (past, present, or future)
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020), // Allow past dates for admin
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF006876)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF006876)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF006876)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  String _formatDateTime() {
    if (_selectedDate == null) return '';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${months[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}';

    if (_startTime != null && _endTime != null) {
      final startStr = _startTime!.format(context);
      final endStr = _endTime!.format(context);
      return '$dateStr - $startStr to $endStr';
    } else if (_startTime != null) {
      return '$dateStr - ${_startTime!.format(context)}';
    }

    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialData == null ? 'Create Workshop' : 'Edit Workshop',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: providerController,
                decoration: const InputDecoration(
                  labelText: 'Provider',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (PKR)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxParticipantsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Participants',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Date and Time Section
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
                    Row(
                      children: [
                        const Icon(
                          Icons.event,
                          color: Color(0xFF006876),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Workshop Schedule',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (widget.initialData != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Admin: Can extend any date',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date *',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _selectedDate == null
                                        ? 'Select date'
                                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedDate == null
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartTime,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Time *',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _startTime == null
                                        ? 'Select'
                                        : _startTime!.format(context),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _startTime == null
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndTime,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'End Time *',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _endTime == null
                                        ? 'Select'
                                        : _endTime!.format(context),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _endTime == null
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDate != null &&
                        _startTime != null &&
                        _endTime != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF006876),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formatDateTime(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF006876),
                                  fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Title is required')),
              );
              return;
            }

            if (_selectedDate == null ||
                _startTime == null ||
                _endTime == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select date and time')),
              );
              return;
            }

            final workshopData = {
              'title': titleController.text,
              'description': descriptionController.text,
              'provider': providerController.text,
              'price': double.tryParse(priceController.text) ?? 0,
              'location': locationController.text,
              'maxParticipants':
                  int.tryParse(maxParticipantsController.text) ?? 30,
              'schedule': _formatDateTime(),
              'selectedDate': _selectedDate!.toIso8601String(),
              'startTime': '${_startTime!.hour}:${_startTime!.minute}',
              'endTime': '${_endTime!.hour}:${_endTime!.minute}',
            };

            Navigator.pop(context, workshopData);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006876),
          ),
          child: Text(widget.initialData == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}
