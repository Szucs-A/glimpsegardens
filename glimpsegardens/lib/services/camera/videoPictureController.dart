import 'package:flutter/material.dart';
import 'package:glimpsegardens/shared/constants.dart';

import 'dart:async';
import 'dart:io';

import 'package:exif/exif.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/BusinessPage.dart';
import 'package:glimpsegardens/screens/maps.dart';
import 'package:glimpsegardens/screens/mapshelper.dart';
import 'package:glimpsegardens/screens/loading.dart';
import 'package:glimpsegardens/shared/constants.dart';
// import 'package:glimpsegardens/screens/settings.dart';
import 'package:glimpsegardens/screens/VideoPlayerScreen.dart';
import 'package:glimpsegardens/services/camera/display_picture_screen.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:carousel_slider/carousel_slider.dart';

class videoPictureController extends StatefulWidget {
  videoPictureController({Key key}) : super(key: key);

  @override
  _videoPictureController createState() => _videoPictureController();
}

class _videoPictureController extends State<videoPictureController> {
  List mappingItems = [];

  @protected
  @mustCallSuper
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
        body: Stack(children: [
      Container(
          height: size.height,
          width: size.width,
          child: CarouselSlider(
            options: CarouselOptions(
              height: size.height,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: false,
            ),
            items: BusinessPage.videoPictureCombiners.map((element) {
              if (!element.isVideo) {
                return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: 0.0),
                    child: DisplayPictureScreen(
                      imagePath: null,
                      imageUrl: element.url,
                      imageMessage: element.description,
                      simplify: true,
                      tags: element.tags,
                    ));
              } else {
                return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: 0.0),
                    child: VideoPlayerScreen(
                      videoPath: null,
                      videoUrl: element.url,
                      videoMessage: element.description,
                      simplify: true,
                      tags: element.tags,
                    ));
              }
            }).toList(),
          )),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 25),
          Container(
              margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
              decoration:
                  BoxDecoration(color: lightTone, shape: BoxShape.circle),
              child: new IconTheme(
                data: new IconThemeData(color: Colors.white),
                child: IconButton(
                  icon: new Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              )),
        ],
      ),
    ]));
  }
}
