// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'package:glimpsegardens/shared/constants.dart';

import 'package:flutter/material.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';

class languageSettings extends StatefulWidget {
  @override
  _languageSettings createState() => _languageSettings();
}

class _languageSettings extends State<languageSettings> {
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                          currentLanguage[96],
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("English",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('english');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Español",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('spanish');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Mandarin",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('mandarin');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Cantonese",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('cantonese');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Korean",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('korean');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Bangla",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('bangla');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Russian",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('russian');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Greek",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('greek');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Tagalog",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('tagalog');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("French",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('french');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Creole",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('creole');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(height: 2, thickness: 2),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: TextButton(
                style: TextButton.styleFrom(fixedSize: Size.fromHeight(50)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Vietnamese",
                      style: TextStyle(
                          fontFamily: 'Arial',
                          color: normalText,
                          fontSize: 18)),
                ),
                onPressed: () {
                  changeLanguages('vietnamese');
                },
              )),
            ]),
          ),
          SizedBox(
            height: 10,
          ),
        ],
      )),
    );
  }
}
