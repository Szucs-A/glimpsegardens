// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'dart:async';
import 'package:glimpsegardens/shared/constants.dart';

import 'package:flutter/material.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glimpsegardens/screens/settings/businessEditPage.dart';
import 'package:glimpsegardens/screens/settings/BusinessLocationPage.dart';

class accountSettingsPage extends StatefulWidget {
  static bool showPreferencesSaved = false;

  @override
  _accountSettingsPage createState() => _accountSettingsPage();
}

class _accountSettingsPage extends State<accountSettingsPage> {
  String _uid;

  String lastCodeEntered = "";

  final AuthService _auth = AuthService();

  bool isVisible = false;

  static String email = "";

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
  Future _getEmail() async {
    User user = await FirebaseAuth.instance.currentUser;

    if (user.email != null) {
      String tmp = user.email;
      String atSymbol = user.email.split('@')[1];
      tmp = tmp.substring(0, 3) + "***@" + atSymbol;
      setState(() {
        email = tmp;
      });
    } else {
      setState(() {
        email = "Permissions Denied.";
      });
    }
  }

  // Sets variable '_uid' to the uid stored locally.
  Future _getUid() async {
    _uid = await PreferencesHelper().getUid();
  }

  Future visibleToggle() async {
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
    _getEmail();
    _getUid();
    super.initState();
  }

  void showSaveText() {
    if (accountSettingsPage.showPreferencesSaved) {
      accountSettingsPage.showPreferencesSaved = false;
      visibleToggle();
    }
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
                        currentLanguage[83],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 17,
                            color: normalText,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Arial'),
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
                    child: Text(currentLanguage[159],
                        style: TextStyle(
                            color: normalText,
                            fontSize: 22,
                            fontFamily: 'Arial')),
                  )),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(currentLanguage[85],
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Arial',
                        color: normalText,
                        fontSize: 18,
                      )),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                child: Container(
                  color: fadedOutButtons,
                  height: 50,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(email,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Arial',
                            color: normalText,
                            fontSize: 18,
                          )),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              /*
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
                          child: const Text('Reset Blocked Users'),
                          onPressed: () {
                            PreferencesHelper().setBlockedUsers([]);
                            visibleToggle();
                          }),
                      padding: EdgeInsets.symmetric(horizontal: 20)),
                ),
              ]),
              SizedBox(
                height: 10,
              ),
              */
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
                          child: Text(currentLanguage[186],
                              style: TextStyle(
                                fontFamily: 'Arial',
                              )),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    BusinessEditPage()));
                          }),
                      padding: EdgeInsets.symmetric(horizontal: 20)),
                ),
              ]),
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
                          child: Text(currentLanguage[185],
                              style: TextStyle(
                                fontFamily: 'Arial',
                              )),
                          onPressed: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        BusinessLocationPage()))
                                .then((value) => showSaveText());
                          }),
                      padding: EdgeInsets.symmetric(horizontal: 20)),
                ),
              ]),
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
                          child: Text(currentLanguage[161],
                              style: TextStyle(
                                fontFamily: 'Arial',
                              )),
                          onPressed: () {
                            PreferencesHelper().setFinishedTutorial(false);
                            visibleToggle();
                          }),
                      padding: EdgeInsets.symmetric(horizontal: 20)),
                ),
              ]),
            ],
          ),
        ));
  }
}
