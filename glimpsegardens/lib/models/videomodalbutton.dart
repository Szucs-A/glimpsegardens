import 'package:flutter/material.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/VideoPlayerScreen.dart';
import 'package:glimpsegardens/services/camera/display_picture_screen.dart';
import 'dart:io' show Platform;

class VideoModalButton extends StatefulWidget {
  final bool isVideo;

  final String url;
  final String message;
  final String interstitialAdId;

  VideoModalButton(this.isVideo, this.url, this.message, this.interstitialAdId);

  @override
  _VideoModalButtonState createState() => _VideoModalButtonState();
}

class _VideoModalButtonState extends State<VideoModalButton>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _heightAnimation;
  Animation<double> _widthAnimation;

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);

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

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: TextButton.styleFrom(
          primary: Colors.white,
          backgroundColor: normalText,
          textStyle: loginPageTextStyle,
          shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(10.0),
              side: BorderSide(color: normalText, width: 5)),
          minimumSize: Size(_widthAnimation.value, _heightAnimation.value),
        ),
        child: Text(
          widget.isVideo ? currentLanguage[284] : currentLanguage[283],
          style: TextStyle(
            fontSize: 22,
          ),
        ),
        onPressed: () async {
          if (_controller.status == AnimationStatus.completed) {
            _controller.reverse();
          } else {
            _controller.forward();
          }
          if (widget.isVideo) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  videoPath: null,
                  videoUrl: widget.url,
                  videoMessage: widget.message,
                  simplify: false,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  imagePath: null,
                  imageUrl: widget.url,
                  imageMessage: widget.message,
                  simplify: false,
                  tags: [],
                ),
              ),
            );
          }
        });
  }

  // TODO: Testing Ads.
  String getInterstitialAdUnitId() {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    return null;
  }
}
