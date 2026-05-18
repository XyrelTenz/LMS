import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'dart:convert';

class SessionManager {
  static const _keyUser = 'session_user';

  static Future<void> saveUser(domain.User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'id': user.id,
      'username': user.username,
      'full_name': user.fullName,
      'role': user.role.toString(),
    };
    try {
      await prefs.setString(_keyUser, jsonEncode(userData));
    } catch (e) {
      debugPrint("Session storage error: $e");
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_keyUser);
      if (value != null) {
        return jsonDecode(value);
      }
    } catch (e) {
      debugPrint("Session storage error: $e");
    }
    return null;
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
    } catch (e) {
      debugPrint("Session storage error: $e");
    }
  }
}
