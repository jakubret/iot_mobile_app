import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_project/config.dart';
//import 'package:my_new_project/pages/home_page_temperature.dart';
import '../services/session.dart';
import 'package:my_new_project/pages/nowa_page.dart';

class DevicesList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DevicesListState();
  }
}

class DevicesListState extends State<DevicesList> {
  List<Map<String, dynamic>> _devices = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    try {
      final userId = await SessionService.getUserID();
      final token = await SessionService.getToken();
      if (userId == null || token == null) {
        setState(() {
          errorMessage = 'User ID or Token not found. Please log in again.';
        });
        return;
      }

      final String apiUrl = 'http://${Config.apiURL}/api/users/$userId/sensors';
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        setState(() {
          _devices =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception(
            'Failed to load devices. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching devices: $e';
      });
    }
  }

  Future<void> deleteDevice(int userId, int sensorId, String token) async {
    final String apiUrl =
        'http://${Config.apiURL}/api/users/$userId/sensors/$sensorId';
    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device deleted successfully')),
        );
        _fetchDevices();
      } else {
        throw Exception(
            'Failed to delete device. Status code: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting device: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Text('Error: $errorMessage'))
          : _devices.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(device['sensorName'] ?? 'Unnamed Device'),
                        subtitle: Text(
                            'State: ${device['currentState'] ?? 'Unknown'}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePageTemperature(
                                topic: device['sensorName'] ?? 'Unnamed Device',
                                sensorId: device['sensorId'],
                              ),
                            ),
                          );
                        },
                        onLongPress: () async {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Device'),
                              content: Text(
                                  'Are you sure you want to delete this device?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();

                                    final int? userId =
                                        await SessionService.getUserID();
                                    final String? token =
                                        await SessionService.getToken();

                                    if (userId == null || token == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed to retrieve user details or authorization token')),
                                      );
                                      return;
                                    }

                                    deleteDevice(
                                        userId, device['sensorId'], token);
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
