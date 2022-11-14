// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'dart:async';
import 'package:glimpsegardens/shared/constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';

class MeSettingsPage extends StatefulWidget {
  @override
  _MeSettingsPage createState() => _MeSettingsPage();
}

class _MeSettingsPage extends State<MeSettingsPage> {
  String _newFirstName = "";

  String _uid;

  bool _isAnon = false;

  static String _currentFirstName = "";

  String lastCodeEntered = "";

  final AuthService _auth = AuthService();

  bool isVisible = false;

  final myController = TextEditingController();

  Timer timer;

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  // Sets variable '_userName' to the email address of the current user
  // Uses name in prefs helper if db returns null
  // Will change name if the user decides to change their name in the future
  Future _getNames() async {
    String _tmpFirstName = await PreferencesHelper().getFirstName();

    setState(() {
      _currentFirstName = _tmpFirstName;
    });
  }

  // Sets variable '_uid' to the uid stored locally.
  Future _getUid() async {
    _uid = await PreferencesHelper().getUid();
  }

  Future _saveData(String _newFirstName) async {
    // Save to database
    DatabaseService()
        .userCollection
        .doc(_uid)
        .update({'firstName': _newFirstName});

    PreferencesHelper().setFirstName(_newFirstName);

    _currentFirstName = _newFirstName;

    setState(() {
      isVisible = true;
    });

    timer?.cancel();

    timer = new Timer(const Duration(milliseconds: 3000), () {
      setState(() {
        isVisible = false;
      });
    });
  }

  @override
  void initState() {
    _getNames();
    _getUid();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 25),
              Stack(
                children: [
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Center(
                      child: Text(
                        currentLanguage[213],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 17,
                            color: headers,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  Container(
                      alignment: Alignment.centerLeft,
                      child: new IconTheme(
                        data: new IconThemeData(color: normalText),
                        child: IconButton(
                          icon: new Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ))
                ],
              ),
              SizedBox(
                height: 10,
              ),
              AnimatedOpacity(
                  // If the widget is visible, animate to 0.0 (invisible).
                  // If the widget is hidden, animate to 1.0 (fully visible).
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  // The green box must be a child of the AnimatedOpacity widget.
                  child: Center(
                    child: Text(currentLanguage[164],
                        style: TextStyle(
                          color: headers,
                          fontSize: 22,
                          fontFamily: 'Arial',
                        )),
                  )),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(currentLanguage[141],
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Arial',
                        color: buttonsBorders,
                        fontSize: 18,
                      )),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                child: TextFormField(
                  controller: myController,
                  keyboardType: TextInputType.visiblePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(
                    color: normalText,
                    decoration: TextDecoration.none,
                    fontFamily: 'Arial',
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(254),
                  ],
                  decoration: businessRegisterInputDecoration.copyWith(
                      hintText: _currentFirstName,
                      hintStyle:
                          TextStyle(color: fadeoutText, fontFamily: 'Arial')),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(children: [
                Expanded(
                  child: Padding(
                      child: TextButton(
                          style: TextButton.styleFrom(
                            alignment: Alignment.center,
                            primary: Colors.white,
                            minimumSize: Size(325, 50),
                            backgroundColor: buttonsBorders,
                            textStyle: loginPageTextStyle,
                            shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(5.0),
                            ),
                          ),
                          child: Text(currentLanguage[88],
                              style: TextStyle(fontFamily: 'Arial')),
                          onPressed: () {
                            if (myController.text != "") {
                              _saveData(myController.text);
                            }
                          }),
                      padding: EdgeInsets.symmetric(horizontal: 20)),
                ),
              ]),
            ],
          ),
        ));
  }
}
