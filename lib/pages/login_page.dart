import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:my_new_project/api/api_service.dart';
import 'package:my_new_project/pages/home_page.dart';
import 'package:snippet_coder_utils/FormHelper.dart';
import 'package:snippet_coder_utils/ProgressHUD.dart';
import 'package:snippet_coder_utils/hex_color.dart';

import '../services/api_service.dart';
import '../config.dart';
import '../models/login_request_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

final ApiService apiService = ApiService();

void _showSnackBar(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
  ));
}

Future<void> login(
    String username, String password, BuildContext context) async {
  final requestModel = LoginRequestModel(
    username: username,
    password: password,
  );

  try {
    final response = await apiService.login(requestModel);
    if (response != null) {
      _showSnackBar('Zalogowano pomyślnie.', context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      _showSnackBar('Nieprawidłowe dane logowania.', context);
    }
  } catch (e) {
    print(e);
    _showSnackBar('Błąd połączenia: $e', context);
  }
}

class _LoginPageState extends State<LoginPage> {
  bool isApiCallProcess = false;
  bool hidePassword = true;
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  late final String userName;
  late final String password;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: HexColor("#1f9c44"),
        body: ProgressHUD(
          child: Form(
            key: globalFormKey,
            child: _loginUI(context),
          ),
          inAsyncCall: isApiCallProcess,
          opacity: 0.3,
          key: UniqueKey(),
        ),
      ),
    );
  }

  Widget _loginUI(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 5.2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(100),
                bottomLeft: Radius.circular(100),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    "assets/images/greenhouse1.png",
                    fit: BoxFit.contain,
                    width: 120,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 30, top: 50),
            child: Text(
              "Zaloguj się",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FormHelper.inputFieldWidget(
              context,
              prefixIcon: Icon(Icons.person),
              "Username",
              "Username",
              (onValidateVal) {
                if (onValidateVal.isEmpty) {
                  return 'Username nie może być puste.';
                }

                return null;
              },
              (onSavedVal) => {
                userName = onSavedVal,
              },
              initialValue: "",
              obscureText: false,
              borderFocusColor: Colors.white,
              prefixIconColor: Colors.white,
              borderColor: Colors.white,
              textColor: Colors.white,
              hintColor: Colors.white.withOpacity(0.7),
              borderRadius: 10,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FormHelper.inputFieldWidget(
              context,
              prefixIcon: Icon(Icons.lock),
              "Hasło",
              "Hasło",
              (onValidateVal) {
                if (onValidateVal.isEmpty) {
                  return 'Hasło nie może być puste.';
                }

                return null;
              },
              (onSavedVal) => {
                password = onSavedVal,
              },
              initialValue: "",
              obscureText: hidePassword,
              borderFocusColor: Colors.white,
              prefixIconColor: Colors.white,
              borderColor: Colors.white,
              textColor: Colors.white,
              hintColor: Colors.white.withOpacity(0.7),
              borderRadius: 10,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
                color: Colors.white.withOpacity(0.7),
                icon: Icon(
                  hidePassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 25,
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Zapomiałeś hasła? ',
                      style: const TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Center(
            child: FormHelper.submitButton(
              "Zaloguj się",
              () {
                if (validateAndSave()) {
                  setState(() {
                    isApiCallProcess = true;
                  });

                  if (userName != null || password != null) {
                    login(userName, password, context);
                  }
                }
              },
              btnColor: HexColor("#1f9c44"),
              borderColor: Colors.white,
              txtColor: Colors.white,
              borderRadius: 10,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Center(
            child: Text(
              "LUB",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 25,
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 14.0),
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Nie masz konta? ',
                    ),
                    TextSpan(
                      text: 'Zarejestruj się',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(
                            context,
                            '/register',
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  bool validateAndSave() {
    final form = globalFormKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }
}
