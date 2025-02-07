import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_new_project/api/sensordetails.dart';
import 'package:my_new_project/config.dart';
import 'package:my_new_project/services/session.dart';
import 'package:http/http.dart' as http;

class FormScreen extends StatefulWidget {
  final int sensorId;

  FormScreen({required this.sensorId});

  @override
  State<StatefulWidget> createState() {
    return FormScreenState();
  }
}

class FormScreenState extends State<FormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _temperatureAlertController =
      TextEditingController();
  final TextEditingController _temperatureActionController =
      TextEditingController();
  final TextEditingController _soilMoistureController = TextEditingController();
  final TextEditingController _readingPeriodController =
      TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _soilMoistureActionController =
      TextEditingController();
  String _selectedState = 'NORMAL';
  final SensorApiService _apiService = SensorApiService();
  String sensorName = "";

  Future<void> _submitForm(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final String apiUrl =
          'http://${Config.apiURL}/api/sensors/${widget.sensorId}$endpoint';
      print("Sending request to $apiUrl with body: $body");

      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.putUrl(Uri.parse(apiUrl));

      request.headers.set('content-type', 'application/json');
      request.headers.set('Authorization', 'Bearer $token');
      request.add(utf8.encode(json.encode(body)));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Success! Data sent to $endpoint.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Success! wysłano dane')),
        );
      } else {
        print(
            "Failed to send data to $endpoint. Status code: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to send data. Status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error while sending data to $endpoint: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSensorDetails();
  }

  void _fetchSensorDetails() async {
    String? token = await SessionService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Authentication token not found, please log in again.')),
      );
      return;
    }

    SensorDetailDto? sensorDetails =
        await _apiService.fetchSensorDetails(widget.sensorId, token);
    if (sensorDetails != null) {
      setState(() {
        sensorName = sensorDetails.sensorName;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch sensor details')),
      );
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String endpoint,
    required String bodyKey,
    required String successMessage,
    bool isNumeric = false,
    int? minValue,
    int? maxValue,
    //bool isNumeric = false,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText:
                "$label ${minValue != null && maxValue != null ? '($minValue - $maxValue)' : ''}",
          ),
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Wprowadź wartość';
            }
            if (isNumeric) {
              final numValue = int.tryParse(value);
              if (numValue == null) {
                return 'Wporwadź poprawną liczbę';
              }
              if ((minValue != null && numValue < minValue) ||
                  (maxValue != null && numValue > maxValue)) {
                return 'Wartość musi być pomiędzy $minValue i $maxValue';
              }
            }
            return null;
          },
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Wprowadź wartość 123')),
              );
              return;
            }

            print(
                "Temperature Action Controller Value: ${_temperatureActionController.text}");
            print(
                "Soil Moisture Action Controller Value: ${_soilMoistureActionController.text}");

            final numValue = isNumeric
                ? int.tryParse(controller.text)
                : null; // Ensures numValue is null if not numeric

            if (isNumeric) {
              if (numValue == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Wprowadź poprawną liczbę')),
                );
                return;
              }

              if (numValue < minValue! || numValue > maxValue!) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Wartość musi być pomiędzy $minValue i $maxValue')),
                );
                return;
              }

              final processedValue =
                  (endpoint == '/reading_period') ? numValue * 60000 : numValue;
              print("Submitting data: $processedValue for $label");

              _submitForm(endpoint, {bodyKey: processedValue});
            } else {
              print("Submitting data: ${controller.text} for $label");
              _submitForm(endpoint, {bodyKey: controller.text});
            }
            controller.clear();
          },
          child: Text(successMessage),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Konfiguracja sensora'),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // Endpoint dla nazwy urządzenia
              if (sensorName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Nazwa urządzenia: $sensorName',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              _buildTextFormField(
                controller: _nameController,
                label: 'Podaj nową nazwę urządzenia',
                endpoint: '/name',
                bodyKey: 'sensorName',
                successMessage: 'Zatwierdź',
              ),
              // Endpoint dla progu alarmowego temperatury
              _buildTextFormField(
                controller: _temperatureAlertController,
                label: 'Podaj próg alarmowy temperatury (°C)',
                endpoint: '/temperature_alert_threshold',
                bodyKey: 'threshold',
                successMessage: 'Zatwierdź',
                isNumeric: true,
                minValue: -100,
                maxValue: 100,
              ),
              // Endpoint dla progu akcji temperatury
              _buildTextFormField(
                controller: _temperatureActionController,
                label: 'Podaj próg akcji temperatury',
                endpoint: '/temperature_action_threshold',
                bodyKey: 'threshold',
                successMessage: 'Zatwierdź',
                isNumeric: true,
                minValue: -1000,
                maxValue: 1000,
              ),
              // Endpoint dla progu alarmowego wilgotności gleby
              _buildTextFormField(
                controller: _soilMoistureController,
                label: 'Podaj próg alarmowy wilgotności gleby (%)',
                endpoint: '/soil_moisture_alert_threshold',
                bodyKey: 'threshold',
                successMessage: 'Zatwierdź',
                isNumeric: true,
                minValue: 0,
                maxValue: 100,
              ),
              // Dropdown dla stanu urządzenia

              _buildTextFormField(
                controller: _soilMoistureActionController,
                label: 'Podaj próg akcji wilgotności gleby',
                endpoint: '/soil_moisture_action_threshold',
                bodyKey: 'threshold',
                successMessage: 'Zatwierdź',
                isNumeric: true,
                minValue: -1000,
                maxValue: 1000,
              ),

              // Endpoint dla okresu odczytu
              _buildTextFormField(
                controller: _readingPeriodController,
                label: 'Podaj okres odczytu (min)',
                endpoint: '/reading_period',
                bodyKey: 'readingPeriod',
                successMessage: 'Zatwierdź',
                isNumeric: true,
                minValue: 1, // Minimum 1 minute
                maxValue: 1440, // Maximum 1440 minutes (24 hours)
              ),
              // Endpoint dla wysokości czujnika
              _buildTextFormField(
                controller: _heightController,
                label: 'Podaj wysokość nad poziomem morza (m)',
                endpoint: '/height',
                bodyKey: 'height',
                successMessage: 'Zatwierdź',
                isNumeric: true,
                minValue: -434, // Lowest land point (Dead Sea)
                maxValue: 8848, // Mount Everest
              ),
            ],
          ),
        ),
      ),
    );
  }
}
