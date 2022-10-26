// Copyright © 2020 Glimpse Social Inc. All rights reserved.
// Used for <Future> type.
import 'dart:async';

// Import for plugin package.
import 'package:shared_preferences/shared_preferences.dart';

/// This class is an access point for persistent storage for simple data.
///
/// All getters and setters are handled inside the [PreferencesHelper] class along with a
/// scoped variable that refreshes itself every call: [_prefs].
///
/// Must not be trusted for critical user data.
///
/// Link to the package: https://pub.dev/packages/shared_preferences.
/// {@category Interface}
class PreferencesHelper {
  /// This member is a shared access point among all getters and setters in [PreferencesHelper].
  SharedPreferences _prefs;

  /// Saves [name] string-value to [_prefs] key 'firstName'.
  ///
  /// Returns a boolean- true if [_prefs] is properly set and false if there is some error.
  /// Used in [Settings] and [Authentication] classes.
  Future<bool> setFirstName(String name) async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.setString('firstName', name);
  }

  /// Gets [_prefs] to return a string from key 'firstName'.
  ///
  /// Returns a string that is the first name of the user.
  /// Used in [Settings] classes.
  Future<String> getFirstName() async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getString('firstName');
  }

  /// Saves [uid] string-value to [_prefs] key 'uid'.
  ///
  /// Returns a boolean- true if [_prefs] is properly set and false if there is some error.
  /// Used in [Authentication] classes.
  Future<bool> setUid(String uid) async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.setString('uid', uid);
  }

  /// Gets [_prefs] to return a string from key 'uid'.
  ///
  /// Returns a string that is the uid of the current user.
  /// Used in [Settings] classes.
  Future<String> getUid() async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getString('uid');
  }

  /// Gets [_prefs] to return a list of strings(blocked users) from key 'blockedUsers'.
  ///
  /// Returns a list of strings that are emails of blocked users.
  /// Used in [Maps], [Authentication] and [Settings] classes.
  Future<List<String>> getBlockedUsers() async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    // If the list is null then it sends an empty array.
    return _prefs.getStringList('blockedUsers') ?? [];
  }

  /// Saves [blockedUsers] list-string-value to [_prefs] key 'blockedUsers'.
  ///
  /// [blockedUsers] represent emails of users.
  /// Returns a boolean- true if [_prefs] is properly set and false if there is some error.
  /// Used in [Maps], [Settings], and [Authentication] classes.
  Future<bool> setBlockedUsers(List<String> blockedUsers) async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.setStringList('blockedUsers', blockedUsers);
  }

  /// Gets [_prefs] to return a boolean from key 'finishedTutorial'.
  ///
  /// Returns a boolean that represents whether or not the user has clicked the floating tutorial
  /// icon in the [Camera] class.
  /// Used primarily in [Camera] and [Settings] classes.
  Future<bool> getFinishedTutorial() async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool('finishedTutorial');
  }

  /// Saves [finishedTutorial] bool-value to [_prefs] key 'finishedTutorial'.
  ///
  /// Returns a boolean- true if [_prefs] is properly set and false if there is some error.
  /// Used in [Authentication] classes primarily.
  Future<bool> setFinishedTutorial(bool finishedTutorial) async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.setBool('finishedTutorial', finishedTutorial);
  }

  /// Used in [Deprecated] classes.
  Future<bool> setFollowersAnswered(int followersAnswered) async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.setInt('followersAnswered', followersAnswered);
  }

  /// Used in [Deprecated] classes.
  Future<int> getFollowersAnswered() async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getInt('followersAnswered');
  }

  /// Saves [nA] bool-value to [_prefs] key 'notificationAlerts'.
  ///
  /// Returns a boolean- true if [_prefs] is properly set and false if there is some error.
  /// Used primarily in [Settings] classes as it controls all notifications going through the app.
  Future<bool> setNotificationAlerts(bool nA) async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.setBool('notificationAlerts', nA);
  }

  /// Gets [_prefs] to return a boolean from key 'notificationAlerts'.
  ///
  /// Returns a string that determines whether or not notifications should be received from this user.
  /// Used in [Settings] classes primarily.
  Future<bool> getNotificationAlerts() async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool('notificationAlerts');
  }

  /// Saves [en] boolean-value to [_prefs] key 'isEnglish'.
  ///
  /// Returns a boolean- true if [_prefs] is properly set and false if there is some error.
  /// This preference controls the language in the app.
  /// Used primarily in [Settings] classes.
  Future<bool> setLanguage(String lan) async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.setString('currentLanguage', lan);
  }

  /// Gets [_prefs] to return a boolean from key 'isEnglish'.
  ///
  /// Returns a boolean that controls the language of the app.
  /// Used everywhere.
  Future<String> getLanguage() async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getString('currentLanguage');
  }

  /// Gets [_prefs] to return a list of strings from key 'MarkedBusinesses'.
  ///
  /// Returns a list of strings that are the businesses documentid values.
  /// Marked Businesses are the businesses that are marked for new content with the red circle.
  /// Used in [Maps] classes.
  Future<List<String>> getMarkedBusinesses() async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getStringList('MarkedBusinesses');
  }

  /// Saves [marked] list-string-value to [_prefs] key 'MarkedBusinesses'.
  ///
  /// Marked Businesses are the businesses that are marked for new content with the red circle.
  /// Returns a boolean- true if [_prefs] is properly set and false if there is some error.
  /// Used in [Maps] classes.
  Future<bool> setMarkedBusinesses(List<String> marked) async {
    // Obtain shared preferences.
    _prefs = await SharedPreferences.getInstance();
    return _prefs.setStringList('MarkedBusinesses', marked);
  }
}
