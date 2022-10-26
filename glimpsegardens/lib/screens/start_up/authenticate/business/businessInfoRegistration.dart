import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glimpsegardens/services/auth.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/businessOrUser.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/start_up/wrapper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusinessInfoRegistration extends StatefulWidget {
  final PassingUser pUser;
  final int businessType;
  final LatLng pos;

  const BusinessInfoRegistration(
      {Key key,
      @required this.pUser,
      @required this.businessType,
      @required this.pos})
      : super(key: key);
  @override
  _BusinessInfoRegistration createState() => _BusinessInfoRegistration();
}

class _BusinessInfoRegistration extends State<BusinessInfoRegistration>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  CarouselController buttonCarouselController = CarouselController();
  bool loading = false;

  final AuthService _auth = AuthService();
  String businessName;
  String businessAddress;
  String businessNumber = "";
  String businessWebsite = "";
  HoursOfOperation businessHours =
      HoursOfOperation(week: [null, null, null, null, null, null, null]);

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  showHourPopUp(BuildContext context) {
    final size = MediaQuery.of(context).size;
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

    // ignore: avoid_function_literals_in_foreach_calls
    tempTimes.forEach((element) {
      times.add(element + ' am');
    });

    // ignore: avoid_function_literals_in_foreach_calls
    tempTimes.forEach((element) {
      times.add(element + ' pm');
    });

    List littleCircles = <Widget>[];
    for (int i = 0; i < 7; i++) {
      if (i == 0) {
        littleCircles.add(Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: const BoxDecoration(
            color: buttonsBorders,
            shape: BoxShape.circle,
          ),
        ));
      } else {
        littleCircles.add(Container(
          width: littleCircleSize,
          height: littleCircleSize,
          decoration: const BoxDecoration(
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
          littleCircles.add(Container(
            width: littleCircleSize,
            height: littleCircleSize,
            decoration: const BoxDecoration(
              color: buttonsBorders,
              shape: BoxShape.circle,
            ),
          ));
        } else {
          littleCircles.add(Container(
            width: littleCircleSize,
            height: littleCircleSize,
            decoration: const BoxDecoration(
              color: lightTone,
              shape: BoxShape.circle,
            ),
          ));
        }
      }
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
                              resetColors(index);
                              currentDay = days[index];
                              currentDayIndex = index;
                            });
                          }),
                      items: days.map((i) {
                        return Builder(
                          builder: (BuildContext context) {
                            // ignore: avoid_unnecessary_containers
                            return Container(
                                child: Center(
                                    child: Text(i,
                                        style: const TextStyle(
                                            fontSize: 36,
                                            color: normalText,
                                            fontFamily: 'Arial'))));
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  // ignore: sized_box_for_whitespace
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
                                    const SizedBox(width: 10)
                                  ]);
                          }),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 10),
                              border: InputBorder.none,
                            ),
                            items: times.map((value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: const TextStyle(
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
                                      TimeRanges(openTime: index);
                                } else {
                                  hours[currentDayIndex].openTime = index;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 10),
                            ),
                            items: times.map((value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: const TextStyle(
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
                                      TimeRanges(closeTime: index);
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(currentLanguage[81] + currentDay,
                          style: const TextStyle(
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
                  const SizedBox(height: 20),
                  const Divider(
                    height: 20,
                    thickness: 2,
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: Padding(
                          child: TextButton(
                              style: TextButton.styleFrom(
                                alignment: Alignment.center,
                                primary: Colors.white,
                                minimumSize: const Size(325, 50),
                                backgroundColor: buttonsBorders,
                                textStyle: loginPageTextStyle,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              child: Text(currentLanguage[10],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      fontFamily: 'Arial')),
                              onPressed: () {
                                List<TimeRanges> complete = [];
                                for (int i = 0; i < 7; i++) {
                                  if (!onOrOffs[i]) {
                                    complete.add(null);
                                  } else {
                                    complete.add(hours[i]);
                                  }
                                }
                                businessHours =
                                    HoursOfOperation(week: complete);
                                Navigator.pop(context);
                              }),
                          padding: const EdgeInsets.symmetric(horizontal: 10)),
                    ),
                  ])
                ],
              ),
            ),
            shape: const RoundedRectangleBorder(),
          );
        });
      },
    );
  }

  // Stolen from the login page
  showAlertDialog(BuildContext context, String title, String msg,
      [bool success = false]) {
    Widget okButton = TextButton(
      child: Text(currentLanguage[13]),
      onPressed: () {
        if (success) {
          _auth.signOut().then((value) => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const Wrapper())));
        } else {
          Navigator.pop(context);
        }
      },
      style: flatButtonStyle,
    );

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(msg),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0))),
      actions: <Widget>[okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void showFillingInInformationDialog(BuildContext context) async {
    Widget continueButton = TextButton(
      child: Text(currentLanguage[13],
          style: const TextStyle(
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
                style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 18,
                    color: buttonsBorders,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(currentLanguage[30],
                textAlign: TextAlign.left,
                style: const TextStyle(fontFamily: 'Arial', color: normalText)),
            const SizedBox(height: 20),
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
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(
                        icon: const IconTheme(
                          data: IconThemeData(color: normalText),
                          child: Icon(Icons.arrow_back),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ]),
                    Text(currentLanguage[19],
                        style: const TextStyle(
                            fontFamily: 'Arial',
                            color: headers,
                            fontSize: 40,
                            fontWeight: FontWeight.w200)),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(currentLanguage[20],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Arial',
                            color: normalText,
                            fontSize: 22,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(
                      height: 30,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("*" + currentLanguage[21],
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              fontFamily: 'Arial',
                              color: headers,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return currentLanguage[156];
                        }
                        return null;
                      },
                      keyboardType: TextInputType.visiblePassword,
                      onChanged: (value) => {businessName = value},
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(
                          color: normalText, decoration: TextDecoration.none),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(254),
                      ],
                      decoration: businessRegisterInputDecoration,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("*" + currentLanguage[23],
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              fontFamily: 'Arial',
                              color: headers,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      onChanged: (value) => {businessAddress = value},
                      autocorrect: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return currentLanguage[157];
                        }
                        return null;
                      },
                      enableSuggestions: false,
                      style: const TextStyle(
                          color: normalText, decoration: TextDecoration.none),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(128),
                      ],
                      decoration: businessRegisterInputDecoration,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(currentLanguage[158],
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              fontFamily: 'Arial',
                              color: headers,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      autocorrect: false,
                      onChanged: (value) => {businessNumber = value},
                      enableSuggestions: false,
                      style: const TextStyle(
                          color: normalText, decoration: TextDecoration.none),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(128),
                      ],
                      decoration: businessRegisterInputDecoration,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(currentLanguage[24],
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              fontFamily: 'Arial',
                              color: headers,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      autocorrect: false,
                      onChanged: (value) => {businessWebsite = value},
                      enableSuggestions: false,
                      style: const TextStyle(
                          color: normalText, decoration: TextDecoration.none),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(128),
                      ],
                      decoration: businessRegisterInputDecoration,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(currentLanguage[27],
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              color: headers,
                              fontFamily: 'Arial',
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(children: [
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: loading,
                          child: TextButton(
                              style: TextButton.styleFrom(
                                alignment: Alignment.center,
                                primary: buttonsBorders,
                                backgroundColor: lightTone,
                                textStyle: loginPageTextStyle,
                                minimumSize: const Size(325, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              child: const IconTheme(
                                data: IconThemeData(color: Colors.white),
                                child: Icon(Icons.arrow_forward),
                              ),
                              onPressed: () {
                                showHourPopUp(context);
                              }),
                        ),
                      ),
                    ]),
                    const SizedBox(
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
                                minimumSize: const Size(325, 60),
                                backgroundColor: buttonsBorders,
                                textStyle: loginPageTextStyle,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              child: const Text('REGISTER',
                                  style: TextStyle(
                                      fontFamily: 'Arial',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              onPressed: () async {
                                if (_formKey.currentState.validate()) {
                                  setState(() {
                                    loading = true;
                                  });
                                  String result = await _auth
                                      .registerWithEmailAndPasswordBusiness(
                                          widget.pUser.email
                                              .toLowerCase()
                                              .trim(),
                                          widget.pUser.password,
                                          widget.pUser.name,
                                          BusinessInformation(
                                              bname: businessName,
                                              address: businessAddress,
                                              website: businessWebsite,
                                              hours: businessHours,
                                              pos: widget.pos,
                                              type: widget.businessType,
                                              number: businessNumber));
                                  if (result != "") {
                                    setState(() {
                                      loading = false;
                                    });

                                    showAlertDialog(
                                        context, result, currentLanguage[142]);
                                  } else {
                                    setState(() {
                                      loading = false;
                                    });
                                    // Go back to sign in page after popup indicating
                                    // that we sent a verification email.
                                    // Once the user taps 'ok', we send them back to
                                    // the login screen and log them out of the app
                                    showAlertDialog(
                                        context,
                                        currentLanguage[130],
                                        currentLanguage[144],
                                        true);
                                  }
                                }
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

class BusinessInformation {
  final String bname;
  final String address;
  final String website;
  final String number;
  final HoursOfOperation hours;
  final int type;
  final LatLng pos;

  BusinessInformation({
    this.bname,
    this.address,
    this.website,
    this.hours,
    this.type,
    this.pos,
    this.number,
  });
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
    // ignore: avoid_print
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
