import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Add this line
import 'package:shared_preferences/shared_preferences.dart';


class PetService {
  // Use 10.0.2.2 if using Android Emulator, or your IP if using a real device
  final String baseUrl = "http://127.0.0.1:8000"; 

  Future<List<dynamic>> getOwnerPets(int ownerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pets/owner/$ownerId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return []; // Return empty list if no pets found
    } else {
      throw Exception('Failed to load pets');
    }
  }

  // lib/services/pet_service.dart
// lib/services/pet_service.dart
  Future<bool> createPet({
    required String pet_first_name,
    required String pet_last_name,
    required int species_id,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Pull the owner's logistical data saved during login
    final int? ownerId = prefs.getInt('owner_id');
    final String? ownerAddr = prefs.getString('owner_address1');
    final String? ownerPost = prefs.getString('owner_postcode');
    final String? ownerCity = prefs.getString('owner_city');

    // If we don't have an owner ID, we can't create a pet
    if (ownerId == null) {
      debugPrint("Error: No owner_id found in SharedPreferences");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/pets/create"), // Ensure this matches your FastAPI route
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pet_first_name": pet_first_name,
          "pet_last_name": pet_last_name,
          "species_id": species_id,
          "owner_id": ownerId,
          "pet_address1": ownerAddr ?? "Address not set",
          "pet_postcode": ownerPost ?? "Postcode not set",
          "pet_city": ownerCity ?? "City not set",
        }),
      );

      debugPrint("Create Pet Status: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Connection Error: $e");
      return false;
    }
  }

  Future<bool> deleteOwner(int ownerId) async {
  // Use 10.0.2.2 for Android, 127.0.0.1 for iOS
  final url = Uri.parse("http://127.0.0.1:8000/owners/$ownerId"); 
  try {
    final response = await http.delete(url);
    return response.statusCode == 200;
  } catch (e) {
    debugPrint("Delete Error: $e");
    return false;
  }
}
}
