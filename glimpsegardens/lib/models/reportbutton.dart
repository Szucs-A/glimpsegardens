import 'package:flutter/material.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glimpsegardens/services/database.dart';
import 'dart:core';

class ReportButton extends StatelessWidget {
  final DocumentSnapshot doc;
  final String userName;
  final bool isRequest;
  final List<DocumentSnapshot> videosReported;

  // ignore: use_key_in_widget_constructors, prefer_const_constructors_in_immutables
  ReportButton(this.isRequest, this.doc, this.userName, this.videosReported);

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: TextButton.styleFrom(
          primary: Colors.white,
          backgroundColor: normalText,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
          minimumSize: const Size(100, 20),
        ),
        child: Text(
          currentLanguage[263],
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        onPressed: () {
          if (isRequest) {
            reportButtonRequest(doc, context);
          } else {
            reportButtonVideo(doc, context);
          }
        });
  }

  void reportButtonRequest(DocumentSnapshot document, context) {
    bool selectedAReason = false;
    bool selectedAUser = false;
    String reason;
    DocumentSnapshot video;
    String errorMessage = "";

    Map<String, DocumentSnapshot> titles = <String, DocumentSnapshot>{};
    titles[document['message']] = document;
    int counter = 1;
    for (DocumentSnapshot v in videosReported) {
      titles[counter.toString() + ": " + v['message'].toString()] = v;
      counter++;
    }

    Widget cancelButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[77]),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(currentLanguage[264]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(currentLanguage[265]),
                  Text(errorMessage, style: const TextStyle(color: Colors.red)),
                  DropdownButton<String>(
                    items: <String>[
                      currentLanguage[266],
                      currentLanguage[267],
                      currentLanguage[268],
                      currentLanguage[269],
                      currentLanguage[270],
                      currentLanguage[271]
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    value: reason,
                    hint: Text(currentLanguage[272]),
                    onChanged: (String newValue) {
                      selectedAReason = true;

                      setState(() {
                        reason = newValue;
                      });
                    },
                  ),
                  Text(currentLanguage[273]),
                  DropdownButton<DocumentSnapshot>(
                    items: titles
                        .map((String name, DocumentSnapshot element) {
                          return MapEntry(
                              name,
                              DropdownMenuItem<DocumentSnapshot>(
                                value: element,
                                child: Text(name),
                              ));
                        })
                        .values
                        .toList(),
                    value: video,
                    hint: Text(currentLanguage[274]),
                    onChanged: (newValue) {
                      selectedAUser = true;

                      setState(() {
                        video = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[275]),
                  onPressed: () {
                    if (selectedAReason == false || selectedAUser == false) {
                      setState(() {
                        errorMessage = currentLanguage[276];
                      });
                    } else {
                      Navigator.pop(context);

                      blockDialog(video, reason, video.id, "Pin-Video",
                          context); // video would be the user's title
                    }
                  },
                ),
                TextButton(
                    style: flatButtonStyle,
                    child: Text(currentLanguage[263]),
                    onPressed: () {
                      if (selectedAReason == false || selectedAUser == false) {
                        setState(() {
                          errorMessage = currentLanguage[276];
                        });
                      } else {
                        sendEmail(reason, video.id, video['email'], "Pin-Video",
                            userName);

                        Navigator.pop(context);

                        Fluttertoast.showToast(msg: currentLanguage[277]);
                      }
                    }),
                cancelButton,
              ],
            );
          });
        });
  }

  void reportButtonVideo(DocumentSnapshot document, context) {
    bool selectedAReason = false;
    String reason;
    String errorMessage = "";

    Widget cancelButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[77]),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(currentLanguage[264]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(currentLanguage[265]),
                  Text(errorMessage, style: const TextStyle(color: Colors.red)),
                  DropdownButton<String>(
                    items: <String>[
                      currentLanguage[266],
                      currentLanguage[267],
                      currentLanguage[268],
                      currentLanguage[269],
                      currentLanguage[270],
                      currentLanguage[271]
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    value: reason,
                    hint: Text(currentLanguage[272]),
                    onChanged: (String newValue) {
                      selectedAReason = true;

                      setState(() {
                        reason = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[275]),
                  onPressed: () {
                    if (selectedAReason == false) {
                      setState(() {
                        errorMessage = "Please select a reason.";
                      });
                    } else {
                      Navigator.pop(context);

                      blockDialog(document, reason, document.id, "Pin-Video",
                          context); // video would be the user's title
                    }
                  },
                ),
                TextButton(
                    style: flatButtonStyle,
                    child: Text(currentLanguage[263]),
                    onPressed: () {
                      if (selectedAReason == false) {
                        setState(() {
                          errorMessage = currentLanguage[276];
                        });
                      } else {
                        sendEmail(reason, document.id, document['email'],
                            "Pin-Video", userName);

                        Navigator.pop(context);

                        Fluttertoast.showToast(msg: currentLanguage[277]);
                      }
                    }),
                cancelButton,
              ],
            );
          });
        });
  }

  void sendEmail(String reason, String documentID, String userName,
      String videoOrPin, String reporter) async {
    Map<String, dynamic> json = {
      'reason': reason,
      'docid': documentID,
      'username': userName,
      'videoorpin': videoOrPin,
      'reporter': reporter
    };

    firestore.runTransaction((Transaction tx) async {
      DatabaseService().reportsCollection.add(json);
    });
  }

  void blockDialog(DocumentSnapshot video, String reason, String documentID,
      String videoOrPin, context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(currentLanguage[279]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(currentLanguage[278]),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[10]),
                  onPressed: () {
                    sendEmail(reason, documentID, video['email'], videoOrPin,
                        userName);
                    Navigator.pop(context);

                    Fluttertoast.showToast(msg: currentLanguage[280]);

                    blockUser(video['email']);
                  },
                ),
                TextButton(
                    style: flatButtonStyle,
                    child: Text(currentLanguage[77]),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
              ],
            );
          });
        });
  }

  void blockUser(String email) {
    // Add the blocker to the list
    PreferencesHelper().getBlockedUsers().then((blocks) {
      blocks.add(email);
      PreferencesHelper().setBlockedUsers(blocks);
      //gettingAllPins();
      return null;
    });
  }
}
