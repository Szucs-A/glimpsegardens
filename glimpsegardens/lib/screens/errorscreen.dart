import 'package:flutter/material.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class ErrorScreen extends StatelessWidget {
  String message;

  ErrorScreen(message, {Key key}) : super(key: key) {
    // ignore: prefer_initializing_formals
    this.message = message;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color.fromRGBO(249, 164, 26, 1.0),
            height: size.height,
            width: size.width,
            child: Transform.scale(
              scale: (9 / 16) / size.aspectRatio,
              child: AspectRatio(
                  aspectRatio: (9 / 16),
                  child: Image.asset(
                    'assets/drawable/error.gif',
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
            child: Align(
              alignment: const Alignment(0, .7),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontFamily: 'CircularBold',
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "ErrorPageFloatingActionButtonOpenSettings",
        onPressed: () {
          HapticFeedback.heavyImpact();
          openAppSettings();
        },
        label: Text(currentLanguage[187]),
        backgroundColor: buttonsBorders,
      ),
    );
  }
}
