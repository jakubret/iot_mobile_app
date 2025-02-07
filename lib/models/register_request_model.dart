class RegisterRequestModel {
  RegisterRequestModel({
    this.username,
    this.password,
    this.firstName,
    this.lastName,
  });
  late final String? username;
  late final String? password;
  late final String? firstName;
  late final String? lastName;

  RegisterRequestModel.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    password = json['password'];
    firstName = json['firstname'];
    lastName = json['lastname'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['username'] = username;
    _data['password'] = password;
    _data['firstName'] = firstName;
    _data['lastName'] = lastName;
    return _data;
  }
}
