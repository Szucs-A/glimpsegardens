import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/services/push_notification_service.dart';
import 'package:glimpsegardens/services/database.dart';

// ignore: must_be_immutable
class FollowButton extends StatefulWidget {
  final DocumentSnapshot doc;
  bool alreadyFollowed = false;
  int followers;
  final String uid;

  // ignore: use_key_in_widget_constructors
  FollowButton(this.followers, this.doc, this.uid);

  @override
  _FollowButton createState() => _FollowButton();
}

class _FollowButton extends State<FollowButton>
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
          tween: Tween<double>(begin: 30, end: 25), weight: 50),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 25, end: 30), weight: 50)
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

        if (!widget.alreadyFollowed) {
          widget.alreadyFollowed = true;
          bool b = await followProcess(widget.doc);

          if (b) {
            setState(() {
              widget.followers = widget.followers + 1;
            });

            Fluttertoast.showToast(msg: currentLanguage[259]);
          } else {
            Fluttertoast.showToast(msg: currentLanguage[260]);
          }
        } else {
          Fluttertoast.showToast(msg: currentLanguage[260]);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
//            height: 30,
            height: _heightAnimation.value,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                      offset: Offset(0.0, 7), color: _colorAnimation.value),
                ],
                color: Colors.white),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 15, right: 10),
                  child: Text(
                      currentLanguage[261] + ": " + widget.followers.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: _heightAnimation.value - 10,
                          color: normalText)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The first process that runs here is to check if the same account is attempting to follow
  // a request but using another person's phone.
  // The second process that runs is to check if someone is using the same phone with multiple accounts
  // to boost their follows.
  // This code makes sure that someone can only follow with one account and one device.
  Future<bool> followProcess(DocumentSnapshot element) async {
    // Make a way to track the follow thing, like the likes feature.
    // May not need this feature because arrayUnion doesn't add duplicates.

    DocumentSnapshot refresh =
        await DatabaseService().requestsCollection.doc(element.id).get();

    List<dynamic> uidList = refresh['followaccounts'];
    List<String> sender = [];
    sender.add(widget.uid);

    await element.reference
        .update({'followaccounts': FieldValue.arrayUnion(sender)});

    // Get the new document again.
    DocumentSnapshot element2 =
        await DatabaseService().requestsCollection.doc(element.id).get();

    List<dynamic> uidList2 = element2['followaccounts'];

    if (uidList2.length != uidList.length) {
      // The account was actually added
      String myToken = await PushNotificationService.getDeviceToken();
      List<String> followTokens = [];
      followTokens.add(myToken);

      List<dynamic> followList = element2['followtokens'];
      int before = followList.length;

      await element.reference
          .update({'followtokens': FieldValue.arrayUnion(followTokens)});

      // Get the new document again.
      DocumentSnapshot element3 =
          await DatabaseService().requestsCollection.doc(element.id).get();

      followList = element3['followtokens'];

      if (before != followList.length) {
        // A user was actually added to the list successfully.
        // send the person a notification for following their stuff.

        PushNotificationService.sendOwnerFollowerNotification(
            element['token'], element.id);
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
}
