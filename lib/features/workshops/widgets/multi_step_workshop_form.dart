import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Multi-step Workshop Form Widget
/// Provides a guided form experience for creating/editing workshops
class MultiStepWorkshopForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback? onCancel;

  const MultiStepWorkshopForm({
    super.key,
    this.initialData,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<MultiStepWorkshopForm> createState() => _MultiStepWorkshopFormState();
}

class _MultiStepWorkshopFormState extends State<MultiStepWorkshopForm> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1: Basic Information
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'health';

  // Step 2: Schedule & Duration
  DateTime? _startDate;
  TimeOfDay? _startTime;
  final _durationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  // Step 3: Location & Mode
  String _mode = 'in-person';
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();

  // Step 4: Pricing & Materials
  final _priceController = TextEditingController();
  final List<String> _materialsProvided = [];
  final _materialController = TextEditingController();

  // Step 5: Requirements & Instructions
  final _prerequisitesController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _titleController.text = data['title'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _category = data['category'] ?? 'health';

    if (data['startDate'] != null) {
      _startDate = DateTime.parse(data['startDate']);
    }
    if (data['startTime'] != null) {
      final timeParts = data['startTime'].toString().split(':');
      _startTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    _durationController.text = data['duration']?.toString() ?? '';
    _maxParticipantsController.text = data['maxParticipants']?.toString() ?? '';
    _mode = data['mode'] ?? 'in-person';
    _locationController.text = data['location'] ?? '';
    _meetingLinkController.text = data['meetingLink'] ?? '';
    _priceController.text = data['price']?.toString() ?? '';

    if (data['materialsProvided'] != null) {
      _materialsProvided.addAll(List<String>.from(data['materialsProvided']));
    }

    _prerequisitesController.text = data['prerequisites'] ?? '';
    _instructionsController.text = data['instructions'] ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _maxParticipantsController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _priceController.dispose();
    _materialController.dispose();
    _prerequisitesController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  List<Step> _buildSteps() {
    return [
      // Step 1: Basic Information
      Step(
        title: const Text('Basic Info'),
        subtitle: const Text('Workshop details'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Workshop Title *',
                hintText: 'e.g., Yoga for Beginners',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe what participants will learn...',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                if (value.length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'health',
                  child: Text('Health & Wellness'),
                ),
                DropdownMenuItem(value: 'fitness', child: Text('Fitness')),
                DropdownMenuItem(value: 'nutrition', child: Text('Nutrition')),
                DropdownMenuItem(value: 'mental', child: Text('Mental Health')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
          ],
        ),
      ),

      // Step 2: Schedule & Duration
      Step(
        title: const Text('Schedule'),
        subtitle: const Text('Date & time'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _startDate == null
                    ? 'Select Start Date *'
                    : 'Start Date: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                _startTime == null
                    ? 'Select Start Time *'
                    : 'Start Time: ${_startTime!.format(context)}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _startTime = time);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Duration (minutes) *',
                hintText: 'e.g., 60',
                prefixIcon: Icon(Icons.timer),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter duration';
                }
                final duration = int.tryParse(value);
                if (duration == null || duration < 15) {
                  return 'Duration must be at least 15 minutes';
                }
                if (duration > 480) {
                  return 'Duration cannot exceed 8 hours';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxParticipantsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Max Participants *',
                hintText: 'e.g., 20',
                prefixIcon: Icon(Icons.people),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter max participants';
                }
                final max = int.tryParse(value);
                if (max == null || max < 1) {
                  return 'Must be at least 1 participant';
                }
                if (max > 100) {
                  return 'Cannot exceed 100 participants';
                }
                return null;
              },
            ),
          ],
        ),
      ),

      // Step 3: Location & Mode
      Step(
        title: const Text('Location'),
        subtitle: const Text('Mode & venue'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workshop Mode *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              value: 'in-person',
              groupValue: _mode,
              title: const Text('In-Person'),
              subtitle: const Text('Physical location required'),
              secondary: const Icon(Icons.location_on),
              onChanged: (value) => setState(() => _mode = value!),
            ),
            RadioListTile<String>(
              value: 'online',
              groupValue: _mode,
              title: const Text('Online'),
              subtitle: const Text('Virtual meeting link required'),
              secondary: const Icon(Icons.video_call),
              onChanged: (value) => setState(() => _mode = value!),
            ),
            RadioListTile<String>(
              value: 'hybrid',
              groupValue: _mode,
              title: const Text('Hybrid'),
              subtitle: const Text('Both in-person and online'),
              secondary: const Icon(Icons.merge_type),
              onChanged: (value) => setState(() => _mode = value!),
            ),
            const SizedBox(height: 16),
            if (_mode == 'in-person' || _mode == 'hybrid') ...[
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Physical Location *',
                  hintText: 'e.g., Community Center, Room 101',
                  prefixIcon: Icon(Icons.place),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((_mode == 'in-person' || _mode == 'hybrid') &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            if (_mode == 'online' || _mode == 'hybrid') ...[
              TextFormField(
                controller: _meetingLinkController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Link *',
                  hintText: 'e.g., https://zoom.us/j/123456789',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((_mode == 'online' || _mode == 'hybrid') &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter meeting link';
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      !value.startsWith('http')) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),

      // Step 4: Pricing & Materials
      Step(
        title: const Text('Pricing'),
        subtitle: const Text('Cost & materials'),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Price (PKR) *',
                hintText: '0 for free workshop',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price (0 for free)';
                }
                final price = int.tryParse(value);
                if (price == null || price < 0) {
                  return 'Invalid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.inventory, color: Color(0xFF006876)),
                const SizedBox(width: 8),
                const Text(
                  'Materials Provided',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_materialsProvided.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    'No materials added yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _materialsProvided
                    .map(
                      (material) => Chip(
                        label: Text(material),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _materialsProvided.remove(material));
                        },
                        backgroundColor: const Color(
                          0xFF006876,
                        ).withValues(alpha: 0.1),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _materialController,
                    decoration: const InputDecoration(
                      hintText: 'Add material item',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    if (_materialController.text.isNotEmpty) {
                      setState(() {
                        _materialsProvided.add(_materialController.text);
                        _materialController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF006876),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Step 5: Requirements & Instructions
      Step(
        title: const Text('Details'),
        subtitle: const Text('Requirements & info'),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _prerequisitesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Prerequisites',
                hintText: 'Any requirements for participants (optional)',
                prefixIcon: Icon(Icons.checklist),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Special Instructions',
                hintText:
                    'What should participants bring or prepare? (optional)',
                prefixIcon: Icon(Icons.info),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Review all information before submitting. You can edit it later if needed.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  bool _validateCurrentStep() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    switch (_currentStep) {
      case 1: // Schedule
        if (_startDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select start date')),
          );
          return false;
        }
        if (_startTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select start time')),
          );
          return false;
        }
        break;
    }

    return true;
  }

  Map<String, dynamic> _buildFormData() {
    return {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category': _category,
      'startDate': _startDate?.toIso8601String(),
      'startTime': '${_startTime?.hour}:${_startTime?.minute}',
      'duration': int.parse(_durationController.text),
      'maxParticipants': int.parse(_maxParticipantsController.text),
      'mode': _mode,
      'location': _locationController.text,
      'meetingLink': _meetingLinkController.text,
      'price': int.parse(_priceController.text),
      'materialsProvided': _materialsProvided,
      'prerequisites': _prerequisitesController.text,
      'instructions': _instructionsController.text,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            if (_validateCurrentStep()) {
              setState(() => _currentStep++);
            }
          } else {
            if (_validateCurrentStep()) {
              widget.onSubmit(_buildFormData());
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            widget.onCancel?.call();
          }
        },
        onStepTapped: (step) {
          setState(() => _currentStep = step);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006876),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentStep < 4 ? 'Continue' : 'Submit Workshop',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF006876),
                      side: const BorderSide(color: Color(0xFF006876)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentStep > 0 ? 'Back' : 'Cancel',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        steps: _buildSteps(),
      ),
    );
  }
}
