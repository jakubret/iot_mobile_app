import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:my_new_project/api/jwt_utils.dart';
import 'package:my_new_project/pages/devices_list.dart';

import '../services/shared.dart';
import '../services/session.dart';

void main() => runApp(const MyAppp());

class MyAppp extends StatelessWidget {
  const MyAppp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  final something = FlutterBluePlus.instance;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};
  final Map<Guid, String> readValues1 = <Guid, String>{};
  final Map<Guid, String> decodedReadValues = <Guid, String>{};

  @override
  MyHomePageState createState() => MyHomePageState();
}

class ServiceInfo {
  BluetoothService service;
  String label;

  ServiceInfo({required this.service, this.label = ''});

  void updateLabel() {
    if (service.uuid.toString().toUpperCase() == "FF00") {
      label = "Special Configuration Service";
    }
  }
}

class MyHomePageState extends State<MyHomePage> {
  final _writeController = TextEditingController();
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];
  List<ServiceInfo> _serviceInfos = [];

  bool _needsConfiguration = false;
  String userName = "";
  String userEmail = "";
  int userID = 0;

  var counter = 0;

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        if (device.name.contains("ESP")) {
          /// nazwa urzadzenia

          widget.devicesList.add(device);
        }
      });
    }
    print('Adding device to list: ${device.platformName} [${device.remoteId}]');
  }

///////
  ///
  ///

  void connectToDevice(BluetoothDevice device) async {
    try {
      FlutterBluePlus.stopScan();
      await device.connect(autoConnect: false);
      var services = await device.discoverServices();
      setState(() {
        _connectedDevice = device;
        _services = services;
      });
      print("Connection successful to ${device.platformName}");
    } on FlutterBluePlusException catch (e) {
      print('FlutterBluePlusException caught: ${e.toString()}');
      if (e.code == 'already_connected') {
        try {
          var services = await device.discoverServices();
          setState(() {
            _connectedDevice = device;
            _services = services;
          });
        } catch (e) {
          print(
              'Error discovering services after already connected: ${e.toString()}');
        }
      } else if (e.code == 'connection_error') {
        print('Attempting to reconnect...');
        await device.disconnect();
        await Future.delayed(Duration(seconds: 1));
        connectToDevice(device);
      }
    } catch (e) {
      print(
          'General exception caught during Bluetooth connection: ${e.toString()}');
    }
  }

  ///
  ///
  @override
  void initState() {
    super.initState();
    SharedService.loginDetails().then((value) {
      setState(() {
        userName = "test";
        userID = value!.data.userID;
      });
    });

    initBluetooth();
  }

  Future<void> initBluetooth() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;
      for (BluetoothDevice device in devices) {
        print('Connected device: ${device.name} [${device.id}]');
      }
      FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        for (ScanResult result in results) {
          print(
              'Discovered device: ${result.device.platformName} [${result.device.remoteId}], RSSI: ${result.rssi}');
          _addDeviceTolist(result.device);
        }
      });

      await FlutterBluePlus.startScan();
    } catch (e) {
      print('Error initializing Bluetooth: $e');
    }
  }

  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  ListView _buildListViewOfDevices() {
    List<Widget> containers = <Widget>[];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        SizedBox(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              TextButton(
                child: const Text('Connect',
                    style:
                        TextStyle(color: Color.fromARGB(255, 211, 218, 227))),
                onPressed: () => connectToDevice(device),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];

    if (characteristic.uuid.toString() == "ff05") {
      print("Znaleziono charakterystyke 2A00!!!!!!!!!!");
      if (characteristic.properties.read) {
        buttons.add(
          ButtonTheme(
            minWidth: 10,
            height: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                child: const Text('ZAPISZ URZĄDZENIE',
                    style:
                        TextStyle(color: Color.fromARGB(255, 225, 233, 237))),
                onPressed: () async {
                  var sub = characteristic.value.listen((value) {
                    setState(() {
                      widget.readValues[characteristic.uuid] = value;
                    });
                  });
                  await characteristic.read();
                  sub.cancel();
                  print("ODCZYTANIE WARTOSCI : " +
                      widget.readValues[characteristic.uuid].toString());

                  var sub1 = characteristic.value.listen((value) {
                    setState(() {
                      widget.readValues[characteristic.uuid] = value;
                    });
                  });
                  await characteristic.read();
                  sub.cancel();

                  var mac = widget.readValues[characteristic.uuid];

                  var macString = mac!
                      .map((e) => e.toRadixString(16).padLeft(2, '0'))
                      .join(':');

                  String macString_original = macString.toUpperCase();
                  print("MAC ODCZYTANY: " + macString_original);

                  final decodedToken = await JwtUtils.decodeJwtPayload();
                  print(decodedToken!.payload);
                  print("username to jest : " + JwtUtils.username);
                  print("userid to jest : " + JwtUtils.username);

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                            "Pomyślnie dodano urządzenie do twojego konta"),
                        actions: [
                          TextButton(
                            child: Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      }
    }

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              child: const Text('READ',
                  style: TextStyle(color: Color.fromARGB(255, 225, 233, 237))),
              onPressed: () async {
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;

                    String decodedString =
                        value.map((e) => String.fromCharCode(e)).join();

                    widget.decodedReadValues[characteristic.uuid] =
                        decodedString;

                    //       print("RAW: " + value.toString());
                    //      print("DECODED STRING: $decodedString");

                    //        print("RAW: " + value.toString());
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }
    // kontroler do wprowadzania ssid
    TextEditingController ssidController = TextEditingController();
// Kontroler dla wprowadzania hasła
    TextEditingController passwordController = TextEditingController();

    if (characteristic.uuid.toString() == "ff01") {
      if (characteristic.properties.write) {
        buttons.add(
          ButtonTheme(
            minWidth: 10,
            height: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                child: const Text(
                  'WRITE SSID',
                  style: TextStyle(color: Color.fromARGB(255, 90, 134, 210)),
                ),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Write SSID"),
                        content: TextField(
                          controller: ssidController,
                          decoration:
                              const InputDecoration(labelText: 'Enter SSID'),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text("Send"),
                            onPressed: () async {
                              String ssid = ssidController.text;
                              await characteristic.write(utf8.encode(ssid));

                              setState(() {
                                widget.decodedReadValues[characteristic.uuid] =
                                    ssid;
                              });

                              Navigator.pop(context);
                              print("SSID sent: $ssid");
                            },
                          ),
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      }
    }

    if (characteristic.uuid.toString() == "ff02") {
      if (characteristic.properties.write) {
        buttons.add(
          ButtonTheme(
            minWidth: 10,
            height: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                child: const Text('WRITE PASSWORD',
                    style: TextStyle(color: Color.fromARGB(255, 90, 134, 210))),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Write Password"),
                        content: TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                              labelText: 'Enter Password'),
                          obscureText: true,
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text("Send"),
                            onPressed: () {
                              String ssid = passwordController.text;
                              characteristic
                                  .write(utf8.encode(passwordController.text));
                              Navigator.pop(context);
                              setState(() {
                                widget.decodedReadValues[characteristic.uuid] =
                                    ssid;
                              });

                              print(
                                  "Password sent: ${passwordController.text}");
                            },
                          ),
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      }
    }
    if (characteristic.uuid.toString() == "ff03") {
      if (characteristic.properties.write) {
        buttons.add(
          ButtonTheme(
            minWidth: 10,
            height: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                child: const Text('WRITE USERID',
                    style: TextStyle(color: Color.fromARGB(255, 90, 134, 210))),
                onPressed: () async {
                  int? userId = await SessionService.getUserID();
                  if (userId != null) {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Write UserID"),
                          content: Text("UserID: will be sent"),
                          actions: <Widget>[
                            TextButton(
                              child: const Text("Send"),
                              onPressed: () {
                                characteristic
                                    .write(utf8.encode(userId.toString()));
                                Navigator.pop(context);
                                print("UserID sent: $userId");
                              },
                            ),
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    print("UserID is null");
                  }
                },
              ),
            ),
          ),
        );
      }
    }

    if (characteristic.uuid.toString() == "ff04") {
      if (characteristic.properties.write) {
        buttons.add(
          ButtonTheme(
            minWidth: 10,
            height: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                child: const Text('CONFIRM',
                    style: TextStyle(color: Color.fromARGB(255, 90, 134, 210))),
                onPressed: () async {
                  // Poniższa wartość to UINT8 '1'
                  Uint8List valueToSend = Uint8List(1);
                  valueToSend[0] = 1;

                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm Action"),
                        content:
                            Text("Are you sure you want to send confirmation?"),
                        actions: <Widget>[
                          TextButton(
                            child: const Text("Send"),
                            onPressed: () {
                              characteristic.write(valueToSend);
                              Navigator.pop(context);
                              print("Confirmation value '1' sent as UINT8.");
                            },
                          ),
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      }
    }

    String _lastNotificationMessage = "";

    void showLatestNotificationMessage(bool navigate) {
      if (!mounted || _lastNotificationMessage.isEmpty) return;

      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissal by tapping outside
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Latest Notification"),
            content: Text(_lastNotificationMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (navigate) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => DevicesList()),
                    );
                  }
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }

    void handleNotification(Uint8List value) {
      if (value.length != 2) return; // Ensure the value is valid

      String message = '';
      bool navigateToDevicesList = false;

      // Determine the appropriate message based on the notification value
      if (value[0] == 0 && value[1] == 0) {
        message = "WiFi setup started. Please wait.";
      } else if (value[0] == 0 && value[1] == 1) {
        message = "WiFi connected successfully!";
      } else if (value[0] == 1 && value[1] == 0) {
        message = "MQTT connection failed.";
      } else if (value[0] == 1 && value[1] == 1) {
        message = "MQTT connection successful.";
      } else if (value[0] == 2 && value[1] == 0) {
        message = "Configuration failed. Please retry.";
      } else if (value[0] == 2 && value[1] == 1) {
        message = "Configuration successful. Navigating to devices list.";
        navigateToDevicesList = true;
      }

      if (message.isNotEmpty) {
        print(message);
        setState(() {
          _lastNotificationMessage = message;
        });

        showLatestNotificationMessage(navigateToDevicesList);
      }
    }

    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('NOTIFY',
                  style: TextStyle(color: Color.fromARGB(255, 185, 208, 227))),
              onPressed: () async {
                if (!characteristic.isNotifying) {
                  await characteristic.setNotifyValue(true);
                  characteristic.value.listen((value) {
                    // Convert List<int> to Uint8List
                    Uint8List uint8Value = Uint8List.fromList(value);

                    // Log the received value
                    print('Received NOTIFY with value: $uint8Value');
                    print(
                        'Received NOTIFY with value (HEX): ${uint8Value.map((v) => v.toRadixString(16).padLeft(2, '0')).join(':')}');

                    handleNotification(uint8Value);
                  });
                }
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  ListView _buildConnectDeviceView() {
    List<Widget> containers = <Widget>[];

    for (BluetoothService service in _services) {
      // Only process the service with UUID "00ff"
      if (service.uuid.toString().toLowerCase() == '00ff') {
        List<Widget> characteristicsWidget = <Widget>[];

        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          String characteristicLabel =
              _getCharacteristicLabel(characteristic.uuid);

          characteristicsWidget.add(
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        characteristicLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      ..._buildReadWriteNotifyButton(characteristic),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        'Value: ${widget.decodedReadValues[characteristic.uuid] ?? " "}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              ),
            ),
          );
        }

        containers.add(
          ExpansionTile(
            title: Text(
              ' ${_getServiceLabel(service.uuid)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: characteristicsWidget,
          ),
        );
      }
    }

    return ListView(
      children: containers,
    );
  }

  String _getCharacteristicLabel(Guid uuid) {
    // Replace UUIDs with human-readable labels
    switch (uuid.toString().toLowerCase()) {
      case '2a00':
        return 'Nazwa płytki';
      case 'ff01':
        return 'WIFI SSID';
      case 'ff02':
        return 'HASŁO WIFI';
      case 'ff03':
        return 'USERID';
      case 'ff04':
        return 'ZATWIERDŹ';
      case 'ff05':
        return 'KOMUNIKATY';
      default:
        return ' ${uuid.toString()}';
    }
  }

  String _getServiceLabel(Guid uuid) {
    switch (uuid.toString().toLowerCase()) {
      case '00001800-0000-1000-8000-00805f9b34fb':
        return 'Generic Access';
      case '1800':
        return 'Generic Attribute';
      case '00ff':
        return 'KONFIGURACJA PŁYTKI';
      default:
        return ' ${uuid.toString()}';
    }
  }

  String _getValue(Guid serviceUuid, Guid characteristicUuid) {
    if (serviceUuid.toString() == "1800") {
      if (widget.readValues1.containsKey(characteristicUuid)) {
        return widget.readValues1[characteristicUuid]!;
      }
    } else {
      if (widget.readValues.containsKey(characteristicUuid)) {
        final rawValue = widget.readValues[characteristicUuid];
        if (rawValue != null && rawValue.isNotEmpty) {
          try {
            return rawValue.map((e) => String.fromCharCode(e)).join();
          } catch (_) {
            return rawValue.toString();
          }
        }
      }
    }
    return "N/A";
  }

  ListView _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) {
    print("witaj: " + userName);

    return Scaffold(
      body: _buildView(),
    );
  }
}

extension on Map<String, dynamic> {
  get data => null;
}
