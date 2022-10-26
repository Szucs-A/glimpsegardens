import 'package:flutter/material.dart';
import 'package:glimpsegardens/models/user.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/authenticate.dart';
import 'package:provider/provider.dart';
import 'package:glimpsegardens/services/push_notification_service.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:glimpsegardens/screens/maps.dart';
import 'package:glimpsegardens/shared/constants.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key key}) : super(key: key);

  startNotifications(BuildContext context) async {
    bool getNotificationAlerts =
        await PreferencesHelper().getNotificationAlerts();
    PushNotificationService.initilise(context, getNotificationAlerts);
  }

  @override
  Widget build(BuildContext context) {
    startNotifications(context);

    final user = Provider.of<User>(context);
    getIfBusinessAccount(user?.uid);
    getIfContentAvailable(user?.uid);
    getInitialLanguage();

    if (user != null) {
      if (user.isAnonymous || user.isEmailVerified || user.isThirdParty) {
        // print("User is anonymous or is verified.");
        return const MapsPage();
      } else {
        // print("User is not anonymous or verified.");
        return const Authenticate();
      }
    } else if (user == null) {
      // print("User is null");
      return const Authenticate();
    } else {
      // print("User is neither null or not null.");
      return const MapsPage();
    }
  }
}
