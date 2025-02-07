import 'dart:convert';

RegisterResponseModel registerResponseJson(String str) =>
    RegisterResponseModel.fromJson(json.decode(str));

class RegisterResponseModel {
  late final Data data;

  RegisterResponseModel({required this.data});

  RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    data = Data.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
    };
  }
}

class Data {
  late final int id;
  late final String username;
  late final String firstName;
  late final String lastName;
  late final List<String> roles;

  Data({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.roles,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    roles = List<String>.from(json['roles'].map((x) => x));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'roles': List<dynamic>.from(roles.map((x) => x)),
    };
  }
}
