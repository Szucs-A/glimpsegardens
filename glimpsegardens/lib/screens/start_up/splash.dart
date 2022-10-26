import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'wrapper.dart';

class Splash extends StatefulWidget {
  const Splash({Key key}) : super(key: key);

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    precacheImage(
        const AssetImage('assets/drawable/glimpse_logo.png'), context);
    cacheImages(false);
    super.didChangeDependencies();
  }

  void cacheImages(bool isInAmerica) {
    precacheImage(const AssetImage("assets/drawable/uploading.gif"), context);
    precacheImage(const AssetImage("assets/drawable/loading.gif"), context);
  }

  @override
  void dispose() {
    super.dispose();

    replacement?.cancel();
  }

  Timer replacement;

  @override
  Widget build(BuildContext context) {
    replacement = Timer(
        const Duration(
            seconds: 1), // You can change the splash screen timeout here
        () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Wrapper())));

    return Scaffold(
      body: Center(
        child: Image.asset('assets/drawable/loading.gif', fit: BoxFit.fitWidth),
      ),
      backgroundColor: buttonsBorders,
    );
  }
}
