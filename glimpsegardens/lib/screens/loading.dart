import 'package:flutter/material.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/start_up/wrapper.dart';
import 'dart:async';

// ignore: must_be_immutable
class LoadingScreen extends StatefulWidget {
  bool isUploading;
  LoadingScreen({Key key, this.isUploading}) : super(key: key);

  @override
  _LoadingScreen createState() => _LoadingScreen();
}

class _LoadingScreen extends State<LoadingScreen> {
  Timer _timer;
  int _start = 5;
  bool isVisible = false;

  @override
  @protected
  @mustCallSuper
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          _timer.cancel();
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (BuildContext context) => const Wrapper()));
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  @override
  void initState() {
    startTimer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
        color: buttonsBorders,
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            widget.isUploading
                ? Image.asset(
                    'assets/drawable/loading.gif',
                    fit: BoxFit.fitWidth,
                  )
                : Image.asset(
                    'assets/drawable/loading.gif',
                    fit: BoxFit.fitWidth,
                  ),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Visibility(
                  visible: isVisible,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        alignment: Alignment.center,
                        primary: Colors.white,
                        minimumSize: const Size(325, 50),
                        maximumSize: const Size(325, 50),
                        backgroundColor: lightTone,
                        textStyle: loginPageTextStyle,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      onPressed: () {},
                      child: Text(currentLanguage[218]),
                    ),
                  ),
                ))
          ],
        ));
  }
}
