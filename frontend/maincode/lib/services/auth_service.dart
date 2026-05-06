import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl {
    // Use localhost for web, 10.0.2.2 for Android emulator
    if (kIsWeb) {
      return "http://localhost:8000";
    }
    return "http://10.0.2.2:8000";
  }

  // --- LOGIN ---
  Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('owner_id', data['owner_id']);
        await prefs.setString('owner_email', data['owner_email'] ?? "");
        await prefs.setString('owner_first_name', data['owner_first_name'] ?? "");
        await prefs.setString('owner_last_name', data['owner_last_name'] ?? "");
        await prefs.setString('owner_password', password);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login error: $e");
      return false;
    }
  }

  // --- SIGN UP ---
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "owner_first_name": firstName,
          "owner_last_name": lastName.isEmpty ? "User" : lastName,
          "owner_email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('owner_id', data['owner_id']);
        await prefs.setString('owner_email', email);
        await prefs.setString('owner_first_name', firstName);
        await prefs.setString('owner_last_name', lastName);
        await prefs.setString('owner_password', password);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("SignUp error: $e");
      return false;
    }
  }

  // --- DELETE ACCOUNT ---
  Future<bool> deleteAccount(int ownerId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/owners/$ownerId"),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete error: $e");
      return false;
    }
  }
}