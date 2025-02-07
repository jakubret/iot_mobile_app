import 'package:my_new_project/models/register_response_model.dart';
import 'package:my_new_project/pages/admin_page.dart';
import 'package:my_new_project/pages/alert_page.dart';
import 'package:my_new_project/pages/configuration.dart';
import 'package:my_new_project/pages/main.dart';
import 'package:my_new_project/pages/nowa_page.dart';
import 'package:my_new_project/pages/start_with_logo.dart';
import 'package:flutter/material.dart';
import 'package:my_new_project/services/shared.dart';

import '../services/api_service.dart';
import 'devices_list.dart';
import '../services/session.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentPageIndex;
  final List<Widget> _pages = [];
  String userName = "";
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    _currentPageIndex = 0;
    _initializePages();
    _loadUserName();
  }

  Future<void> _initializePages() async {
    // Zainicjalizuj strony standardowe
    setState(() {
      _pages.add(WelcomePage());
      _pages.add(DevicesList());
      _pages.add(MyHomePage());
      //_pages.add(FormScreen(sensorId: 10));
      //_pages.add(HomePageTemperature(topic: "temperature", sensorId: 10));
      //_pages.add(AlertsScreen(userId: 1));
    });

    // Pobierz role użytkownika i sprawdź, czy ma dostęp do strony admina
    final roles = await SharedService.getRoles();
    if (roles != null && roles.contains("ADMIN")) {
      setState(() {
        _pages.add(AdminPage());
      });
    }
  }

  Future<void> _loadUserName() async {
    final username = await SessionService.getUsername();
    if (username != null) {
      setState(() {
        userName = username;
      });
    }
  }

  Widget _getCurrentPage() => _pages[_currentPageIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Witaj, $userName w greenHouse"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex,
        onTap: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Strona startowa",
            backgroundColor: Color.fromARGB(255, 96, 208, 90),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: "Urządzenia",
            backgroundColor: Color.fromARGB(255, 96, 208, 90),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: "Bluetooth",
            backgroundColor: Color.fromARGB(255, 96, 208, 90),
          ),
          if (_pages.any((page) => page is AdminPage))
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: "ADMIN",
              backgroundColor: Color.fromARGB(255, 90, 184, 208),
            ),
        ],
      ),
    );
  }
}
