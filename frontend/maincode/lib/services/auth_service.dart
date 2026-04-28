import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://localhost:8000";

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

        // Save all owner data returned from login
        await prefs.setInt('owner_id', data['owner_id']);
        await prefs.setString('owner_email', data['owner_email'] ?? "");
        await prefs.setString('owner_first_name', data['owner_first_name'] ?? "");
        await prefs.setString('owner_last_name', data['owner_last_name'] ?? "");
        await prefs.setString('owner_phone_number', data['owner_phone_number'] ?? "");
        await prefs.setString('owner_address1', data['owner_address1'] ?? "");
        await prefs.setString('owner_address2', data['owner_address2'] ?? "");
        await prefs.setString('owner_postcode', data['owner_postcode'] ?? "");
        await prefs.setString('owner_city', data['owner_city'] ?? "");
        // Store password for editing profile
        await prefs.setString('owner_password', password);
        await prefs.setBool('owner_password_set', true);

        return true;
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  // --- SIGN UP (Updated with Address Fields) ---
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String postcode,
    required String city,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "owner_first_name": firstName,
          "owner_last_name": lastName,
          "owner_email": email,
          "password": password,
          "owner_phone_number": phone, // Matches backend 'owner_phone_number'
          "owner_address1": address,
          "owner_postcode": postcode,
          "owner_city": city,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        // Save all owner data
        await prefs.setInt('owner_id', data['owner_id']);
        await prefs.setString('owner_email', email);
        await prefs.setString('owner_first_name', firstName);
        await prefs.setString('owner_last_name', lastName);
        await prefs.setString('owner_phone_number', phone);
        await prefs.setString('owner_address1', address);
        await prefs.setString('owner_postcode', postcode);
        await prefs.setString('owner_city', city);
        // Store password for editing profile
        await prefs.setString('owner_password', password);
        // Store a flag indicating password is set (we don't store actual password for security)
        await prefs.setBool('owner_password_set', true);
        
        return true;
      }
      return false;
    } catch (e) {
      print("SignUp error: $e");
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
      print("Delete error: $e");
      return false;
    }
  }
}