import 'package:flutter/material.dart';
import 'package:glimpsegardens/screens/MapsHelper.dart';
import 'dart:async';
import 'package:glimpsegardens/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:glimpsegardens/shared/languages/french.dart';
import 'package:glimpsegardens/shared/languages/vietnamese.dart';
import 'package:glimpsegardens/shared/languages/greek.dart';
import 'package:glimpsegardens/shared/languages/cantonese.dart';
import 'package:glimpsegardens/shared/languages/creole.dart';
import 'package:glimpsegardens/shared/languages/english.dart';
import 'package:glimpsegardens/shared/languages/korean.dart';
import 'package:glimpsegardens/shared/languages/mandarin.dart';
import 'package:glimpsegardens/shared/languages/russian.dart';
import 'package:glimpsegardens/shared/languages/tagalog.dart';
import 'package:glimpsegardens/shared/languages/bangla.dart';
import 'package:glimpsegardens/shared/languages/spanish.dart';
import 'package:validators/validators.dart';

class ConstantsClass {
  static bool businessAccount = false;
  static bool contentAvailable = false;
  static String currentLanguageABB = "english";
}

List currentLanguage = englishPhrases;

// ignore: camel_case_types
class tagPost {
  final String message;
  final double positionx;
  final double positiony;

  tagPost(
      {@required this.message,
      @required this.positionx,
      @required this.positiony});

  Map<String, dynamic> toJson() =>
      {'message': message, 'positionx': positionx, 'positiony': positiony};
}

// ignore: camel_case_types
class businessPost {
  final String datePosted;
  final String description;
  final bool isVideo;
  final int likes;
  final String likesUids;
  final String url;
  final String expiryDate;

  businessPost(
      {@required this.url,
      @required this.likes,
      @required this.isVideo,
      @required this.datePosted,
      @required this.likesUids,
      @required this.expiryDate,
      @required this.description});

  Map<String, dynamic> toJson() => {
        'url': url,
        'likes': likes,
        'isVideo': isVideo,
        'datePosted': datePosted,
        'likesUids': likesUids,
        'expiryDate': expiryDate,
        'description': description,
      };
}

void getIfContentAvailable(String uid) async {
  if (uid == null) return;

  DocumentSnapshot infoDocument =
      await DatabaseService().userCollection.doc(uid).get();

  if (!infoDocument.exists) {
    return;
  }

  Map<String, dynamic> tester = infoDocument.data();

  if (tester['contentAvailable']) {
    ConstantsClass.contentAvailable = true;
  }
}

void changeLanguages(String language) async {
  await PreferencesHelper().setLanguage(language);
  ConstantsClass.currentLanguageABB = language;

  if (ConstantsClass.currentLanguageABB == "english") {
    currentLanguage = englishPhrases;
  } else if (ConstantsClass.currentLanguageABB == "bangla") {
    currentLanguage = banglaPhrases;
  } else if (ConstantsClass.currentLanguageABB == "creole") {
    currentLanguage = creolePhrases;
  } else if (ConstantsClass.currentLanguageABB == "greek") {
    currentLanguage = greekPhrases;
  } else if (ConstantsClass.currentLanguageABB == "mandarin") {
    currentLanguage = mandarinPhrases;
  } else if (ConstantsClass.currentLanguageABB == "cantonese") {
    currentLanguage = cantonesePhrases;
  } else if (ConstantsClass.currentLanguageABB == "russian") {
    currentLanguage = russianPhrases;
  } else if (ConstantsClass.currentLanguageABB == "tagalog") {
    currentLanguage = tagalogPhrases;
  } else if (ConstantsClass.currentLanguageABB == "french") {
    currentLanguage = frenchPhrases;
  } else if (ConstantsClass.currentLanguageABB == "spanish") {
    currentLanguage = spanishPhrases;
  } else if (ConstantsClass.currentLanguageABB == "korean") {
    currentLanguage = koreanPhrases;
  } else if (ConstantsClass.currentLanguageABB == "vietnamese") {
    currentLanguage = vietnamesePhrases;
  }
}

void getInitialLanguage() async {
  ConstantsClass.currentLanguageABB = await PreferencesHelper().getLanguage();

  if (ConstantsClass.currentLanguageABB == "english") {
    currentLanguage = englishPhrases;
  } else if (ConstantsClass.currentLanguageABB == "bangla") {
    currentLanguage = banglaPhrases;
  } else if (ConstantsClass.currentLanguageABB == "creole") {
    currentLanguage = creolePhrases;
  } else if (ConstantsClass.currentLanguageABB == "greek") {
    currentLanguage = greekPhrases;
  } else if (ConstantsClass.currentLanguageABB == "mandarin") {
    currentLanguage = mandarinPhrases;
  } else if (ConstantsClass.currentLanguageABB == "cantonese") {
    currentLanguage = cantonesePhrases;
  } else if (ConstantsClass.currentLanguageABB == "russian") {
    currentLanguage = russianPhrases;
  } else if (ConstantsClass.currentLanguageABB == "tagalog") {
    currentLanguage = tagalogPhrases;
  } else if (ConstantsClass.currentLanguageABB == "french") {
    currentLanguage = frenchPhrases;
  } else if (ConstantsClass.currentLanguageABB == "vietnamese") {
    currentLanguage = vietnamesePhrases;
  }
}

void getIfBusinessAccount(String uid) async {
  if (uid == null) return;

  DocumentSnapshot infoDocument =
      await DatabaseService().userCollection.doc(uid).get();

  if (!infoDocument.exists) {
    return;
  }

  Map<String, dynamic> tester = infoDocument.data();

  if (tester.containsKey('bName')) {
    ConstantsClass.businessAccount = true;
  } else {
    ConstantsClass.businessAccount = false;
  }
}

Timer codeTimer;

enum PinType { normal, geocached, vip }
enum CodeType { entertainment, employee, vip }

CodeType convertIndexToCodeType(int index) {
  if (index == 0) {
    return CodeType.entertainment;
  } else if (index == 1) {
    return CodeType.employee;
  } else {
    return CodeType.vip;
  }
}

PinType getPinType(String select) {
  // Used by dropdowns in requests
  if (select == "Public") {
    return PinType.normal;
  } else if (select == "Geocached") {
    return PinType.geocached;
  } else if (select == "VIP") {
    return PinType.vip;
  }
  return PinType.normal;
}

const Color fadeoutText = Color.fromRGBO(205, 202, 197, 1);
const Color normalText = Color.fromRGBO(101, 101, 101, 1);

const Color headers = Color.fromRGBO(246, 153, 0, 1);
const Color buttonsBorders = Color.fromRGBO(246, 189, 96, 1);
const Color lightTone = Color.fromRGBO(255, 218, 158, 1);
const Color fadedOutButtons = Color.fromRGBO(255, 245, 230, 1);
const Color heartColor = Color.fromRGBO(255, 130, 193, 1);
const Color notificationColor = Color.fromRGBO(255, 132, 132, 1);
const Color locationColor = Color.fromRGBO(38, 153, 251, 1);

const Color facebookBlue = Color(0xFF4267B2);
const Color appleGrey = Color(0xFF555555);
const Color twitterBlue = Color.fromRGBO(29, 161, 242, 1);
const Color googleColor = Color.fromRGBO(219, 74, 57, 1);

const List iconNames = [
  "Bar",
  "Beauty",
  "Coffee",
  "Grocery",
  "Gym",
  "Health",
  "Hotel",
  "Restaurant",
  "Shopping",
  "Theatre",
  "Tour",
  "Service"
];

List iconImages = [
  Image.asset("assets/drawable/Bar.png"),
  Image.asset("assets/drawable/Beauty.png"),
  Image.asset("assets/drawable/Coffee.png"),
  Image.asset("assets/drawable/Grocery.png"),
  Image.asset("assets/drawable/Gym.png"),
  Image.asset("assets/drawable/Health.png"),
  Image.asset("assets/drawable/Hotel.png"),
  Image.asset("assets/drawable/Restaurant.png"),
  Image.asset("assets/drawable/Shopping.png"),
  Image.asset("assets/drawable/Theatre.png"),
  Image.asset("assets/drawable/Tour.png"),
  Image.asset("assets/drawable/Services.png")
];

const double dynamicSize = 10;
List iconBitmaps = [
  "assets/drawable/Bar.png",
  "assets/drawable/Beauty.png",
  "assets/drawable/Coffee.png",
  "assets/drawable/Grocery.png",
  "assets/drawable/Gym.png",
  "assets/drawable/Health.png",
  "assets/drawable/Hotel.png",
  "assets/drawable/Restaurant.png",
  "assets/drawable/Shopping.png",
  "assets/drawable/Theatre.png",
  "assets/drawable/Tour.png",
  "assets/drawable/Services.png"
];

List iconBitmapsMarked = [
  "assets/drawable/Bar-M.png",
  "assets/drawable/Beauty-M.png",
  "assets/drawable/Coffee-M.png",
  "assets/drawable/Grocery-M.png",
  "assets/drawable/Gym-M.png",
  "assets/drawable/Health-M.png",
  "assets/drawable/Hotel-M.png",
  "assets/drawable/Restaurant-M.png",
  "assets/drawable/Shopping-M.png",
  "assets/drawable/Theatre-M.png",
  "assets/drawable/Tour-M.png",
  "assets/drawable/Services-M.png"
];

const Map linkedBusinesses = {
  'Bar': 0,
  'Beauty': 1,
  'Coffee': 2,
  'Grocery': 3,
  'Gym': 4,
  'Health': 5,
  'Hotel': 6,
  'Restaurant': 7,
  'Shopping': 8,
  'Theatre': 9,
  'Tour': 10,
  'Services': 11
};

const String mapStyle = '''[
    {
        "featureType": "administrative",
        "elementType": "labels.text.fill",
        "stylers": [
            {
                "color": "#6195a0"
            }
        ]
    },
    {
        "featureType": "administrative.province",
        "elementType": "geometry.stroke",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "landscape",
        "elementType": "geometry",
        "stylers": [
            {
                "lightness": "0"
            },
            {
                "saturation": "0"
            },
            {
                "color": "#f5f5f2"
            },
            {
                "gamma": "1"
            }
        ]
    },
    {
        "featureType": "landscape.man_made",
        "elementType": "all",
        "stylers": [
            {
                "lightness": "-3"
            },
            {
                "gamma": "1.00"
            }
        ]
    },
    {
        "featureType": "landscape.natural.terrain",
        "elementType": "all",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "poi",
        "elementType": "all",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "poi.park",
        "elementType": "geometry.fill",
        "stylers": [
            {
                "color": "#bae5ce"
            },
            {
                "visibility": "on"
            }
        ]
    },
    {
        "featureType": "road",
        "elementType": "all",
        "stylers": [
            {
                "saturation": -100
            },
            {
                "lightness": 45
            },
            {
                "visibility": "simplified"
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "all",
        "stylers": [
            {
                "visibility": "simplified"
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "geometry.fill",
        "stylers": [
            {
                "color": "#fac9a9"
            },
            {
                "visibility": "simplified"
            }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "labels.text",
        "stylers": [
            {
                "color": "#4e4e4e"
            }
        ]
    },
    {
        "featureType": "road.arterial",
        "elementType": "labels.text.fill",
        "stylers": [
            {
                "color": "#787878"
            }
        ]
    },
    {
        "featureType": "road.arterial",
        "elementType": "labels.icon",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "transit",
        "elementType": "all",
        "stylers": [
            {
                "visibility": "simplified"
            }
        ]
    },
    {
        "featureType": "transit.station.airport",
        "elementType": "labels.icon",
        "stylers": [
            {
                "hue": "#0a00ff"
            },
            {
                "saturation": "-77"
            },
            {
                "gamma": "0.57"
            },
            {
                "lightness": "0"
            }
        ]
    },
    {
        "featureType": "transit.station.rail",
        "elementType": "labels.text.fill",
        "stylers": [
            {
                "color": "#43321e"
            }
        ]
    },
    {
        "featureType": "transit.station.rail",
        "elementType": "labels.icon",
        "stylers": [
            {
                "hue": "#ff6c00"
            },
            {
                "lightness": "4"
            },
            {
                "gamma": "0.75"
            },
            {
                "saturation": "-68"
            }
        ]
    },
    {
        "featureType": "water",
        "elementType": "all",
        "stylers": [
            {
                "color": "#eaf6f8"
            },
            {
                "visibility": "on"
            }
        ]
    },
    {
        "featureType": "water",
        "elementType": "geometry.fill",
        "stylers": [
            {
                "color": "#c7eced"
            }
        ]
    },
    {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
            {
                "lightness": "-49"
            },
            {
                "saturation": "-53"
            },
            {
                "gamma": "0.79"
            }
        ]
    }
]''';

List<BottomNavigationBarItem> navBottomListSeperate = [
  BottomNavigationBarItem(
    icon: const Icon(Icons.map),
    label: currentLanguage[219],
  ),
  BottomNavigationBarItem(
    icon: const Icon(Icons.settings),
    label: currentLanguage[221],
  ),
];

List<BottomNavigationBarItem> navBottomList = [
  BottomNavigationBarItem(
    icon: const Icon(Icons.map),
    label: currentLanguage[219],
  ),
  BottomNavigationBarItem(
    icon: const Icon(Icons.camera_alt),
    label: currentLanguage[220],
  ),
  BottomNavigationBarItem(
    icon: const Icon(Icons.settings),
    label: currentLanguage[221],
  ),
];

bool codeValidation(String enteredCode) {
  if (enteredCode.split('-').length != 4) {
    return false;
  }

  String firstLink = enteredCode.split('-')[0];
  String secondLink = enteredCode.split('-')[1];
  String thirdLink = enteredCode.split('-')[2];
  String fourthLink = enteredCode.split('-')[3];

  if (firstLink.length != 4 ||
      secondLink.length != 4 ||
      thirdLink.length != 4 ||
      fourthLink.length != 4) {
    return false;
  }

  if (isNumeric(firstLink) &&
      isNumeric(secondLink) &&
      isNumeric(thirdLink) &&
      isNumeric(fourthLink)) {
    return true;
  }
  return false;
}

bool secondaryCodeValidation(String enteredCode, DocumentSnapshot parent) {
  int prime = int.parse(parent['second']);
  int full = int.parse(enteredCode.split('-')[2] + enteredCode.split('-')[3]);

  if (full % prime == 0) {
    return true;
  }
  return false;
}

String convertCodeIntoFirstHalf(String enteredCode) {
  String firstLink = enteredCode.split('-')[0];
  String secondLink = enteredCode.split('-')[1];

  int fullFirstHalf = int.parse(firstLink) + int.parse(secondLink);

  String firstNumber = fullFirstHalf.toString();
  while (firstNumber.length != 4) {
    firstNumber = "0" + firstNumber;
  }

  return firstNumber;
}

Future<CodeType> findCodeType(
    String enteredCode, DocumentSnapshot parent) async {
  int prime = int.parse(parent['second']);
  int minimum = 10000000 ~/ prime;
  minimum++;

  String full = enteredCode.split('-')[2] + enteredCode.split('-')[3];
  int parentMultiple = int.parse(full);
  parentMultiple = parentMultiple ~/ prime;
  parentMultiple -= minimum;

  CollectionReference pinsCollection =
      parent.reference.collection("Event Info").doc("Info").collection("Pins");
  QuerySnapshot pinsReference = await pinsCollection.get();

  int maxEmployeeCodes = 0;

  for (DocumentSnapshot pinDoc in pinsReference.docs) {
    maxEmployeeCodes = maxEmployeeCodes + pinDoc['EmployeeCodes'];
  }

  DocumentSnapshot infoDocument =
      await parent.reference.collection("Event Info").doc("Info").get();

  int vipCodes = infoDocument["VIPcodes"];
  int entertainmentCodes = infoDocument["Ecodes"];

  int firstCarry = maxEmployeeCodes;
  int secondCarry = maxEmployeeCodes + entertainmentCodes;

  if (parentMultiple >= 0 && parentMultiple < maxEmployeeCodes) {
    print("Code is Employee type.");
    return CodeType.employee;
  } else if (parentMultiple >= firstCarry && parentMultiple < secondCarry) {
    print("Code is Entertainment type.");
    return CodeType.entertainment;
  } else if (parentMultiple >= secondCarry &&
      parentMultiple < secondCarry + vipCodes) {
    print("Code is VIP type.");
    return CodeType.vip;
  }

  return null;
}

Future<bool> testCodeLinkedToAccount(
    DocumentSnapshot codeSnap, String _uid, CodeType type) async {
  DocumentSnapshot infoDoc =
      await codeSnap.reference.collection("Event Info").doc("Info").get();

  DocumentSnapshot user =
      await DatabaseService().userCollection.doc(_uid).get();
  // Probably the best solution is to keep track of the time on the user's account.
  Map<String, dynamic> tester = user.data();
  if (!tester.containsKey("enteredCode") || user['enteredCode'] == "") {
    MapsHelper.removeCodeMaterials();
    if (codeTimer != null && codeTimer.isActive) codeTimer.cancel();
    return true;
  }

  int timestamp = int.parse(user['timestamp']);

  DateTime now = new DateTime.now();
  DateTime convertedTimestamp =
      new DateTime.fromMillisecondsSinceEpoch(timestamp);
  Duration difference = now.difference(convertedTimestamp);

  if (double.parse(difference.inMinutes.toString()) / 60.0 >=
      infoDoc['Length']) {
    firestore.runTransaction((Transaction myTransaction) async {
      myTransaction.update(user.reference, {'currentParent': ""});
      myTransaction.update(user.reference, {'currentCodeType': -1});
      myTransaction.update(user.reference, {'timestamp': ""});
      myTransaction.update(user.reference, {'enteredCode': ""});
    });
    MapsHelper.removeCodeMaterials();
    if (codeTimer != null && codeTimer.isActive) codeTimer.cancel();
  } else {
    MapsHelper.gatherCodeMaterials(codeSnap, type, user['enteredCode']);
  }

  return true;
}

InputDecoration textInputDecoration = const InputDecoration(
  hintStyle: TextStyle(color: normalText),
  contentPadding: EdgeInsets.symmetric(horizontal: 24.0),
  fillColor: Colors.white,
  filled: true,
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: lightTone),
    borderRadius: BorderRadius.all(Radius.circular(50)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: lightTone),
    borderRadius: BorderRadius.all(Radius.circular(50)),
  ),
  border: OutlineInputBorder(
    borderSide: BorderSide(color: lightTone),
    borderRadius: BorderRadius.all(Radius.circular(50)),
  ),
);

InputDecoration businessRegisterInputDecoration = const InputDecoration(
  hintStyle: TextStyle(color: headers),
  contentPadding: EdgeInsets.symmetric(horizontal: 24.0),
  fillColor: Colors.white,
  filled: true,
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: buttonsBorders),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: buttonsBorders),
  ),
  border: OutlineInputBorder(
    borderSide: BorderSide(color: buttonsBorders),
  ),
);

InputDecoration registerTextInputDecoration = const InputDecoration(
  hintStyle: TextStyle(color: normalText),
  fillColor: Colors.white,
  filled: true,
  enabledBorder: UnderlineInputBorder(
    borderSide: BorderSide(color: lightTone),
  ),
  focusedBorder: UnderlineInputBorder(
    borderSide: BorderSide(color: lightTone),
  ),
  border: UnderlineInputBorder(
    borderSide: BorderSide(color: lightTone),
  ),
);

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  primary: Colors.black87,
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2.0)),
  ),
);

ButtonStyle flatButtonStyleExtra = TextButton.styleFrom(
  primary: Colors.black87,
  backgroundColor: Colors.blueGrey.shade100,
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
      side: const BorderSide(color: Color(0xFFB0BEC5), width: 5)),
  minimumSize: const Size(350, 50),
);

const TextStyle loginPageTextStyle =
    TextStyle(fontSize: 17, fontFamily: 'CircularBold');

ButtonStyle loginPageButtonStyle = TextButton.styleFrom(
  primary: Colors.white,
  backgroundColor: buttonsBorders,
  textStyle: loginPageTextStyle,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(50.0),
  ),
  minimumSize: const Size(325, 50),
);

ButtonStyle settingsPageButtonStyle = TextButton.styleFrom(
  alignment: Alignment.centerLeft,
  primary: buttonsBorders,
  backgroundColor: Colors.grey[100],
  textStyle: loginPageTextStyle,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5.0),
  ),
  minimumSize: const Size(325, 50),
);

ButtonStyle registerPageButtonStyle = TextButton.styleFrom(
  primary: buttonsBorders,
  backgroundColor: Colors.white,
  textStyle: loginPageTextStyle,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5.0),
    side: const BorderSide(width: 2, color: lightTone),
  ),
  minimumSize: const Size(325, 50),
);

ButtonStyle loginPageFacebookStyle = TextButton.styleFrom(
  primary: Colors.white,
  backgroundColor: facebookBlue,
  textStyle: loginPageTextStyle,
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
      side: const BorderSide(color: buttonsBorders, width: 5)),
  minimumSize: const Size(350, 50),
);
