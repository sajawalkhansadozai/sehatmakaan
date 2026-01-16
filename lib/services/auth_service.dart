import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase Authentication Service
/// Handles user registration, login, logout, and session management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User logged in status
  bool get isLoggedIn => _auth.currentUser != null;

  /// Register new doctor
  Future<Map<String, dynamic>> registerDoctor({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required int age,
    required String gender,
    required String pmdcNumber,
    required String cnicNumber,
    required String phoneNumber,
    required String specialty,
    required int yearsOfExperience,
  }) async {
    try {
      // Create Firebase Auth user
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

      // Create Firestore user document
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'email': email,
        'fullName': fullName,
        'username': username,
        'age': age,
        'gender': gender,
        'pmdcNumber': pmdcNumber,
        'cnicNumber': cnicNumber,
        'phoneNumber': phoneNumber,
        'specialty': specialty,
        'yearsOfExperience': yearsOfExperience,
        'isVerified': false,
        'isApproved': false,
        'status': 'pending', // pending, approved, rejected
        'rejectionReason': null,
        'approvedAt': null,
        'rejectedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Doctor registered: ${user.uid}');
      return {
        'success': true,
        'userId': user.uid,
        'message': 'Registration successful. Awaiting admin approval.',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Registration error: ${e.code} - ${e.message}');
      return {'success': false, 'error': _getAuthErrorMessage(e.code)};
    } catch (e) {
      debugPrint('❌ Unexpected registration error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Login doctor
  Future<Map<String, dynamic>> loginDoctor({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Login failed');
      }

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'error': 'User data not found. Please contact support.',
        };
      }

      final userData = userDoc.data()!;

      // Check account status
      final status = userData['status'] as String?;

      if (status == 'suspended') {
        await _auth.signOut();
        return {
          'success': false,
          'error':
              'Account Suspended\n\nYour account has been temporarily suspended due to violation of our Terms and Conditions. All activities are paused. Please contact admin for details.',
        };
      }

      if (status == 'rejected') {
        await _auth.signOut();
        return {
          'success': false,
          'error':
              'Account Rejected\n\n${userData['rejectionReason'] ?? 'Your registration has been rejected. Contact support for details.'}',
        };
      }

      if (status != 'approved') {
        await _auth.signOut();
        return {
          'success': false,
          'error':
              'Account Pending Approval\n\nYour account is awaiting admin approval. You will be notified once approved.',
        };
      }

      // Check if account is active
      if (userData['isActive'] == false) {
        await _auth.signOut();
        return {
          'success': false,
          'error':
              'Account Inactive\n\nYour account has been deactivated. Please contact admin for assistance.',
        };
      }

      // Save login session in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);
      await prefs.setString('user_email', userData['email']);
      await prefs.setString('user_type', userData['userType']);
      await prefs.setString('login_status', 'logged_in');
      await prefs.remove('registration_status'); // Clear registration status

      debugPrint('✅ Doctor logged in: ${user.uid}');
      return {
        'success': true,
        'userId': user.uid,
        'userData': userData,
        'message': 'Login successful',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Login error: ${e.code} - ${e.message}');
      return {'success': false, 'error': _getAuthErrorMessage(e.code)};
    } catch (e) {
      debugPrint('❌ Unexpected login error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Admin login
  Future<Map<String, dynamic>> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Admin login failed');
      }

      // Check if user is admin by userType field
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'error': 'User data not found. Please contact support.',
        };
      }

      final userData = userDoc.data()!;

      // Debug: Print user data from Firestore
      debugPrint('🔍 Firestore userData: $userData');
      debugPrint('🔍 fullName field: ${userData['fullName']}');
      debugPrint('🔍 username field: ${userData['username']}');
      debugPrint('🔍 email field: ${userData['email']}');

      // Check if userType is admin
      if (userData['userType'] != 'admin') {
        await _auth.signOut();
        return {
          'success': false,
          'error': 'Admin access denied. You do not have admin privileges.',
        };
      }

      // Check if admin is active
      if (userData['isActive'] != true) {
        await _auth.signOut();
        return {
          'success': false,
          'error': 'Admin account is inactive. Please contact support.',
        };
      }

      debugPrint('✅ Admin logged in: ${user.uid}');
      return {
        'success': true,
        'adminId': user.uid,
        'adminData': userData,
        'message': 'Admin login successful',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Admin login error: ${e.code} - ${e.message}');
      return {'success': false, 'error': _getAuthErrorMessage(e.code)};
    } catch (e) {
      debugPrint('❌ Unexpected admin login error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('login_status');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_type');

      // Sign out from Firebase
      await _auth.signOut();
      debugPrint('✅ User logged out');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent to: $email');
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset error: ${e.code} - ${e.message}');
      return {'success': false, 'error': _getAuthErrorMessage(e.code)};
    } catch (e) {
      debugPrint('❌ Unexpected password reset error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(updates);

      debugPrint('✅ User profile updated: $userId');
      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      debugPrint('❌ Profile update error: $e');
      return {
        'success': false,
        'error': 'Failed to update profile. Please try again.',
      };
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Get user data error: $e');
      return null;
    }
  }

  /// Check if username exists
  Future<bool> isUsernameExists(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Username check error: $e');
      return false;
    }
  }

  /// Check if email exists
  Future<bool> isEmailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Email check error: $e');
      return false;
    }
  }

  /// Helper: Get user-friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Authentication error. Please try again.';
    }
  }
}
