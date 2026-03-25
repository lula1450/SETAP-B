import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
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
        
        // Save ID and Address info for pet registration later
        await prefs.setInt('owner_id', data['owner_id']);
        await prefs.setString('owner_address1', data['owner_address1'] ?? "");
        await prefs.setString('owner_postcode', data['owner_postcode'] ?? "");
        await prefs.setString('owner_city', data['owner_city'] ?? "");
        
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
        
        // IMPORTANT: Save these now so AddPetPage can auto-fill them
        await prefs.setInt('owner_id', data['owner_id']);
        await prefs.setString('owner_address1', address);
        await prefs.setString('owner_postcode', postcode);
        await prefs.setString('owner_city', city);
        
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
        Uri.parse("$baseUrl/auth/owner/$ownerId"),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Delete error: $e");
      return false;
    }
  }
}