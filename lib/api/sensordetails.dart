import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_project/config.dart';

class SensorApiService {
  Future<SensorDetailDto?> fetchSensorDetails(
      int sensorId, String token) async {
    try {
      final String apiUrl = 'http://${Config.apiURL}/api/sensors/$sensorId';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization':
              'Bearer $token', // Use Bearer token for authorization
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return SensorDetailDto.fromJson(json.decode(response.body));
      } else {
        print('Failed to load sensor details: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching sensor details: $e');
    }
    return null;
  }
}

class SensorDetailDto {
  //final int sensorId;
  //final int ownerId;
  final String sensorName;
  //final int readingPeriod;
  //final String currentState;
  //final int height;
  //final int soilMoistureAlertThreshold;
  //final int soilMoistureActionThreshold;
  //final int temperatureAlertThreshold;
  //final int temperatureActionThreshold;

  SensorDetailDto({
    //required this.sensorId,
    //required this.ownerId,
    required this.sensorName,
    //required this.readingPeriod,
    //required this.currentState,
    //required this.height,
    //required this.soilMoistureAlertThreshold,
    //required this.soilMoistureActionThreshold,
    //required this.temperatureAlertThreshold,
    //required this.temperatureActionThreshold,
  });

  factory SensorDetailDto.fromJson(Map<String, dynamic> json) {
    return SensorDetailDto(
      //sensorId: json['sensorId'],
      //ownerId: json['ownerId'],
      sensorName: json['sensorName'],
      //readingPeriod: json['readingPeriod'],
      //currentState: json['currentState'],
      //height: json['height'],
      //soilMoistureAlertThreshold: json['soilMoistureAlertThreshold'],
      //soilMoistureActionThreshold: json['soilMoistureActionThreshold'],
      //temperatureAlertThreshold: json['temperatureAlertThreshold'],
      //temperatureActionThreshold: json['temperatureActionThreshold'],
    );
  }
}
