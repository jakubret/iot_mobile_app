import "dart:convert";
import "dart:ffi";

import "package:my_new_project/models/register_response_model.dart";
import "package:my_new_project/services/shared.dart";

class SessionService {
  static Future<void> saveSession(
    String token,
    String username,
    int userid,
    Set<String>? roles,
  ) async {
    await SharedService.saveToken(token);
    await SharedService.saveUsername(username);
    await SharedService.saveUserID(userid);
    await SharedService.saveLoginDetails(token, username, userid);
    if (roles != null) {
      await SharedService.saveRoles(
          roles.toList()); // Saving roles as a JSON string
    }
  }

  static Future<void> clearSession() async {
    await SharedService.removeToken();
    await SharedService.removeUsername();
    await SharedService.removeRoles();
  }

  static Future<String?> getToken() async {
    return await SharedService.getToken();
  }

  static Future<String?> getUsername() async {
    return await SharedService.getUsername();
  }

  static Future<int?> getUserID() async {
    return await SharedService.getUserID();
  }

  static bool hasPendingAlerts = false; // Track alert status

  static void setAlertStatus(bool status) async {
    hasPendingAlerts = status;
  }

  static Future<Map<String, dynamic>?> getSessionDetails() async {
    String? token = await SharedService.getToken();
    String? username = await SharedService.getUsername();
    int? userID = await SharedService.getUserID();
    List<String>? roles = await SharedService.getRoles();

    if (token == null || username == null || userID == null) {
      return null;
    }

    return {
      'token': token,
      'username': username,
      'userID': userID,
      'userRoles': roles ?? [],
    };
  }

  static Future<void> saveSessionData(
      RegisterResponseModel registerResponse) async {
    await SharedService.saveUserID(registerResponse.data.id);
    await SharedService.saveUsername(registerResponse.data.username);
    await SharedService.saveFullName(
      '${registerResponse.data.firstName} ${registerResponse.data.lastName}',
    );
    if (registerResponse.data.roles != null) {
      await SharedService.saveRoles(registerResponse.data.roles);
    }
  }

  static Future<List<String>?> getRoles() async {
    String? rolesJson =
        (await SharedService.getRoles()) as String?; // Pobieranie ról z pamięci
    if (rolesJson != null) {
      return List<String>.from(
          jsonDecode(rolesJson)); // Dekodowanie JSON na listę
    }
    return null;
  }
}
