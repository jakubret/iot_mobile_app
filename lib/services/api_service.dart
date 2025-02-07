import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_new_project/services/session.dart';

import '../../config.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';
import '../models/register_response_model.dart';

class APIService {
  static var client = http.Client();

  static Future<RegisterResponseModel> register(
    RegisterRequestModel model,
  ) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };

    var url = Uri.http(
      Config.apiURL,
      Config.registerAPI,
    );

    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Response body: ${response.body}'); // Logowanie odpowiedzi
      final registerResponse = registerResponseJson(response.body);
      await SessionService.saveSessionData(registerResponse);
      return registerResponse;
    } else {
      print('Error: ${response.body}');
      throw Exception(
          'Failed to register. Status code: ${response.statusCode}');
    }
  }
}
