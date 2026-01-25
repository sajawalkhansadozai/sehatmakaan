import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart';
import '../services/user_status_service.dart';
import 'dart:math';

class LoginPage extends StatefulWidget {
  final Function(Map<String, dynamic>)? onLogin;

  const LoginPage({super.key, this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _obscurePassword = true;

  String? _generatedOtp;
  DateTime? _otpExpiry;

  // ✅ Resend OTP timer state
  int _resendCountdown = 0;
  bool get _canResendOtp => _resendCountdown == 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // ✅ Start resend OTP countdown timer
  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        }
      });

      return _resendCountdown > 0;
    });
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSendingOtp = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // ✅ STEP 1: Authenticate with email/password FIRST
      debugPrint('🔐 Attempting authentication before OTP...');
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('✅ Password verified successfully');
      } on FirebaseAuthException catch (e) {
        debugPrint('❌ Authentication failed: ${e.code}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.code == 'user-not-found'
                    ? '❌ No account found with this email'
                    : e.code == 'wrong-password'
                    ? '❌ Incorrect password'
                    : '❌ Authentication failed: ${e.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // ✅ STEP 2: Check user status from Firestore
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        await _auth.signOut(); // Sign out if no user data found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ User data not found. Contact support.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userData = usersQuery.docs.first.data();
      final status = userData['status'] as String?;
      final isActive = userData['isActive'] as bool? ?? false;

      debugPrint('🔐 Email Verification Check - Email: $email');
      debugPrint('🔐 Email Verification Check - Status: $status');
      debugPrint('🔐 Email Verification Check - isActive: $isActive');

      // Check if account is suspended
      if (status == 'suspended') {
        debugPrint('⛔ SUSPENDED ACCOUNT - Showing suspension page');
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/account-suspended',
            arguments: 'Terms and Conditions Violation',
          );
        }
        return;
      }

      // Check if account is rejected or inactive
      if (status == 'rejected') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Your account has been rejected: ${userData['rejectionReason'] ?? 'Contact support'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!isActive) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Your account is inactive. Contact admin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (status != 'approved') {
        await _auth.signOut(); // Sign out before showing error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏳ Your account is pending admin approval'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // ✅ STEP 3: Password verified, now generate and send OTP
      _generatedOtp = _generateOtp();
      _otpExpiry = DateTime.now().add(const Duration(minutes: 10));

      debugPrint('📧 Sending OTP to verified user: $email');
      await _firestore.collection('email_queue').add({
        'to': email,
        'template': 'otp',
        'data': {'otp': _generatedOtp, 'name': userData['fullName'] ?? 'User'},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Sign out temporarily - will sign in again after OTP verification
      await _auth.signOut();
      debugPrint('🔓 Signed out temporarily - awaiting OTP verification');

      if (mounted) {
        setState(() {
          _otpSent = true;
          _resendCountdown = 60; // ✅ Start 60-second countdown
        });

        // ✅ Start countdown timer
        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ OTP sent to your email!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP must be 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verify OTP
    if (_generatedOtp == null || _otpExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please request OTP first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (DateTime.now().isAfter(_otpExpiry!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP expired. Please request a new one'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_otpController.text.trim() != _generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Firebase authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Login failed');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User data not found');

      final userData = userDoc.data()!;

      // Check account status
      final status = userData['status'] as String?;
      final isActive = userData['isActive'] as bool? ?? false;

      debugPrint('🔐 Login Check - Email: $email');
      debugPrint('🔐 Login Check - Status: $status');
      debugPrint('🔐 Login Check - isActive: $isActive');

      if (status == 'suspended') {
        debugPrint(
          '⛔ SUSPENDED USER - Blocking login and showing suspension page',
        );
        await _auth.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/account-suspended',
            arguments: 'Terms and Conditions Violation',
          );
        }
        return;
      }

      if (status == 'rejected') {
        await _auth.signOut();
        throw Exception(
          'Account Rejected: ${userData['rejectionReason'] ?? 'Contact support'}',
        );
      }

      if (!isActive) {
        await _auth.signOut();
        throw Exception('Account Deactivated - Contact Admin');
      }

      if (status != 'approved') {
        await _auth.signOut();
        throw Exception('Account Pending Approval');
      }

      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);
      await prefs.setString('user_email', userData['email']);
      await prefs.setString('user_full_name', userData['fullName'] ?? '');
      await prefs.setString('user_type', userData['userType'] ?? 'doctor');
      await prefs.setString('login_status', 'logged_in');

      if (mounted) {
        widget.onLogin?.call(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Login Successful!'),
            backgroundColor: Color(0xFF90D26D),
          ),
        );

        final userSessionData = {
          'id': user.uid,
          'email': userData['email'],
          'fullName': userData['fullName'],
          'userType': userData['userType'] ?? 'doctor',
          'status': userData['status'],
          'isActive': userData['isActive'] ?? true,
        };

        debugPrint('🔐 Login - Passing userSession: $userSessionData');
        debugPrint('🔐 Login - fullName: ${userData['fullName']}');

        // Start real-time status monitoring
        await UserStatusService.startMonitoring(context, user.uid);
        debugPrint('✅ User status monitoring started');

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
          arguments: userSessionData,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006876)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: 500,
        child: Center(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: ResponsiveHelper.isMobile(context) ? 60 : 80,
                  height: ResponsiveHelper.isMobile(context) ? 60 : 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.login,
                    size: ResponsiveHelper.isMobile(context) ? 30 : 40,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context),
                ),
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      32,
                    ),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006876),
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) * 0.3,
                ),
                Text(
                  'Access your practitioner dashboard',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      16,
                    ),
                    color: const Color(0xFF006876).withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context) * 1.5,
                ),
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(context) * 1.3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Email',
                          style: TextStyle(
                            color: Color(0xFF006876),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_otpSent,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Password',
                          style: TextStyle(
                            color: Color(0xFF006876),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_otpSent,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF006876),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'OTP Code',
                            style: TextStyle(
                              color: Color(0xFF006876),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              hintText: 'Enter 6-digit OTP',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ✅ RESEND OTP BUTTON with countdown timer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _canResendOtp
                                    ? 'Didn\'t receive OTP?'
                                    : 'Resend OTP in ${_resendCountdown}s',
                                style: const TextStyle(
                                  color: Color(0xFF006876),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: _canResendOtp && !_isSendingOtp
                                    ? () async {
                                        // Reset OTP state and resend
                                        setState(() {
                                          _otpSent = false;
                                          _generatedOtp = null;
                                          _otpExpiry = null;
                                          _otpController.clear();
                                        });
                                        await _sendOtp();
                                      }
                                    : null,
                                child: Text(
                                  'Resend',
                                  style: TextStyle(
                                    color: _canResendOtp
                                        ? const Color(0xFFFF6B35)
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                        if (!_otpSent)
                          ElevatedButton(
                            onPressed: _isSendingOtp ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSendingOtp
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Verify Email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          )
                        else
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
