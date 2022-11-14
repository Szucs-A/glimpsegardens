import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/businessOrUser.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:email_validator/email_validator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glimpsegardens/screens/start_up/wrapper.dart';
import 'package:glimpsegardens/screens/loading.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Text field state
  String email = "";
  String password = "";
  String passwordTwo = "";
  String error = "";
  String firstName = "";

  List<DropdownMenuItem<String>> listDropYear = [];
  List<DropdownMenuItem<String>> listDropMonth = [];
  List<DropdownMenuItem<String>> listDropDay = [];
  String listValueYear = "2020";
  String listValueDay = "01";
  String listValueMonth = "01";

  bool _isChecked = false;
  bool loading = false;

  Widget checkbox_error;

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  // Stolen from the docs @ https://pub.dev/packages/url_launcher#-readme-tab-
  _launchURL() async {
    const url = 'https://glimpsesocial.com/TOC.html';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (listDropYear.isEmpty) {
      for (var i = 2020; i > 1900; i--) {
        listDropYear.add(new DropdownMenuItem(
          child: new Text(i.toString()),
          value: i.toString(),
        ));
      }

      for (var i = 1; i < 13; i++) {
        if (i > 9) {
          listDropMonth.add(new DropdownMenuItem(
            child: new Text(i.toString()),
            value: i.toString(),
          ));
        } else {
          listDropMonth.add(new DropdownMenuItem(
            child: new Text("0" + i.toString()),
            value: "0" + i.toString(),
          ));
        }
      }

      for (var i = 1; i < 32; i++) {
        if (i > 9) {
          listDropDay.add(new DropdownMenuItem(
            child: new Text(i.toString()),
            value: i.toString(),
          ));
        } else {
          listDropDay.add(new DropdownMenuItem(
            child: new Text("0" + i.toString()),
            value: "0" + i.toString(),
          ));
        }
      }
    }

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Arial'),
        home: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 25),
                  Row(children: [
                    Padding(
                        child: IconButton(
                          icon: new IconTheme(
                            data: new IconThemeData(color: normalText),
                            child: new Icon(Icons.arrow_back),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Wrapper()),
                            );
                          },
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20)),
                  ]),
                  SizedBox(height: 25),
                  Form(
                      key: _formKey,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context)
                              .colorScheme
                              .copyWith(primary: buttonsBorders),
                        ),
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25),
                              child: TextFormField(
                                autocorrect: false,
                                enableSuggestions: false,
                                keyboardType: TextInputType.visiblePassword,
                                style: TextStyle(
                                    color: normalText,
                                    decoration: TextDecoration.none),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(128),
                                ],
                                decoration:
                                    registerTextInputDecoration.copyWith(
                                        prefixIcon: Icon(Icons.person),
                                        hintText: currentLanguage[141]),
                                validator: (val) => val.length < 1
                                    ? currentLanguage[140]
                                    : null,
                                onChanged: (val) {
                                  firstName = val;
                                },
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25),
                              child: TextFormField(
                                autocorrect: false,
                                enableSuggestions: false,
                                keyboardType: TextInputType.visiblePassword,
                                style: TextStyle(
                                    color: normalText,
                                    decoration: TextDecoration.none),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(254),
                                ],
                                decoration:
                                    registerTextInputDecoration.copyWith(
                                        prefixIcon: Icon(Icons.email),
                                        hintText: currentLanguage[85]),
                                // The false, false on the validator is for top-level domains and for
                                // international domains. Putting false, false fixed the emoji problem.
                                validator: (val) =>
                                    EmailValidator.validate(val, false, false)
                                        ? null
                                        : currentLanguage[126],
                                onChanged: (val) {
                                  email = val;
                                },
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25),
                              child: TextFormField(
                                obscureText: true,
                                style: TextStyle(
                                    color: normalText,
                                    decoration: TextDecoration.none),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(128),
                                ],
                                decoration:
                                    registerTextInputDecoration.copyWith(
                                        prefixIcon: Icon(Icons.lock),
                                        hintText: currentLanguage[86]),
                                validator: (val) => val.length < 6
                                    ? currentLanguage[127]
                                    : null,
                                onChanged: (val) {
                                  password = val;
                                },
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25),
                              child: TextFormField(
                                obscureText: true,
                                style: TextStyle(
                                    color: normalText,
                                    decoration: TextDecoration.none),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(128),
                                ],
                                decoration:
                                    registerTextInputDecoration.copyWith(
                                        prefixIcon: Icon(Icons.lock),
                                        hintText: currentLanguage[87]),
                                validator: (val) => val != password
                                    ? currentLanguage[137]
                                    : null,
                                onChanged: (val) {
                                  passwordTwo = val;
                                },
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        left: 25, right: 25, top: 15),
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(50)),
                                      ),
                                      child: CheckboxListTile(
                                        checkColor: normalText,
                                        activeColor: normalText,
                                        title: RichText(
                                            text: TextSpan(children: <TextSpan>[
                                          TextSpan(
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: normalText),
                                            text: currentLanguage[235] + " ",
                                          ),
                                          TextSpan(
                                              text: currentLanguage[236],
                                              style: TextStyle(
                                                  color: Colors.blueAccent,
                                                  decoration:
                                                      TextDecoration.underline),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  _launchURL();
                                                }),
                                        ])),
                                        value: _isChecked,
                                        subtitle: checkbox_error,
                                        onChanged: (bool value) {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _isChecked = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                  SizedBox(
                    height: 15,
                  ),
                  TextButton(
                      style: loginPageButtonStyle,
                      child: Text(
                        currentLanguage[28],
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        HapticFeedback.heavyImpact();
                        if (_formKey.currentState.validate()) {
                          if (_isChecked) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusinessOrUser(
                                    pUser: PassingUser(
                                        password: password,
                                        email: email,
                                        name: firstName)),
                              ),
                            );
                          }
                        }

                        if (!_isChecked) {
                          setState(() {
                            checkbox_error = Padding(
                              padding: EdgeInsets.fromLTRB(12.0, 0, 0, 0),
                              child: Text(
                                currentLanguage[136],
                                style: TextStyle(
                                    color: Color(0xFFe53935), fontSize: 12),
                              ),
                            );
                          });
                        } else {
                          setState(() {
                            checkbox_error = null;
                          });
                        }
                      }),
                  Text(
                    error,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  SizedBox(height: 30),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    /*ElevatedButton(
                      onPressed: () async {
                        return;
                        dynamic result; // = await _auth.signInWithFacebook();
                        if (result != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Wrapper()),
                          );
                        }
                      },
                      child:
                          Icon(Icons.facebook, color: facebookBlue, size: 25),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: CircleBorder(
                            side: BorderSide(width: 2.0, color: facebookBlue)),
                        padding: EdgeInsets.all(15),
                        primary: Colors.blue.withOpacity(0), // <-- Button color
                      ),
                    ),
                    */
                    SizedBox(width: 15),
                    !AuthService.appleSignInAvailable
                        ? ElevatedButton(
                            onPressed: () async {
                              dynamic result = await _auth.signInWithGoogle();
                              if (result != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Wrapper()),
                                );
                              }
                            },
                            child: Icon(FlutterIcons.google__with_circle_ent,
                                color: googleColor, size: 25),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: CircleBorder(
                                  side: BorderSide(
                                      width: 2.0, color: googleColor)),
                              padding: EdgeInsets.all(15),
                              primary: Colors.blue
                                  .withOpacity(0), // <-- Button color
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              dynamic result = await _auth.signInWithApple();
                              if (result != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Wrapper()),
                                );
                              }
                            },
                            child: Icon(FlutterIcons.apple_faw,
                                color: appleGrey, size: 25),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: CircleBorder(
                                  side:
                                      BorderSide(width: 2.0, color: appleGrey)),
                              padding: EdgeInsets.all(15),
                              primary: Colors.blue
                                  .withOpacity(0), // <-- Button color
                            ),
                          ),
                  ]),
                  SizedBox(height: 25),
                  Text(
                    currentLanguage[5],
                    style: TextStyle(
                      color: normalText,
                    ),
                  ),
                  SizedBox(height: 25),
                ],
              ),
            )));
  }
}
