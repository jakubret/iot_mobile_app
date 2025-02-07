import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_new_project/config.dart';
import 'package:my_new_project/services/session.dart';
import 'package:http/http.dart' as http;

class AlertsScreen extends StatefulWidget {
  final int userId;

  AlertsScreen({required this.userId});

  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class AlertService {
  final _alertController = StreamController<bool>.broadcast();

  Stream<bool> get alertStream => _alertController.stream;

  void updateAlerts(bool hasAlerts) {
    _alertController.sink.add(hasAlerts);
  }

  void dispose() {
    _alertController.close();
  }
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final String apiUrl =
          'http://${Config.apiURL}/api/users/${widget.userId}/alerts?checked=false';
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _alerts = data.map((alert) => alert as Map<String, dynamic>).toList();
          SessionService.setAlertStatus(_alerts.isNotEmpty);
        });
      } else {
        throw Exception(
            'Failed to load alerts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        SessionService.setAlertStatus(false);
      });
    }
  }

  Future<void> _markAlertAsChecked(int alertId) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final String apiUrl =
          'http://${Config.apiURL}/api/users/${widget.userId}/alerts/$alertId';
      final response = await http.put(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alert marked as checked!')),
        );
        _fetchAlerts(); // Refresh the alerts list
      } else {
        throw Exception(
            'Failed to update alert. Status code: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts'),
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Text('Error: $errorMessage'))
          : _alerts.isEmpty
              ? Center(child: Text('No alerts to display.'))
              : ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Alert Type: ${alert['alertType']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Value: ${alert['value']}'),
                            Text('Timestamp: ${alert['timestamp']}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _markAlertAsChecked(alert['id']),
                          child: Text('Mark as Checked'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
