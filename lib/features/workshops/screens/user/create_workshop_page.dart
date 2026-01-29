import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:sehatmakaan/features/workshops/models/workshop_model.dart';
import 'package:sehatmakaan/features/workshops/services/workshop_creator_service.dart';

class CreateWorkshopPage extends StatefulWidget {
  final Map<String, dynamic> userSession;

  const CreateWorkshopPage({super.key, required this.userSession});

  @override
  State<CreateWorkshopPage> createState() => _CreateWorkshopPageState();
}

class _CreateWorkshopPageState extends State<CreateWorkshopPage> {
  final _formKey = GlobalKey<FormState>();
  final WorkshopCreatorService _creatorService = WorkshopCreatorService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAuthorized = false;
  String? _creatorId;
  String? _userId; // Store actual user ID
  dynamic _bannerImage; // File for mobile, Uint8List for web
  dynamic _syllabusPdf; // File for mobile, Uint8List for web
  String? _pdfFileName;
  final ImagePicker _imagePicker = ImagePicker();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _certTypeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _maxParticipantsController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  final TextEditingController _prerequisitesController =
      TextEditingController();
  final TextEditingController _materialsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _providerController.dispose();
    _certTypeController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    _locationController.dispose();
    _scheduleController.dispose();
    _instructorController.dispose();
    _prerequisitesController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorization() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.userSession['id']?.toString();
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _isAuthorized = false;
        });
        return;
      }

      final creator = await _creatorService.getCreatorByUserId(userId);

      if (mounted) {
        setState(() {
          _isAuthorized = creator != null && creator.isActive;
          _creatorId = creator?.id;
          _userId = userId; // Store actual user ID
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAuthorized = false;
        });
      }
    }
  }

  Future<void> _pickBannerImage() async {
    try {
      if (kIsWeb) {
        // Use FilePicker for web
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          final bytes = result.files.single.bytes!;
          final fileSizeInMB = bytes.length / (1024 * 1024);

          if (fileSizeInMB > 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image size must be less than 5MB'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          setState(() {
            _bannerImage = bytes;
          });
        }
      } else {
        // Use ImagePicker for mobile
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          final file = File(pickedFile.path);
          final fileSizeInBytes = await file.length();
          final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

          if (fileSizeInMB > 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image size must be less than 5MB'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          setState(() {
            _bannerImage = file;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickSyllabusPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        if (kIsWeb) {
          // Web platform - use bytes
          final bytes = result.files.single.bytes!;
          final fileSizeInMB = bytes.length / (1024 * 1024);

          if (fileSizeInMB > 10) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF size must be less than 10MB'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          setState(() {
            _syllabusPdf = bytes;
            _pdfFileName = result.files.single.name;
          });
        } else {
          // Mobile platform - use path
          if (result.files.single.path != null) {
            final file = File(result.files.single.path!);
            final fileSizeInBytes = await file.length();
            final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

            if (fileSizeInMB > 10) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF size must be less than 10MB'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            setState(() {
              _syllabusPdf = file;
              _pdfFileName = result.files.single.name;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking PDF: $e')));
      }
    }
  }

  Future<String?> _uploadBannerImage() async {
    if (_bannerImage == null) {
      debugPrint('⚠️ No banner image selected, skipping upload');
      return null;
    }

    try {
      debugPrint('📸 Starting banner image upload...');
      final fileName =
          'workshop_banners/${DateTime.now().millisecondsSinceEpoch}_$_creatorId.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      final UploadTask uploadTask;
      if (_bannerImage is Uint8List) {
        // Web platform
        debugPrint('📤 Uploading banner image (Web - Uint8List)...');
        uploadTask = storageRef.putData(
          _bannerImage as Uint8List,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // Mobile platform
        debugPrint('📤 Uploading banner image (Mobile - File)...');
        uploadTask = storageRef.putFile(
          _bannerImage as File,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Banner image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading banner image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload banner image: $e')),
        );
      }
      return null;
    }
  }

  Future<String?> _uploadSyllabusPdf() async {
    if (_syllabusPdf == null) {
      debugPrint('⚠️ No syllabus PDF selected, skipping upload');
      return null;
    }

    try {
      debugPrint('📄 Starting syllabus PDF upload...');
      final fileName =
          'workshop_syllabi/${DateTime.now().millisecondsSinceEpoch}_$_creatorId.pdf';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      final UploadTask uploadTask;
      if (_syllabusPdf is Uint8List) {
        // Web platform
        debugPrint('📤 Uploading PDF (Web - Uint8List)...');
        uploadTask = storageRef.putData(
          _syllabusPdf as Uint8List,
          SettableMetadata(contentType: 'application/pdf'),
        );
      } else {
        // Mobile platform
        debugPrint('📤 Uploading PDF (Mobile - File)...');
        uploadTask = storageRef.putFile(
          _syllabusPdf as File,
          SettableMetadata(contentType: 'application/pdf'),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Syllabus PDF uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading syllabus PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload syllabus PDF: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      initialTime: TimeOfDay.now(),
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
        // 🔄 Auto-calculate end time when start time changes
        _calculateEndTime();
      });
    }
  }

  // Calculate end time based on start time and duration
  void _calculateEndTime() {
    if (_startTime == null) return;

    final durationText = _durationController.text.trim();
    if (durationText.isEmpty) return;

    final duration = int.tryParse(durationText);
    if (duration == null || duration <= 0) return;

    // Convert start time to minutes
    int startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    // Add duration (hours)
    int endMinutes = startMinutes + (duration * 60);

    // Handle day overflow (if end time goes past midnight)
    if (endMinutes >= 24 * 60) {
      endMinutes = endMinutes % (24 * 60);
    }

    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;

    setState(() {
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }

  // Placeholder for end time selection (disabled - auto-calculated)
  Future<void> _selectEndTime() async {
    // End time is auto-calculated and read-only
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'End time is automatically calculated from Start Time + Duration',
        ),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
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

  Future<void> _submitWorkshop() async {
    if (!_formKey.currentState!.validate()) return;
    if (_creatorId == null) return;

    // Validate date and time selection
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select workshop date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if date is in the past
    final workshopDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    if (workshopDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot create workshop for past date/time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload banner image if selected
      String? bannerImageUrl;
      if (_bannerImage != null) {
        debugPrint('🖼️ Banner image selected, uploading...');
        bannerImageUrl = await _uploadBannerImage();
        if (bannerImageUrl == null) {
          debugPrint('⚠️ Banner image upload failed');
        }
      } else {
        debugPrint('⚠️ No banner image selected');
      }

      // Upload syllabus PDF if selected
      String? syllabusPdfUrl;
      if (_syllabusPdf != null) {
        debugPrint('📋 Syllabus PDF selected, uploading...');
        syllabusPdfUrl = await _uploadSyllabusPdf();
        if (syllabusPdfUrl == null) {
          debugPrint('⚠️ Syllabus PDF upload failed');
        }
      } else {
        debugPrint('⚠️ No syllabus PDF selected');
      }

      final scheduleText = _formatDateTime();

      final workshop = WorkshopModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        provider: _providerController.text.trim(),
        certificationType: _certTypeController.text.trim(),
        duration: int.parse(_durationController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        maxParticipants: int.parse(_maxParticipantsController.text.trim()),
        location: _locationController.text.trim(),
        schedule: scheduleText,
        instructor: _instructorController.text.trim().isEmpty
            ? null
            : _instructorController.text.trim(),
        prerequisites: _prerequisitesController.text.trim().isEmpty
            ? null
            : _prerequisitesController.text.trim(),
        materials: _materialsController.text.trim().isEmpty
            ? null
            : _materialsController.text.trim(),
        bannerImage: bannerImageUrl,
        syllabusPdf: syllabusPdfUrl,
        createdBy: _userId!, // Use actual user ID, not creator table ID
        permissionStatus: 'pending_admin',
      );

      await _firestore.collection('workshops').add(workshop.toJson());

      if (mounted) {
        final uploadedFiles = [];
        if (bannerImageUrl != null) uploadedFiles.add('banner image');
        if (syllabusPdfUrl != null) uploadedFiles.add('syllabus PDF');

        final fileMessage = uploadedFiles.isEmpty
            ? ''
            : ' (uploaded: ${uploadedFiles.join(', ')})';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workshop submitted successfully!$fileMessage Admin will review and set pricing.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating workshop: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Workshop'),
          backgroundColor: const Color(0xFF006876),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Workshop'),
          backgroundColor: const Color(0xFF006876),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 80,
                  color: Colors.red.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You are not authorized to create workshops.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please contact the administrator to be added as a workshop creator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006876),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Workshop'),
        backgroundColor: const Color(0xFF006876),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Basic Information'),

            // Banner Image Section
            _buildBannerImagePicker(),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _titleController,
              label: 'Workshop Title',
              hint: 'e.g., Basic Life Support (BLS) Certification',
              icon: Icons.title,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Detailed description of the workshop',
              icon: Icons.description,
              maxLines: 4,
              required: true,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Workshop Details'),
            _buildTextField(
              controller: _providerController,
              label: 'Provider',
              hint: 'e.g., American Heart Association',
              icon: Icons.business,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _certTypeController,
              label: 'Certification Type',
              hint: 'e.g., BLS, ACLS, PALS',
              icon: Icons.card_membership,
              required: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Duration (hours) *',
                      hintText: 'e.g., 6',
                      prefixIcon: const Icon(Icons.schedule),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) {
                      // 🔄 Recalculate end time whenever duration changes
                      _calculateEndTime();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Price (PKR)',
                    hint: 'e.g., 15000',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _maxParticipantsController,
                    label: 'Max Participants',
                    hint: 'e.g., 30',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _locationController,
                    label: 'Location',
                    hint: 'Workshop venue',
                    icon: Icons.location_on,
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date and Time Selection
            _buildSectionTitle('Workshop Schedule'),
            _buildDateTimePicker(),

            const SizedBox(height: 24),
            _buildSectionTitle('Additional Information (Optional)'),
            _buildTextField(
              controller: _instructorController,
              label: 'Instructor Name',
              hint: 'e.g., Dr. Ahmad Khan',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _prerequisitesController,
              label: 'Prerequisites',
              hint: 'Any requirements for participants',
              icon: Icons.checklist,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _materialsController,
              label: 'Materials Included',
              hint: 'What participants will receive',
              icon: Icons.inventory,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildPdfPicker(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitWorkshop,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006876),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create Workshop',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerImagePicker() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_bannerImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: _bannerImage is Uint8List
                      ? Image.memory(
                          _bannerImage as Uint8List,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          _bannerImage as File,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _bannerImage = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: _pickBannerImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to add banner image',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optional - Recommended size: 1920x1080',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_bannerImage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: _pickBannerImage,
                icon: const Icon(Icons.edit),
                label: const Text('Change Banner'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF006876),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selection
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF006876)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Workshop Date *',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDate == null
                              ? 'Tap to select date'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Time Selection
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectStartTime,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF006876)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Time *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _startTime == null
                                    ? 'Select'
                                    : _startTime!.format(context),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _startTime == null
                                      ? Colors.grey.shade400
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectEndTime, // Shows info message only
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors
                          .grey
                          .shade50, // Slightly grayed to show disabled state
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          color: Color(0xFF006876),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'End Time (Auto)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Tooltip(
                                    message:
                                        'Automatically calculated: Start Time + Duration',
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _endTime == null
                                    ? 'Will auto-calculate'
                                    : _endTime!.format(context),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _endTime == null
                                      ? Colors.grey.shade400
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Show formatted schedule preview
          if (_selectedDate != null &&
              _startTime != null &&
              _endTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    color: Color(0xFF006876),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateTime(),
                      style: const TextStyle(
                        fontSize: 14,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF006876),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              if (keyboardType == TextInputType.number) {
                if (label.contains('Duration')) {
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Duration must be greater than 0';
                  }
                } else if (label.contains('Price')) {
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Price must be greater than 0';
                  }
                } else if (label.contains('Participants')) {
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Must be at least 1 participant';
                  }
                  if (num > 500) {
                    return 'Maximum 500 participants allowed';
                  }
                } else {
                  final num = int.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Please enter a valid number';
                  }
                }
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildPdfPicker() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Color(0xFF006876)),
              const SizedBox(width: 8),
              const Text(
                'Workshop Syllabus (PDF)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_syllabusPdf != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pdfFileName ?? 'Syllabus.pdf',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        _syllabusPdf = null;
                        _pdfFileName = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _pickSyllabusPdf,
            icon: Icon(_syllabusPdf == null ? Icons.upload_file : Icons.edit),
            label: Text(_syllabusPdf == null ? 'Upload PDF' : 'Change PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF006876),
              side: const BorderSide(color: Color(0xFF006876)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional - Max size: 10MB',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
