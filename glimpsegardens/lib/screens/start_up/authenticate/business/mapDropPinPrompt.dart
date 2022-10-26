import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/loading.dart';
import 'package:glimpsegardens/screens/errorscreen.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/BusinessInfoRegistration.dart';
import 'package:glimpsegardens/services/mapshelper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/businessOrUser.dart';
import 'dart:core';
import 'package:geolocator/geolocator.dart';

// ignore: camel_case_types
class mapDropPinprompt extends StatefulWidget {
  static bool answering = false;
  static String requestID = "";
  static bool comingFromUserPage = false;
  static LatLng comingFromUserPageLat;
  static DocumentSnapshot notificationRef;
  static Timer repeatingPositionTimer;
  static bool hasRunRequest = false;
  static bool hasReturnedFromRequest = false;
  static bool resetInitialPosition = false;
  final PassingUser pUser;
  final int businessType;

  const mapDropPinprompt(
      {Key key, @required this.pUser, @required this.businessType})
      : super(key: key);

  @override
  _mapDropPinprompt createState() => _mapDropPinprompt();
}

// ignore: camel_case_types
class _mapDropPinprompt extends State<mapDropPinprompt>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  GoogleMap map;
  GoogleMap g;
  Position _initialUserPosition;
  GoogleMapController mapController;
  bool centerFailed = false;
  LatLngBounds googleMapsBounds;
  double googleMapsZoom;
  double mapBottomPadding = 40;
  double dynamicSize = 75;
  LatLng cameraPos;
  bool isVisible = false;
  Set<Marker> selectedPlace = {};

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  businessLocationPopup(BuildContext context) async {
    Widget okButton = TextButton(
      style: flatButtonStyle,
      child: Text(
        currentLanguage[13],
        style: const TextStyle(
            fontFamily: 'Arial',
            color: buttonsBorders,
            fontSize: 14,
            fontWeight: FontWeight.w700),
      ),
      onPressed: () {
        setState(() {
          closedDisclosure = true;
        });
        Navigator.pop(context);
      },
    );

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: Text(
                  currentLanguage[11],
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      fontFamily: 'Arial',
                      color: buttonsBorders,
                      fontWeight: FontWeight.w700),
                ),
                content: Text(
                  currentLanguage[14],
                  textAlign: TextAlign.left,
                  style:
                      const TextStyle(fontFamily: 'Arial', color: normalText),
                ),
                actions: <Widget>[
                  okButton,
                ],
              ));
        });
  }

  showLocationFailedDialogue(BuildContext context) async {
    Widget appSettingsButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[97]),
      onPressed: () async {
        await openAppSettings();
        // PERFORM LOGOUT
        Navigator.pop(context);
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
                  appSettingsButton,
                ],
              ));
        });
  }

  bool hasShownDisclosure = false;
  bool closedDisclosure = false;
  Future<void> showProminentDisclosure() async {
    if (hasShownDisclosure) return;
    hasShownDisclosure = true;
    Future.delayed(Duration.zero, () {
      businessLocationPopup(context);
    });
  }

  Future<bool> gettingLocationPermission() async {
    var status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      return true;
    }
    return false;
  }

  Future<bool> gettingLocationPermissionStatus() async {
    bool newStatus;
    if (!mapDropPinprompt.hasRunRequest) {
      showProminentDisclosure();
      if (closedDisclosure) {
        mapDropPinprompt.hasRunRequest = true;
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

  moveCamera(LatLng lat) {
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: lat, zoom: 18.0)));
  }

  void getInitialPosition() async {
    if (mapDropPinprompt.resetInitialPosition) {
      _initialUserPosition = null;
      map = null;
      mapDropPinprompt.resetInitialPosition = false;
    }

    if (_initialUserPosition != null) {
      return;
    }

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
      setState(() {
        _initialUserPosition = center;

        cameraPos = LatLng(
            _initialUserPosition.latitude, _initialUserPosition.longitude);
      });
    }
  }

  makeMap() {
    map = GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(40.717996679466296, -73.99868611868771),
        zoom: 15.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        controller.setMapStyle(mapStyle);
        mapController = controller;
        setState(() {});
        moveCamera(cameraPos);
      },
      markers: selectedPlace,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      onTap: (LatLng l) {
        setState(() {
          selectedPlace.clear();
          Marker mark = Marker(
            markerId: const MarkerId("1"),
            position: l,
          );
          selectedPlace.add(mark);

          if (!isVisible) isVisible = true;
        });
      },
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
      padding:
          EdgeInsets.only(bottom: mapBottomPadding, top: 0, right: 0, left: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    makeMap();
    final size = MediaQuery.of(context).size;
    return StreamProvider<QuerySnapshot>.value(
      initialData: null,
      value: DatabaseService().users,
      child: Scaffold(
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Column(children: [
                Expanded(
                  child: FutureBuilder<bool>(
                    future: gettingLocationPermissionStatus(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if (!snapshot.hasData) {
                        // while data is loading:
                        return LoadingScreen(isUploading: false);
                      } else {
                        // data loaded:
                        final locationStatus = snapshot.data;
                        if (locationStatus) {
                          getInitialPosition();

                          return _initialUserPosition == null
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
                ),
                Container(
                  height: 20,
                ),
              ]),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                bottom: isVisible ? 0 : -130,
                curve: Curves.fastOutSlowIn,
                child: Container(
                  height: 180,
                  width: size.width,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Align(
                          alignment: Alignment.topCenter,
                          child: Column(children: [
                            Text(currentLanguage[233],
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: buttonsBorders,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 15),
                            Text(currentLanguage[18],
                                style: const TextStyle(
                                    color: normalText, fontFamily: 'Arial')),
                            const SizedBox(height: 15),
                            Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        isVisible = false;
                                        selectedPlace.clear();
                                      });
                                    },
                                    child: const Icon(
                                        Icons.not_interested_rounded,
                                        color: headers),
                                    style: ElevatedButton.styleFrom(
                                      primary: lightTone,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: CircleBorder(
                                          side: BorderSide(
                                              width: 2.0,
                                              color: buttonsBorders
                                                  .withOpacity(0))),
                                      padding: const EdgeInsets.all(15),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BusinessInfoRegistration(
                                                  pUser: widget.pUser,
                                                  businessType:
                                                      widget.businessType,
                                                  pos: selectedPlace
                                                      .first.position),
                                        ),
                                      );
                                    },
                                    child:
                                        const Icon(Icons.check, color: headers),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: CircleBorder(
                                          side: BorderSide(
                                              width: 2.0,
                                              color: buttonsBorders
                                                  .withOpacity(0))),
                                      padding: const EdgeInsets.all(15),
                                      primary: lightTone, // <-- Button color
                                    ),
                                  ),
                                ]),
                          ]))),
                ),
              ),
            ],
          )),
    );
  }
}
