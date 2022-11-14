import 'package:flutter/material.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/login.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({Key key}) : super(key: key);

  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Login(),
    );
  }
}
