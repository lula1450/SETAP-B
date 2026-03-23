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
Future<bool> createPet(String name, int speciesId, String city) async {
  final prefs = await SharedPreferences.getInstance();
  final int? ownerId = prefs.getInt('owner_id');

  final response = await http.post(
    Uri.parse("http://127.0.0.1:8000/pets/"), // Matches your router POST "/"
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "pet_first_name": name,
      "pet_last_name": "", // Or prompt in UI
      "species_id": speciesId,
      "owner_id": ownerId,
      "pet_address1": "TBD",
      "pet_postcode": "TBD",
      "pet_city": city,
    }),
  );
  return response.statusCode == 200;
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
