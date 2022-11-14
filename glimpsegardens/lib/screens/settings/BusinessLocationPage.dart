import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: implementation_imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glimpsegardens/screens/settings/accountSettingsPage.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/loading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glimpsegardens/screens/errorscreen.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/BusinessInfoRegistration.dart';
import 'package:glimpsegardens/screens/mapshelper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/businessOrUser.dart';
import 'dart:core';
import 'package:geolocator/geolocator.dart';

class BusinessLocationPage extends StatefulWidget {
  static bool hasRunRequest = false;
  static bool resetInitialPosition = false;
  BusinessLocationPage({Key key}) : super(key: key);

  @override
  _BusinessLocationPage createState() => new _BusinessLocationPage();
}

class _BusinessLocationPage extends State<BusinessLocationPage>
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
  Set<Marker> selectedPlace = new Set();

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  moveCamera(LatLng lat) {
    mapController
        .animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: lat, zoom: 18.0)))
        .then((value) => print("Done Moving."));
  }

  LatLng l;
  bool ranOnce = false;
  Future<bool> getInitialPosition() async {
    if (ranOnce != false) return true;
    ranOnce = true;

    print("Initial Position");
    User user = await FirebaseAuth.instance.currentUser;
    String uid = user.uid;

    var doc = await DatabaseService().businessCollection.doc(uid).get();
    if (!doc.exists) return false;

    l = LatLng(doc['latitude'], doc['longitude']);

    selectedPlace.clear();
    Marker mark = Marker(
      markerId: MarkerId("1"),
      position: l,
    );
    selectedPlace.add(mark);

    setState(() {
      cameraPos = LatLng(l.latitude, l.longitude);
    });

    return true;
  }

  makeMap() {
    map = GoogleMap(
      initialCameraPosition: CameraPosition(
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
            markerId: MarkerId("1"),
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
                    future: getInitialPosition(),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if (!snapshot.hasData) {
                        // while data is loading:
                        return LoadingScreen(isUploading: false);
                      } else {
                        return map;
                      }
                    },
                  ),
                ),
                Container(
                  height: 20,
                ),
              ]),
              AnimatedPositioned(
                duration: Duration(milliseconds: 500),
                bottom: isVisible ? 0 : -130,
                curve: Curves.fastOutSlowIn,
                child: Container(
                  height: 180,
                  width: size.width,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Align(
                          alignment: Alignment.topCenter,
                          child: Column(children: [
                            Text(currentLanguage[233],
                                style: TextStyle(
                                    fontSize: 18,
                                    color: buttonsBorders,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w700)),
                            SizedBox(height: 15),
                            Text(currentLanguage[18],
                                style: TextStyle(
                                    color: normalText, fontFamily: 'Arial')),
                            SizedBox(height: 15),
                            Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        isVisible = false;
                                        selectedPlace.clear();
                                        Marker mark = Marker(
                                          markerId: MarkerId("1"),
                                          position: l,
                                        );
                                        selectedPlace.add(mark);
                                        moveCamera(cameraPos);
                                      });
                                    },
                                    child: Icon(Icons.not_interested_rounded,
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
                                      padding: EdgeInsets.all(15),
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  ElevatedButton(
                                    onPressed: () async {
                                      LatLng t = selectedPlace.last.position;
                                      User user = await FirebaseAuth
                                          .instance.currentUser;

                                      await firestore
                                          .runTransaction((Transaction tx) {
                                        tx.update(
                                            firestore
                                                .collection('users')
                                                .doc("" + user.uid),
                                            {
                                              'latitude': t.latitude,
                                              'longitude': t.longitude
                                            });
                                        return;
                                      });

                                      await firestore
                                          .runTransaction((Transaction tx) {
                                        tx.update(
                                            firestore
                                                .collection('businesses')
                                                .doc("" + user.uid),
                                            {
                                              'latitude': t.latitude,
                                              'longitude': t.longitude
                                            });
                                        return;
                                      });

                                      accountSettingsPage.showPreferencesSaved =
                                          true;

                                      Navigator.pop(context);
                                    },
                                    child: Icon(Icons.check, color: headers),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: CircleBorder(
                                          side: BorderSide(
                                              width: 2.0,
                                              color: buttonsBorders
                                                  .withOpacity(0))),
                                      padding: EdgeInsets.all(15),
                                      primary: lightTone, // <-- Button color
                                    ),
                                  ),
                                ]),
                          ]))),
                ),
              ),
              Padding(
                  padding: new EdgeInsets.fromLTRB(0, 25, 0, 0),
                  child: Container(
                      alignment: Alignment.topLeft,
                      child: new IconTheme(
                        data: new IconThemeData(color: normalText),
                        child: IconButton(
                          icon: new Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      )))
            ],
          )),
    );
  }
}
