import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Keep the baseUrl as the root of your server
  static const String baseUrl = "http://127.0.0.1:8000";

  Future<bool> login(String email, String password) async {
    try {
      // This now correctly points to http://127.0.0.1:8000/auth/login
      final url = Uri.parse("$baseUrl/auth/login");
      
      print("Attempting login at: $url"); // Check your console for this!

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
      } else {
        print("Login failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Network error: $e");
      return false;
    }
  }
}
Future<bool> deleteAccount(int ownerId) async {
  final response = await http.delete(
    Uri.parse("http://127.0.0.1:8000/auth/owner/$ownerId"),
  );
  return response.statusCode == 200;
}