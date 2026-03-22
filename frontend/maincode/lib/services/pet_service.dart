import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Add this line

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

  Future<void> createPet(Map<String, dynamic> petData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pets/'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(petData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create pet');
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
