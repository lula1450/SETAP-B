import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS/Web/Desktop
  static const String baseUrl = "http://127.0.0.1:8000";

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
        return true;
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  // --- SIGN UP ---
  Future<bool> signUp(String firstName, String lastName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "owner_first_name": firstName,
          "owner_last_name": lastName,
          "owner_email": email,
          "password": password,
          "owner_phone": "0000000000" 
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("SignUp error: $e");
      return false;
    }
  }

  // --- DELETE ACCOUNT ---
  Future<bool> deleteAccount(int ownerId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/auth/owner/$ownerId"),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Delete error: $e");
      return false;
    }
  }
}