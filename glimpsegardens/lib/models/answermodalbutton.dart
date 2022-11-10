import 'package:glimpsegardens/services/Camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/maps.dart';

class AnswerModalButton extends StatefulWidget {
  final DocumentSnapshot doc;
  final int proximityInMeters;
  final String id;

  AnswerModalButton(this.doc, this.proximityInMeters, this.id);

  @override
  _AnswerModalButtonState createState() => _AnswerModalButtonState();
}

class _AnswerModalButtonState extends State<AnswerModalButton>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _heightAnimation;
  Animation<double> _widthAnimation;

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

    _heightAnimation = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 75, end: 65), weight: 50),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 65, end: 75), weight: 50)
    ]).animate(_controller);

    _widthAnimation = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 350, end: 300), weight: 50),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 300, end: 350), weight: 50)
    ]).animate(_controller);
  }

  String title = currentLanguage[255];
  bool isAbsorbing = false;

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isAbsorbing,
      child: TextButton(
          style: TextButton.styleFrom(
            primary: Colors.white,
            backgroundColor: normalText,
            textStyle: loginPageTextStyle,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: const BorderSide(color: normalText, width: 5)),
            minimumSize: Size(_widthAnimation.value, _heightAnimation.value),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
            ),
          ),
          onPressed: () async {
            setState(() {
              title = currentLanguage[256];
              isAbsorbing = true;
            });

            if (_controller.status == AnimationStatus.completed) {
              _controller.reverse();
            } else {
              _controller.forward();
            }
            Position userPosition = await Geolocator.getCurrentPosition();

            setState(() {
              title = currentLanguage[256] + ".";
            });
            double meters = GeolocatorPlatform.instance.distanceBetween(
                widget.doc['latitude'],
                widget.doc['longitude'],
                userPosition.latitude,
                userPosition.longitude);
            if (meters <= widget.proximityInMeters) {
              setState(() {
                title = currentLanguage[256] + "..";
              });
              MapsPage.answering = true;
              MapsPage.requestID = widget.id;
              startRequestCamera(context);
            } else {
              tooFarAwayDialog(context);
              setState(() {
                title = currentLanguage[255];
                isAbsorbing = false;
              });
            }
          }),
    );
  }

  Future<void> startRequestCamera(context) async {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) => const Camera()));
  }

  Future<void> tooFarAwayDialog(context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Text(currentLanguage[257]),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(currentLanguage[258]),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(currentLanguage[13]),
              style: flatButtonStyle,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
