import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:glimpsegardens/screens/maps.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:glimpsegardens/services/remote_config.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PushNotificationService {
  static final FirebaseMessaging fcm = FirebaseMessaging.instance;

  static final psh = PushNotificationService();

  static StreamSubscription<RemoteMessage> onMessageListener;
  static StreamSubscription<RemoteMessage> onBackgroundMessage;
  static StreamSubscription<RemoteMessage> onMessageOpenedApp;

  static Future initilise(BuildContext context, bool notificationsOn) async {
    if (notificationsOn != null && !notificationsOn) {
      onMessageListener?.cancel();
      onBackgroundMessage?.cancel();
      onMessageOpenedApp?.cancel();
      return;
    }

    if (Platform.isIOS) {
      fcm.requestPermission(
          sound: true, badge: true, alert: true, provisional: false);
    }

    onMessageListener =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      psh.showItemDialog(message, context);
    });

    onMessageOpenedApp =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      psh._navigateToItemDetail(message, context);
    });
  }

  Future<DocumentSnapshot> getDetailsFromId(String id) async {
    DocumentSnapshot reff;
    await DatabaseService().requestsCollection.doc(id).get().then((ref) {
      if (ref.exists) {
        reff = ref;
      }
    });

    await DatabaseService().videoCollection.doc(id).get().then((ref) {
      if (ref.exists) {
        reff = ref;
      }
    });

    await DatabaseService().businessCollection.doc(id).get().then((ref) {
      if (ref.exists) {
        reff = ref;
      }
    });

    return reff;
  }

  void _navigateToItemDetail(
      RemoteMessage message, BuildContext context) async {
    DocumentSnapshot ref;
    if (Platform.isAndroid) {
      ref = await getDetailsFromId(message.data['id']);
    } else {
      ref = await getDetailsFromId(message.data['id']);
    }
    MapsPage.notificationRef = ref;

    // Clear away dialogs
    Route route = MaterialPageRoute(builder: (context) => MapsPage());
    Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
    if (!route.isCurrent) {
      Navigator.push(context, route);
    }
  }

  void showItemDialog(RemoteMessage message, BuildContext context) {
    if (Platform.isAndroid) {
      Fluttertoast.showToast(
          msg: message.notification.title.toString() +
              ": " +
              message.notification.body.toString());
    } else {
      Fluttertoast.showToast(
          msg: message.notification.title.toString() +
              ": " +
              message.notification.body.toString());
    }
  }

  // Remove the notification property in DATA to send a data message.
  static sendNotificationMessage(String token, String requestId) async {
    String serverToken =
        RemoteConfigInit.remoteConfig.getString('notificationServerToken');
    Uri whereToSend = Uri.parse("https://fcm.googleapis.com/fcm/send");
    await http.post(
      whereToSend,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'A generous user has answered your pin with a video!',
            'title': 'Hello from Glimpse!'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': requestId,
          },
          'to': token,
        },
      ),
    );
  }

  static sendNotificationMessageBusiness(
      String token, String businessId, String serverToken) async {
    Uri whereToSend = Uri.parse("https://fcm.googleapis.com/fcm/send");
    await http.post(
      whereToSend,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'A business you follow has uploaded new content!',
            'title': 'Hello from Glimpse!'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': businessId,
          },
          'to': token,
        },
      ),
    );
  }

  static sendFollowerNotificationMessage(
      String token, String requestId, String serverToken) async {
    Uri whereToSend = Uri.parse("https://fcm.googleapis.com/fcm/send");
    await http.post(
      whereToSend,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'A generous user has answered your pin with a video!',
            'title': 'Hello from Glimpse!'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': requestId,
          },
          'to': token,
        },
      ),
    );
  }

  static sendBusinessOwnerFollowerNotification(
      String token, String requestId) async {
    String serverToken =
        RemoteConfigInit.remoteConfig.getString('notificationServerToken');
    Uri whereToSend = Uri.parse("https://fcm.googleapis.com/fcm/send");
    await http.post(
      whereToSend,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'Someone has followed your business!',
            'title': 'Hello from Glimpse!'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': requestId,
          },
          'to': token,
        },
      ),
    );
  }

  static sendBusinessOwnerLikeNotification(
      String token, String requestId) async {
    String serverToken =
        RemoteConfigInit.remoteConfig.getString('notificationServerToken');
    Uri whereToSend = Uri.parse("https://fcm.googleapis.com/fcm/send");
    await http.post(
      whereToSend,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'Someone has liked your content!',
            'title': 'Hello from Glimpse!'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': requestId,
          },
          'to': token,
        },
      ),
    );
  }

  static sendOwnerFollowerNotification(String token, String requestId) async {
    String serverToken =
        RemoteConfigInit.remoteConfig.getString('notificationServerToken');
    Uri whereToSend = Uri.parse("https://fcm.googleapis.com/fcm/send");
    await http.post(
      whereToSend,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'Someone has followed your request!',
            'title': 'Hello from Glimpse!'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': requestId,
          },
          'to': token,
        },
      ),
    );
  }

  static sendLikedMessage(String token, String requestId) async {
    String serverToken =
        RemoteConfigInit.remoteConfig.getString('notificationServerToken');
    Uri whereToSend = Uri.parse("https://fcm.googleapis.com/fcm/send");
    await http.post(
      whereToSend,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'Someone liked your request!',
            'title': 'Hello from Glimpse!'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': requestId,
          },
          'to': token,
        },
      ),
    );
  }

  static Future<String> getDeviceToken() async {
    String fcmToken = await fcm.getToken();

    if (fcmToken != null) {
      return fcmToken;
    } else {
      return "failed.";
    }
  }
}
