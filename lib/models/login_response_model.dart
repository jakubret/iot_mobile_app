class LoginResponseModel {
  String? token;
  String? username;
  int? userID;
  Set<String>? userRoles;

  LoginResponseModel({
    required this.token,
    this.username,
    this.userID,
    this.userRoles,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['jwt'],
      username: json['username'],
      userID: json['id'],
      userRoles: (json['userRoles'] as List<dynamic>?)?.cast<String>().toSet(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jwt': token,
      'username': username,
      'id': userID,
      'userRoles': userRoles?.toList(),
    };
  }
}
