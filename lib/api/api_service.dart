//import 'dart:convert';
//import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:my_new_project/config.dart';
import 'package:my_new_project/models/login_request_model.dart';
import 'package:my_new_project/models/login_response_model.dart';
import 'package:my_new_project/services/session.dart';

class ApiService {
  String baseUrl = Config.apiURL;
  static var client = http.Client();

  Future<LoginResponseModel?> login(LoginRequestModel requestModel) async {
    var url = Uri.http(
      Config.apiURL,
      Config.loginAPI,
    );

    print(url);
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };

    final Body = jsonEncode({
      'username': requestModel.username,
      'password': requestModel.password,
    });

    print(Body);

    try {
      //final response = await http.post(url, body: body);
      final response = await client.post(
        url,
        headers: requestHeaders,
        body: Body,
      );
      final responseBody = jsonDecode(response.body);
      print(response.body);
      print(response.statusCode);
      print(response.headers);
      print(responseBody['userRoles']);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        final String? token = responseBody['jwt'];
        final String username = responseBody['username'];
        final int? userid = responseBody['userId'];
        final Set<String> userRoles =
            (responseBody['userRoles'] as List<dynamic>).cast<String>().toSet();
        if (token == null) {
          throw Exception('JWT token is null');
        }
        if (userid == null) {
          throw Exception('UserID is null');
        }

        await SessionService.saveSession(token, username, userid, userRoles);
        return LoginResponseModel.fromJson(jsonDecode(response.body));
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorResponse = jsonDecode(response.body);
        final errorMessage =
            errorResponse['message'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      } else {
        final Map<String, dynamic> errorResponse = jsonDecode(response.body);
        throw Exception(errorResponse['message']);
      }
    } catch (e) {
      throw Exception('Error logging in: ${e.toString()}');
    }
  }
}
