import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedService {
  static Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  static Future<void> removeToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
  }

  static Future<void> saveUsername(String username) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('username', username);
  }

  static Future<void> saveLoginDetails(
      String token, String username, int userID) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('username', username);
    await prefs.setInt('userID', userID);
  }

  static Future<String?> getUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString('username');
  }

  static Future<void> removeUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove('username');
  }

  static Future<void> saveUserID(int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt('userID', id);
  }

  static Future<int?> getUserID() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getInt('userID');
  }

  static Future<void> removeUserID() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove('userID');
  }

  static Future<void> saveRoles(List<String> roles) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRoles', jsonEncode(roles));
  }

  static Future<void> saveFullName(String fullName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', fullName);
  }

  static Future<List<String>?> getRoles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? rolesJson = prefs.getString('userRoles');
    if (rolesJson != null) {
      return List<String>.from(jsonDecode(rolesJson));
    }
    return null;
  }

  static Future<void> removeRoles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRoles');
  }

  static Future<String?> getFullName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('fullName');
  }

  static Future<Map<String, dynamic>?> loginDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');
    String? username = prefs.getString('username');
    String? userID = prefs.getString('userID');

    if (token == null || username == null || userID == null) {
      return null;
    }

    return {
      'token': token,
      'username': username,
      'userID': userID,
    };
  }
}
