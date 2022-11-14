import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glimpsegardens/screens/start_up/splash.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:glimpsegardens/services/remote_config.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:glimpsegardens/models/user.dart';
import 'package:apple_sign_in/apple_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await RemoteConfigInit.initRemoteConfig();

  AuthService.appleSignInAvailable = await AppleSignInAvailable.check();

  runApp(const MyApp());
}

class AppleSignInAvailable {
  AppleSignInAvailable(this.isAvailable);
  final bool isAvailable;

  static Future<bool> check() async {
    return await AppleSignIn.isAvailable();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return StreamProvider<User>.value(
      initialData: null,
      catchError: (_, __) => null,
      value: AuthService().user,
      child: MaterialApp(
        //showPerformanceOverlay: true,
        home: const Splash(),
        theme: ThemeData(fontFamily: 'CircularBold'),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
