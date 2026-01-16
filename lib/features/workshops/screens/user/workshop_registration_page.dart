import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkshopRegistrationPage extends StatefulWidget {
  final Map<String, dynamic> workshop;
  final Map<String, dynamic> userSession;

  const WorkshopRegistrationPage({
    super.key,
    required this.workshop,
    required this.userSession,
  });

  @override
  State<WorkshopRegistrationPage> createState() =>
      _WorkshopRegistrationPageState();
}

class _WorkshopRegistrationPageState extends State<WorkshopRegistrationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _institutionController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isRegistering = false;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if available
    final email = widget.userSession['email'];
    if (email != null) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _institutionController.dispose();
    _specialtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F9),
      appBar: AppBar(
        title: const Text('Workshop Registration'),
        backgroundColor: const Color(0xFF006876),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [_buildWorkshopHeader(), _buildRegistrationForm()],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildWorkshopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.workshop['title'] ?? 'Workshop',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006876),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                _formatDate(widget.workshop['date']),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                widget.workshop['time'] ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PKR ${widget.workshop['price']?.toStringAsFixed(0) ?? '0'}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    return date.toString();
  }

  Widget _buildRegistrationForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Invalid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cnicController,
              label: 'CNIC Number (xxxxx-xxxxxxx-x)',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'CNIC is required';
                }
                final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (cleaned.length != 13) {
                  return 'CNIC must be 13 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number (03XX-XXXXXXX)',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone is required';
                }
                final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (cleaned.length != 11 || !cleaned.startsWith('03')) {
                  return 'Enter valid Pakistani mobile (03XX-XXXXXXX)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Professional Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _institutionController,
              label: 'Institution/Organization',
              icon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Institution is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _specialtyController,
              label: 'Medical Specialty',
              icon: Icons.medical_services,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Specialty is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006876),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: 'Special Requirements or Notes (Optional)',
              icon: Icons.note,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _termsAccepted,
              onChanged: (value) {
                setState(() => _termsAccepted = value ?? false);
              },
              title: const Text(
                'I agree to the terms and conditions',
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF006876),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 80), // Space for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF006876)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006876), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _termsAccepted && !_isRegistering
              ? _handleRegistration
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006876),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isRegistering
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    try {
      final userId = widget.userSession['id']?.toString();
      final workshopId = widget.workshop['id'];

      if (userId == null || workshopId == null) {
        throw Exception('Missing required data');
      }

      // Check workshop capacity
      final workshopDoc = await _firestore
          .collection('workshops')
          .doc(workshopId)
          .get();
      if (!workshopDoc.exists) {
        throw Exception('Workshop not found');
      }

      final workshopData = workshopDoc.data()!;
      final maxParticipants = workshopData['maxParticipants'] as int? ?? 0;
      final currentParticipants =
          workshopData['currentParticipants'] as int? ?? 0;

      if (currentParticipants >= maxParticipants) {
        throw Exception('Workshop is full. No seats available.');
      }

      // Check for duplicate registration
      final existingRegistration = await _firestore
          .collection('workshop_registrations')
          .where('workshopId', isEqualTo: workshopId)
          .where('userId', isEqualTo: userId)
          .where(
            'status',
            whereIn: ['pending_payment', 'confirmed', 'attended'],
          )
          .limit(1)
          .get();

      if (existingRegistration.docs.isNotEmpty) {
        throw Exception('You have already registered for this workshop.');
      }

      // Create registration document
      final registrationRef = await _firestore
          .collection('workshop_registrations')
          .add({
            'workshopId': workshopId,
            'userId': userId,
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'cnic': _cnicController.text.trim(),
            'phone': _phoneController.text.trim(),
            'institution': _institutionController.text.trim(),
            'specialty': _specialtyController.text.trim(),
            'notes': _notesController.text.trim(),
            'status': 'pending_payment',
            'paymentStatus': 'pending',
            'registeredAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Navigate to checkout page
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/workshop-checkout',
          arguments: {
            'workshop': widget.workshop,
            'registrationId': registrationRef.id,
            'registrationData': {
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'email': _emailController.text.trim(),
            },
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }
}
