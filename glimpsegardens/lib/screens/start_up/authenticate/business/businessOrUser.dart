import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glimpsegardens/screens/start_up/wrapper.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/whichTypeofBusiness.dart';
import 'package:glimpsegardens/shared/constants.dart';

class BusinessOrUser extends StatefulWidget {
  final PassingUser pUser;

  const BusinessOrUser({Key key, @required this.pUser}) : super(key: key);

  @override
  _BusinessOrUser createState() => _BusinessOrUser();
}

class _BusinessOrUser extends State<BusinessOrUser> {
  // Text field state
  String email = "";
  String password = "";
  String passwordTwo = "";
  String error = "";
  String firstName = "";
  bool loading = false;
  final AuthService _auth = AuthService();

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  // Stolen from the login page
  showAlertDialog(BuildContext context, String title, String msg,
      [bool success = false]) {
    Widget okButton = TextButton(
      child: Text(currentLanguage[13]),
      onPressed: () {
        if (success) {
          _auth.signOut().then((value) => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const Wrapper())));
        } else {
          Navigator.pop(context);
        }
      },
      style: flatButtonStyle,
    );

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(msg),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0))),
      actions: <Widget>[okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Arial'),
        home: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
                child: Column(children: [
              const SizedBox(height: 25),
              Row(children: [
                Padding(
                    child: IconButton(
                      icon: const IconTheme(
                        data: IconThemeData(color: normalText),
                        child: Icon(Icons.arrow_back),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20)),
              ]),
              const SizedBox(height: 45),
              Container(
                  height: size.height / 4,
                  width: size.width,
                  color: Colors.white,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Image.asset(
                        'assets/drawable/basic_logo.png',
                        height: 225,
                      ))),
              const SizedBox(height: 30),
              Text(currentLanguage[6],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: normalText,
                  )),
              const SizedBox(height: 30),
              SizedBox(
                  width: size.width / 1.2,
                  child: Column(children: [
                    AbsorbPointer(
                      absorbing: loading,
                      child: TextButton(
                          style: registerPageButtonStyle,
                          child: Center(
                              child: Text(currentLanguage[7],
                                  style: const TextStyle(fontSize: 16))),
                          onPressed: () async {
                            setState(() {
                              loading = true;
                            });
                            dynamic result =
                                await _auth.registerWithEmailAndPassword(
                                    widget.pUser.email.toLowerCase().trim(),
                                    widget.pUser.password,
                                    widget.pUser.name);
                            if (result != "") {
                              setState(() {
                                loading = false;
                              });
                              showAlertDialog(
                                  context, result, currentLanguage[142]);
                            } else {
                              setState(() {
                                loading = false;
                              });
                              // Go back to sign in page after popup indicating
                              // that we sent a verification email.
                              // Once the user taps 'ok', we send them back to
                              // the login screen and log them out of the app
                              showAlertDialog(context, currentLanguage[130],
                                  currentLanguage[144], true);
                            }
                          }),
                    ),
                    const SizedBox(height: 20),
                    AbsorbPointer(
                      absorbing: loading,
                      child: TextButton(
                          style: registerPageButtonStyle,
                          child: Center(
                              child: Text(currentLanguage[8],
                                  style: const TextStyle(fontSize: 16))),
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    whichTypeofBusiness(pUser: widget.pUser),
                              ),
                            );
                          }),
                    ),
                  ]))
            ]))));
  }
}

class PassingUser {
  final String password;
  final String email;
  final String name;

  PassingUser({
    this.password,
    this.email,
    this.name,
  });
}
