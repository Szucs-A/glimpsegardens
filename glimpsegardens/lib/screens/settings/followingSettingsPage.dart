// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'dart:async';
import 'package:glimpsegardens/shared/constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glimpsegardens/services/push_notification_service.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:glimpsegardens/screens/maps.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FollowingSettingsPage extends StatefulWidget {
  final String uid;

  FollowingSettingsPage({Key key, @required String this.uid}) : super(key: key);

  @override
  _FollowingSettingsPage createState() => _FollowingSettingsPage();
}

class _FollowingSettingsPage extends State<FollowingSettingsPage> {
  bool justOnce = true;
  bool isVisible = false;
  TextEditingController _controller;

  List autoList = [];
  List filteredList = [];

  final myController = TextEditingController();

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

  void gatherDocuments() async {
    DocumentSnapshot base =
        await DatabaseService().userCollection.doc(widget.uid).get();

    List splits = base['followUids'].toString().split(":");

    for (int i = 0; i < splits.length; i++) {
      if (splits[i] != "") {
        DocumentSnapshot<Object> userSnap =
            await DatabaseService().userCollection.doc(splits[i]).get();

        autoList.add(userSnap);
      }
    }

    setState(() {
      filteredList.addAll(autoList);
    });
  }

  Future<bool> showDeletionDialog(BuildContext context) async {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text(currentLanguage[77],
          style: TextStyle(
              fontFamily: 'Arial',
              color: buttonsBorders,
              fontWeight: FontWeight.w700,
              fontSize: 18)),
      onPressed: () {
        Navigator.pop(context, false);
      },
    );
    Widget continueButton = TextButton(
      child: Text(currentLanguage[10],
          style: TextStyle(
              fontFamily: 'Arial',
              fontSize: 18,
              color: buttonsBorders,
              fontWeight: FontWeight.w700)),
      onPressed: () {
        Navigator.pop(context, true);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(currentLanguage[74],
                style: TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 18,
                    color: buttonsBorders,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            Text(currentLanguage[93],
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Arial', color: normalText)),
            SizedBox(height: 20),
            Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(child: continueButton), // button 1
                  Expanded(child: cancelButton), // button 2
                ])
          ]),
    );

    // show the dialog
    var nuller = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

    if (nuller == null)
      return false;
    else
      return nuller;
  }

  @override
  Widget build(BuildContext context) {
    if (justOnce) {
      justOnce = false;
      gatherDocuments();
    }

    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
          height: size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  color: buttonsBorders,
                  child: Column(children: [
                    SizedBox(height: 25),
                    Stack(
                      children: [
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: Center(
                            child: Text(
                              currentLanguage[91],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Arial'),
                            ),
                          ),
                        ),
                        Container(
                            alignment: Alignment.centerLeft,
                            child: new IconTheme(
                              data: new IconThemeData(color: Colors.white),
                              child: IconButton(
                                icon: new Icon(Icons.arrow_back),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ))
                      ],
                    ),
                  ])),
              SizedBox(
                height: 10,
              ),
              SizedBox(height: 25),
              Padding(
                  child: Container(
                    child: TextField(
                      style: TextStyle(color: normalText, fontFamily: 'Arial'),
                      controller: _controller,
                      decoration: new InputDecoration(
                        suffixIcon: new IconTheme(
                          data: new IconThemeData(color: buttonsBorders),
                          child: IconButton(
                            icon: new Icon(Icons.search),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: currentLanguage[201],
                        hintStyle:
                            TextStyle(color: fadeoutText, fontFamily: 'Arial'),
                        contentPadding: const EdgeInsets.only(
                            left: 14.0, bottom: 8.0, top: 8.0),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              new BorderSide(color: buttonsBorders, width: 2),
                          borderRadius: new BorderRadius.circular(2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              new BorderSide(color: buttonsBorders, width: 2),
                          borderRadius: new BorderRadius.circular(2.0),
                        ),
                      ),
                      onChanged: (value) {
                        print("Changed.");
                        setState(() {
                          if (value == "") {
                            filteredList.clear();
                            filteredList.addAll(
                                autoList); //getting list to original state
                          } else {
                            filteredList
                                .clear(); //for the next time that we search we want the list to be unfilterted
                            filteredList.addAll(
                                autoList); //getting list to original state

                            //removing items that do not contain the entered Text
                            filteredList.removeWhere((i) =>
                                i
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toString().toLowerCase()) ==
                                false);
                          }
                        });
                      },
                    ),
                    height: 60,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 25)),
              Expanded(
                child: ListView.builder(
                    padding: EdgeInsets.all(0),
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  height: 75,
                                  color: fadedOutButtons,
                                  child: Row(
                                    children: [
                                      SizedBox(width: 15),
                                      SizedBox(
                                          child: Image.asset(
                                              iconBitmaps[item['bType']]),
                                          height: 50),
                                      SizedBox(width: 15),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item['bName'],
                                              style: TextStyle(
                                                  color: normalText,
                                                  fontFamily: 'Arial',
                                                  fontWeight: FontWeight.w700)),
                                          Text(item['bAddress'],
                                              style: TextStyle(
                                                  color: normalText,
                                                  fontFamily: 'Arial')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              InkWell(
                                onTap: () {
                                  MapsPage.comingFromUserPage = true;
                                  MapsPage.comingFromUserPageLat = LatLng(
                                      item['latitude'], item['longitude']);
                                  Navigator.popUntil(
                                      context, (route) => route.isFirst);
                                },
                                child: Container(
                                  width: 75,
                                  color: fadedOutButtons,
                                  height: 75,
                                  child: new IconTheme(
                                    data:
                                        new IconThemeData(color: locationColor),
                                    child: Icon(Icons.location_on),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              InkWell(
                                onTap: () async {
                                  bool response =
                                      await showDeletionDialog(context);

                                  print(response);

                                  if (response) {
                                    // Remove follow uid on user
                                    DocumentSnapshot userDoc =
                                        await DatabaseService()
                                            .userCollection
                                            .doc(widget.uid)
                                            .get();

                                    String uidtemp = userDoc['followUids'];
                                    uidtemp =
                                        uidtemp.replaceFirst(':' + item.id, "");

                                    await firestore.runTransaction(
                                        (Transaction myTransaction) async {
                                      myTransaction.update(userDoc.reference,
                                          {'followUids': uidtemp});
                                    });

                                    // Remove device token on business
                                    DocumentSnapshot busDoc =
                                        await DatabaseService()
                                            .businessCollection
                                            .doc(item.id)
                                            .get();

                                    String temp = busDoc['followUids'];
                                    temp =
                                        temp.replaceFirst(':' + widget.uid, "");

                                    await firestore.runTransaction(
                                        (Transaction myTransaction) async {
                                      myTransaction.update(busDoc.reference,
                                          {'followUids': temp});
                                    });

                                    String deviceToken =
                                        await PushNotificationService
                                            .getDeviceToken();

                                    // Remove follow uid on business
                                    temp = busDoc['followDevices'];
                                    temp = temp.replaceFirst(
                                        ':' + deviceToken, "");

                                    await firestore.runTransaction(
                                        (Transaction myTransaction) async {
                                      myTransaction.update(busDoc.reference,
                                          {'followDevices': temp});
                                    });

                                    setState(() {
                                      // remove from autolist and filtered.
                                      filteredList.remove(item);
                                      autoList.remove(item);
                                    });
                                  }
                                },
                                child: Container(
                                  width: 75,
                                  color: fadedOutButtons,
                                  height: 75,
                                  child: new IconTheme(
                                    data: new IconThemeData(color: heartColor),
                                    child: Icon(FlutterIcons.heart_ant),
                                  ),
                                ),
                              ),
                            ],
                          ));
                    }),
              ),
            ],
          )),
    );
  }
}
