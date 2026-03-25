import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class PetService {
  final String baseUrl = "http://127.0.0.1:8000"; 

  // --- 1. GET OWNER PETS ---
  Future<List<dynamic>> getOwnerPets(int ownerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pets/owner/$ownerId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return []; 
    } else {
      throw Exception('Failed to load pets');
    }
  }

  // --- 2. CREATE PET ---
  Future<bool> createPet({
    required String pet_first_name,
    required String pet_last_name,
    required int species_id,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final int? ownerId = prefs.getInt('owner_id');
    final String? ownerAddr = prefs.getString('owner_address1');
    final String? ownerPost = prefs.getString('owner_postcode');
    final String? ownerCity = prefs.getString('owner_city');

    if (ownerId == null) {
      debugPrint("Error: No owner_id found in SharedPreferences");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/pets/create"), 
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
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Connection Error: $e");
      return false;
    }
  }

  // --- 3. CREATE APPOINTMENT ---
  Future<bool> createAppointment({
    required int petId,
    required String date, 
    required String time, 
    required String notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/schedule/appointments"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pet_id": petId,
          "appointment_date": date,
          "appointment_time": time,
          "notes": notes, 
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Booking Error: $e");
      return false;
    }
  }

  // --- 4. FETCH ALL APPOINTMENTS FOR HOUSEHOLD (Shared Calendar) ---
  Future<List<dynamic>> getAllAppointments(int ownerId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/schedule/appointments/owner/$ownerId")
      );
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      debugPrint("Fetch Household Appts Error: $e");
    }
    return [];
  }

  // --- 5. DELETE OWNER ---
  Future<bool> deleteOwner(int ownerId) async {
    final url = Uri.parse("$baseUrl/owners/$ownerId"); 
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete Error: $e");
      return false;
    }
  }
} // End of PetService class