import 'package:http/http.dart' as http;
import 'package:my_new_project/config.dart';
import 'dart:convert';

import 'package:my_new_project/services/session.dart';

class SensorService {
  Future<List<int>> getSensorIDs() async {
    try {
      final userId = await SessionService.getUserID();
      if (userId == null) {
        throw Exception("User ID not found.");
      }

      final token = await SessionService.getToken();
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      //const String baseUrl = 'http://192.168.217.13:8080/api';
      const String baseUrl = 'http://${Config.apiURL}:8080/api';
      final String apiUrl = '$baseUrl/users/$userId/sensors';

      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<int>((device) => device['sensorId'] as int).toList();
      } else {
        throw Exception(
            'Failed to load sensor IDs. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sensor IDs: $e');
    }
  }

  Future<int?> getFirstSensorID() async {
    try {
      final sensorIDs = await getSensorIDs();
      if (sensorIDs.isNotEmpty) {
        return sensorIDs.first;
      } else {
        throw Exception("No sensors available.");
      }
    } catch (e) {
      throw Exception('Error fetching first sensor ID: $e');
    }
  }
}
