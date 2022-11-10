import 'dart:core';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/services/push_notification_service.dart';
import 'package:glimpsegardens/services/database.dart';

// ignore: must_be_immutable
class LikeButton extends StatefulWidget {
  int likes;
  final DocumentSnapshot doc;
  bool alreadyLiked = false;
  final String uid;

  // ignore: use_key_in_widget_constructors
  LikeButton(this.likes, this.doc, this.uid);

  @override
  _LikeButton createState() => _LikeButton();
}

class _LikeButton extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _heightAnimation;
  Animation<Color> _colorAnimation;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    _controller.addListener(() {
      setState(() {});
    });

    _colorAnimation = TweenSequence(<TweenSequenceItem<Color>>[
      TweenSequenceItem<Color>(
          tween: ColorTween(
              begin: Colors.grey.withOpacity(0.9),
              end: Colors.grey.withOpacity(0)),
          weight: 50),
      TweenSequenceItem<Color>(
          tween: ColorTween(
              begin: Colors.grey.withOpacity(0),
              end: Colors.grey.withOpacity(0.9)),
          weight: 50)
    ]).animate(_controller);

    _heightAnimation = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 30, end: 20), weight: 50),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 20, end: 30), weight: 50)
    ]).animate(_controller);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_controller.status == AnimationStatus.completed) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
        if (!widget.alreadyLiked) {
          widget.alreadyLiked = true;
          bool b = await likeProcess(widget.doc);
          if (b) {
            setState(() {
              widget.likes = widget.likes + 1;
            });
          }
        } else {
          Fluttertoast.showToast(msg: currentLanguage[262]);
        }
      },
      child: Container(
//        height: 30,
        height: _heightAnimation.value,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                  offset: const Offset(0.0, 7), color: _colorAnimation.value),
            ],
            color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 10),
              child: Icon(
                Icons.thumb_up,
                size: _heightAnimation.value - 5,
              ),
            ),
            Padding(
              child: Text(widget.likes.toString(),
                  style: TextStyle(
                      fontSize: _heightAnimation.value - 10,
                      color: normalText)),
              padding: const EdgeInsets.only(right: 15),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> likeProcess(DocumentSnapshot element) async {
    //List<dynamic> likedalready = element['likedaccounts'];
    //if (likedalready != null) {
    //  for (var v in likedalready) {
    //   if (v == uid) {
    //      return false;
    //    }
    //  }
    //}

    DocumentSnapshot refresh;
    Map<String, dynamic> tester = element.data();

    if (!tester.containsKey("isVideo")) {
      // If it is a request.
      refresh =
          await DatabaseService().requestsCollection.doc(element.id).get();
    } else // If it is a videoPin
    {
      refresh = await DatabaseService().videoCollection.doc(element.id).get();
    }

    List<dynamic> likeList = refresh['likedaccounts'];
    int beforeLength = 0;
    if (likeList != null) {
      beforeLength = likeList.length;
    }

    List<dynamic> dyn = [];
    dyn.add(widget.uid);

    await element.reference
        .update({'likedaccounts': FieldValue.arrayUnion(dyn)});

    DocumentSnapshot q;

    if (!tester.containsKey("isVideo")) {
      // If it is a request.
      q = await DatabaseService().requestsCollection.doc(element.id).get();
    } else // If it is a videoPin
    {
      q = await DatabaseService().videoCollection.doc(element.id).get();
    }

    likeList = q['likedaccounts'];
    int afterLength = 0;
    if (likeList != null) {
      afterLength = likeList.length;
    }

    if (beforeLength != afterLength) {
      likeUserProcess(element);
      element.reference.update({'likes': FieldValue.increment(1)});

      // Send that person a notification for liking their stuff.
      String token = element['token'];
      if (token != null) {
        print('Notification Sending');
        PushNotificationService.sendLikedMessage(token, element.id);
      }

      return true;
    }

    return false;
  }

  void likeUserProcess(DocumentSnapshot element) async {
    DatabaseService()
        .userCollection
        .where('email', isEqualTo: element['email'])
        .get()
        .then((elements) {
      if (elements.docs.length == 1) {
        for (var v in elements.docs) {
          v.reference.update({'likes': FieldValue.increment(1)});
        }
      }
    });
  }
}
