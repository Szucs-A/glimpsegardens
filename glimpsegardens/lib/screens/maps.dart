// ignore_for_file: prefer_collection_literals, non_constant_identifier_names, constant_identifier_names, avoid_function_literals_in_foreach_calls, await_only_futures, sized_box_for_whitespace, avoid_unnecessary_containers

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/screens/settings/searchSettingsPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/BusinessPage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glimpsegardens/screens/settings/settings.dart' as glimpse;
import 'package:glimpsegardens/models/SideBar.dart';
import 'package:path/path.dart' as Path;
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as Poly;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_webservice/places.dart' as loco;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:glimpsegardens/services/mapshelper.dart';
import 'package:glimpsegardens/services/push_notification_service.dart';
import 'package:glimpsegardens/services/favorite_object.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'dart:io' show Platform;
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:glimpsegardens/services/camera/camera.dart';
import 'package:glimpsegardens/models/request.dart';
import 'package:glimpsegardens/services/remote_config.dart';
import 'package:glimpsegardens/models/messageitem.dart';
import 'package:glimpsegardens/models/requestmodel.dart';
import 'package:glimpsegardens/models/videomodal.dart';
import 'package:glimpsegardens/screens/loading.dart';
import 'package:glimpsegardens/screens/errorscreen.dart';
import 'package:googleapis/civicinfo/v2.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:geocoder/geocoder.dart';
import 'dart:core';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:glimpsegardens/models/business.dart';

class MapsPage extends StatefulWidget {
  static bool answering = false;
  static String requestID = "";
  static bool comingFromUserPage = false;
  static LatLng comingFromUserPageLat;
  static DocumentSnapshot notificationRef;
  static Timer repeatingPositionTimer;
  static bool hasRunRequest = false;
  static bool hasReturnedFromRequest = false;
  static bool resetInitialPosition = false;

  static bool comingFromBusinessPage = false;
  static String comingFromBusinessPageResponse = '';
  static String comingFromBusinessPageLat = "";
  static String comingFromBusinessPageLong = "";

  const MapsPage({Key key}) : super(key: key);

  static void cancelRepeatingPositionTimer() {
    MapsPage.repeatingPositionTimer?.cancel();
    MapsPage.repeatingPositionTimer = null;
  }

  @override
  _MapsPage createState() => _MapsPage();
}

class _MapsPage extends State<MapsPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Points to Toronto
  Position _initialUserPosition;
  Position repeatingUserPosition;
  GoogleMapController mapController;
  Map<String, Marker> allMarkers = Map<String, Marker>();
  List<Marker> businessMarkers = [];
  Map<String, Marker> newMarkers = Map<String, Marker>();
  Map<String, Marker> pollMarkers = Map<String, Marker>();
  Set<Marker> mapMarkers = Set();
  List<DocumentSnapshot> toDeleteRequest = [];
  List<DocumentSnapshot> toDeleteVideos = [];
  final AuthService _auth = AuthService();

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
      super.setState(setStateMap);
    }
  }

  LatLng lastTappedLocation;

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  final Color glimpseOrange = const Color(0xFFFFA600);
  final Color glimpseOrangeSecondary = const Color(0xFFFFB62E);

  int minutesToDeletion = 60;

  String userName;
  String uid;
  String deviceToken;
  String interstitialAdId;

  bool centerFailed = false;
  DateTime now;

  LatLngBounds googleMapsBounds;
  double googleMapsZoom;
  GoogleMap map;
  bool launchedPopUp = false;

  int proximityInMeters = 500;

  // ignore: unused_field
  static String googleApiKey = ""; // do not delete
  static String placesApiKey = "";
  loco.GoogleMapsPlaces _places;

  Set<Circle> activeDeadZones = Set<Circle>();

  static bool userInDeadZone = false;

  Future myFuture;

  DirectionsResult _info;

// TODO:
  static const String API_KEY =
      "Zd9H1UHSMlmjHla1GT3_DPMLHCN-LsBMxQV5gQfWJRuMiKAGAcMaSTwLoBeosNznXX3enJvsaOba8EjF1wjAnMlIqdSC_T1yYq5ZtwmwB7rKAJ8JA3a2Kq8Lt7iNYnYx";
  static const Map<String, String> AUTH_HEADER = {
    "Authorization": "Bearer $API_KEY"
  };

  int CODE_OK = 200;
  int CODE_REDIRECTION = 300;
  int CODE_NOT_FOUND = 404;

  Future<List<Business>> getBusinesses() async {
    // (43.472941, -80.535592)
    String webAddress =
        "https://api.yelp.com/v3/businesses/search?latitude=43.472941&longitude=-80.535592";

    http.Response response = await http
        .get(Uri.parse(webAddress), headers: AUTH_HEADER)
        .catchError((resp) {});

    // Error handling
    if (response == null ||
        response.statusCode < CODE_OK ||
        response.statusCode >= CODE_REDIRECTION) {
      return Future.error(response.body);
    }

    Map<String, dynamic> map = json.decode(response.body);

    Iterable jsonList = map["businesses"];
    List<Business> businesses =
        jsonList.map((model) => Business.fromJson(model)).toList();

    debugPrint(jsonList.toString());

    return businesses;
  }

  void DirectionsMockTest() async {
    if (!MapsPage.comingFromBusinessPage) {
      return;
    }

    Position currentLocation = await MapsHelper.getCurrentLocation();

    DirectionsService.init('AIzaSyB6KIClUhFzMgQQvWcoVFQsAsO9Lpy9m4g');
    TODO:
    final directionsService = DirectionsService();

    TravelMode mode;

    if (MapsPage.comingFromBusinessPageResponse == currentLanguage[207]) {
      mode = TravelMode.driving;
    } else if (MapsPage.comingFromBusinessPageResponse ==
        currentLanguage[208]) {
      mode = TravelMode.walking;
    } else if (MapsPage.comingFromBusinessPageResponse ==
        currentLanguage[209]) {
      mode = TravelMode.bicycling;
    } else if (MapsPage.comingFromBusinessPageResponse ==
        currentLanguage[210]) {
      mode = TravelMode.transit;
    } else {
      MapsPage.comingFromBusinessPage = false;
      MapsPage.comingFromBusinessPageResponse = '';
      MapsPage.comingFromBusinessPageLat = "";
      MapsPage.comingFromBusinessPageLong = "";
      return;
    }

    final request = DirectionsRequest(
      origin: currentLocation.latitude.toString() +
          "," +
          currentLocation.longitude.toString(),
      destination: MapsPage.comingFromBusinessPageLat +
          "," +
          MapsPage.comingFromBusinessPageLong,
      travelMode: mode,
    );

    directionsService.route(
      request,
      (DirectionsResult response, DirectionsStatus status) {
        if (status == DirectionsStatus.ok) {
          // do something with successful response
          setState(() {
            _info = response;
          });

          LatLng southwest = LatLng(
              _info.routes.first.bounds.southwest.latitude,
              _info.routes.first.bounds.southwest.longitude);

          LatLng northeast = LatLng(
              _info.routes.first.bounds.northeast.latitude,
              _info.routes.first.bounds.northeast.longitude);

          mapController.animateCamera(CameraUpdate.newLatLngBounds(
              LatLngBounds(southwest: southwest, northeast: northeast), 100.0));
        } else {
          // do something with error response
        }

        // Json routes->legs-> distance, duration and bounds.
      },
    );

    MapsPage.comingFromBusinessPage = false;
    MapsPage.comingFromBusinessPageResponse = '';
    MapsPage.comingFromBusinessPageLat = "";
    MapsPage.comingFromBusinessPageLong = "";
  }

  @override
  void initState() {
    super.initState();

    _getUserName(); // No User Location

    getProximityUpdate(); // No User Location

    loadPlacesAPI(); // No User Location

    // load all secure data
    loadSecureData(); // No User Location

    WidgetsBinding.instance.addObserver(this);
  }

  showLegend(BuildContext context) {
    Widget okButton = TextButton(
      style: loginPageButtonStyle,
      child: Text(currentLanguage[13],
          style: const TextStyle(fontFamily: 'Arial')),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      content:
          /* INSIDE THE COLUMN */
          Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15),
          Text(currentLanguage[40],
              style: const TextStyle(
                  fontFamily: 'Arial',
                  color: headers,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 15),
          ShelfItem(SideBarItem("Bar", "Bar"),
              SideBarItem(currentLanguage[51], "Beauty")),
          const SizedBox(height: 10),
          ShelfItem(SideBarItem(currentLanguage[42], "Coffee"),
              SideBarItem(currentLanguage[43], "Grocery")),
          const SizedBox(height: 10),
          ShelfItem(SideBarItem(currentLanguage[48], "Gym"),
              SideBarItem(currentLanguage[45], "Health")),
          const SizedBox(height: 10),
          ShelfItem(SideBarItem(currentLanguage[50], "Hotel"),
              SideBarItem(currentLanguage[47], "Restaurant")),
          const SizedBox(height: 10),
          ShelfItem(SideBarItem(currentLanguage[44], "Shopping"),
              SideBarItem(currentLanguage[46], "Theatre")),
          const SizedBox(height: 10),
          ShelfItem(SideBarItem(currentLanguage[49], "Tour"),
              SideBarItem("Service", "Services")),
          const SizedBox(height: 10),
          ShelfItem(SideBarItem(currentLanguage[250], "All"), null),
        ],
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0))),
      actions: <Widget>[okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    ).then((value) => gettingAllPins());
  }

  void getInitialPosition() async {
    if (MapsPage.resetInitialPosition) {
      _initialUserPosition = null;
      map = null;
      MapsPage.resetInitialPosition = false;
    }

    if (_initialUserPosition != null) {
      return;
    }

    // print("Running Initial Position");
    var status = await Permission.location.isGranted;
    if (!status) {
      centerFailed = true;
      return;
    }
    final center = await MapsHelper.getCurrentLocation();
    //final center = null;
    if (center == null) {
      // Throw a dialogue box and maybe log out.
      centerFailed = true;
      showLocationFailedDialogue(context);
    } else {
      _initialUserPosition = center;
      repeatingUserPosition = center;

      await getDeadZones(center).then((circles) {
        activeDeadZones = circles;
        if (MapsPage.repeatingPositionTimer == null) {
          const oneMin = Duration(seconds: 30);

          MapsPage.repeatingPositionTimer =
              Timer.periodic(oneMin, (Timer t) => {getRepeatingPosition()});
        }
      });
      LatLng cameraPos =
          LatLng(_initialUserPosition.latitude, _initialUserPosition.longitude);

      setState(() {
        map = GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: cameraPos,
              zoom: 15.0,
            ),
            markers: mapMarkers,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            onTap: mapTapped,
            circles: activeDeadZones,
            compassEnabled: true,
            myLocationEnabled: true,
            onCameraMove: (CameraPosition cameraPosition) {
              if (mapController != null) {
                mapController.getVisibleRegion().then((value) {
                  // print("googleMapsBounds Changed.");
                  googleMapsBounds = value;
                });
                mapController.getZoomLevel().then((value) {
                  googleMapsZoom = value;
                });
              }
            },
            onCameraIdle: () {
              // This could also be used to help gather pins
              // Get Pins.
              gettingAllPins();

              // whatCityIsOnTheScreen(googleMapsBounds);
            },
            padding: const EdgeInsets.only(
              top: 40.0,
            ));
      });
    }
  }

  void getRepeatingPosition() async {
    final center = await MapsHelper.getCurrentLocation();
    if (center == null) {
      showLocationFailedDialogue(context);
    } else {
      repeatingUserPosition = center;
      getDeadZones(center).then((circles) {
        setState(() {
          activeDeadZones = circles;
          if (userInDeadZone) {
            // print("User is in deadzone.");
          } else {
            // print("User is not in deadzone.");
          }
        });
      });
    }
  }

  void getPollingLocations() async {
    if (pollMarkers.isNotEmpty) return;

    // Check if in America and Americanized.
    return;
  }

  showLocationFailedDialogue(BuildContext context) async {
    Widget signoutButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[226]),
      onPressed: () async {
        Navigator.pop(context);
        // PERFORM LOGOUT
        await _auth.signOut();
      },
    );

    Widget appSettingsButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[221]),
      onPressed: () async {
        await openAppSettings();
        // PERFORM LOGOUT
        Navigator.pop(context);
        await _auth.signOut();
      },
    );

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                title: Text(
                  currentLanguage[124],
                  textAlign: TextAlign.center,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(currentLanguage[125]),
                  ],
                ),
                actions: <Widget>[
                  signoutButton,
                  appSettingsButton,
                ],
              ));
        });
  }

  void getProximityUpdate() {
    proximityInMeters =
        RemoteConfigInit.remoteConfig.getInt('proximityMetersToAnswer');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> resumeTestActiveCode() async {
    DocumentSnapshot user =
        await DatabaseService().userCollection.doc(uid).get();
    Map<String, dynamic> tester = user.data();
    if (!tester.containsKey("currentParent") || user['currentParent'] == "") {
      return true;
    }

    DocumentSnapshot codeSnapshot = await DatabaseService()
        .codesCollection
        .doc(user['currentParent'])
        .get();

    CodeType type = convertIndexToCodeType(user['currentCodeType']);

    testCodeLinkedToAccount(codeSnapshot, uid, type);

    const oneMin = Duration(minutes: 1);
    // codeTimer is in Constants.dart
    if (codeTimer != null && codeTimer.isActive) codeTimer.cancel();
    codeTimer = Timer.periodic(
        oneMin, (Timer t) => testCodeLinkedToAccount(codeSnapshot, uid, type));

    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        resumeTestActiveCode();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        if (codeTimer != null && codeTimer.isActive) codeTimer.cancel();

        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  // Loads the ad id + reporting email and password
  void loadSecureData() {
    if (Platform.isAndroid) {
      interstitialAdId =
          RemoteConfigInit.remoteConfig.getString('androidInterstitialAdId');
    } else {
      interstitialAdId =
          RemoteConfigInit.remoteConfig.getString('iOSInterstitialAdId');
    }
  }

  void loadPlacesAPI() {
    placesApiKey = RemoteConfigInit.remoteConfig.getString('placesAPI');
  }

  Future _getUserName() async {
    User user = await FirebaseAuth.instance.currentUser;
    userName = user.email;
    if (user.isAnonymous) {
      userName = "Anonymous";
    }

    uid = user.uid;
    deviceToken = await PushNotificationService.getDeviceToken();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    allMarkers.clear();
    mapMarkers.clear();

    if (mapController != null) {
      controller.setMapStyle(mapStyle);
      mapController.getVisibleRegion().then((value) {
        googleMapsBounds = value;
      });
      mapController.getZoomLevel().then((value) {
        googleMapsZoom = value;
      });
    }

    // Calling refresh in order to travel to the user's location upon loadup.
    refresh();
  }

  void refresh() async {
    await getPollingLocations();

    gettingAllPins();

    now = DateTime.now();

    _places = loco.GoogleMapsPlaces(apiKey: placesApiKey);

    if (MapsPage.notificationRef != null) {
      LatLng lat = LatLng(MapsPage.notificationRef['latitude'],
          MapsPage.notificationRef['longitude']);
      mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: lat, zoom: 18.0)));
    }
  }

  void getCurrentVideos(List<String> blockList) async {
    if (googleMapsBounds == null) return;

    toDeleteVideos.clear();
    QuerySnapshot snapshot = await DatabaseService()
        .videoCollection
        .where('latitude', isGreaterThan: googleMapsBounds.southwest.latitude)
        .where('latitude', isLessThan: googleMapsBounds.northeast.latitude)
        .get();

    for (var element in snapshot.docs) {
      if (compareEmailsToBlockList(element['email'], blockList) == false) {
        DateTime t = DateTime.tryParse(element['time']);

        var difference = now.difference(t);
        Map<String, dynamic> tester = element.data();
        if (tester.containsKey("endTime") && element["endTime"] != "") {
          DateTime d = DateTime.tryParse(element["endTime"]);
          if (d != null && now.isAfter(d)) {
            toDeleteVideos.add(element);
          } else {
            String t = await documentPinName(element);
            await createCurrentVideo(
              t,
              LatLng(element['latitude'].toDouble(),
                  element['longitude'].toDouble()),
              element['url'],
              element.id,
              element['message'],
              element['likes'],
              element,
              element['isVideo'],
            );
          }
        } else if (difference.inMinutes >= minutesToDeletion) {
          toDeleteVideos.add(element);
        } else {
          String t = await documentPinName(element);
          await createCurrentVideo(
            t,
            LatLng(element['latitude'].toDouble(),
                element['longitude'].toDouble()),
            element['url'],
            element.id,
            element['message'],
            element['likes'],
            element,
            element['isVideo'],
          );
        }
      }
    }

    for (var v in toDeleteVideos) {
      deleteReferenceVideo(v.reference);
    }
  }

  void deleteReferenceVideo(DocumentReference f) async {
    try {
      if (f != null) {
        await firestore.runTransaction((Transaction myTransaction) async {
          myTransaction.delete(f);
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("Failed to delete or run a transaction that attempted to delete.");
    }
  }

  Future<String> documentPinName(DocumentSnapshot element) async {
    Map<String, dynamic> tester = element.data();
    if (tester.containsKey("name") && element['name'] != "") {
      return element['name'];
    }

    return await getVideoUserPin(element['email'].toString());
  }

  Future<String> getVideoUserPin(String email) async {
    QuerySnapshot snapshot = await DatabaseService()
        .userCollection
        .where('email', isEqualTo: email)
        .get();

    String r;

    snapshot.docs.forEach((element) {
      r = element['firstName'].toString();
    });

    return r;
  }

  int getAge(DocumentSnapshot element) {
    DateTime t = DateTime.tryParse(element['time']);

    var difference = now.difference(t);
    return difference.inMinutes.toInt();
  }

  bool compareEmailsToBlockList(String contentEmail, List<String> blockList) {
    for (String s in blockList) {
      if (contentEmail == s) {
        return true;
      }
    }

    return false;
  }

  void clearBlockList() {
    // Add the blocker to the list
    PreferencesHelper().getBlockedUsers().then((blocks) {
      blocks.clear();
      PreferencesHelper().setBlockedUsers(blocks);
    });
  }

  void createCurrentVideo(
      String name,
      LatLng pinPosition,
      String path,
      String id,
      String message,
      int likes,
      DocumentSnapshot video,
      bool isVideo) async {
    Map<String, dynamic> tester = video.data();
    if (tester.containsKey("type")) {
      if (video['type'] == PinType.normal.index) {
        // Continue, everyone can see this
      } else if (video['type'] == PinType.geocached.index) {
        if (!tester.containsKey("radius")) return; // Version Differences

        if (repeatingUserPosition == null) {
          return;
        } // If we don't have the user position yet.

        if (pointInCircle(
            video['latitude'],
            video['longitude'],
            repeatingUserPosition.latitude,
            repeatingUserPosition.longitude,
            video['radius'])) {
          // Continue normally.
        } else {
          return;
        }
      } else {
        if (MapsHelper.getCodeString() != video['codesnippet'] ||
            (MapsHelper.getCodeType() != CodeType.vip &&
                MapsHelper.getCodeType() != CodeType.employee)) {
          return; // Return as you don't have permission to view this pin.
        }
      }
    } else {
      return;
    }

    if (MapsHelper.withinBounds(
        googleMapsBounds.southwest, googleMapsBounds.northeast, pinPosition)) {
      // For version differences, don't display it.
      if (!tester.containsKey("pinUrl")) return;

      BitmapDescriptor bmd = await MapsHelper.setCustomMapPinAnswered(
          getAge(video),
          googleMapsZoom,
          false,
          video['pinUrl'] == ""
              ? null
              : video['pinUrl']); // Does it have a pinUrl that is custom?

      // The MARKERID must be unique. Otherwise, this will not present all the Markers.
      Marker mark = Marker(
        markerId: MarkerId(id),
        position: pinPosition,
        icon: bmd,
        onTap: () {
          mainModalBottomSheetVideo(
              id, path, name, message, likes, video, isVideo);
        },
      );

      allMarkers.putIfAbsent(id, () => mark);
      newMarkers.putIfAbsent(id, () => mark);
    }
  }

  Future<void> searchButtonPressed() async {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) =>
            SearchSettingsPage(googleMapsBounds: googleMapsBounds)));

    // Here we should see if the user position was calculated or not.
    try {
      final center = _initialUserPosition;
      loco.Prediction p = await PlacesAutocomplete.show(
          context: context,
          strictbounds: center == null ? false : true,
          apiKey: placesApiKey,
          mode: Mode.overlay,
          onError: onError,
          language: "en",
          location: center == null
              ? null
              : loco.Location(lat: center.latitude, lng: center.longitude),
          radius: center == null ? null : 5000);

      if (p != null) {
        //FocusScope.of(context).requestFocus(FocusNode());
        //FocusScope.of(context).unfocus();
        moveToPosition(p.placeId);
        // Call the dialog here.
        showRequestSearchDialog(
            context, p.description.split(',')[0], p.placeId);
      }
    } catch (e) {
      print("CHLOE: Prediction Failed.");
    }
  }

  void onError(loco.PlacesAutocompleteResponse response) {
    // ignore: deprecated_member_use
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Future<void> moveToPosition(String placeId) async {
    if (placeId != null) {
      loco.PlacesDetailsResponse place =
          await _places.getDetailsByPlaceId(placeId);

      final location = place.result.geometry.location;
      final lat = location.lat;
      final lng = location.lng;
      final center = LatLng(lat, lng);
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: center == null
              ? const LatLng(0, 0)
              : LatLng(center.latitude, center.longitude),
          zoom: 18.0)));
    }
  }

  @override
  void didChangeDependencies() {
    precacheImage(const AssetImage("assets/drawable/Wumbo.png"), context);
    precacheImage(const AssetImage("assets/drawable/popupimage.png"), context);

    super.didChangeDependencies();
  }

  Future<Set<Circle>> getDeadZones(Position pos) async {
    MapsHelper.currentDeadZones.clear();
    List<DocumentSnapshot> toDeleteZones = [];
    userInDeadZone = false;

    // 1 / 110.574  is roughly one km for LATITUDE AND ONLY LATITUDE
    QuerySnapshot query = await DatabaseService()
        .deadZoneCollection
        .where('lat', isGreaterThan: pos.latitude - 0.1)
        .where('lat', isLessThan: pos.latitude + 0.1)
        .get();

    Set<Circle> circles = Set<Circle>();
    for (DocumentSnapshot doc in query.docs) {
      if (MapsHelper.getCodeString() != "" &&
          doc['codesnippet'] == MapsHelper.getCodeString() &&
          MapsHelper.getCodeType() == CodeType.employee) {
        continue;
      }

      if ((doc['long'] - pos.longitude).abs() <= 0.1) {
        /*
        I/flutter ( 8903): Getting Center 1 Minute.
        I/flutter ( 8903): EnableTime: 2020-11-30 19:02:52.000Z
        I/flutter ( 8903): DisableTime: 2020-12-01 06:49:22.000Z
        I/flutter ( 8903): Diff: -28
        I/flutter ( 8903): User is in deadzone.
        */

        var now = DateTime.now();
        int t = DateTime.parse(doc['enabletime']).millisecondsSinceEpoch;

        var enableTime = DateTime.fromMillisecondsSinceEpoch(t);

        t = DateTime.parse(doc['disabletime']).millisecondsSinceEpoch;
        var disableTime = DateTime.fromMillisecondsSinceEpoch(t);

        // var diff = disableTime.difference(now);
        //print("EnableTime: " + enableTime.toUtc().toString());
        //print("DisableTime: " + disableTime.toUtc().toString());
        //print("Diff: " + diff.inDays.toString());

        if (now.isAfter(enableTime) && now.isBefore(disableTime)) {
          double meters = doc['meters'].toDouble();

          circles.add(Circle(
            circleId: CircleId(doc.id),
            center: LatLng(doc['lat'], doc['long']),
            radius: meters,
            consumeTapEvents: true,
            fillColor: Colors.black26,
            strokeWidth: 0,
            onTap: circleTapToAvoidError,
          ));

          MapsHelper.currentDeadZones.add(doc);

          if (pointInCircle(pos.latitude, pos.longitude, doc['lat'].toDouble(),
              doc['long'].toDouble(), doc['meters'].toDouble())) {
            userInDeadZone = true;
          }
        } else if (now.isAfter(disableTime)) {
          toDeleteZones.add(doc);
        }
      }
    }

    deleteAllDeadZones(toDeleteZones);

    return circles;
  }

  void deleteAllDeadZones(List<DocumentSnapshot> allDeadZones) {
    allDeadZones.forEach((element) {
      deleteDeadZone(element.reference);
    });
  }

  void deleteDeadZone(DocumentReference zone) async {
    try {
      if (zone != null) {
        await firestore.runTransaction((Transaction myTransaction) async {
          myTransaction.delete(zone);
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("Failed to delete or run a transaction.");
    }
  }

  bool pointInCircle(double xp, double yp, double xc, double yc, double r) {
    // Geolocator package has the distanceBetween method
    double distanceInMeters =
        GeolocatorPlatform.instance.distanceBetween(xp, yp, xc, yc);

    if (distanceInMeters <= r) {
      return true;
    }

    return false;
  }

  bool hasShownDisclosure = false;
  bool closedDisclosure = false;
  Future<void> showProminentDisclosure() async {
    if (hasShownDisclosure) return;
    hasShownDisclosure = true;
    Future.delayed(Duration.zero, () {
      setState(() {
        closedDisclosure = true;
      });
    });
    /*Future.delayed(Duration.zero, () {
      showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              actions: [
                TextButton(
                  style: flatButtonStyle,
                  child: const Text("Close"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
              content: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "This app collects location data to enable the Map feature, the Requests & Videos feature, & Background Pins feature even when the app is closed or not in use.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            );
          });
    });
    */
  }

  Future<bool> gettingLocationPermission() async {
    var status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      return true;
    }
    return false;
  }

  Future<bool> gettingLocationPermissionStatus() async {
    var newStatus;
    if (!MapsPage.hasRunRequest) {
      showProminentDisclosure();
      if (closedDisclosure) {
        MapsPage.hasRunRequest = true;
        newStatus = await gettingLocationPermission();
      } else {
        return null;
      }
    }

    if (newStatus != null) {
      if (newStatus) {
        return true;
      } else {
        return false;
      }
    }

    var status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      return true;
    }
    return null;
  }

  void circleTapToAvoidError() {}

  Widget activeSideBar = Container();

  Future<void> whatCityIsOnTheScreen(LatLngBounds latlngBounds) async {
    // This is used for the NYC Launch and Costa Rica
    // NYC:
    // 40.913616678135675, -74.2831853597579
    // 40.913616678135675, -73.71601619616776
    // 40.487275530156595, -73.71601619616776
    // 40.487275530156595, -74.2831853597579
    // COSTA RICA:
    // 11.1474299205868, -86.11546518878247
    // 11.1474299205868, -82.62730614127172
    // 7.962693846448804, -82.62730614127172
    // 7.962693846448804, -86.11546518878247

    Rectangle google = Rectangle.fromPoints(
        Point(
            latlngBounds.northeast.latitude, latlngBounds.northeast.longitude),
        Point(
            latlngBounds.southwest.latitude, latlngBounds.southwest.longitude));

    // NYC Check.
    Rectangle nyc = Rectangle.fromPoints(
        const Point(40.913616678135675, -74.2831853597579),
        const Point(40.487275530156595, -73.71601619616776));

    bool result = nyc.intersects(google);

    // COSTA RICA Check.
    Rectangle costarica = Rectangle.fromPoints(
        const Point(11.1474299205868, -86.11546518878247),
        const Point(7.962693846448804, -82.62730614127172));

    bool result2 = costarica.intersects(google);
    if (result2 || result) {
      // CREATE SIDEBAR.
      setState(() {
        // activeSideBar = SideBar();
      });
    } else {
      // DELETE SIDEBAR.
      setState(() {
        activeSideBar = Container();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MapsPage.comingFromUserPage) {
      MapsPage.comingFromUserPage = false;

      mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: MapsPage.comingFromUserPageLat, zoom: 18.0)));
      MapsPage.comingFromUserPageLat = null;
    }

    return StreamProvider<QuerySnapshot>.value(
      initialData: null,
      value: DatabaseService().users,
      child: Scaffold(
          key: homeScaffoldKey,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          resizeToAvoidBottomInset: false,
          floatingActionButton: _initialUserPosition == null
              ? null
              : FloatingActionButton(
                  elevation: 0.0,
                  child: const Icon(Icons.search),
                  backgroundColor: buttonsBorders,
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    searchButtonPressed();
                  }),
          body: Stack(children: [
            FutureBuilder<bool>(
              future: gettingLocationPermissionStatus(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (!snapshot.hasData) {
                  // while data is loading:
                  return LoadingScreen(isUploading: false);
                } else {
                  // data loaded:
                  final locationStatus = snapshot.data;
                  if (locationStatus) {
                    getInitialPosition();

                    // ignore: prefer_if_null_operators
                    return map == null
                        ? LoadingScreen(isUploading: false)
                        : map;
                  } else {
                    //showADialog(context,
                    //    "By not allowing location permissions, the map will be unavailable until location permissions are allowed.");
                    return ErrorScreen(currentLanguage[146]);
                  }
                }
              },
            ),
            map != null
                ? Align(
                    alignment: const Alignment(-0.50, 0.95),
                    child: InkWell(
                        onTap: () {
                          showLegend(context);
                        },
                        child: Container(
                            height: 50,
                            child: Image.asset(
                                'assets/drawable/Map Legend Icon.png'))))
                : Container(),
            AnimatedOpacity(
                child: Align(
                  alignment: const Alignment(0, -0.85),
                  child: Container(
                      height: 40,
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Container(
                              child: Center(
                                  child: _info == null
                                      ? Container()
                                      : Text(
                                          _info.routes.first.legs.first.distance
                                                  .text
                                                  .toString() +
                                              ", " +
                                              _info.routes.first.legs.first
                                                  .duration.text
                                                  .toString(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18))),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                                onTap: () {},
                                child: IconTheme(
                                    data: const IconThemeData(
                                        color: Colors.white),
                                    child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        alignment: Alignment.center,
                                        iconSize: 25,
                                        icon: const Icon(
                                            FlutterIcons.close_box_mco),
                                        onPressed: () {
                                          setState(() {
                                            _info = null;
                                          });
                                        })))
                          ]),
                      padding: const EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: buttonsBorders,
                        borderRadius: BorderRadius.circular(20.0),
                      )),
                ),
                opacity: _info == null ? 0.0 : 1.0,
                duration: _info == null
                    ? const Duration()
                    : const Duration(milliseconds: 500))
          ]),
          bottomNavigationBar: map == null
              ? null
              : BottomNavigationBar(
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  items: ConstantsClass.contentAvailable ||
                          ConstantsClass.businessAccount
                      ? navBottomList
                      : navBottomListSeperate,
                  currentIndex: 0,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white.withOpacity(0.5),
                  backgroundColor: buttonsBorders,
                  onTap: ConstantsClass.contentAvailable ||
                          ConstantsClass.businessAccount
                      ? onTabTapped
                      : onTabTappedSeperate,
                )),
    );
  }

  void gettingAllPins() async {
    if (_initialUserPosition == null) {
      return;
    }

    if (MapsPage.repeatingPositionTimer == null &&
        _initialUserPosition != null) {
      const oneMin = Duration(seconds: 30);

      MapsPage.repeatingPositionTimer =
          Timer.periodic(oneMin, (Timer t) => {getRepeatingPosition()});
    }

    now = DateTime.now();

    newMarkers.clear();

    // Add the blocker to the list
    PreferencesHelper().getBlockedUsers().then((blocks) async {
      Set<Marker> markers = Set();
      if (ConstantsClass.contentAvailable) {
        await getCurrentRequests(blocks); // IN THIS ORDER
        await getCurrentVideos(blocks);
        List<String> markersNotOnScreen = [];

        allMarkers.forEach((key, value) {
          bool isOnNewMarkers = false;
          Marker bdd;
          newMarkers.forEach((key2, value2) {
            if (key == key2) {
              // the keys are the IDS
              isOnNewMarkers = true;
              bdd = value2;
            }
          });

          if (isOnNewMarkers == false) {
            // Was at some point deleted.
            markersNotOnScreen.add(key);
          } else if (MapsHelper.withinBounds(googleMapsBounds.southwest,
              googleMapsBounds.northeast, value.position)) {
            allMarkers.update(key, (value) => bdd);
            markers.add(value); // the markers map doesn't allow repitions.
            //value.icon = bdd;
          } else {
            // Not inbound
            markersNotOnScreen.add(key);
          }
        });

        for (String key in markersNotOnScreen) {
          allMarkers.remove(key);
        }

        BitmapDescriptor bmd;
        if (googleMapsZoom != null) {
          bmd = await MapsHelper.setCustomMapPinAnswered(
              0, googleMapsZoom, true, null);
        }

        pollMarkers.forEach((key, value) {
          Marker poll = Marker(
            markerId: value.markerId,
            position: value.position,
            icon: bmd,
            onTap: () {},
          );

          if (markers.contains(value)) {
            markers.remove(value);
          }
          value = poll;
          markers.add(value);
        });
      }

      await getCurrentBusinesses();
      businessMarkers.forEach((value) => markers.add(value));

      setState(() {
        mapMarkers = markers;
      }); // This causes a crash. Maybe a check to see if it can do this line? This always loops.
    });

    if (_places != null && (_places.apiKey == "" || _places.apiKey == null)) {
      // loadPlacesAPI();
      setState(() {
        _places = loco.GoogleMapsPlaces(apiKey: placesApiKey);
      });
    }
  }

  void setStateMap() {
    if (_initialUserPosition == null) {
      return;
    }

    LatLng cameraPos =
        LatLng(repeatingUserPosition.latitude, repeatingUserPosition.longitude);

    map = GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: cameraPos,
          zoom: 15.0,
        ),
        markers: mapMarkers,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        onTap: mapTapped,
        polylines: _info == null
            ? {}
            : {
                Polyline(
                    polylineId: const PolylineId('overview_polyline'),
                    color: buttonsBorders,
                    width: 5,
                    points: Poly.PolylinePoints()
                        .decodePolyline(
                            _info.routes.first.overviewPolyline.points)
                        .map((e) => LatLng(e.latitude, e.longitude))
                        .toList()),
              },
        circles: activeDeadZones,
        compassEnabled: true,
        myLocationEnabled: true,
        onCameraMove: (CameraPosition cameraPosition) {
          if (mapController != null) {
            mapController.getVisibleRegion().then((value) {
              googleMapsBounds = value;
            });
            mapController.getZoomLevel().then((value) {
              googleMapsZoom = value;
            });
          }
        },
        onCameraIdle: () {
          // This could also be used to help gather pins
          // Get Pins.
          gettingAllPins();

          // whatCityIsOnTheScreen(googleMapsBounds);
        },
        padding: const EdgeInsets.only(
          top: 40.0,
        ));
  }

  void mapTapped(LatLng location) {
    lastTappedLocation = location;

    if (userName != "Anonymous") {
      showRequestDialog(context);
    }
  }

  Future<void> startMapCamera() async {
    Navigator.of(context)
        .push(
            MaterialPageRoute(builder: (BuildContext context) => new Camera()))
        .then((value) {
      gettingAllPins();
    });
  }

  Future<String> documentPinNameRequest(DocumentSnapshot element) async {
    Map<String, dynamic> tester = element.data();
    if (tester.containsKey("name") && element['name'] != "") {
      return element['name'];
    }

    return await getRequestUserPin(element['email'].toString());
  }

  Future<String> getRequestUserPin(String email) async {
    QuerySnapshot snapshot = await DatabaseService()
        .userCollection
        .where('email', isEqualTo: email)
        .get();

    String r;

    snapshot.docs.forEach((element) {
      r = element['firstName'].toString();
    });

    return r;
  }

  // This is the logic behind creating requested markers and handles which
  // document snapshot should be added to the deletion list.
  void testingMarker(DocumentSnapshot f) async {
    String t = await documentPinNameRequest(f);

    int result = await createRequestsMarker(
        f.id,
        LatLng(f['latitude'].toDouble(), f['longitude'].toDouble()),
        f['message'],
        f['time'],
        t,
        f['likes'],
        f);

    if (result == -1) {
      toDeleteRequest.add(f);
    }
  }

  Future<bool> isAnswered(String id) async {
    QuerySnapshot snapshot = await (DatabaseService()
        .requestsCollection
        .doc("" + id)
        .collection('answers')
        .get());

    return snapshot.docs.isEmpty ? false : true;
  }

  Future<int> createRequestsMarker(
      String documentID,
      LatLng pinPosition,
      String message,
      String dt,
      String name,
      int likes,
      DocumentSnapshot doc) async {
    // Here we test the distance of the latitude and longitude to tell if it is
    // within the radius.
    Map<String, dynamic> tester = doc.data();
    if (tester.containsKey("type")) {
      if (doc['type'] == PinType.normal.index) {
        // Continue, everyone can see this
      } else if (doc['type'] == PinType.geocached.index) {
        if (!tester.containsKey("radius")) return 0; // Version Differences

        if (repeatingUserPosition == null) {
          return 0;
        } // If we don't have the user position yet.

        if (pointInCircle(
            doc['latitude'],
            doc['longitude'],
            repeatingUserPosition.latitude,
            repeatingUserPosition.longitude,
            doc['radius'])) {
          // Continue normally.
        } else {
          return 0;
        }
      } else {
        if (MapsHelper.getCodeString() != doc['codesnippet'] ||
            (MapsHelper.getCodeType() != CodeType.vip &&
                MapsHelper.getCodeType() != CodeType.employee)) {
          return 0; // Return as you don't have permission to view this pin.
        }
      }
    } else {
      // For version differences we won't display this thing.
      return 0;
    }

    DateTime t = DateTime.tryParse(dt);

    var difference = now.difference(t);

    if (difference.inMinutes >= minutesToDeletion) {
      return -1;
    }

    if (MapsHelper.withinBounds(
        googleMapsBounds.southwest, googleMapsBounds.northeast, pinPosition)) {
      // Is Within the Screen Bounds

      BitmapDescriptor bmd;
      bool answered = await isAnswered(documentID);
      // For version differences, don't display it.
      if (!tester.containsKey("pinUrl")) return 0;
      if (answered) {
        bmd = await MapsHelper.setCustomMapPinAnswered(
            difference.inMinutes.toInt(),
            googleMapsZoom,
            false,
            doc['pinUrl'] == "" ? null : doc['pinUrl']);
      } else {
        bmd = await MapsHelper.setCustomMapPinUnanswered(
            difference.inMinutes.toInt(),
            googleMapsZoom,
            doc['pinUrl'] == "" ? null : doc['pinUrl']);
      }

      // The MARKERID must be unique. Otherwise, this will not present all the Markers.
      Marker mark = Marker(
        markerId: MarkerId(documentID),
        position: pinPosition,
        icon: bmd,
        onTap: () {
          mainModalBottomSheetRequest(documentID, name, message, doc);
        },
      );

      allMarkers.putIfAbsent(documentID, () => mark);
      newMarkers.putIfAbsent(documentID, () => mark);

      return 1;
    }

    return 0;
  }

  bool isWithinNewBracket(QueryDocumentSnapshot s) {
    Map<String, dynamic> tester = s.data();
    if (!tester.containsKey("newPost")) {
      // Does not contain key.
      return false;
    }

    String postTime = s['newPost'].toString();
    DateTime tempDate = DateTime.tryParse(postTime);
    DateTime date = DateTime.now();

    Duration difference = date.difference(tempDate);
    if (difference.inDays == 0) {
      return true;
    }
    return false;
  }

  Future<bool> isWithinPreferencesMarkedBusinesses(
      QueryDocumentSnapshot business) async {
    List<String> markedBusinesses =
        await PreferencesHelper().getMarkedBusinesses();

    if (markedBusinesses == null || markedBusinesses.isEmpty) {
      return false; // not within it.
    }

    bool found = false;
    String foundStr = "";

    for (String s in markedBusinesses) {
      if (s.split("@")[0] == business.reference.id) {
        found = true;
        foundStr = s;
        break;
      }
    }

    if (!found) {
      return false; // not within it
    } else {
      // look for @
      // is inside list

      Map<String, dynamic> tester = business.data();
      if (!tester.containsKey("newPost")) {
        // Does not contain key.
        return true; // Turn off the new content thing.
      }

      DateTime lastTimeLooked = DateTime.tryParse(foundStr.split("@")[1]);
      String tempTime = business['newPost'].toString();
      DateTime postTime = DateTime.tryParse(tempTime);

      Duration difference = lastTimeLooked.difference(postTime);
      if (difference.isNegative) {
        // THEN THERE IS NEW CONTENT! DELETE IT FROM THE MARKED BUSINESS LIST
        markedBusinesses.remove(foundStr);
        await PreferencesHelper().setMarkedBusinesses(markedBusinesses);
        return false;
      } else {
        // NOT NEW CONTENT. SOME TYPE OF DELETION IF SOMETHING

        DateTime currentTime = DateTime.now();
        Duration anotherDifference = currentTime.difference(postTime);

        if (anotherDifference.inDays != 0) {
          // DELETE
          markedBusinesses.remove(foundStr);
          await PreferencesHelper().setMarkedBusinesses(markedBusinesses);
          return false;
        } else {
          return true;
        }
      }
    }
  }

  void getCurrentBusinesses() async {
    businessMarkers.clear();
    if (googleMapsBounds == null) {
      return;
    }

    QuerySnapshot snapshot = await DatabaseService()
        .businessCollection
        .where('latitude', isGreaterThan: googleMapsBounds.southwest.latitude)
        .where('latitude', isLessThan: googleMapsBounds.northeast.latitude)
        .get();

    for (var v in snapshot.docs) {
      // 11 -> 11
      if (v['bType'] >= linkedBusinesses.length) {
        continue;
      }

      // test if there is a selected button first
      if (SideBarItem.selectedName != "All") {
        int btype = v['bType'];
        int btypeSelected = linkedBusinesses[SideBarItem.selectedName];
        if (btype != btypeSelected) {
          continue;
        }
      }

      LatLng pos = LatLng(v['latitude'], v['longitude']);

      BitmapDescriptor bitMap;
      bool isWithinNewBracketBool = isWithinNewBracket(v);
      bool isWithinListBool = await isWithinPreferencesMarkedBusinesses(v);

      if (isWithinNewBracketBool && !isWithinListBool) {
        // NEW IMAGE HERE1
        final Uint8List markerIcon = await MapsHelper.getBytesFromAsset(
            iconBitmapsMarked[v['bType']],
            MapsHelper.getCustomSizeZoom(googleMapsZoom));

        bitMap = BitmapDescriptor.fromBytes(markerIcon);
      } else {
        final Uint8List markerIcon = await MapsHelper.getBytesFromAsset(
            iconBitmaps[v['bType']],
            MapsHelper.getCustomSizeZoom(googleMapsZoom));

        bitMap = BitmapDescriptor.fromBytes(markerIcon);
      }

      Marker m = Marker(
          markerId: MarkerId(v['uid']),
          position: pos,
          icon: bitMap,
          onTap: () {
            goToBusinessPage(v['uid'], v);
          });
      businessMarkers.add(m);
    }
  }

  void goToBusinessPage(String myuid, QueryDocumentSnapshot v) {
    setMarkedBusinesses(v);

    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (BuildContext context) =>
                BusinessPage(uid: myuid, deviceToken: deviceToken, myuid: uid)))
        .then((value) => DirectionsMockTest());
  }

  void setMarkedBusinesses(QueryDocumentSnapshot v) async {
    DateTime currentTime = DateTime.now();
    String currentTimeStr = currentTime.toIso8601String();

    List<String> b = await PreferencesHelper().getMarkedBusinesses();
    // ignore: prefer_conditional_assignment
    if (b == null) {
      b = [];
    }

    int temp = -1;

    for (int i = 0; i < b.length; i++) {
      String s = b[i];
      if (s.split("@")[0] == v.reference.id) {
        temp = i;
        break;
      }
    }

    if (temp != -1) {
      b.removeAt(temp);
    }

    b.add(v.reference.id + '@' + currentTimeStr);

    await PreferencesHelper().setMarkedBusinesses(b);
  }

  // Queries the firestore database and gathers all users within a radius.
  // It then creates markers for each user by using createUserMarker and adds those
  // to allMarkers.
  void getCurrentRequests(List<String> blockList) async {
    if (googleMapsBounds == null) {
      return;
    }

    //allMarkers.clear();
    //toDeleteRequest.clear();

    QuerySnapshot snapshot = await DatabaseService()
        .requestsCollection
        .where('latitude', isGreaterThan: googleMapsBounds.southwest.latitude)
        .where('latitude', isLessThan: googleMapsBounds.northeast.latitude)
        .get();

    for (var v in snapshot.docs) {
      if (compareEmailsToBlockList(v['email'], blockList) == false) {
        await testingMarker(v);
      }
    }

    deletingTransactionsRequests();
  }

  void deletingTransactionsRequests() {
    toDeleteRequest.forEach((element) {
      deleteReferenceRequest(element.reference);
    });
  }

  void deleteReferenceRequest(DocumentReference f) async {
    try {
      if (f != null) {
        await firestore.runTransaction((Transaction myTransaction) async {
          QuerySnapshot answers = await DatabaseService()
              .requestsCollection
              .doc(f.id)
              .collection('answers')
              .get();
          for (var answer in answers.docs) {
            answer.reference.delete(); // Delete all the answers as well.
          }

          myTransaction.delete(f);
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("Failed to delete or run a transaction that attempted to delete.");
    }
  }

  void onTabTappedSeperate(int index) {
    MapsPage.cancelRepeatingPositionTimer();
    if (index == 1) {
      HapticFeedback.heavyImpact();

      Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (BuildContext context) =>
                  glimpse.Settings(googleMapsBounds: googleMapsBounds)))
          .then((value) {
        gettingAllPins();
      });
    }
  }

  // Function is for when a navigation icon is tapped
  void onTabTapped(int index) {
    MapsPage.cancelRepeatingPositionTimer();
    if (index == 1) {
      HapticFeedback.heavyImpact();
      if (userInDeadZone) {
        showInDeadZoneDialog(context);
      } else {
        startMapCamera();
      }
    } else if (index == 2) {
      HapticFeedback.heavyImpact();
      Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (BuildContext context) =>
                  glimpse.Settings(googleMapsBounds: googleMapsBounds)))
          .then((value) {
        gettingAllPins();
      });
    }
  }

  showADialog(BuildContext context, String msg) {
    Widget okButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[13]),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(msg),
      content: Column(mainAxisSize: MainAxisSize.min, children: const []),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      actions: <Widget>[okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showInDeadZoneDialog(BuildContext context) {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            content: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                      child: Text(
                    currentLanguage[252],
                    textAlign: TextAlign.center,
                    softWrap: true,
                  )),
                  TextButton(
                    style: flatButtonStyle,
                    child: Text(currentLanguage[251]),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  void mainModalBottomSheetVideo(String id, String url, String name,
      String message, int likes, DocumentSnapshot video, bool isVideo) async {
    DocumentSnapshot refresh =
        await DatabaseService().videoCollection.doc(video.id).get();

    int likes = refresh['likes'];

    showModalBottomSheet(
        backgroundColor: glimpseOrange,
        context: context,
        builder: (context) {
          return VideoModal(name, message, likes, video, uid, userName,
              videosReported, isVideo, url, interstitialAdId);
        });
  }

  Future<String> getImgUrl(String email) async {
    QuerySnapshot snapshot = await DatabaseService()
        .userCollection
        .where('email', isEqualTo: email)
        .get();

    String r;

    snapshot.docs.forEach((element) {
      r = element['imgUrl'].toString();
    });

    return r;
  }

  List<MessageItem> videos = [];
  List<DocumentSnapshot> videosReported = [];

  void gatherVideos(String id, List<String> blockList) async {
    QuerySnapshot snapshot = await (DatabaseService()
        .requestsCollection
        .doc("" + id)
        .collection('answers')
        .get());

    videos.clear();
    videosReported.clear();

    int counter = 1;
    for (var element in snapshot.docs) {
      if (compareEmailsToBlockList(element['email'], blockList) == false) {
        String imgurl = await getImgUrl(element['email']);

        String dt = element['time'];
        DateTime t = DateTime.tryParse(dt);

        var difference = DateTime.now().difference(t);
        int minutes = difference.inMinutes;
        if (minutes < 0) {
          minutes = 0;
        }

        videos.add(MessageItem(
            element['message'],
            minutes.toString() + " minutes ago!",
            element['url'],
            imgurl,
            counter,
            element['isVideo']));
        counter++;

        videosReported.add(element);
      }
    }

    // ignore: prefer_is_empty
    if (snapshot.docs.length == -1) {
      videos.add(MessageItem(
          currentLanguage[253], currentLanguage[254], "q", null, 0, false));
    }
  }

  void mainModalBottomSheetRequest(
      String id, String name, String message, DocumentSnapshot doc) {
    // Generate List of Videos

    PreferencesHelper().getBlockedUsers().then((blocked) async {
      await gatherVideos(id, blocked);

      DocumentSnapshot refresh =
          await DatabaseService().requestsCollection.doc(doc.id).get();

      int likes = refresh['likes'];
      List<dynamic> followList = refresh['followtokens'];
      int followers = followList.length;

      showModalBottomSheet<dynamic>(
          backgroundColor: glimpseOrange,
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return RequestModal(
                name,
                videos,
                message,
                followers,
                proximityInMeters,
                likes,
                id,
                doc,
                uid,
                userName,
                videosReported);
          });
    });
  }

  // Shows the request pop-up and created the new request which is stored
  // in the database.
  showRequestDialog(BuildContext context) {
    final myController = TextEditingController();
    final _dialogKey = GlobalKey<FormState>();

    var dropDownValue;
    String dropDownHint = currentLanguage[193];

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(currentLanguage[181]),
              content: Form(
                key: _dialogKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    MapsHelper.getCodeType() == CodeType.employee
                        ? DropdownButtonFormField<String>(
                            hint: Text(dropDownHint),
                            validator: (value) =>
                                value == null ? currentLanguage[195] : null,
                            items: (MapsHelper.getCodeRadius() <= 0
                                    ? <String>['Public', 'VIP']
                                    : <String>['Public', 'Geocached', 'VIP'])
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            value: dropDownValue,
                            onChanged: (changedValue) {
                              if (mounted) {
                                setState(() {
                                  dropDownValue = changedValue;
                                });
                              }
                            },
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                          ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      controller: myController,
                      maxLength: 75,
                      decoration:
                          InputDecoration(hintText: currentLanguage[182]),
                      validator: (value) {
                        if (value.isEmpty) {
                          return currentLanguage[183];
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[77]),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[199]),
                  onPressed: () async {
                    if (_dialogKey.currentState.validate()) {
                      var a = await Favorite.getInformation(LatLng(
                          lastTappedLocation.latitude,
                          lastTappedLocation.longitude));

                      List<String> debug = [];
                      debug.add(deviceToken);

                      List<String> debug2 = [];
                      debug2.add(uid);

                      Request r = Request(
                        email: userName,
                        latitude: lastTappedLocation.latitude,
                        longitude: lastTappedLocation.longitude,
                        message: myController.text,
                        time: DateTime.now().toIso8601String(),
                        // This is so that the datetime can be parsed
                        userToken: deviceToken,
                        likes: 0,
                        country: a.countryName,
                        city: a.locality,
                        followTokens: debug,
                        likedAccounts: null,
                        followAccounts: debug2,
                        pinUrl: MapsHelper.getCustomInt8(),
                        name: MapsHelper.getCustomName(),
                        type: getPinType(dropDownValue).index,
                        codeSnippet: MapsHelper.getCodeString() == ""
                            ? ""
                            : MapsHelper.getCodeString(),
                        radius: MapsHelper.getCodeRadius(),
                      );

                      firestore.runTransaction((Transaction tx) async {
                        DatabaseService().requestsCollection.add(r.toJson());
                      }).whenComplete(() => gettingAllPins());

                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          });
        });
  }

  // Shows the request pop-up and created the new request which is stored
  // in the database.
  showAmericanPopup(BuildContext context) {
    if (launchedPopUp) return;

    launchedPopUp = true;
    final _dialogKey = GlobalKey<FormState>();

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            content: Form(
              key: _dialogKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(
                    'assets/drawable/popupimage.png',
                    fit: BoxFit.scaleDown,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        style: flatButtonStyle,
                        child: Text(currentLanguage[251]),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  showRequestSearchDialog(
      BuildContext context, String name, String placeId) async {
    final myController = TextEditingController();
    final _dialogKey = GlobalKey<FormState>();

    loco.PlacesDetailsResponse place =
        await _places.getDetailsByPlaceId(placeId);

    final location = place.result.geometry.location;
    final lat = location.lat;
    final lng = location.lng;
    final center = LatLng(lat, lng);

    Widget cancelButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[77]),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    String dropDownHint = currentLanguage[193];
    var dropDownValue;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(
                currentLanguage[184] + name,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              content: Form(
                key: _dialogKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    MapsHelper.getCodeType() == CodeType.employee
                        ? DropdownButtonFormField<String>(
                            hint: Text(dropDownHint),
                            validator: (value) =>
                                value == null ? currentLanguage[195] : null,
                            items: (MapsHelper.getCodeRadius() <= 0
                                    ? <String>['Public', 'VIP']
                                    : <String>['Public', 'Geocached', 'VIP'])
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            value: dropDownValue,
                            onChanged: (changedValue) {
                              if (mounted) {
                                setState(() {
                                  dropDownValue = changedValue;
                                });
                              }
                            },
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                          ),
                    TextFormField(
                      controller: myController,
                      maxLength: 75,
                      decoration:
                          InputDecoration(hintText: currentLanguage[182]),
                      validator: (value) {
                        if (value.isEmpty) {
                          return currentLanguage[183];
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                cancelButton,
                TextButton(
                  child: Text(currentLanguage[199]),
                  style: flatButtonStyle,
                  onPressed: () async {
                    if (_dialogKey.currentState.validate()) {
                      var a = await Favorite.getInformation(
                          LatLng(center.latitude, center.longitude));

                      List<String> debug = [];
                      debug.add(deviceToken);

                      List<String> debug2 = [];
                      debug2.add(uid);

                      Request r = Request(
                        email: userName,
                        latitude: center.latitude,
                        longitude: center.longitude,
                        message: myController.text,
                        time: DateTime.now().toIso8601String(),
                        // This is so that the datetime can be parsed
                        userToken: deviceToken,
                        likes: 0,
                        country: a.countryName,
                        city: a.locality,
                        followTokens: debug,
                        likedAccounts: null,
                        followAccounts: debug2,
                        pinUrl: MapsHelper.getCustomInt8(),
                        name: MapsHelper.getCustomName(),
                        type: getPinType(dropDownValue).index,
                        codeSnippet: MapsHelper.getCodeString() == ""
                            ? ""
                            : MapsHelper.getCodeString(),
                        radius: MapsHelper.getCodeRadius(),
                      );

                      firestore.runTransaction((Transaction tx) async {
                        DatabaseService().requestsCollection.add(r.toJson());
                      }).whenComplete(() => gettingAllPins());

                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          });
        });
  }
}
