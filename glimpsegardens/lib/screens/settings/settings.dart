// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'dart:async';
import 'package:glimpsegardens/shared/constants.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/services/push_notification_service.dart';
import 'package:glimpsegardens/screens/mapshelper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_switch/flutter_switch.dart';
import 'package:glimpsegardens/screens/start_up/splash.dart';

import 'package:glimpsegardens/screens/settings/meSettingsPage.dart';
import 'package:glimpsegardens/screens/settings/accountSettingsPage.dart';
import 'package:glimpsegardens/screens/settings/languageSettings.dart';
import 'package:glimpsegardens/screens/settings/searchSettingsPage.dart';
import 'package:glimpsegardens/screens/settings/followingSettingsPage.dart';
import 'package:glimpsegardens/screens/settings/followersSettingsPage.dart';

class Settings extends StatefulWidget {
  final LatLngBounds googleMapsBounds;

  Settings({Key key, @required LatLngBounds this.googleMapsBounds})
      : super(key: key);
  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  String _newFirstName = "";

  String _uid;

  String _currentFirstName = "";
  bool _currentNotificationValue = true;
  String _currentEmail = "";

  bool _isAnon = false;

  String lastCodeEntered = "";

  final AuthService _auth = AuthService();

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  // Stolen from the login page
  showAlertDialog(
      BuildContext context, String title, String command, String msg) {
    Widget yesButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[224]),
      onPressed: () async {
        if (command == 'save') {
          _saveData();
          Navigator.pop(context);
        } else if (command == 'block') {
          List<String> properBlocked =
              await PreferencesHelper().getBlockedUsers();
          properBlocked.clear();
          PreferencesHelper().setBlockedUsers(properBlocked);

          Navigator.pop(context);
        } else {
          Navigator.pop(context);
        }
      },
    );
    Widget cancelButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[77]),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget okButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[13]),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(msg),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      actions: _isAnon ? <Widget>[okButton] : <Widget>[yesButton, cancelButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // Sets variable '_userName' to the email address of the current user
  // Uses name in prefs helper if db returns null
  // Will change name if the user decides to change their name in the future
  Future _getNames() async {
    String _tmpFirstName = await PreferencesHelper().getFirstName();
    bool _tmpNotifications = await PreferencesHelper().getNotificationAlerts();

    if (_tmpNotifications == null) {
      _tmpNotifications = false;
    }

    setState(() {
      _currentFirstName = _tmpFirstName;
      _currentNotificationValue = _tmpNotifications;
    });

    User user = await FirebaseAuth.instance.currentUser;

    if (user.email != null) {
      String tmp = user.email;
      String atSymbol = user.email.split('@')[1];
      tmp = tmp.substring(0, 3) + "***@" + atSymbol;
      setState(() {
        _currentEmail = tmp;
      });
    } else {
      setState(() {
        _currentEmail = "Permissions Denied.";
      });
    }

    setState(() {
      _currentFirstName = _tmpFirstName;
      _currentNotificationValue = _tmpNotifications;
    });
  }

  // Sets variable '_uid' to the uid stored locally.
  Future _getUid() async {
    _uid = await PreferencesHelper().getUid();
  }

  Future _saveData() async {
    // Save to database
    DatabaseService()
        .userCollection
        .doc(_uid)
        .update({'firstName': _newFirstName});

    PreferencesHelper().setFirstName(_newFirstName);
  }

  @override
  void initState() {
    super.initState();
    _getNames();
    _getUid();
  }

  void checkNames() async {
    String _tmpFirstName = await PreferencesHelper().getFirstName();
    if (_currentFirstName != _tmpFirstName) {
      setState(() {
        _currentFirstName = _tmpFirstName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    checkNames();

    final size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
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
                        currentLanguage[97],
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
                height: 20,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(currentLanguage[98],
                        style: TextStyle(
                            color: normalText,
                            fontSize: 17,
                            fontFamily: 'Arial'))),
              ),
              SizedBox(
                height: 10,
              ),
              settingsButton(currentLanguage[213], Icon(Icons.edit), meSettings,
                  _currentFirstName),
              settingsButton(currentLanguage[100], Icon(Icons.account_box),
                  accountSettings, _currentEmail),
              ConstantsClass.businessAccount
                  ? settingsButton(
                      currentLanguage[73],
                      Icon(FlutterIcons.md_people_ion),
                      followerSettings,
                      currentLanguage[225])
                  : Container(),
              settingsButton(currentLanguage[101], Icon(FlutterIcons.heart_ant),
                  followingSettings, currentLanguage[104]),
              //settingsButton(currentLanguage[201], Icon(Icons.search),
              //    searchBusinessesSettings, "Local Businesses"),
              settingsButton(currentLanguage[102], Icon(FlutterIcons.earth_mco),
                  languageSetting, currentLanguage[105]),
              settingsButton(
                  currentLanguage[226], Icon(Icons.logout), signOut, ""),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentLanguage[99],
                        style: TextStyle(
                            fontSize: 17,
                            color: normalText,
                            fontFamily: 'Arial'),
                      ),
                      SizedBox(width: 10),
                      FlutterSwitch(
                        height: 30,
                        width: 60,
                        toggleSize: 15,
                        value: _currentNotificationValue,
                        activeColor: buttonsBorders,
                        onToggle: (value) async {
                          setState(() {
                            _currentNotificationValue = value;
                          });
                          await PreferencesHelper()
                              .setNotificationAlerts(value);
                          PushNotificationService.initilise(context, value);
                        },
                      ),
                    ]),
              ),
              SizedBox(height: 50),
            ],
          ),
        ));
  }

  languageSetting() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => languageSettings()));
  }

  followingSettings() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => FollowingSettingsPage(uid: _uid)));
  }

  followerSettings() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => FollowersSettingsPage(
            googleMapsBounds: widget.googleMapsBounds, uid: _uid)));
  }

  meSettings() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) => MeSettingsPage()));
  }

  searchBusinessesSettings() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) =>
            SearchSettingsPage(googleMapsBounds: widget.googleMapsBounds)));
  }

  accountSettings() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => accountSettingsPage()));
  }

  signOut() {
    Navigator.of(context)
        .pushReplacement(
            MaterialPageRoute(builder: (BuildContext context) => Splash()))
        .then((value) => _auth.signOut());
  }

  Future<bool> deactiveCodeOnAccount() async {
    await _getUid();
    DocumentSnapshot user =
        await DatabaseService().userCollection.doc(_uid).get();

    await firestore.runTransaction((Transaction myTransaction) async {
      myTransaction.update(user.reference, {'currentParent': ""});
      myTransaction.update(user.reference, {'currentCodeType': -1});
      myTransaction.update(user.reference, {'timestamp': ""});
      myTransaction.update(user.reference, {'enteredCode': ""});
    });
    MapsHelper.removeCodeMaterials();

    print("Finished Deleting.");
    return true;
  }

  Future<bool> linkAccountToCode(String parent, DocumentSnapshot codeSnap,
      DocumentSnapshot user, CodeType type, String enteredCode) async {
    String now = new DateTime.now().millisecondsSinceEpoch.toString();
    await firestore.runTransaction((Transaction myTransaction) async {
      myTransaction.update(user.reference, {'currentParent': parent});
      myTransaction.update(user.reference, {'currentCodeType': type.index});
      myTransaction.update(user.reference, {'timestamp': now});
      myTransaction.update(user.reference, {'enteredCode': enteredCode});
    });
    codeSnap = await DatabaseService().codesCollection.doc(codeSnap.id).get();

    await _getUid();

    const oneMin = const Duration(minutes: 1);
    // codeTimer is in Constants.dart
    if (codeTimer != null && codeTimer.isActive) codeTimer.cancel();
    codeTimer = new Timer.periodic(
        oneMin, (Timer t) => testCodeLinkedToAccount(codeSnap, _uid, type));

    return true;
  }

  showDialogCode(BuildContext context) {
    final codeController = TextEditingController(text: lastCodeEntered);

    Widget cancelButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[77]),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget okButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[13]),
      onPressed: () async {
        lastCodeEntered = codeController.text;

        String enteredCode = codeController.text;
        if (!codeValidation(enteredCode)) {
          Navigator.pop(context);
          showDialogCodeFail(context, currentLanguage[227]);
          return;
        }
        String pFirstNumber = convertCodeIntoFirstHalf(enteredCode);

        QuerySnapshot parentQ = await DatabaseService()
            .codesCollection
            .where("first", isEqualTo: pFirstNumber)
            .get();
        DocumentSnapshot parent;
        if (parentQ.docs.length == 1) {
          parent = parentQ.docs[0];
        } else {
          Navigator.pop(context);
          showDialogCodeFail(context, currentLanguage[227]);
          return;
        }

        if (!secondaryCodeValidation(enteredCode, parent)) {
          Navigator.pop(context);
          showDialogCodeFail(context, currentLanguage[227]);
          return;
        }

        CodeType type = await findCodeType(enteredCode, parent);
        if (type == null) {
          print("Pintype was not found properly.");
        }

        await _getUid();
        DocumentSnapshot user =
            await DatabaseService().userCollection.doc(_uid).get();

        // This stops other people from using it if the timestamp exists already
        int prime = int.parse(parent['second']);
        int minimum = 10000000 ~/ prime;
        minimum++;

        String full = enteredCode.split('-')[2] + enteredCode.split('-')[3];
        int parentMultiple = int.parse(full);
        parentMultiple = parentMultiple ~/ prime;
        parentMultiple -= minimum;

        print("Verified " +
            parent['verificationStack']
                .toString()
                .substring(parentMultiple * 4, (parentMultiple * 4) + 4));

        print("Entered " + enteredCode.split('-')[0]);
        Map<String, dynamic> tester = user.data();
        if (parent['verificationStack']
                .toString()
                .substring(parentMultiple * 4, (parentMultiple * 4) + 4) !=
            enteredCode.split('-')[0]) {
          Navigator.pop(context);
          showDialogCodeFail(context, currentLanguage[227]);
          return;
        } else if (parent['stack'][parentMultiple] == '1') {
          Navigator.pop(context);
          showDialogCodeFail(context, currentLanguage[229]);
        } else if (tester.containsKey("currentParent") &&
            user['currentParent'] != "") {
          Navigator.pop(context);
          showDialogCodeFail(context, currentLanguage[228]);
        } else {
          String starter = parent['stack']
              .toString()
              .replaceRange(parentMultiple, parentMultiple + 1, '1');

          await firestore.runTransaction((Transaction myTransaction) async {
            myTransaction.update(parent.reference, {'stack': starter});
          });

          MapsHelper.gatherCodeMaterials(parent, type, enteredCode);

          // Linking Code to Account in DataBase
          linkAccountToCode(parent.id, parent, user, type, enteredCode);

          Navigator.pop(context);
          showDialogCodeFail(context, currentLanguage[231]);

          return;
        }
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(currentLanguage[232]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: codeController,
        ),
      ]),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      actions:
          _isAnon ? <Widget>[cancelButton] : <Widget>[okButton, cancelButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showDialogCodeFail(BuildContext context, String msg) {
    Widget okButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[13]),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(msg),
      content: Column(mainAxisSize: MainAxisSize.min, children: []),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      actions: _isAnon ? <Widget>[okButton] : <Widget>[okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

class settingsButton extends StatelessWidget {
  String title;
  Icon icon;
  Function() dynamicFunction;
  String msg;

  settingsButton(String title, Icon icon, Function() dynamic, String msg) {
    this.title = title;
    this.icon = icon;
    dynamicFunction = dynamic;
    this.msg = msg;

    if (msg == null) {
      this.msg = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          if (dynamicFunction == null) return;
          dynamicFunction.call();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5.0),
          child: Container(
            color: fadedOutButtons,
            padding: const EdgeInsets.all(20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    new IconTheme(
                      data: new IconThemeData(color: headers),
                      child: icon,
                    ),
                    SizedBox(width: 20),
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 18,
                          color: normalText,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w700),
                    )
                  ]),
                  Text(msg,
                      style: TextStyle(color: fadeoutText, fontFamily: 'Arial'))
                ]),
          ),
        ));
  }
}

/*
TextButton(
              style: TextButton.styleFrom(
                primary: Colors.red,
                backgroundColor: glimpseOrange,
                textStyle: loginPageTextStyle,
                shape: RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(10.0),
                    side: BorderSide(color: glimpseOrangeSecondary, width: 5)),
                minimumSize: Size(350, 50),
              ),
              child: const Text('Reset Blocked Users'),
              onPressed: () async {
                HapticFeedback.heavyImpact();
                showAlertDialog(context, "Warning", "block",
                    "All blocked users will now be able to interact with you. Would you still like to continue?");
              },
            ),
            SizedBox(
              height: 10,
            ),
            TextButton(
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: glimpseOrange,
                textStyle: loginPageTextStyle,
                shape: RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(10.0),
                    side: BorderSide(color: glimpseOrangeSecondary, width: 5)),
                minimumSize: Size(350, 50),
              ),
              child: const Text('Background Pin Settings'),
              onPressed: () async {
                HapticFeedback.heavyImpact();

                bool workManagerBool =
                    await PreferencesHelper().getWorkManagerBool();

                if (workManagerBool == null) {
                  workManagerBool = false;
                }

                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) =>
                        new BackgroundSettings(workManagerBool)));
              },
            ),
            SizedBox(
              height: 10,
            ),
            TextButton(
              style: loginPageButtonStyle,
              child: const Text('Log Out'),
              onPressed: () async {
                HapticFeedback.heavyImpact();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (BuildContext context) => Splash()));
                MapsPage.resetInitialPosition = true;
                await _auth.signOut();
              },
            ),
            SizedBox(
              height: 10,
            ),
            TextButton(
              style: loginPageButtonStyle,
              child: const Text('Enter Code'),
              onPressed: () async {
                HapticFeedback.heavyImpact();
                showDialogCode(context);
              },
            ),
            SizedBox(
              height: 10,
            ),
            */
