import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_project/config.dart';
import 'package:my_new_project/services/session.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<dynamic> users = [];
  List<dynamic> sensors = [];
  bool isLoadingUsers = true;
  bool isLoadingSensors = true;

  final TextEditingController macAddressController = TextEditingController();
  final TextEditingController sensorCodeController = TextEditingController();
  final TextEditingController readingPeriodController = TextEditingController();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Add a key for the form
  final RegExp macAddressRegExp =
      RegExp(r"^([0-9A-Fa-f]{2}[-]){5}([0-9A-Fa-f]{2})$");
  bool isUsersExpanded = false;
  bool isSensorsExpanded = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchSensors();
  }

  Future<void> fetchUsers() async {
    try {
      final token = await SessionService.getToken();
      final response = await http.get(
        Uri.parse('http://${Config.apiURL}/api/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          users = jsonDecode(response.body);
          isLoadingUsers = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() {
        isLoadingUsers = false;
      });
      print('Error fetching users: $e');
    }
  }

  Future<void> fetchSensors() async {
    try {
      final token = await SessionService.getToken();
      final response = await http.get(
        Uri.parse('http://${Config.apiURL}/api/sensors'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          sensors = jsonDecode(response.body);
          isLoadingSensors = false;
        });
      } else {
        throw Exception('Failed to load sensors');
      }
    } catch (e) {
      setState(() {
        isLoadingSensors = false;
      });
      print('Error fetching sensors: $e');
    }
  }

  Future<void> createSensor() async {
    try {
      final token = await SessionService.getToken();
      final response = await http.post(
        Uri.parse('http://${Config.apiURL}/api/sensors'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'macAddress': macAddressController.text,
          'sensorCode': sensorCodeController.text,
          'currentState': 'NORMAL',
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSensors();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sensor created successfully!')),
        );
        macAddressController.clear();
        sensorCodeController.clear();
        readingPeriodController.clear();
      } else {
        throw Exception('Failed to create sensor');
      }
    } catch (e) {
      print('Error creating sensor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isUsersExpanded = !isUsersExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Users',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Icon(isUsersExpanded
                        ? Icons.expand_less
                        : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (isUsersExpanded)
              isLoadingUsers
                  ? CircularProgressIndicator()
                  : ExpansionPanelList(
                      expansionCallback: (int index, bool isExpanded) {
                        setState(() {
                          users[index]['isExpanded'] =
                              !(users[index]['isExpanded'] ?? false);
                        });
                      },
                      children: users.map<ExpansionPanel>((user) {
                        return ExpansionPanel(
                          headerBuilder: (context, isExpanded) {
                            return ListTile(
                              title: Text(user['username']),
                            );
                          },
                          body: Column(
                            children: [
                              ListTile(
                                title: Text('Full Name:'),
                                subtitle: Text(
                                    '${user['firstName']} ${user['lastName']}'),
                              ),
                              ListTile(
                                title: Text('Roles:'),
                                subtitle: Text('${user['roles'].join(', ')}'),
                              ),
                              ListTile(
                                title: Text('ID:'),
                                subtitle: Text('${user['id']}'),
                              ),
                            ],
                          ),
                          isExpanded: user['isExpanded'] ?? false,
                        );
                      }).toList(),
                    ),

            GestureDetector(
              onTap: () {
                setState(() {
                  isSensorsExpanded = !isSensorsExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sensors',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Icon(isSensorsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (isSensorsExpanded)
              isLoadingSensors
                  ? CircularProgressIndicator()
                  : ExpansionPanelList(
                      expansionCallback: (int index, bool isExpanded) {
                        setState(() {
                          sensors[index]['isExpanded'] =
                              !(sensors[index]['isExpanded'] ?? false);
                        });
                      },
                      children: sensors.map<ExpansionPanel>((sensor) {
                        return ExpansionPanel(
                          headerBuilder: (context, isExpanded) {
                            return ListTile(
                              title: Text(sensor['sensorName']),
                            );
                          },
                          body: Column(
                            children: [
                              ListTile(
                                title: Text('Sensor ID:'),
                                subtitle: Text('${sensor['sensorId']}'),
                              ),
                              ListTile(
                                title: Text('Owner ID:'),
                                subtitle: Text('${sensor['ownerId']}'),
                              ),
                              ListTile(
                                title: Text('State:'),
                                subtitle: Text('${sensor['currentState']}'),
                              ),
                              ListTile(
                                title: Text('Reading Period:'),
                                subtitle: Text('${sensor['readingPeriod']} ms'),
                              ),
                            ],
                          ),
                          isExpanded: sensor['isExpanded'] ?? false,
                        );
                      }).toList(),
                    ),

            // Create Sensor Form
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Create Sensor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: macAddressController,
                decoration: InputDecoration(labelText: 'MAC Address'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: sensorCodeController,
                decoration: InputDecoration(labelText: 'Sensor Code'),
              ),
            ),

            ElevatedButton(
              onPressed: createSensor,
              child: Text('Create Sensor'),
            ),
          ],
        ),
      ),
    );
  }
}
