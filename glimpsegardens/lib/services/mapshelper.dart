import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:glimpsegardens/models/answerpin.dart';
import 'package:glimpsegardens/models/videopin.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:glimpsegardens/services/push_notification_service.dart';
import 'package:glimpsegardens/services/camera/display_picture_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glimpsegardens/screens/maps.dart';
import 'package:glimpsegardens/models/favorite_object.dart';
import 'package:glimpsegardens/services/remote_config.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:location/location.dart';
import 'package:flutter/services.dart';

class MapsHelper {
  // ignore: prefer_collection_literals
  static Set<DocumentSnapshot> currentDeadZones = Set<DocumentSnapshot>();

  static Uint8List pinLocationIcon8List;
  static Uint8List pinVideoIcon8List;
  static BitmapDescriptor pinLocationIcon;
  static BitmapDescriptor pinVideoIcon;
  static User user;
  static String message = "Hello!";
  static int maxSize = 100; // every 2 minutes is a tick off
  static int minSize = 20;
  static String documentUserId = "";
  static String customInt8Str = "";
  static String customName = "";
  static String codeString = "";
  static double codeRadius = -1;
  static CodeType codeType;

  static void setUserId() async {
    // ignore: await_only_futures
    user = await FirebaseAuth.instance.currentUser;
    String email = user.email;

    if (email != null) {
      QuerySnapshot querySnapshot = await DatabaseService()
          .userCollection
          .where('email', isEqualTo: email)
          .get();
      if (querySnapshot.docs.length > 1) {
        // Do Nothing.
      } else {
        for (var v in querySnapshot.docs) {
          documentUserId = v.id;
        }
      }
    }
  }

  static int getCustomSizeZoom(double zoom) {
    int zoomSize = (pow(2, zoom.toInt())) ~/ 1000;
    // Closest zoom is 21 -> Right to MaxSize
    // Farthest Zoom is 2 -> Right to 8

    if (zoomSize > maxSize) {
      zoomSize = maxSize;
    }

    if (zoomSize < minSize) {
      zoomSize = minSize;
    }

    return zoomSize;
  }

  static int getCustomSize(int cleanTime, double zoom) {
    int zoomSize = (zoom.toInt() * (zoom.toInt()));
    // Closest zoom is 21 -> Right to MaxSize
    // Farthest Zoom is 2 -> Right to 8

    if (zoomSize > maxSize) {
      zoomSize = maxSize;
    }

    if (zoomSize < minSize) {
      zoomSize = minSize;
    }

    int halfTime = cleanTime ~/ 2; // Every 2 minutes a tick is off.
    int newSize =
        zoomSize - halfTime; // If 59 minutes old - then it is size 61.

    if (newSize < minSize) newSize = minSize;

    return newSize;
  }

  static String getCustomInt8() {
    return customInt8Str;
  }

  static String getCustomName() {
    return customName;
  }

  static String getCodeString() {
    return codeString;
  }

  static double getCodeRadius() {
    return codeRadius;
  }

  static CodeType getCodeType() {
    return codeType;
  }

  static void setCustomInt8(String list) {
    customInt8Str = list;
  }

  static void setCodeString(String code) {
    codeString = code;
  }

  static void setCodeRadius(double radius) {
    codeRadius = radius;
  }

  static void setCustomName(String name) {
    customName = name;
  }

  static void setCodeType(CodeType type) {
    codeType = type;
  }

  static Future<DocumentSnapshot> getEmployeePinDoc(
      DocumentSnapshot parent, String enteredCode) async {
    int prime = int.parse(parent['second']);
    int minimum = 10000000 ~/ prime;
    minimum++;

    String full = enteredCode.split('-')[2] + enteredCode.split('-')[3];
    int parentMultiple = int.parse(full);
    parentMultiple = parentMultiple ~/ prime;
    parentMultiple -= minimum;

    CollectionReference pinsCollection = parent.reference
        .collection("Event Info")
        .doc("Info")
        .collection("Pins");
    QuerySnapshot pinsReference = await pinsCollection.get();

    var pinsEmployeeNumbers = List<int>.filled(pinsReference.docs.length, 0);
    var pinsDocuments =
        List<DocumentSnapshot>.filled(pinsReference.docs.length, null);

    for (DocumentSnapshot pinDoc in pinsReference.docs) {
      String pinName = pinDoc.id;
      int pinNumber = int.parse(pinName.split("Pin")[1]);

      pinsEmployeeNumbers[pinNumber] = pinDoc['EmployeeCodes'];
      pinsDocuments[pinNumber] = pinDoc;
    }

    // Find out which Pin.
    int minRollingCarry = 0;
    int maxRollingCarry = 0;

    for (int i = 0; i < pinsReference.docs.length; i++) {
      minRollingCarry = maxRollingCarry;
      maxRollingCarry += pinsEmployeeNumbers[i];

      if (parentMultiple >= minRollingCarry &&
          parentMultiple < maxRollingCarry) {
        return pinsDocuments[i];
      }
    }

    return null;
  }

  static Future<bool> gatherCodeMaterials(
      DocumentSnapshot codeSnap, CodeType type, String enteredCode) async {
    setCodeType(type);
    setCodeString(codeSnap.id);
    if (type != CodeType.employee) return true;

    DocumentSnapshot pinDocument =
        await getEmployeePinDoc(codeSnap, enteredCode);

    if (customInt8Str != "" && customName != "" && codeString != "") {
      return false;
    }
    Map<String, dynamic> tester = pinDocument.data();
    if (tester.containsKey("Department") && pinDocument['Department'] != "") {
      setCustomName(pinDocument['Department']);
    }

    if (!tester.containsKey("Georadius") ||
        pinDocument['Georadius'] == "None") {
      setCodeRadius(-1);
    } else {
      setCodeRadius(pinDocument['Georadius'].toDouble());
    }

    setCustomInt8(pinDocument['Img']);

    return true;
  }

  static void removeCodeMaterials() {
    customInt8Str = "";
    customName = "";
    codeString = "";
    codeRadius = -1;
    codeType = null;
  }

  static Future<BitmapDescriptor> setCustomMapPinUnanswered(
      int cleanTime, double zoom, String customInt8Str) async {
    if (customInt8Str != null) {
      final Uint8List imageData =
          (await NetworkAssetBundle(Uri.parse(customInt8Str))
                  .load(customInt8Str))
              .buffer
              .asUint8List();

      return setCustom8(cleanTime, zoom, imageData);
    } else {
      String drawable = 'assets/drawable/unanswered.png';

      final Uint8List markerIcon =
          await getBytesFromAsset(drawable, getCustomSize(cleanTime, zoom));
      return BitmapDescriptor.fromBytes(markerIcon);
    }
  }

  static Future<BitmapDescriptor> setCustomMapPinAnswered(
      int cleanTime, double zoom, bool poll, String customInt8Str) async {
    if (customInt8Str != null) {
      final Uint8List imageData =
          (await NetworkAssetBundle(Uri.parse(customInt8Str))
                  .load(customInt8Str))
              .buffer
              .asUint8List();

      return setCustom8(cleanTime, zoom, imageData);
    } else {
      if (poll) {
        String drawable = 'assets/drawable/Polling-location-Pin.png';

        final Uint8List markerIcon =
            await getBytesFromAsset(drawable, getCustomSize(cleanTime, zoom));
        return BitmapDescriptor.fromBytes(markerIcon);
      } else {
        String drawable = 'assets/drawable/answered.png';

        final Uint8List markerIcon =
            await getBytesFromAsset(drawable, getCustomSize(cleanTime, zoom));
        return BitmapDescriptor.fromBytes(markerIcon);
      }
    }
  }

  static Future<BitmapDescriptor> setCustom8(
      int cleanTime, double zoom, Uint8List int8) async {
    final Uint8List markerIcon =
        await getBytesFromNetwork(int8, getCustomSize(cleanTime, zoom));
    return BitmapDescriptor.fromBytes(markerIcon);
  }

  static Future<Uint8List> getBytesFromNetwork(
      Uint8List image8List, int width) async {
    ui.Codec codec =
        await ui.instantiateImageCodec(image8List, targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);

    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  // This should just jump as soon as it recognizes where you are.
  static Future<Position> getCurrentLocation() async {
    Position res;
    try {
      // res = await Geolocator.getCurrentPosition(timeLimit: Duration(seconds: 8));
      Location location = Location();
      LocationData _locationData;
      _locationData = await location.getLocation();
      res = Position(
          latitude: _locationData.latitude,
          longitude: _locationData.longitude,
          speed: _locationData.speed,
          accuracy: _locationData.accuracy,
          heading: _locationData.heading,
          timestamp:
              DateTime.fromMillisecondsSinceEpoch(_locationData.time.toInt()),
          speedAccuracy: _locationData.speedAccuracy,
          altitude: _locationData.altitude);
      return res;
    } catch (error) {
      return null;
    }
  }

  static Future<bool> createVideoMarker(String urld, bool isVideo, int pintype,
      DateTime endTime, List<StatefulDragArea> tags) async {
    if (user == null) {
      // ignore: await_only_futures
      await setUserId();
    }

    if (ConstantsClass.businessAccount) {
      businessPost ap = businessPost(
        datePosted: DateTime.now().toIso8601String(),
        url: urld,
        isVideo: isVideo,
        likes: 0,
        likesUids: "",
        description: MapsHelper.message,
        expiryDate: endTime == null ? "" : endTime.toIso8601String(),
      );

      DocumentReference dr = firestore
          .collection('businesses')
          .doc("" + user.uid)
          .collection('posts')
          .doc();

      await firestore.runTransaction((Transaction tx) {
        tx.set(dr, ap.toJson());
        return;
      });

      await firestore.runTransaction((Transaction tx) {
        tx.update(firestore.collection('businesses').doc("" + user.uid),
            {'newPost': DateTime.now().toIso8601String()});
        return;
      });

      CollectionReference cr = dr.collection("tags");
      for (int i = 0; i < tags.length; i++) {
        tagPost tp = tagPost(
            message: tags[i].message,
            positionx: tags[i].positionx,
            positiony: tags[i].positiony);

        await firestore.runTransaction((Transaction tx) {
          tx.set(cr.doc(), tp.toJson());
          return;
        });
      }

      return true;
    } else {
      Position pos = await getCurrentLocation();

      for (DocumentSnapshot deadzone in currentDeadZones) {
        if (pointInCircle(
            pos.latitude,
            pos.longitude,
            deadzone['lat'].toDouble(),
            deadzone['long'].toDouble(),
            deadzone['meters'].toDouble())) {
          return false;
        }
      }

      LatLng where = LatLng(pos.latitude, pos.longitude);
      String myVideoToken = await PushNotificationService.getDeviceToken();

      if (MapsPage.answering) {
        AnswerPin ap = AnswerPin(
          email: user.email,
          time: DateTime.now().toIso8601String(),
          url: urld,
          userID: user.uid,
          message: MapsHelper.message,
          name: await PreferencesHelper().getFirstName(),
          isVideo: isVideo,
        );

        await firestore.runTransaction((Transaction tx) {
          tx.set(
              firestore
                  .collection('requests')
                  .doc("" + MapsPage.requestID)
                  .collection('answers')
                  .doc(),
              ap.toJson());
          return;
        });

        DocumentSnapshot doc = await DatabaseService()
            .requestsCollection
            .doc("" + MapsPage.requestID)
            .get();
        List<dynamic> notifyTokens = doc['followtokens'];

        // Notifying the Person and followers.
        // PushNotificationService.sendNotificationMessage(ownerToken, MapsPage.requestID);

        Map tokenMap = {};
        tokenMap['tokens'] = notifyTokens;
        tokenMap['doc'] = doc;

        MapsPage.answering = false;
        MapsPage.requestID = "";

        tokenMap['server'] =
            RemoteConfigInit.remoteConfig.getString('notificationServerToken');

        int numberOfFollowers = notifyTokens.length;
        DatabaseService().userCollection.doc(documentUserId).update(
            {'followersAnswered': FieldValue.increment(numberOfFollowers)});

        compute(sendFollowersNotifications, tokenMap);
      } else {
        var a = await Favorite.getInformation(where);

        VideoPin vp = VideoPin(
          email: user.email,
          latitude: where.latitude,
          longitude: where.longitude,
          message: MapsHelper.message,
          time: DateTime.now().toIso8601String(),
          url: urld,
          userid: user.uid,
          likes: 0,
          city: a.locality,
          country: a.countryName,
          isVideo: isVideo,
          myToken: myVideoToken,
          likedAccounts: null,
          pinUrl: customInt8Str,
          name: customName,
          type: pintype,
          codeSnippet: MapsHelper.getCodeString() == ""
              ? ""
              : MapsHelper.getCodeString(),
          radius: MapsHelper.getCodeRadius(),
          endTime: endTime == null ? "" : endTime.toIso8601String(),
        );

        firestore.runTransaction((Transaction tx) async {
          DatabaseService()
              .videoCollection
              .add(vp.toJson())
              .catchError((e) {})
              .whenComplete(() {});
        });
      }
      message = "Hello!";
      return true;
    }
  }

  static bool withinBounds(LatLng low, LatLng high, LatLng position) {
    if (position.longitude < high.longitude &&
        position.longitude > low.longitude) {
      return true;
    }

    return false;
  }

  static bool pointInCircle(
      double xp, double yp, double xc, double yc, double r) {
    // Geolocator package has the distanceBetween method
    double distanceInMeters =
        GeolocatorPlatform.instance.distanceBetween(xp, yp, xc, yc);

    if (distanceInMeters <= r) {
      return true;
    }

    return false;
  }
}

/// Dart Doc Test.
///
/// {@category Amazing}
Future<int> sendFollowersNotifications(Map tokenMap) async {
  DocumentSnapshot element = tokenMap['doc'];
  List<dynamic> tokens = tokenMap['tokens'];
  String server = tokenMap['server'];

  // Put this on a different Thread.
  for (var v in tokens) {
    await PushNotificationService.sendFollowerNotificationMessage(
        v.toString(), element.id, server);
  }

  return tokens.length;
}
