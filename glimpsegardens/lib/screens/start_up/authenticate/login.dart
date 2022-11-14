import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/register.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/gestures.dart';
import 'package:glimpsegardens/screens/start_up/forgotten.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  String email = "";
  String password = "";
  String error = "";

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return WillPopScope(
        onWillPop: () async => false,
        child: loading
            ? Container(
                color: buttonsBorders,
                height: size.height,
                width: size.width,
                child: Transform.scale(
                  scale: (9 / 16) / size.aspectRatio,
                  child: AspectRatio(
                      aspectRatio: (9 / 16),
                      child: Image.asset('assets/drawable/loading.gif',
                          fit: BoxFit.fitWidth)),
                ),
              )
            : MaterialApp(
                theme: ThemeData(fontFamily: 'Arial'),
                home: Scaffold(
                  backgroundColor: Colors.white,
                  body: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            height: size.height / 4,
                            width: size.width,
                            color: buttonsBorders,
                            child: Padding(
                                padding: const EdgeInsets.only(top: 30),
                                child: Image.asset(
                                  'assets/drawable/white-static-logo.png',
                                  height: 225,
                                ))),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              const SizedBox(
                                height: 40,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 25),
                                child: TextFormField(
                                  keyboardType: TextInputType.visiblePassword,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  style: const TextStyle(
                                      color: normalText,
                                      decoration: TextDecoration.none),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(254),
                                  ],
                                  decoration: textInputDecoration.copyWith(
                                      hintText: currentLanguage[85]),
                                  validator: (val) =>
                                      EmailValidator.validate(val)
                                          ? null
                                          : currentLanguage[126],
                                  onChanged: (val) {
                                    email = val;
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 25),
                                child: TextFormField(
                                  obscureText: true,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  style: const TextStyle(
                                      color: normalText,
                                      decoration: TextDecoration.none),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(128),
                                  ],
                                  decoration: textInputDecoration.copyWith(
                                      hintText: currentLanguage[86]),
                                  // ignore: null_aware_before_operator
                                  validator: (val) => val?.length < 6
                                      ? currentLanguage[127]
                                      : null,
                                  onChanged: (val) {
                                    password = val;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          error,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                        const SizedBox(height: 30),
                        Container(
                            height: 3,
                            width: 30,
                            decoration: BoxDecoration(
                                color: lightTone,
                                borderRadius: BorderRadius.circular(50))),
                        const SizedBox(height: 40),
                        TextButton(
                            style: loginPageButtonStyle,
                            child: Text(
                              currentLanguage[1],
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              HapticFeedback.heavyImpact();
                              if (_formKey.currentState.validate()) {
                                setState(() {
                                  loading = true;
                                });
                                dynamic result =
                                    await _auth.signInWithEmailAndPassword(
                                        email, password);
                                if (result == null) {
                                  setState(() {
                                    error = currentLanguage[133];
                                    loading = false;
                                  });
                                  showAlertDialog(context, currentLanguage[128],
                                      currentLanguage[129], false);
                                } else if (!result[1]) {
                                  // NOT VERIFIED
                                  setState(() {
                                    loading = false;
                                  });
                                  showAlertDialog(context, currentLanguage[130],
                                      currentLanguage[131], true);
                                } //else {
                                setState(() {
                                  loading = false;
                                });
                              }
                            }),
                        const SizedBox(
                          height: 25,
                        ),
                        TextButton(
                            style: loginPageButtonStyle,
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Register()),
                              );
                            },
                            child: Text(
                              currentLanguage[2],
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(
                          height: 40,
                        ),
                        RichText(
                          text: TextSpan(
                              text: currentLanguage[3],
                              style: const TextStyle(color: normalText),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Forgotten()));
                                }),
                        ),
                      ],
                    ),
                  ),
                ),
                debugShowCheckedModeBanner: false,
              ));
  }

  showAlertDialog(
      BuildContext context, String title, String msg, bool needToVerify) {
    Widget okButton = TextButton(
      child: Text(currentLanguage[13]),
      onPressed: () {
        Navigator.pop(context);
      },
      style: flatButtonStyle,
    );

    Widget resendButton = TextButton(
        child: Text(currentLanguage[134]),
        onPressed: () async {
          _auth
              .getUser()
              .then((value) => value.sendEmailVerification())
              .then((value) => _auth.signOut());
          Fluttertoast.showToast(msg: currentLanguage[135]);
          Navigator.pop(context);
        },
        style: flatButtonStyle);

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(msg),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      actions:
          needToVerify ? <Widget>[resendButton, okButton] : <Widget>[okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
