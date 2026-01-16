import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class RegistrationProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form Controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final ageController = TextEditingController();
  final yearsExpController = TextEditingController();
  final pmdcController = TextEditingController();
  final cnicController = TextEditingController();
  final phoneController = TextEditingController();
  final emailOtpController = TextEditingController();
  final phoneOtpController = TextEditingController();

  // Form State
  String? selectedGender;
  String? selectedSpecialty;
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // OTP State
  bool isEmailVerified = false;
  bool isPhoneVerified = false;
  bool isSendingEmailOtp = false;
  bool isSendingPhoneOtp = false;
  bool isVerifyingEmailOtp = false;
  bool isVerifyingPhoneOtp = false;

  String? _emailOtp;
  DateTime? _emailOtpExpiry;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    yearsExpController.dispose();
    pmdcController.dispose();
    cnicController.dispose();
    phoneController.dispose();
    emailOtpController.dispose();
    phoneOtpController.dispose();
    super.dispose();
  }

  void setGender(String? value) {
    selectedGender = value;
    notifyListeners();
  }

  void setSpecialty(String? value) {
    selectedSpecialty = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  // Generate random 6-digit OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send Email OTP
  Future<String?> sendEmailOtp() async {
    if (emailController.text.trim().isEmpty) {
      return 'Please enter email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(emailController.text.trim())) {
      return 'Please enter a valid email address';
    }

    isSendingEmailOtp = true;
    notifyListeners();

    try {
      // Generate OTP
      _emailOtp = _generateOtp();
      _emailOtpExpiry = DateTime.now().add(const Duration(minutes: 10));

      // Send OTP via Cloud Function
      final docRef = await _firestore.collection('email_queue').add({
        'to': emailController.text.trim(),
        'template': 'otp',
        'data': {
          'otp': _emailOtp,
          'name': fullNameController.text.trim().isEmpty
              ? 'User'
              : fullNameController.text.trim(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint('✅ Email OTP queued successfully! Doc ID: ${docRef.id}');
      debugPrint('📧 Sending to: ${emailController.text.trim()}');
      debugPrint('🔑 OTP: $_emailOtp (for debugging only)');
      debugPrint('⏰ Wait 30-60 seconds for email delivery (cold start delay)');

      isSendingEmailOtp = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      isSendingEmailOtp = false;
      notifyListeners();
      return 'Failed to send OTP: ${e.toString()}';
    }
  }

  // Verify Email OTP
  String? verifyEmailOtp() {
    if (emailOtpController.text.trim().isEmpty) {
      return 'Please enter OTP';
    }

    if (_emailOtp == null) {
      return 'Please request OTP first';
    }

    // Check if OTP expired (10 minutes)
    if (_emailOtpExpiry != null && DateTime.now().isAfter(_emailOtpExpiry!)) {
      _emailOtp = null;
      _emailOtpExpiry = null;
      return 'OTP expired. Please request a new one.';
    }

    if (emailOtpController.text.trim().length != 6) {
      return 'OTP must be 6 digits';
    }

    if (emailOtpController.text.trim() == _emailOtp) {
      isEmailVerified = true;
      _emailOtp = null; // Clear OTP after successful verification
      _emailOtpExpiry = null;
      notifyListeners();
      return null; // Success
    }

    return 'Invalid OTP. Please check and try again.';
  }

  // ========== PHONE VERIFICATION REMOVED ==========
  // Phone number validation only - no OTP verification required

  // Validate all fields before submission
  String? validateForm() {
    if (fullNameController.text.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (emailController.text.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!isEmailVerified) {
      return 'Please verify your email address';
    }
    if (phoneController.text.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    // Phone verification removed - phone number validation only
    final cleanNumber = phoneController.text.replaceAll(RegExp(r'[\s-]'), '');
    final phoneRegex = RegExp(r'^(\+92|0)?3[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleanNumber)) {
      return 'Enter valid Pakistani phone number';
    }
    if (passwordController.text.isEmpty) {
      return 'Please enter a password';
    }
    if (passwordController.text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (passwordController.text != confirmPasswordController.text) {
      return 'Passwords do not match';
    }
    if (ageController.text.trim().isEmpty) {
      return 'Please enter your age';
    }
    if (selectedGender == null) {
      return 'Please select your gender';
    }
    if (yearsExpController.text.trim().isEmpty) {
      return 'Please enter years of experience';
    }
    if (selectedSpecialty == null) {
      return 'Please select your specialty';
    }
    if (pmdcController.text.trim().isEmpty) {
      return 'Please enter PMDC number';
    }
    if (cnicController.text.trim().isEmpty) {
      return 'Please enter CNIC number';
    }
    return null; // All validations passed
  }

  // Submit Registration
  Future<String?> submitRegistration() async {
    // Validate all fields
    final validationError = validateForm();
    if (validationError != null) {
      return validationError;
    }

    isLoading = true;
    notifyListeners();

    try {
      // Check if email is already registered and suspended
      final email = emailController.text.trim();
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        final userData = existingUsers.docs.first.data();
        final status = userData['status'] as String?;
        final isActive = userData['isActive'] as bool? ?? false;

        if (status == 'suspended') {
          isLoading = false;
          notifyListeners();
          return 'ACCOUNT_SUSPENDED:Terms and Conditions Violation';
        }

        if (!isActive || status == 'rejected') {
          isLoading = false;
          notifyListeners();
          return 'Account already exists but is inactive. Please contact support.';
        }

        // Email already registered with active account
        isLoading = false;
        notifyListeners();
        return 'Email already registered. Please login instead.';
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );

      final userId = userCredential.user!.uid;

      // Create user document in Firestore
      await _firestore.collection('users').doc(userId).set({
        'fullName': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'age': int.parse(ageController.text),
        'gender': selectedGender,
        'yearsOfExperience': int.parse(yearsExpController.text),
        'pmdcNumber': pmdcController.text.trim(),
        'cnicNumber': cnicController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'specialty': selectedSpecialty,
        'userType': 'doctor',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': false,
        'emailVerified': isEmailVerified,
        'phoneVerified': isPhoneVerified,
      });

      // Send notification to admins
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      for (final adminDoc in adminsSnapshot.docs) {
        await _firestore.collection('notifications').add({
          'userId': adminDoc.id,
          'type': 'new_registration',
          'title': 'New Doctor Registration',
          'message':
              '${fullNameController.text.trim()} has registered. Please review and approve.',
          'priority': 'high',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'doctorId': userId,
            'doctorName': fullNameController.text.trim(),
            'doctorEmail': emailController.text.trim(),
            'specialty': selectedSpecialty,
          },
        });
      }

      // Save registration status locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('registration_status', 'pending');
      await prefs.setString('user_email', emailController.text.trim());
      await prefs.setString('user_id', userId);

      isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();

      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered';
        case 'weak-password':
          return 'Password is too weak (min 6 characters)';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return 'Registration failed: ${e.message}';
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return 'Error: ${e.toString()}';
    }
  }
}
