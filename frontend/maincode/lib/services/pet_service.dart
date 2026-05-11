import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maincode/services/auth_service.dart';

class PetService {
  String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000";
    }
    return "http://10.0.2.2:8000";
  }

  // --- 1. GET OWNER PETS ---
  Future<List<dynamic>> getOwnerPets(int ownerId) async {
    final headers = await AuthService.authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/pets/owner/$ownerId'),
      headers: headers,
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
      final headers = await AuthService.authHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/pets/create"),
        headers: headers,
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
    String reminderFrequency = 'once',
  }) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/schedule/appointments"),
        headers: headers,
        body: jsonEncode({
          "pet_id": petId,
          "appointment_date": date,
          "appointment_time": time,
          "notes": notes,
          "reminder_frequency": reminderFrequency,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Booking Error: $e");
      return false;
    }
  }

  // --- 4. FETCH ALL APPOINTMENTS FOR HOUSEHOLD ---
  Future<List<dynamic>> getAllAppointments(int ownerId) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/schedule/appointments/owner/$ownerId"),
        headers: headers,
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
      final headers = await AuthService.authHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl/owners/$ownerId"),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> getMetricAnalysis(int petId, String metric, {String? startDate, String? endDate}) async {
    try {
      Uri uri = Uri.parse('$baseUrl/reports/analysis/$petId/$metric');
      final Map<String, String> queryParams = {};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (queryParams.isNotEmpty) uri = uri.replace(queryParameters: queryParams);

      final headers = await AuthService.authHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load analysis');
      }
    } catch (e) {
      debugPrint("Error fetching analysis: $e");
      return {"is_risk": false, "points": [], "message": "Connection error"};
    }
  }

  Future<List<String>> getLoggedMetrics(int petId) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reports/logged-metrics/$petId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching logged metrics: $e');
    }
    return ['weight'];
  }

  Future<List<dynamic>> getPetHistory(int petId) async {
    final headers = await AuthService.authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/health/history/$petId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load history');
    }
  }

  // --- 6. GET REPORT HISTORY ---
  Future<List<dynamic>> getPetReportHistory(int petId) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reports/history/$petId'),
        headers: headers,
      );
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

  Future<void> deleteAppointmentSeries(int seriesId) async {
    final headers = await AuthService.authHeaders();
    final url = Uri.parse('$baseUrl/schedule/appointments/series/$seriesId');
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 204) {
      throw Exception("Failed to delete appointment series");
    }
  }

  Future<void> deleteAppointment(int appointmentId) async {
    final headers = await AuthService.authHeaders();
    final url = Uri.parse('$baseUrl/schedule/appointments/$appointmentId');

    debugPrint("DEBUG: Sending DELETE request to $url");

    final response = await http.delete(url, headers: headers);

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
    final headers = await AuthService.authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/schedule/appointments/$appointmentId'),
      headers: headers,
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
    final headers = await AuthService.authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/schedule/feeding-schedules/pet/$petId'),
      headers: headers,
    );
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  Future<bool> deleteFeedingSchedule(int scheduleId) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/schedule/feeding-schedules/$scheduleId'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete feeding schedule error: $e');
      return false;
    }
  }

  Future<bool> updateHealthLog(int petId, int metricId, {required dynamic value, String? notes}) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/health/history/entry/$petId/$metricId'),
        headers: headers,
        body: jsonEncode({"value": value, "notes": notes}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Update health log error: $e");
      return false;
    }
  }

  Future<bool> deleteHealthLog(int petId, int metricId) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/health/history/entry/$petId/$metricId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete health log error: $e");
      return false;
    }
  }

  Future<bool> deletePet(int petId) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl/pets/$petId"),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete pet error: $e");
      return false;
    }
  }

  Future<bool> renamePet(int petId, Map<String, dynamic> petData, String newFirstName, String newLastName) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/pets/$petId'),
        headers: headers,
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
    final headers = await AuthService.authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/pets/$petId/image?image_url=$imagePath'),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  // --- GET VET CONTACTS ---
  Future<List<dynamic>> getOwnerVetContacts(int ownerId) async {
    final headers = await AuthService.authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/vets/owner/$ownerId'),
      headers: headers,
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
      final headers = await AuthService.authHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/vets/create"),
        headers: headers,
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
      final headers = await AuthService.authHeaders();
      final response = await http.put(
        Uri.parse("$baseUrl/vets/$vetId"),
        headers: headers,
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
      final headers = await AuthService.authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/health/metrics/$petId'),
        headers: headers,
      );
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
      final headers = await AuthService.authHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl/vets/$vetId"),
        headers: headers,
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
