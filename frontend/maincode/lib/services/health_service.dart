import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HealthService {
  static String get baseUrl {
    // Use localhost for web, 10.0.2.2 for Android emulator
    if (kIsWeb) {
      return "http://localhost:8000";
    }
    return "http://10.0.2.2:8000";
  }

  /// Logs a new metric entry and returns the backend's analysis
  Future<Map<String, dynamic>> logMetric({
    required int petId,
    required String metricName,
    required dynamic value,
    String? notes,
  }) async {
    final url = Uri.parse("$baseUrl/health/log");
    
    // Convert to number if possible, otherwise keep as string (for text metrics)
    var formattedValue = double.tryParse(value.toString()) ?? value.toString();

    try {
      debugPrint("DEBUG: Sending Pet ID: $petId for Metric: $metricName");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pet_id": petId,
          "metric_name": metricName,
          "value": formattedValue,
          "notes": notes ?? "Logged from Flutter",
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Server error ${response.statusCode}", "analysis": "Check backend logs"};
      }
    } catch (e) {
      debugPrint("Flutter Connection Error: $e");
      return {"error": "Connection failed"};
    }
  }

 // inside health_service.dart
  Future<Map<String, String>> getLatestMetric(int petId, String metricName) async {
    final url = Uri.parse("$baseUrl/health/latest?pet_id=$petId&metric_name=$metricName");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
       final data = jsonDecode(response.body);
        return {
          "value": data['value'].toString(),
        "target": data['target']?.toString() ?? "" // Pull the target from backend
        };
      }
    } catch (e) {
      debugPrint("Get latest metric error: $e");
   }
    return {"value": "---", "target": ""};
  }

  /// Syncs a user-entered goal (target) to the permanent database
  Future<void> syncGoalToBackend(int petId, String metricName, String goal) async {
    // Note: Ensure your backend route accepts these as query parameters
    final url = Uri.parse("$baseUrl/health/goal?pet_id=$petId&metric_name=$metricName&goal=$goal");
    try {
      final response = await http.post(url);
      if (response.statusCode != 200) {
        debugPrint("Backend rejected goal update: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Goal sync connection failed: $e");
    }
  }
}