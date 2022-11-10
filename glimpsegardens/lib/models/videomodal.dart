import 'package:flutter/material.dart';
import 'package:glimpsegardens/models/videomodalbutton.dart';
import 'package:glimpsegardens/models/reportbutton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/models/likebutton.dart';
import 'package:glimpsegardens/shared/constants.dart';

class VideoModal extends StatelessWidget {
  final String name;
  final String message;
  final int likes;
  final DocumentSnapshot doc;
  final String uid;
  final String userName;
  final List<DocumentSnapshot> videosReported;
  final bool isVideo;
  final String url;
  final String interstitialAdId;

  VideoModal(
      this.name,
      this.message,
      this.likes,
      this.doc,
      this.uid,
      this.userName,
      this.videosReported,
      this.isVideo,
      this.url,
      this.interstitialAdId);

  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new Padding(
          padding: EdgeInsets.only(left: 25, right: 25, top: 15, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 182, 46),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: new Center(
              child: new Column(
                children: <Widget>[
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    name.trim() + " " + currentLanguage[282] + ",",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 3,
                  ),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
        LikeButton(likes, doc, uid),
        SizedBox(
          height: 15,
        ),
        VideoModalButton(isVideo, url, message, interstitialAdId),
        Padding(
          child: Align(
            alignment: Alignment.center,
            child: ReportButton(false, doc, userName, videosReported),
          ),
          padding: EdgeInsets.only(left: 0, top: 0),
        ),
      ],
    );
  }
}
