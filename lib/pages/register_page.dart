import 'package:my_new_project/models/register_request_model.dart';
import 'package:flutter/material.dart';
import 'package:snippet_coder_utils/FormHelper.dart';
import 'package:snippet_coder_utils/ProgressHUD.dart';
import 'package:snippet_coder_utils/hex_color.dart';

import '../config.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isApiCallProcess = false;
  bool hidePassword = true;
  static final GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  String? userName;
  String? password;
  String? firstname;
  String? lastname;

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
            child: _registerUI(context),
          ),
          inAsyncCall: isApiCallProcess,
          opacity: 0.3,
          key: UniqueKey(),
        ),
      ),
    );
  }

  Widget _registerUI(BuildContext context) {
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
              "Zarejestruj się",
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
              prefixIcon: Icon(Icons.email),
              "Nazwa użytkownika",
              "Nazwa użytkownika",
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
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FormHelper.inputFieldWidget(
              context,
              prefixIcon: Icon(Icons.mail),
              "Imie",
              "Imie",
              (onValidateVal) {
                if (onValidateVal.isEmpty) {
                  return 'Imie nie może być puste.';
                }

                return null;
              },
              (onSavedVal) => {
                firstname = onSavedVal,
              },
              initialValue: "",
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
              prefixIcon: Icon(Icons.mail),
              "Nazwisko",
              "Nazwisko",
              (onValidateVal) {
                if (onValidateVal.isEmpty) {
                  return 'Nazwisko nie może być puste.';
                }

                return null;
              },
              (onSavedVal) => {
                lastname = onSavedVal,
              },
              initialValue: "",
              borderFocusColor: Colors.white,
              prefixIconColor: Colors.white,
              borderColor: Colors.white,
              textColor: Colors.white,
              hintColor: Colors.white.withOpacity(0.7),
              borderRadius: 10,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Center(
            child: FormHelper.submitButton(
              "Zarejestruj się",
              () {
                if (validateAndSave()) {
                  setState(() {
                    isApiCallProcess = true;
                  });

                  RegisterRequestModel model = RegisterRequestModel(
                    username: userName,
                    password: password,
                    firstName: firstname,
                    lastName: lastname,
                  );

                  APIService.register(model).then((response) {
                    setState(() {
                      isApiCallProcess = false;
                    });
                    // Wypisz w konsoli dane odpowiedzi
                    print(response.data);

                    if (response.data != null) {
                      // Zakładamy, że rejestracja przebiegła pomyślnie, jeśli mamy dane
                      FormHelper.showSimpleAlertDialog(
                        context,
                        Config.appName,
                        "Rejestracja przebiegła pomyślnie: ${response.data.username}",
                        "OK",
                        () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        },
                      );
                    } else {
                      FormHelper.showSimpleAlertDialog(
                        context,
                        Config.appName,
                        "Rejestracja nie powiodła się. Proszę spróbować ponownie.",
                        "OK",
                        () {
                          Navigator.of(context).pop();
                        },
                      );
                    }
                  }).catchError((error) {
                    setState(() {
                      isApiCallProcess = false;
                    });
                    FormHelper.showSimpleAlertDialog(
                      context,
                      Config.appName,
                      "Wystąpił błąd: $error",
                      "OK",
                      () {
                        Navigator.of(context).pop();
                      },
                    );
                  });
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
