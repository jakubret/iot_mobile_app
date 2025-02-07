import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:my_new_project/services/session.dart';

class JwtUtils {
  static String username = "";

  static Future<JWT?> decodeJwtPayload() async {
    var var_token = await SessionService.getToken() as String;
    try {
      final jwt = JWT.decode(var_token);
      var payload = jwt.payload;
      username = payload['sub'];

      return jwt;
    } catch (e) {
      print('Error decoding token jwt: $e');
      return null;
    }
  }
}
