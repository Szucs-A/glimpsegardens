import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/businessOrUser.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:glimpsegardens/services/database.dart';
import 'package:glimpsegardens/screens/start_up/wrapper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusinessEditPage extends StatefulWidget {
  BusinessEditPage({
    Key key,
  }) : super(key: key);
  @override
  _BusinessEditPage createState() => _BusinessEditPage();
}

class _BusinessEditPage extends State<BusinessEditPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  CarouselController buttonCarouselController = CarouselController();
  bool loading = false;

  HoursOfOperation businessHours =
      HoursOfOperation(week: [null, null, null, null, null, null, null]);

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  showHourPopUp(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double opacity = 1.0;

    double littleCircleSize = 6;

    int currentDayIndex = 0;
    String currentDay = "Monday";
    List times = [];

    List<TimeRanges> hours = [null, null, null, null, null, null, null];
    List onOrOffs = [false, false, false, false, false, false, false];

    if (businessHours != null) {
      for (int i = 0; i < 7; i++) {
        if (businessHours.week[i] == null) {
          onOrOffs[i] = false;
          hours[i] = null;
        } else {
          onOrOffs[i] = true;
          hours[i] = businessHours.week[i];
        }
      }
    }

    List days = [
      currentLanguage[56],
      currentLanguage[57],
      currentLanguage[58],
      currentLanguage[59],
      currentLanguage[60],
      currentLanguage[61],
      currentLanguage[62]
    ];

    List tempTimes = [
      '12:00',
      '1:00',
      '2:00',
      '3:00',
      '4:00',
      '5:00',
      '6:00',
      '7:00',
      '8:00',
      '9:00',
      '10:00',
      '11:00'
    ];

    tempTimes.forEach((element) {
      times.add(element + ' am');
    });

    tempTimes.forEach((element) {
      times.add(element + ' pm');
    });

    List littleCircles = <Widget>[];
    for (int i = 0; i < 7; i++) {
      if (i == 0) {
        littleCircles.add(new Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: new BoxDecoration(
            color: buttonsBorders,
            shape: BoxShape.circle,
          ),
        ));
      } else {
        littleCircles.add(new Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: new BoxDecoration(
            color: lightTone,
            shape: BoxShape.circle,
          ),
        ));
      }
    }

    resetColors(int index) {
      littleCircles.clear();
      for (int i = 0; i < 7; i++) {
        if (i == index) {
          littleCircles.add(new Container(
            width: littleCircleSize,
            height: littleCircleSize,
            decoration: new BoxDecoration(
              color: buttonsBorders,
              shape: BoxShape.circle,
            ),
          ));
        } else {
          littleCircles.add(new Container(
            width: littleCircleSize,
            height: littleCircleSize,
            decoration: new BoxDecoration(
              color: lightTone,
              shape: BoxShape.circle,
            ),
          ));
        }
      }
    }

    changeOpacity() {
      opacity = 0.0;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: Colors.white,
                    width: size.width / 1.2,
                    height: 100,
                    child: CarouselSlider(
                      carouselController: buttonCarouselController,
                      options: CarouselOptions(
                          enableInfiniteScroll: false,
                          autoPlay: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              changeOpacity();
                              resetColors(index);
                              currentDay = days[index];
                              currentDayIndex = index;
                            });
                          }),
                      items: days.map((i) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                                child: Center(
                                    child: Text(i,
                                        style: TextStyle(
                                            fontSize: 36,
                                            color: normalText,
                                            fontFamily: 'Arial'))));
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Container(
                    height: 40,
                    width: size.width / 1.2,
                    child: Center(
                      child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: littleCircles.length,
                          itemBuilder: (BuildContext context, int index) {
                            return index == littleCircles.length - 1
                                ? Row(children: [
                                    littleCircles[index],
                                  ])
                                : Row(children: [
                                    littleCircles[index],
                                    SizedBox(width: 10)
                                  ]);
                          }),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2.0),
                            border: Border.all(
                              color: buttonsBorders,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            iconEnabledColor: buttonsBorders,
                            iconDisabledColor: buttonsBorders,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 10),
                              border: InputBorder.none,
                            ),
                            items: times.map((value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: TextStyle(
                                        color: normalText,
                                        fontFamily: 'Arial')),
                              );
                            }).toList(),
                            value: hours[currentDayIndex] == null
                                ? '12:00 am'
                                : hours[currentDayIndex].openTime, // HERE,
                            onChanged: (index) {
                              setState(() {
                                if (hours[currentDayIndex] == null) {
                                  hours[currentDayIndex] =
                                      new TimeRanges(openTime: index);
                                } else {
                                  hours[currentDayIndex].openTime = index;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2.0),
                            border: Border.all(
                              color: buttonsBorders,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            iconEnabledColor: buttonsBorders,
                            iconDisabledColor: buttonsBorders,
                            isDense: true,
                            itemHeight: 50,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 10),
                            ),
                            items: times.map((value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: TextStyle(
                                        color: normalText,
                                        fontFamily: 'Arial')),
                              );
                            }).toList(),
                            value: hours[currentDayIndex] == null
                                ? '12:00 am'
                                : hours[currentDayIndex].closeTime, // HERE,
                            onChanged: (index) {
                              setState(() {
                                if (hours[currentDayIndex] == null) {
                                  hours[currentDayIndex] =
                                      new TimeRanges(closeTime: index);
                                } else {
                                  hours[currentDayIndex].closeTime = index;
                                }
                              });
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(currentLanguage[81] + " $currentDay",
                          style: TextStyle(
                              color: normalText, fontFamily: 'Arial')),
                      FlutterSwitch(
                        height: 30,
                        width: 60,
                        toggleSize: 15,
                        value: onOrOffs[currentDayIndex],
                        activeColor: buttonsBorders,
                        onToggle: (value) {
                          setState(() {
                            onOrOffs[currentDayIndex] =
                                !onOrOffs[currentDayIndex];
                            if (!onOrOffs[currentDayIndex]) {
                              hours[currentDayIndex] = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  const Divider(
                    height: 20,
                    thickness: 2,
                  ),
                  SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: Padding(
                          child: TextButton(
                              style: TextButton.styleFrom(
                                alignment: Alignment.center,
                                primary: Colors.white,
                                minimumSize: Size(325, 50),
                                backgroundColor: buttonsBorders,
                                textStyle: loginPageTextStyle,
                                shape: RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(5.0),
                                ),
                              ),
                              child: Text(currentLanguage[10],
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      fontFamily: 'Arial')),
                              onPressed: () async {
                                User user =
                                    await FirebaseAuth.instance.currentUser;
                                String uid = user.uid;

                                var doc = await DatabaseService()
                                    .userCollection
                                    .doc(uid)
                                    .get();
                                if (!doc.exists) return;

                                List<TimeRanges> complete = [];
                                for (int i = 0; i < 7; i++) {
                                  if (!onOrOffs[i]) {
                                    complete.add(null);
                                  } else {
                                    complete.add(hours[i]);
                                  }
                                }
                                businessHours =
                                    new HoursOfOperation(week: complete);

                                await DatabaseService()
                                    .userCollection
                                    .doc(uid)
                                    .update({
                                  'Monday': businessHours.week[0] == null
                                      ? "Closed"
                                      : businessHours.week[0].printMeBusiness(),
                                  'Tuesday': businessHours.week[1] == null
                                      ? "Closed"
                                      : businessHours.week[1].printMeBusiness(),
                                  'Wednesday': businessHours.week[2] == null
                                      ? "Closed"
                                      : businessHours.week[2].printMeBusiness(),
                                  'Thursday': businessHours.week[3] == null
                                      ? "Closed"
                                      : businessHours.week[3].printMeBusiness(),
                                  'Friday': businessHours.week[4] == null
                                      ? "Closed"
                                      : businessHours.week[4].printMeBusiness(),
                                  'Saturday': businessHours.week[5] == null
                                      ? "Closed"
                                      : businessHours.week[5].printMeBusiness(),
                                  'Sunday': businessHours.week[6] == null
                                      ? "Closed"
                                      : businessHours.week[6].printMeBusiness(),
                                });

                                Navigator.pop(context);
                              }),
                          padding: EdgeInsets.symmetric(horizontal: 10)),
                    ),
                  ]),
                  SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: Padding(
                          child: TextButton(
                              style: TextButton.styleFrom(
                                alignment: Alignment.center,
                                primary: Colors.white,
                                minimumSize: Size(325, 50),
                                backgroundColor: buttonsBorders,
                                textStyle: loginPageTextStyle,
                                shape: RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(5.0),
                                ),
                              ),
                              child: Text(currentLanguage[214],
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      fontFamily: 'Arial')),
                              onPressed: () {
                                Navigator.pop(context);
                              }),
                          padding: EdgeInsets.symmetric(horizontal: 10)),
                    ),
                  ])
                ],
              ),
            ),
            shape: RoundedRectangleBorder(),
          );
        });
      },
    );
  }

  void showFillingInInformationDialog(BuildContext context) async {
    Widget continueButton = TextButton(
      child: Text(currentLanguage[13],
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
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentLanguage[29],
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 18,
                    color: buttonsBorders,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            Text(currentLanguage[30],
                textAlign: TextAlign.left,
                style: TextStyle(fontFamily: 'Arial', color: normalText)),
            SizedBox(height: 20),
            Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(child: continueButton), //button 2
                ])
          ]),
    );

    // show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 25),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 25),
                    Stack(
                      children: [
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: Center(
                            child: Text(
                              currentLanguage[100],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 17,
                                  color: normalText,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Arial'),
                            ),
                          ),
                        ),
                        Container(
                            alignment: Alignment.centerLeft,
                            child: new IconTheme(
                              data: new IconThemeData(color: normalText),
                              child: IconButton(
                                icon: new Icon(Icons.arrow_back),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ))
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(currentLanguage[27],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: headers,
                              fontFamily: 'Arial',
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(children: [
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: loading,
                          child: TextButton(
                              style: TextButton.styleFrom(
                                alignment: Alignment.center,
                                primary: Colors.white,
                                backgroundColor: buttonsBorders,
                                textStyle: loginPageTextStyle,
                                minimumSize: Size(325, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(5.0),
                                ),
                              ),
                              child: Text(currentLanguage[289],
                                  style: TextStyle(
                                    fontFamily: 'Arial',
                                  )),
                              onPressed: () {
                                showHourPopUp(context);
                              }),
                        ),
                      ),
                    ]),
                  ],
                ),
              )),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HoursOfOperation {
  // Set to null for not open.
  final List<TimeRanges> week;

  HoursOfOperation({
    this.week,
  });
}

class TimeRanges {
  String openTime;
  String closeTime;

  printMe() {
    print("openTime: " + openTime + " closeTime: " + closeTime);
  }

  String printMeBusiness() {
    return "Open: " + openTime + " to " + closeTime;
  }

  TimeRanges({
    this.openTime = "12:00 am",
    this.closeTime = "12:00 am",
  });
}
