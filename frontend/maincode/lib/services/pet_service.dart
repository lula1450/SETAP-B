import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class PetService {
  final String baseUrl = "http://10.0.2.2:8000";

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
  // Returns the new pet's ID on success, or -1 on failure.
  Future<int> createPet({
    required String pet_first_name,
    required String pet_last_name,
    required int species_id,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final int? ownerId = prefs.getInt('owner_id');

    if (ownerId == null) {
      debugPrint("Error: No owner_id found in SharedPreferences");
      return -1;
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
          "pet_address1": "Local",
          "pet_postcode": "00000",
          "pet_city": "Local",
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        return body['pet_id'] as int;
      }
      return -1;
    } catch (e) {
      debugPrint("Connection Error: $e");
      return -1;
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
  try {
    final response = await http.delete(Uri.parse("$baseUrl/owners/$ownerId"));
    return response.statusCode == 200;
  } catch (e) {
    debugPrint("Delete Error: $e");
    return false;
  }
}

  // Inside your PetService class
  Future<Map<String, dynamic>> getMetricAnalysis(int petId, String metric, {String? startDate, String? endDate}) async {
    try {
      // Build URI with optional query parameters for date filtering
      Uri uri = Uri.parse('$baseUrl/reports/analysis/$petId/$metric');
      final Map<String, String> queryParams = {};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (queryParams.isNotEmpty) uri = uri.replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load analysis');
      }
    } catch (e) {
      print("Error fetching analysis: $e");
      return {"is_risk": false, "points": [], "message": "Connection error"};
    }
  }

  // New: Fetch the list of metric names that have logged data for a pet
  Future<List<String>> getLoggedMetrics(int petId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports/logged-metrics/$petId'));
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching logged metrics: $e');
    }
    // Fallback
    return ['weight'];
  }

  Future<List<dynamic>> getPetHistory(int petId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/history/$petId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load history');
      }
    }

  // --- 6. GET REPORT HISTORY ---
  Future<List<dynamic>> getPetReportHistory(int petId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports/history/$petId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load report history');
      }
    } catch (e) {
      debugPrint('Error fetching report history: $e');
      return [];
    }
  }
  // lib/services/pet_service.dart
  // lib/services/pet_service.dart

  // lib/services/pet_service.dart

  // lib/services/pet_service.dart

  Future<void> deleteAppointment(int appointmentId) async { 
    final url = Uri.parse('$baseUrl/schedule/appointments/$appointmentId');
  
    debugPrint("DEBUG: Sending DELETE request to $url");
  
    final response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 204) {
      debugPrint("Backend responded with: ${response.statusCode}");
      throw Exception("Failed to delete appointment"); 
    }
  }

  Future<void> updateAppointment({
   required int appointmentId,
   required String date,
   required String time,
   required String notes,
 }) async {
   final response = await http.put(
     Uri.parse('$baseUrl/schedule/appointments/$appointmentId'),
     headers: {"Content-Type": "application/json"},
     body: jsonEncode({
       "new_date": date,
       "new_time": time,
       "notes": notes,
     }),
   );

   if (response.statusCode != 200) {
     throw Exception('Failed to update appointment: ${response.body}');
   }
 }

  Future<List<dynamic>> getFeedingSchedules(int petId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/schedule/feeding-schedules/pet/$petId'),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  Future<bool> deleteHealthLog(int petId, int metricId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/health/history/entry/$petId/$metricId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete health log error: $e");
      return false;
    }
  }

  Future<bool> deletePet(int petId) async {
  try {
    final response = await http.delete(Uri.parse("$baseUrl/pets/$petId"));
    return response.statusCode == 200;
  } catch (e) {
    debugPrint("Delete pet error: $e");
    return false;
  }
}

  Future<bool> renamePet(int petId, Map<String, dynamic> petData, String newFirstName, String newLastName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pets/$petId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pet_first_name": newFirstName,
          "pet_last_name": newLastName,
          "species_id": petData['species_id'],
          "owner_id": petData['owner_id'],
          "pet_address1": petData['pet_address1'] ?? "Address not set",
          "pet_postcode": petData['pet_postcode'] ?? "Postcode not set",
          "pet_city": petData['pet_city'] ?? "City not set",
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Rename pet error: $e");
      return false;
    }
  }

  Future<bool> updatePetImage(int petId, String imagePath) async {
   final response = await http.put(
     Uri.parse('$baseUrl/pets/$petId/image?image_url=$imagePath'),
   );
   return response.statusCode == 200;
 }

  // --- GET VET CONTACTS ---
  Future<List<dynamic>> getOwnerVetContacts(int ownerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vets/owner/$ownerId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load vet contacts');
    }
  }

  // --- CREATE VET CONTACT ---
  Future<bool> createVetContact({
    required int ownerId,
    int? petId,
    required String clinicName,
    required String phone,
    required String email,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/vets/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "owner_id": ownerId,
          "pet_id": petId,
          "clinic_name": clinicName,
          "phone": phone,
          "email": email,
          "address": address,
        }),
      );

      if (response.statusCode == 201) {
        debugPrint("Vet contact created successfully");
        return true;
      } else {
        debugPrint("Failed to create vet contact: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error creating vet contact: $e");
      return false;
    }
  }

  // --- UPDATE VET CONTACT ---
  Future<bool> updateVetContact({
    required int vetId,
    required int ownerId,
    int? petId,
    required String clinicName,
    required String phone,
    required String email,
    required String address,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/vets/$vetId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pet_id": petId,
          "clinic_name": clinicName,
          "phone": phone,
          "email": email,
          "address": address,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Vet contact updated successfully");
        return true;
      } else {
        debugPrint("Failed to update vet contact: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error updating vet contact: $e");
      return false;
    }
  }

  // --- GET AVAILABLE METRICS FOR PET ---
  Future<List<String>> getAvailableMetrics(int petId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health/metrics/$petId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map<String>((d) => d['name'] as String).toList();
      }
    } catch (_) {}
    return [];
  }

  // --- DELETE VET CONTACT ---
  Future<bool> deleteVetContact(int vetId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/vets/$vetId"),
      );

      if (response.statusCode == 200) {
        debugPrint("Vet contact deleted successfully");
        return true;
      } else {
        debugPrint("Failed to delete vet contact: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error deleting vet contact: $e");
      return false;
    }
  }
}