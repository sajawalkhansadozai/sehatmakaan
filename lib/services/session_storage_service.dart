import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure user session management
class SessionStorageService {
  static final SessionStorageService _instance =
      SessionStorageService._internal();
  factory SessionStorageService() => _instance;
  SessionStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _userSessionKey = 'user_session';
  static const String _adminSessionKey = 'admin_session';

  /// Save user session securely
  Future<void> saveUserSession(Map<String, dynamic> session) async {
    try {
      final sessionJson = jsonEncode(session);
      await _storage.write(key: _userSessionKey, value: sessionJson);
    } catch (e) {
      throw Exception('Failed to save user session: $e');
    }
  }

  /// Get stored user session
  Future<Map<String, dynamic>> getUserSession() async {
    try {
      final sessionJson = await _storage.read(key: _userSessionKey);
      if (sessionJson != null && sessionJson.isNotEmpty) {
        return jsonDecode(sessionJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Check if user session exists
  Future<bool> hasUserSession() async {
    try {
      final sessionJson = await _storage.read(key: _userSessionKey);
      return sessionJson != null && sessionJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clear user session
  Future<void> clearUserSession() async {
    try {
      await _storage.delete(key: _userSessionKey);
    } catch (e) {
      throw Exception('Failed to clear user session: $e');
    }
  }

  /// Save admin session securely
  Future<void> saveAdminSession(Map<String, dynamic> session) async {
    try {
      final sessionJson = jsonEncode(session);
      await _storage.write(key: _adminSessionKey, value: sessionJson);
    } catch (e) {
      throw Exception('Failed to save admin session: $e');
    }
  }

  /// Get stored admin session
  Future<Map<String, dynamic>> getAdminSession() async {
    try {
      final sessionJson = await _storage.read(key: _adminSessionKey);
      if (sessionJson != null && sessionJson.isNotEmpty) {
        return jsonDecode(sessionJson) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Clear admin session
  Future<void> clearAdminSession() async {
    try {
      await _storage.delete(key: _adminSessionKey);
    } catch (e) {
      throw Exception('Failed to clear admin session: $e');
    }
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear all sessions: $e');
    }
  }
}
