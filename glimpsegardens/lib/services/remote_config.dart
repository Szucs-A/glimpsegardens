import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigInit {
  static RemoteConfig remoteConfig;

  static Future<bool> initRemoteConfig() async {
    // ignore: await_only_futures
    remoteConfig = await RemoteConfig.instance;

    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      minimumFetchInterval: const Duration(hours: 3),
      fetchTimeout: const Duration(seconds: 10),
    ));

    await remoteConfig.fetchAndActivate();
    return true;
  }
}
