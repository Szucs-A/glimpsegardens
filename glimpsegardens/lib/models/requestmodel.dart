// ignore_for_file: sized_box_for_whitespace, avoid_print

import 'package:flutter/material.dart';
import 'package:glimpsegardens/models/messageitem.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/VideoPlayerScreen.dart';
import 'package:glimpsegardens/services/camera/display_picture_screen.dart';
import 'package:glimpsegardens/models/reportbutton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/models/followbutton.dart';
import 'package:glimpsegardens/models/likebutton.dart';
import 'answermodalbutton.dart';

class RequestModal extends StatelessWidget {
  final String name;
  final String message;
  final List<MessageItem> videos;
  final int followers;
  final int proximityInMeters;
  final int likes;
  final String id;
  final DocumentSnapshot doc;
  final String uid;
  final String userName;
  final List<DocumentSnapshot> videosReported;

  // ignore: prefer_const_constructors_in_immutables, use_key_in_widget_constructors
  RequestModal(
      this.name,
      this.videos,
      this.message,
      this.followers,
      this.proximityInMeters,
      this.likes,
      this.id,
      this.doc,
      this.uid,
      this.userName,
      this.videosReported);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding:
              const EdgeInsets.only(left: 25, right: 25, top: 15, bottom: 8),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 255, 182, 46),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Center(
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    name.trim() + " asks, ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FollowButton(followers, doc, uid),
            const SizedBox(width: 55),
            LikeButton(likes, doc, uid),
          ],
        ),
        Padding(
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 255, 182, 46),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: videos.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(
                        height: 5,
                      ),
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              height: 125,
                              child: Image.asset(
                                'assets/drawable/Wumbo.png',
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Flexible(
                              child: Text(
                                currentLanguage[281],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                ),
                                overflow: TextOverflow.fade,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Container(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final item = videos[index];
                        return Container(
                          width: 160.0,
                          child: ListTile(
                            leading: item.buildImage(context),
                            title: item.buildTitle(context),
                            subtitle: item.buildSubtitle(context),
                            onTap: () {
                              item.isVideo
                                  ? Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoPlayerScreen(
                                          videoPath: null,
                                          videoUrl: videos[index].url,
                                          videoMessage: videos[index].sender,
                                          simplify: false,
                                        ),
                                      ),
                                    )
                                  : item.url == "q"
                                      ? print(
                                          "THIS STATEMENT CANNOT BE DELETED - AARON")
                                      : Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DisplayPictureScreen(
                                              imagePath: null,
                                              imageUrl: videos[index].url,
                                              imageMessage:
                                                  videos[index].sender,
                                              simplify: false,
                                              tags: [],
                                            ),
                                          ),
                                        );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
          padding: const EdgeInsets.only(left: 25, right: 25, top: 15),
        ),
        const SizedBox(
          height: 15,
        ),
        AnswerModalButton(doc, proximityInMeters, id),
        Padding(
          child: Align(
            alignment: Alignment.center,
            child: ReportButton(true, doc, userName, videosReported),
          ),
          padding: const EdgeInsets.only(left: 0, top: 0),
        ),
      ],
    );
  }
}
