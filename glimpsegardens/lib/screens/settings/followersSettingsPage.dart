// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'package:glimpsegardens/shared/constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class FollowersSettingsPage extends StatefulWidget {
  final LatLngBounds googleMapsBounds;
  final String uid;

  FollowersSettingsPage(
      {Key key,
      @required LatLngBounds this.googleMapsBounds,
      @required String this.uid})
      : super(key: key);

  @override
  _FollowersSettingsPage createState() => _FollowersSettingsPage();
}

class _FollowersSettingsPage extends State<FollowersSettingsPage> {
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
        await DatabaseService().businessCollection.doc(widget.uid).get();

    List splits = base['followUids'].toString().split(":");

    for (int i = 0; i < splits.length; i++) {
      if (splits[i] != "") {
        DocumentSnapshot<Object> userSnap =
            await DatabaseService().userCollection.doc(splits[i]).get();

        autoList.add(userSnap['firstName']);
      }
    }

    setState(() {
      filteredList.addAll(autoList);
    });
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
                              currentLanguage[73],
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
                                          child: new Icon(
                                              FlutterIcons.user_following_sli),
                                          height: 50),
                                      SizedBox(width: 15),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item,
                                              style:
                                                  TextStyle(color: normalText)),
                                          Text(
                                              currentLanguage[215] +
                                                  " " +
                                                  (index + 1).toString(),
                                              style:
                                                  TextStyle(color: normalText)),
                                        ],
                                      ),
                                    ],
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
