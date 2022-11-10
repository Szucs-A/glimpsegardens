// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:core';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glimpsegardens/services/camera/videoPictureController.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/services/camera/display_picture_screen.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:glimpsegardens/screens/VideoPlayerScreen.dart';
import 'package:flutter/material.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:glimpsegardens/services/push_notification_service.dart';
import 'package:flutter_icons/flutter_icons.dart';

import 'package:glimpsegardens/screens/loading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:glimpsegardens/screens/maps.dart';

class BusinessPage extends StatefulWidget {
  final String uid;
  final String myuid;
  final String deviceToken;
  static List videoPictureCombiners = <videoPictureCombiner>[];

  BusinessPage(
      {Key key,
      @required String this.uid,
      @required String this.deviceToken,
      @required String this.myuid})
      : super(key: key);

  @override
  _BusinessPage createState() => _BusinessPage();
}

class _BusinessPage extends State<BusinessPage> {
  bool doOnce = true;

  LatLng position = null;
  String businessName = "";
  String businessAddress = "";
  String currentHours = "";
  int businessType = -1;
  String businessWebsite = "";
  String businessNumber = "";
  Widget businessIcon = Container();
  String businessIconName = "";
  int numberOfCircles = 0;
  List postLikes = [];
  Icon whichFollowerHeart = Icon(FlutterIcons.heart_multiple_outline_mco);

  double littleCircleSize = 6;
  List littleCircles = <Widget>[];

  List contentHeights = <double>[];
  List contentWidgets = <Widget>[];
  List contentIDS = <String>[];
  CarouselController buttonCarouselController = CarouselController();
  int currentIndex = 0;

  double height = 0;

  bool businessOwned = false;
  int numberOfFollowers = 0;
  bool loaded = false;

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    BusinessPage.videoPictureCombiners.clear();
  }

  Future<Widget> ContentPost(
      int index,
      String description,
      int likes,
      String postTime,
      String image,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      bool isOwned,
      bool isVideo,
      DocumentSnapshot businessDoc) async {
    Widget _image;

    if (isVideo) {
      final fileName = await VideoThumbnail.thumbnailFile(
        video: image,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight:
            200, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
        quality: 75,
      );

      final file = File(fileName);
      Uint8List bytes = file.readAsBytesSync();

      _image = InkWell(
          child: Image.memory(bytes, fit: BoxFit.contain, height: 200),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => videoPictureController(),
              ),
            );
          });
    } else {
      _image = InkWell(
          child: Image.network(
            image,
            fit: BoxFit.contain,
            height: 200,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => videoPictureController(),
              ),
            );
          });
    }

    String timePostedAgo = "";
    DateTime tempDate = DateTime.tryParse(postTime);
    DateTime date = DateTime.now();

    Duration difference = date.difference(tempDate);
    if (difference.inDays != 0) {
      timePostedAgo = difference.inDays.toString() + " " + currentLanguage[202];
    } else if (difference.inHours != 0) {
      timePostedAgo =
          difference.inHours.toString() + " " + currentLanguage[203];
    } else if (difference.inMinutes != 0) {
      timePostedAgo =
          difference.inMinutes.toString() + " " + currentLanguage[204];
    } else {
      // Seconds
      timePostedAgo =
          difference.inSeconds.toString() + " " + currentLanguage[205];
    }

    return StatefulBuilder(builder: (context, setContentState) {
      return Wrap(children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(child: _image, color: fadedOutButtons),
                ),
                Column(
                  children: [
                    SizedBox(height: 65),
                    isVideo == false
                        ? Container()
                        : IgnorePointer(
                            ignoring: true,
                            child: Center(
                                child: Icon(Icons.play_circle_outline,
                                    size: 70.0,
                                    color: Color.fromRGBO(255, 255, 255, 0.5))))
                  ],
                )
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    new IconTheme(
                        data: new IconThemeData(color: heartColor),
                        child: IconButton(
                          icon: postLikes[index], // TODO: This isn't updated.
                          onPressed: () async {
                            // check if followed before.
                            String likesUids = "";
                            likesUids = doc["likesUids"];
                            if (likesUids.contains(widget.myuid)) {
                              print("SHOWING TOAST");
                              Fluttertoast.showToast(msg: currentLanguage[163]);
                              return;
                            }

                            await firestore.runTransaction(
                                (Transaction myTransaction) async {
                              myTransaction.update(
                                  doc.reference, {'likes': doc['likes'] + 1});
                            });

                            likesUids = likesUids + ":" + widget.myuid;
                            await doc.reference
                                .update({'likesUids': likesUids});

                            setContentState(() {
                              postLikes[index] =
                                  Icon(FlutterIcons.heart_multiple_mco);
                            });

                            String token = businessDoc['tokenDevice'];

                            bool canSend = await PreferencesHelper()
                                .getNotificationAlerts();

                            if (canSend) {
                              PushNotificationService
                                  .sendBusinessOwnerLikeNotification(
                                      token, businessDoc.id);
                            }
                          },
                        )),
                    SizedBox(width: 10),
                    Text(likes.toString(),
                        style: TextStyle(
                          color: normalText,
                          fontFamily: 'Arial',
                        )),
                  ],
                ),
                Text(timePostedAgo,
                    style: TextStyle(
                      color: fadeoutText,
                      fontFamily: 'Arial',
                    )),
              ],
            ),
            SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    description,
                    maxLines: 20, // you can change it accordingly
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: normalText,
                      fontFamily: 'Arial',
                    ),
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  height: 24,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(0),
                      primary: headers,
                      textStyle: TextStyle(
                        fontSize: 15,
                        color: headers,
                      ),
                    ),
                    onPressed: () {
                      Share.share(
                        '${image} - $description',
                      );
                    },
                    child: Text(currentLanguage[63],
                        style: TextStyle(
                          fontFamily: 'Arial',
                        )),
                  ),
                ),
              ],
            ),
          ],
        )
      ]);
    });
  }

  resetColors(int index) {
    littleCircles.clear();
    for (int i = 0; i < numberOfCircles; i++) {
      if (i == index) {
        littleCircles.add(new Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: new BoxDecoration(
            color: headers,
            shape: BoxShape.circle,
          ),
        ));
      } else {
        littleCircles.add(new Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: new BoxDecoration(
            color: buttonsBorders,
            shape: BoxShape.circle,
          ),
        ));
      }
    }
  }

  gatherDatabaseMaterials(Size screensize) async {
    if (widget.myuid == widget.uid) {
      print("Business Owns This");
      businessOwned = true;
    }

    DocumentSnapshot<Object> businessDoc =
        await DatabaseService().businessCollection.doc(widget.uid).get();

    DocumentSnapshot<Object> snapshot =
        await DatabaseService().userCollection.doc(widget.uid).get();

    String followUids = "";
    followUids = businessDoc["followUids"];
    numberOfFollowers = followUids.split(':').length - 1;
    if (followUids.contains(widget.myuid)) {
      whichFollowerHeart = Icon(FlutterIcons.heart_multiple_mco);
    }

    if (snapshot.exists) {
      businessAddress = snapshot['bAddress'];
      businessName = snapshot['bName'];
      businessWebsite = snapshot['bWebsite'];
      businessType = snapshot['bType'];
      businessNumber = snapshot['bNumber'];
      position = LatLng(snapshot['latitude'], snapshot['longitude']);
      businessIcon = iconImages[businessType];
      businessIconName = iconNames[businessType];

      String currentDay = DateFormat('EEEE').format(DateTime.now());
      currentHours = snapshot[currentDay];
    }

    QuerySnapshot<Map<String, dynamic>> snapshot2 = await DatabaseService()
        .businessCollection
        .doc(widget.uid)
        .collection("posts")
        .get();

    int limitedAmount = 0;

    for (var element in snapshot2.docs) {
      if (element.exists) {
        if (limitedAmount <= 9) {
          // CHECK IF TIME IS PAST.
          if (element['expiryDate'] != "") {
            DateTime now = new DateTime.now();
            DateTime t = DateTime.tryParse(element['expiryDate']);
            print(now.toIso8601String());
            print(t.toIso8601String());

            if (now.isAfter(t)) {
              // DELETE
              await firestore.runTransaction((Transaction myTransaction) async {
                DocumentReference<Map<String, dynamic>> answers =
                    await DatabaseService()
                        .businessCollection
                        .doc(widget.uid)
                        .collection('posts')
                        .doc(element.id);

                myTransaction.delete(answers);
              });
              continue;
            }
          }

          limitedAmount++;
          numberOfCircles++;
          contentIDS.add(element.id);
          String likesUids = "";
          likesUids = element["likesUids"];
          if (likesUids.contains(widget.myuid)) {
            postLikes.add(Icon(FlutterIcons.heart_multiple_mco));
          } else {
            postLikes.add(Icon(FlutterIcons.heart_multiple_outline_mco));
          }

          Widget content = await ContentPost(
              limitedAmount - 1,
              element['description'],
              element['likes'],
              element['datePosted'].toString(),
              element['url'],
              element,
              businessOwned,
              element['isVideo'],
              businessDoc);

          // TODO: READ TAGS
          List tags = [];

          var snapshot = await element.reference.collection('tags').get();
          for (int i = 0; i < snapshot.size; i++) {
            if (snapshot.docs[i].exists) {
              tags.add(snapshot.docs[i]);
            }
          }

          contentWidgets.add(content);
          BusinessPage.videoPictureCombiners.add(new videoPictureCombiner(
              element['isVideo'],
              element['url'],
              element['description'],
              tags));

          double containerWidth = screensize.width * 0.9;

          Size size =
              _textSize(element['description'], TextStyle(color: normalText));

          double containerHeight = size.width / containerWidth;
          containerHeight = containerHeight * 24;

          contentHeights.add((containerHeight) + 280);

          print(size.height);
          print(size.width);
        }
      }
    }
    ;

    for (int i = 0; i < limitedAmount; i++) {
      if (i == 0) {
        littleCircles.add(new Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: new BoxDecoration(
            color: headers,
            shape: BoxShape.circle,
          ),
        ));
      } else {
        littleCircles.add(new Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: new BoxDecoration(
            color: buttonsBorders,
            shape: BoxShape.circle,
          ),
        ));
      }
    }

    setState(() {
      if (contentHeights.length > 0) height = contentHeights.first;
      loaded = true;
    });
  }

  // Here it is!
  Size _textSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
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
            Text(currentLanguage[75],
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
    final size = MediaQuery.of(context).size;
    if (doOnce) {
      doOnce = false;
      gatherDatabaseMaterials(size);
    }

    return !loaded
        ? LoadingScreen(isUploading: false)
        : Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
                child: Stack(children: [
              Column(
                children: [
                  SizedBox(height: 25),
                  Container(
                      alignment: Alignment.centerLeft,
                      child: new IconTheme(
                        data: new IconThemeData(color: normalText),
                        child: IconButton(
                          icon: new Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context);
                            BusinessPage.videoPictureCombiners.clear();
                          },
                        ),
                      )),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height - (size.height - 100)),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(businessName,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      color: normalText,
                                      fontFamily: 'Arial',
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          businessOwned
                              ? Column(
                                  children: [
                                    Text(numberOfFollowers.toString(),
                                        style: TextStyle(
                                            fontFamily: 'Arial',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: normalText)),
                                    Text(currentLanguage[73],
                                        style: TextStyle(
                                            fontFamily: 'Arial',
                                            fontSize: 14,
                                            color: normalText)),
                                  ],
                                )
                              : new IconTheme(
                                  data: new IconThemeData(color: heartColor),
                                  child: IconButton(
                                    iconSize: 30,
                                    icon: whichFollowerHeart,
                                    onPressed: () async {
                                      DocumentSnapshot businessDoc =
                                          await DatabaseService()
                                              .businessCollection
                                              .doc(widget.uid)
                                              .get();

                                      // check if followed before.
                                      String followUids = "";
                                      followUids = businessDoc["followUids"];
                                      if (followUids.contains(widget.myuid)) {
                                        Fluttertoast.showToast(
                                            msg: currentLanguage[162]);
                                        return;
                                      }

                                      followUids =
                                          followUids + ":" + widget.myuid;
                                      String followDevices =
                                          businessDoc['followDevices'];
                                      followDevices = followDevices +
                                          ":" +
                                          widget.deviceToken;

                                      await businessDoc.reference.update({
                                        'followDevices': followDevices,
                                        'followUids': followUids
                                      });

                                      setState(() {
                                        whichFollowerHeart = Icon(
                                            FlutterIcons.heart_multiple_mco);
                                      });

                                      DocumentSnapshot userDoc =
                                          await DatabaseService()
                                              .userCollection
                                              .doc(widget.myuid)
                                              .get();

                                      String follows = "";
                                      follows = userDoc["followUids"];

                                      follows = follows + ":" + widget.uid;

                                      await userDoc.reference
                                          .update({'followUids': follows});

                                      String token = businessDoc['tokenDevice'];
                                      bool canSend = await PreferencesHelper()
                                          .getNotificationAlerts();

                                      if (canSend) {
                                        PushNotificationService
                                            .sendBusinessOwnerFollowerNotification(
                                                token, businessDoc.id);
                                      }
                                    },
                                  ),
                                ),
                        ]),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Container(child: businessIcon, height: 40),
                        SizedBox(width: 10),
                        Text(businessIconName,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color: normalText,
                                fontFamily: 'Arial',
                                fontSize: 22,
                                fontWeight: FontWeight.w100)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(businessAddress,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: fadeoutText, fontFamily: 'Arial')),
                            Text(currentHours,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: fadeoutText, fontFamily: 'Arial')),
                          ],
                        ),
                        businessOwned
                            ? new IconTheme(
                                data: new IconThemeData(color: heartColor),
                                child: IconButton(
                                    icon: Icon(FlutterIcons.remove_circle_mdi),
                                    onPressed: () async {
                                      bool result =
                                          await showDeletionDialog(context);

                                      if (!result) return;

                                      await firestore.runTransaction(
                                          (Transaction myTransaction) async {
                                        DocumentReference<Map<String, dynamic>>
                                            answers = await DatabaseService()
                                                .businessCollection
                                                .doc(widget.uid)
                                                .collection('posts')
                                                .doc(contentIDS[currentIndex]);

                                        myTransaction.delete(answers);
                                      });

                                      contentWidgets.clear();
                                      postLikes.clear();
                                      littleCircles.clear();
                                      contentHeights.clear();
                                      contentIDS.clear();

                                      setState(() {
                                        loaded = false;
                                        doOnce = true;
                                      });
                                    }))
                            : Container()
                      ],
                    ),
                    SizedBox(height: 10),
                    contentWidgets.length != 0
                        ? CarouselSlider(
                            carouselController: buttonCarouselController,
                            options: CarouselOptions(
                                viewportFraction: 1,
                                height: height,
                                enableInfiniteScroll: false,
                                autoPlay: false,
                                onPageChanged: (index, reason) {
                                  currentIndex = index;
                                  setState(() {
                                    height = contentHeights[index];
                                  });
                                  resetColors(index);
                                }),
                            items: contentWidgets.map((i) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 5.0),
                                      child: i);
                                },
                              );
                            }).toList(),
                          )
                        : Container(
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.asset(
                                'assets/drawable/No-content.gif',
                                fit: BoxFit.fill,
                                height: 200,
                              ),
                            ),
                          ),
                    SizedBox(height: 10),
                    Container(
                      height: 40,
                      width: size.width / 1.2,
                      child: Center(
                        child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: littleCircles.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Row(children: [
                                littleCircles[index],
                                SizedBox(width: 10)
                              ]);
                            }),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    const Divider(height: 2, thickness: 1),
                    SizedBox(
                      height: 15,
                    ),
                    InkWell(
                        onTap: () async {
                          String response = await _showDirectionsOptions();
                          if (response != '') {
                            MapsPage.comingFromBusinessPage = true;
                            MapsPage.comingFromBusinessPageResponse = response;
                            MapsPage.comingFromBusinessPageLat =
                                position.latitude.toString();
                            MapsPage.comingFromBusinessPageLong =
                                position.longitude.toString();
                            Navigator.pop(context);
                            BusinessPage.videoPictureCombiners.clear();
                          }
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                          child: Container(
                            color: fadedOutButtons,
                            padding: const EdgeInsets.all(20),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    new IconTheme(
                                      data: new IconThemeData(color: headers),
                                      child: Icon(FlutterIcons.direction_ent),
                                    ),
                                    SizedBox(width: 20),
                                    Text(
                                      currentLanguage[206],
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: normalText,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w700),
                                    )
                                  ]),
                                ]),
                          ),
                        )),
                    SizedBox(
                      height: 15,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(currentLanguage[24],
                          style: TextStyle(
                              color: headers,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Arial')),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(businessWebsite,
                          style: TextStyle(
                              color: normalText, fontFamily: 'Arial')),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    // Phone Number
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(currentLanguage[158],
                          style: TextStyle(
                              color: headers,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Arial')),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(businessNumber,
                          style: TextStyle(
                              color: normalText, fontFamily: 'Arial')),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ])));
  }

  Future<String> _showDirectionsOptions() async {
    var dropdownvalue = currentLanguage[207];
    var items = [
      currentLanguage[207].toString(),
      currentLanguage[208].toString(),
      currentLanguage[209].toString(),
      currentLanguage[210].toString()
    ];

    return showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                title: Text(currentLanguage[211],
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontFamily: 'Arial',
                        color: buttonsBorders,
                        fontWeight: FontWeight.w700)),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text(
                        currentLanguage[123],
                        textAlign: TextAlign.left,
                        style:
                            TextStyle(fontFamily: 'Arial', color: normalText),
                      ),
                      DropdownButton(
                        isExpanded: true,
                        value: dropdownvalue,
                        icon: Icon(Icons.keyboard_arrow_down_rounded),
                        items: items.map((String items) {
                          return DropdownMenuItem(
                            value: items,
                            child: Text(items,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontFamily: 'Arial', color: normalText)),
                          );
                        }).toList(),
                        onChanged: (dynamic value) {
                          setState(() {
                            dropdownvalue = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text(
                      'GO',
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: buttonsBorders,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                    style: flatButtonStyle,
                    onPressed: () {
                      Navigator.of(context).pop(dropdownvalue);
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'BACK',
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: buttonsBorders,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                    style: flatButtonStyle,
                    onPressed: () {
                      Navigator.of(context).pop('');
                    },
                  ),
                ],
              );
            },
          );
        });
  }
}

class videoPictureCombiner {
  bool isVideo;
  String url;
  String description;
  List<dynamic> tags;

  videoPictureCombiner(
      bool isVideo, String url, String description, List tags) {
    this.isVideo = isVideo;
    this.url = url;
    this.description = description;
    this.tags = tags;
  }
}
