import 'package:flutter/material.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class Forgotten extends StatefulWidget {
  @override
  _Forgotten createState() => _Forgotten();
}

class _Forgotten extends State<Forgotten> {
  final _formKey = GlobalKey<FormState>();

  String email = "";
  String errorText = "";

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          backgroundColor: lightTone,
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Align(
                      alignment: Alignment(0, -0.8),
                      child: Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Image.asset(
                            'assets/drawable/susan.gif',
                            height: 225,
                          ))),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            currentLanguage[149],
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return currentLanguage[150];
                              }
                              return null;
                            },
                            decoration:
                                textInputDecoration.copyWith(hintText: "Email"),
                            onChanged: (val) {
                              email = val;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    errorText,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  Padding(
                    child: TextButton(
                      child: Text(currentLanguage[151]),
                      style: loginPageButtonStyle,
                      onPressed: () async {
                        HapticFeedback.heavyImpact();
                        if (_formKey.currentState.validate()) {
                          try {
                            // THIS WILL FAIL for some reason. It is actually a bug
                            // with try/catch and catchError in Flutter
                            // with specifically vscode as far as I'm seeing
                            // The error is successfully caught and setState will help the user.
                            // Do not worry about this if it crashes, just press resume
                            // in the debugger.
                            // The user will not see this anyways.
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(email: email)
                                .then((value) {
                              // Email Sent
                              showAlertDialog(context, currentLanguage[29],
                                  currentLanguage[152]);
                            });
                          } catch (err) {
                            print(err.code);
                            switch (err.code) {
                              case 'invalid-email':
                                setState(() {
                                  errorText = currentLanguage[234];
                                });
                                break;
                              case 'user-not-found':
                                setState(() {
                                  errorText = currentLanguage[154];
                                });
                                break;
                              default:
                                setState(() {
                                  errorText = currentLanguage[234];
                                });
                                break;
                            }
                          }
                        } else {
                          setState(() {
                            errorText = currentLanguage[234];
                          });
                        }
                      },
                    ),
                    padding: EdgeInsets.only(top: 8),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  ButtonTheme(
                    minWidth: 350.0,
                    height: 50,
                    child: TextButton(
                      style: loginPageButtonStyle,
                      child: Text(currentLanguage[12]),
                      // Move to maps if username and password are valid. Else error.
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          )),
      debugShowCheckedModeBanner: false,
    );
  }

  showAlertDialog(BuildContext context, String title, String msg) {
    Widget okButton = TextButton(
      child: Text(currentLanguage[13]),
      onPressed: () {
        Navigator.pop(context);
      },
      style: flatButtonStyle,
    );

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(msg),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      actions: <Widget>[okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
