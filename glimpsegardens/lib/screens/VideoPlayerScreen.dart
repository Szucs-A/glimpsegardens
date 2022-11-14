import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glimpsegardens/screens/loading.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glimpsegardens/screens/settings/settings.dart';
import 'package:glimpsegardens/screens/mapshelper.dart';
import 'package:path/path.dart' show join;
import 'package:glimpsegardens/screens/maps.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

import 'package:glimpsegardens/services/camera/display_picture_screen.dart';

class VideoPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoPlayerScreen(
        videoMessage: "",
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final List<dynamic> tags;
  VideoPlayerScreen(
      {Key path,
      this.videoPath,
      this.videoUrl,
      @required this.videoMessage,
      @required this.tags,
      @required this.simplify})
      : super(key: path);
  String videoPath;
  final String videoUrl;
  final String videoMessage;
  final bool simplify;

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  AnimationController _animationController;

  bool _isAbsorbing = false;
  bool loading = false;
  bool finishedInitializing = false;
  bool _isShareButtonVisible = false;
  List<StatefulDragArea> hashtags = [];
  int numberOfTags = 0;

  final textEditingControllerTwo = TextEditingController();
  double _opacity = 1.0;

  Icon _uploadButtonIcon = Icon(Icons.file_upload);

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  Widget chatOverlay = Column(
    children: <Widget>[
      Expanded(
          flex: 4,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[])),
      Expanded(
        flex: 6,
        child: Container(),
      ),
    ],
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // TODO: Test if this appears on iOS
        print("app in resumed Camera");
        _animationController.reverse();
        _controller.play();
        break;
      case AppLifecycleState.inactive:
        print("app in inactive Camera");
        _animationController.forward();
        _controller.pause();
        break;
      case AppLifecycleState.paused:
        // TODO: Test if this appears on iOS
        print("app in paused Camera");
        _animationController.forward();
        _controller.pause();
        break;
      case AppLifecycleState.detached:
        print("app in detached Camera");
        _animationController.forward();
        _controller.pause();
        break;
    }
  }

  @override
  void initState() {
    // Create and store the VideoPlayerController.
    // If no path was provided, the controller will source from the videoUrl
    // Upload button will also be disabled
    print("Inside Init");
    print("Video Path...");
    if (widget.videoPath == null) {
      print("Video Path is Null.");
      _controller = VideoPlayerController.network(widget.videoUrl);
      _opacity = 0.75;
      _isAbsorbing = true;
      _isShareButtonVisible = true;
      if (widget.videoMessage != "") {
        setOverlayChat();
      }
      if (widget.tags != null) {
        setTags();
      }
    }
    print("Initialize Video Controller");
    // Initialize the controller and store the Future for later use.
    _initializeVideoPlayerFuture = initializeVideoAndController();
    print("Super Init.");
    super.initState();
    print("Animation Controller");
    _animationController = AnimationController(
        value: 1, duration: Duration(milliseconds: 500), vsync: this);
    print("Widget Binding");
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initializeVideoAndController() async {
    print("Video Path - Initialization");
    if (widget.videoPath != null) {
      print("Video Path NOT NULL");
      if (Platform.isAndroid) {
        print("Platform Android.");
        print("Converting.");
        await convertVideoLandscape(widget.videoPath);
      } else {
        _controller = VideoPlayerController.file(File(widget.videoPath));
        // Use the controller to loop the video.
        _controller.setLooping(true); // currently set to loop
        // Enable autoplay.

        if (!widget.simplify) _controller.play();
        await _controller.initialize();

        setState(() {
          finishedInitializing = true;
        });
      }
      // I believe this is the problem.
    } else {
      print("Video Path NULL");
      print("Networking.");
      _controller = VideoPlayerController.network(widget.videoUrl);
      // Use the controller to loop the video.
      print("Looping");
      _controller.setLooping(true); // currently set to loop
      // Enable autoplay.
      print("Playing.");
      if (!widget.simplify) _controller.play();
      print("Initializing.");
      await _controller.initialize();

      setState(() {
        print("Set Stating.");
        finishedInitializing = true;
      });
    }
  }

  void setTags() {
    // gets elements.
    for (int i = 0; i < widget.tags.length; i++) {
      Size size = new Size(
          (widget.tags[i]['positionx']), (widget.tags[i]['positiony']));

      hashtags.add(new StatefulDragArea(
          fullsize: size,
          message: widget.tags[i]['message'],
          index: numberOfTags,
          isDraggable: false,
          child: Container(
              child: Center(
                  child: DefaultTextStyle(
                style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.white,
                    fontFamily: 'Arial',
                    fontSize: 18),
                child: Text(widget.tags[i]['message']),
              )),
              decoration: ShapeDecoration(
                shape: MessageBorder(),
                color: Colors.black54,
              ),
              width: 200,
              height: 50)));
      numberOfTags++;
    }
  }

  void convertVideoLandscape(String path) async {
    //const int AV_LOG_ERROR = 16;

    //_flutterFFmpeg.setLogLevel(AV_LOG_ERROR);

    // Finding the rotation of the video
    List<String> rotationGrabber = [];
    await FFprobeKit.getMediaInformationAsync(path, (session) async {
      final information =
          await (session as MediaInformationSession).getMediaInformation();

      information.getAllProperties().forEach((key, value) {
        print("GOT MEDIA CORRECTLY.");
        print('KEY: ' + key.toString());
        print('VALUE: ' + value.toString());
      });

      print("GOT MEDIA CORRECTLY.");
      information.getMediaProperties().forEach((key, value) {
        print('KEY: ' + key.toString());
        print('VALUE: ' + value.toString());
      });

      // TODO: Reintroduce this
      //String rrotationGrabber = information.getAllProperties()[0][0].toString();

      //print("NEW: " + rrotationGrabber);
    });

    String rotation = "0";
    if (rotationGrabber.length > 1) {
      rotation =
          rotationGrabber.elementAt(1).split(':')[1].split(',')[0].trim();
    }

    // 0 = 90CounterCLockwise and Vertical Flip (default)
    // 1 = 90Clockwise
    // 2 = 90CounterClockwise
    // 3 = 90Clockwise and Vertical Flip

    String transposeValue = "1"; // Minus 1 for portrait mode.
    switch (rotation) {
      case "0":
        transposeValue = "1";
        break;
      case "90":
        return; // Portrait, so we should not convert this video.
        break;
      case "180":
        transposeValue = "2";
        break;
      case "270":
        transposeValue = "2,transpose=2";
        break;
    }

    _controller = VideoPlayerController.file(File(widget.videoPath));
    // Use the controller to loop the video.
    _controller.setLooping(true); // currently set to loop
    // Enable autoplay.
    _controller.play();
    await _controller.initialize();

    setState(() {
      finishedInitializing = true;
    });

    return;

    List<String> spliter = path.split('.mp4');

    /// The :s:v:0 after -metadata is the stream specifier,
    /// which just tells ffmpeg to which stream it should add the metadata.
    /// :s stands for the streams of the input file,
    /// :v selects video streams and the number is the stream index,
    /// zero-based - so this will select the first video stream.
    /// The -c option specifies the codec
    /// to be used, with copy for just copying the streams, without re-encoding.
    //final String looselessConversion =
    //    '-i $path -c copy -metadata:s:v:0 rotate=0 ${spliter.elementAt(0)}-processed.mp4';
    final String losslessConversion =
        '-i $path -vf "transpose=$transposeValue" ${spliter.elementAt(0)}-processed.mp4';

    //final String looselessConversion =
    //    '-i $path -vf "transpose=1" -c:a copy -metadata:s:v:0 rotate=0 ${spliter.elementAt(0)}-processed.mp4';

    try {
      FFmpegKit.executeAsync(losslessConversion, (session) async {
        // CALLED WHEN SESSION IS EXECUTED
        print("RUNNING>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");

        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          // SUCCESS
          print("Success.");
        } else if (ReturnCode.isCancel(returnCode)) {
          // CANCEL
          print("Cancelled.");
        } else {
          // ERROR
          print("Errored.");
        }
      });

      // delete the original video file
      // await File('$path').delete();
      widget.videoPath = '${spliter.elementAt(0)}-processed.mp4';
      print("PAPER SPLITTER" + widget.videoPath);
    } catch (e) {
      print('video processing error: $e');
    }
  }

  void setOverlayChat() {
    chatOverlay = Column(
      children: <Widget>[
        Expanded(
            flex: 4,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    child: Center(
                      child: Padding(
                        padding: new EdgeInsets.all(6),
                        child: Text(
                          widget.videoMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          overflow: TextOverflow.fade,
                          maxLines: 5,
                        ),
                      ),
                    ),
                    color: Colors.black38,
                  ),
                ])),
        Expanded(
          flex: 6,
          child: Container(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    print("Disposed.");
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // Function is for when a navigation icon is tapped
  void onTabTapped(int index) {
    completedDateTime = null;
    selectedPinType = 0;
    if (index == 0) {
      HapticFeedback.heavyImpact();
      MapsPage.answering = false;
      MapsPage.requestID = "";
      MapsHelper.message = "Hello!";
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    if (index == 1) {
      HapticFeedback.heavyImpact();
      Navigator.pop(context);
    }
    if (index == 2) {
      HapticFeedback.heavyImpact();
      MapsPage.answering = false;
      MapsPage.requestID = "";
      MapsHelper.message = "Hello!";
      Route route = MaterialPageRoute(builder: (context) => Settings());
      Navigator.pushReplacement(context, route);
    }
  }

  // Function to upload videos.
  Future<void> _uploadVideo() async {
    setState(() {
      loading = true;
    });

    File file = File(widget.videoPath);
    User user = await FirebaseAuth.instance.currentUser;
    String uid = user.uid;
    DateTime now = new DateTime.now().toUtc();
    String time =
        '${now.hour}:' '${now.minute}:' '${now.second}:' '${now.millisecond}';
    String storagePath = join('$uid', 'videos', '${now.year}', '${now.month}',
        '${now.day}', '$time.mp4');

    Reference storageReference =
        FirebaseStorage.instance.ref().child(storagePath);

    final UploadTask uploadTask = storageReference.putFile(file);

    final TaskSnapshot downloadUrl = (await uploadTask);
    final String url = (await downloadUrl.ref.getDownloadURL());

    bool toast = await MapsHelper.createVideoMarker(
        url, true, selectedPinType, completedDateTime, hashtags);

    if (toast) {
      Fluttertoast.showToast(msg: currentLanguage[191]);
    } else {
      Fluttertoast.showToast(msg: currentLanguage[192]);
    }

    selectedPinType = 0;
    completedDateTime = null;

    setState(() {
      _isShareButtonVisible = false;
      loading = false;
    });
  }

  void checkForUpdatedMessage() {
    setState(() {
      if (MapsHelper.message != "Hello!") {
        chatOverlay = Column(
          children: <Widget>[
            Expanded(
                flex: 4,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        child: Center(
                          child: Padding(
                            padding: new EdgeInsets.all(6),
                            child: Text(
                              MapsHelper.message,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                              overflow: TextOverflow.fade,
                              maxLines: 5,
                            ),
                          ),
                        ),
                        color: Colors.black38,
                      ),
                    ])),
            Expanded(
              flex: 6,
              child: Container(),
            ),
          ],
        );
      } else {
        chatOverlay = Column(
          children: <Widget>[
            Expanded(
                flex: 4,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[])),
            Expanded(
              flex: 6,
              child: Container(),
            ),
          ],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return loading
        ? LoadingScreen(isUploading: true)
        : Scaffold(
            backgroundColor: buttonsBorders,
            // Use a FutureBuilder to display a loading spinner while waiting for the
            // VideoPlayerController to finish initializing.
            body: !finishedInitializing
                ? LoadingScreen(isUploading: false)
                : Stack(
                    children: [
                      Container(
                        child: Transform.scale(
                          scale:
                              _controller.value.aspectRatio / size.aspectRatio,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        ),
                      ),
                      ConstantsClass.businessAccount && !widget.simplify
                          ? Align(
                              alignment: Alignment(.9, -.90),
                              child: AbsorbPointer(
                                absorbing: _isAbsorbing || loading,
                                child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 100),
                                    opacity: _opacity,
                                    child: FloatingActionButton(
                                      heroTag: 'setPinTimeButton',
                                      child: Icon(Icons.timelapse),
                                      backgroundColor: buttonsBorders,
                                      onPressed: () {
                                        HapticFeedback.heavyImpact();
                                        // Show message dialog.
                                        showPinTimeDialog(context);
                                      },
                                    )),
                              ),
                            )
                          : Container(),
                      /*
                      businessAccount
                          ? Align(
                              alignment: Alignment(-.9, -.90),
                              child: AbsorbPointer(
                                absorbing: _isAbsorbing || loading,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 100),
                                  opacity: _opacity,
                                  child: MapsHelper.getCodeString() != "" &&
                                          MapsHelper.getCodeType() ==
                                              CodeType.employee &&
                                          !MapsPage.answering
                                      ? FloatingActionButton(
                                          heroTag: 'setPinTypeButton',
                                          child: Icon(Icons.public),
                                          backgroundColor: buttonsBorders,
                                          onPressed: () {
                                            HapticFeedback.heavyImpact();
                                            // Show message dialog.
                                            showPublicDialog();
                                          },
                                        )
                                      : Container(),
                                ),
                              ),
                            )
                          : Container(),
                          */
                      ConstantsClass.businessAccount && !widget.simplify
                          ? Align(
                              alignment: Alignment(-.9, .95),
                              child: AbsorbPointer(
                                absorbing: _isAbsorbing,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 100),
                                  opacity: _opacity,
                                  child: FloatingActionButton(
                                    heroTag: 'setMessageButton',
                                    child: Icon(Icons.chat),
                                    backgroundColor: buttonsBorders,
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();
                                      // Show message dialog.
                                      messageDialog();
                                    },
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      ConstantsClass.businessAccount && !widget.simplify
                          ? Align(
                              alignment: Alignment(.9, .95),
                              child: AbsorbPointer(
                                absorbing: _isAbsorbing,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 100),
                                  opacity: _opacity,
                                  child: FloatingActionButton(
                                    heroTag: 'uploadButton',
                                    child: _uploadButtonIcon,
                                    backgroundColor: buttonsBorders,
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();

                                      // Allow the absorber to disable the button
                                      // Also change the button's opacity to show it's disabled
                                      setState(() {
                                        _isAbsorbing = true;
                                        _opacity = 0.75;
                                        _uploadButtonIcon = Icon(Icons.check);
                                      });

                                      // Upload the video & enable loading screen
                                      _uploadVideo();
                                    },
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      !ConstantsClass.businessAccount || widget.simplify
                          ? Container()
                          : Align(
                              alignment: Alignment(-.9, .72),
                              child: AbsorbPointer(
                                absorbing: _isAbsorbing || loading,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 100),
                                  opacity: _opacity,
                                  child: FloatingActionButton(
                                    heroTag: null,
                                    child: Icon(Icons.tag),
                                    backgroundColor: buttonsBorders,
                                    onPressed: () async {
                                      HapticFeedback.heavyImpact();
                                      // Show message dialog.

                                      String value =
                                          await hashtagDialog(context);
                                      if (value != "") {
                                        setState(() {
                                          hashtags.add(new StatefulDragArea(
                                              fullsize: size,
                                              index: numberOfTags,
                                              isDraggable: true,
                                              message: value,
                                              child: Container(
                                                  child: Center(
                                                      child: DefaultTextStyle(
                                                    style: TextStyle(
                                                        decoration:
                                                            TextDecoration.none,
                                                        color: Colors.white,
                                                        fontFamily: 'Arial',
                                                        fontSize: 18),
                                                    child: Text(value),
                                                  )),
                                                  decoration: ShapeDecoration(
                                                    shape: MessageBorder(),
                                                    color: Colors.black54,
                                                  ),
                                                  width: 200,
                                                  height: 50)));
                                        });
                                        numberOfTags++;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                      /*
                      businessAccount
                          ? Visibility(
                              visible: _isShareButtonVisible,
                              child: Align(
                                alignment: Alignment(-.9, .7),
                                child: FloatingActionButton(
                                  heroTag: 'shareButton',
                                  child: Icon(Icons.share),
                                  backgroundColor: buttonsBorders,
                                  onPressed: () {
                                    HapticFeedback.heavyImpact();
                                    Share.share(
                                      '${widget.videoUrl}',
                                    );
                                  },
                                ),
                              ),
                            )
                          : Container(),
                          */
                      chatOverlay,
                      Container(
                          width: size.width,
                          height: size.height,
                          child: Stack(children: hashtags)),
                      !ConstantsClass.businessAccount || widget.simplify
                          ? Container()
                          : Align(
                              alignment: Alignment(.88, .71),
                              child: DragTarget<int>(
                                builder: (context, List<dynamic> candidateData,
                                    rejectedData) {
                                  return Container(
                                      height: 50.0,
                                      width: 50.0,
                                      child: Icon(Icons.delete_forever,
                                          size: 50.0,
                                          color: Color.fromRGBO(0, 0, 0, 0.5)));
                                },
                                onWillAccept: (data) {
                                  return true;
                                },
                                onAccept: (data) {
                                  print(data);
                                  setState(() {
                                    for (var i = 0; i < hashtags.length; i++) {
                                      if (hashtags[i].index == data) {
                                        hashtags[i].child = Container();
                                        break;
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                    ],
                  ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: finishedInitializing
                ? FloatingActionButton(
                    heroTag: null,
                    backgroundColor: buttonsBorders,
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      // Wrap the play or pause in a call to `setState`. This ensures the
                      // correct icon is shown.
                      setState(() {
                        // If the video is playing, pause it.
                        if (_controller.value.isPlaying) {
                          _animationController.forward();
                          _controller.pause();
                        } else {
                          // If the video is paused, play it.
                          _animationController.reverse();
                          _controller.play();
                        }
                      });
                    },
                    child:
                        // Display the correct icon depending on the state of the player.
                        AnimatedIcon(
                      icon: AnimatedIcons.pause_play,
                      progress: _animationController,
                    ))
                : null,

            bottomNavigationBar: !finishedInitializing || widget.simplify
                ? null
                : BottomNavigationBar(
                    items: <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.map),
                        label: currentLanguage[219],
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.arrow_back),
                        label: currentLanguage[214],
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings),
                        label: currentLanguage[221],
                      ),
                    ],
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    currentIndex: 1,
                    selectedItemColor: Colors.white,
                    unselectedItemColor: Colors.white.withOpacity(0.5),
                    backgroundColor: buttonsBorders,
                    onTap: onTabTapped,
                  ), // This trailing comma makes auto-formatting nicer for build methods.
          );
  }

  int selectedPinType = 0;

  showPublicDialog() {
    final _dialogKey = GlobalKey<FormState>();

    var dropDownValue;
    String dropDownHint = currentLanguage[193];

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(currentLanguage[194]),
              content: Form(
                key: _dialogKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new DropdownButtonFormField<String>(
                      hint: Text(dropDownHint),
                      validator: (value) =>
                          value == null ? currentLanguage[195] : null,
                      items: <String>['Public', 'Geocached', 'VIP']
                          .map((String value) {
                        return new DropdownMenuItem<String>(
                          value: value,
                          child: new Text(value),
                        );
                      }).toList(),
                      value: dropDownValue,
                      onChanged: (changedValue) {
                        if (this.mounted) {
                          setState(() {
                            dropDownValue = changedValue;
                          });
                          print(dropDownValue);
                        }
                      },
                    )
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[77]),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[199]),
                  onPressed: () async {
                    if (_dialogKey.currentState.validate()) {
                      selectedPinType = getPinType(dropDownValue).index;
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          });
        });
  }

  final myController = TextEditingController();

  void messageDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(currentLanguage[175]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(currentLanguage[176]),
                  TextField(
                    controller: myController,
                    maxLength: 100,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                    style: flatButtonStyle,
                    child: Text(currentLanguage[77]),
                    onPressed: () {
                      Navigator.pop(context);
                      MapsHelper.message = "Hello!";
                    }),
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[10]),
                  onPressed: () {
                    MapsHelper.message = myController.text.toString();
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
        }).then((value) {
      checkForUpdatedMessage();
    });
  }

  DateTime completedDateTime;
  showPinTimeDialog(BuildContext context) {
    final _dialogKey = GlobalKey<FormState>();

    TextStyle popupStyle = new TextStyle(fontSize: 18);

    DateTime now = DateTime.now();

    DateTime timeDate =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);
    DateTime dateDate =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);

    String dateToday = now.month.toString() +
        "-" +
        now.day.toString() +
        "-" +
        now.year.toString();

    String ampmnow = 'AM';
    int hournow = now.hour;
    if (now.hour >= 13) {
      ampmnow = 'PM';
      hournow -= 12;
    }

    int minute1 = now.minute;
    String strMinute1 = minute1.toString();
    if (minute1 <= 9) {
      strMinute1 = '0' + minute1.toString();
    }

    String timeToday = hournow.toString() + ":" + strMinute1 + " " + ampmnow;

    Text datePickerText = Text(
      dateToday,
      style: popupStyle,
    );
    Text timePickerText = Text(
      timeToday,
      style: popupStyle,
    );

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(currentLanguage[177]),
              content: Form(
                key: _dialogKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    datePickerText,
                    TextButton(
                      style: flatButtonStyleExtra,
                      child: Text(currentLanguage[178]),
                      onPressed: () {
                        DatePicker.showDatePicker(context,
                            showTitleActions: true,
                            minTime: DateTime(now.year, now.month, now.day),
                            maxTime: DateTime(now.year + 1, now.month, now.day),
                            onChanged: (date) {
                          print('change $date');
                        }, onConfirm: (date) {
                          print('confirm $date');
                          setState(() {
                            dateDate = date;
                            String datePicked = date.month.toString() +
                                "-" +
                                date.day.toString() +
                                "-" +
                                date.year.toString();

                            datePickerText = Text(
                              datePicked,
                              style: popupStyle,
                            );
                          });
                        }, currentTime: DateTime.now(), locale: LocaleType.en);
                      },
                    ),
                    SizedBox(height: 25),
                    timePickerText,
                    TextButton(
                      style: flatButtonStyleExtra,
                      child: Text(currentLanguage[179]),
                      onPressed: () {
                        DatePicker.showTime12hPicker(context,
                            showTitleActions: true, onChanged: (date) {
                          print('change $date');
                        }, onConfirm: (date) {
                          print('confirm $date');
                          timeDate = date;
                          setState(() {
                            String ampm = 'AM';
                            int hour = date.hour;
                            if (date.hour >= 13) {
                              ampm = 'PM';
                              hour -= 12;
                            }

                            int minute = date.minute;
                            String strMinute = minute.toString();
                            if (minute <= 9) {
                              strMinute = '0' + minute.toString();
                            }

                            String timePicked =
                                hour.toString() + ":" + strMinute + " " + ampm;

                            timePickerText = Text(
                              timePicked,
                              style: popupStyle,
                            );
                          });
                        }, currentTime: DateTime.now(), locale: LocaleType.en);
                      },
                    )
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[77]),
                  onPressed: () {
                    Navigator.pop(context);
                    completedDateTime = null;
                  },
                ),
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[199]),
                  onPressed: () async {
                    if (_dialogKey.currentState.validate()) {
                      Navigator.pop(context);

                      DateTime newDateTime = DateTime(
                          dateDate.year,
                          dateDate.month,
                          dateDate.day,
                          timeDate.hour,
                          timeDate.minute);

                      print("$newDateTime");
                      print(newDateTime.toIso8601String());
                      completedDateTime = newDateTime;
                    }
                  },
                ),
              ],
            );
          });
        });
  }

  Future<String> hashtagDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(currentLanguage[291]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: textEditingControllerTwo,
                    maxLength: 20,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                    style: flatButtonStyle,
                    child: Text(currentLanguage[77]),
                    onPressed: () {
                      Navigator.pop(context, "");
                    }),
                TextButton(
                  style: flatButtonStyle,
                  child: Text(currentLanguage[10]),
                  onPressed: () {
                    Navigator.pop(
                        context, textEditingControllerTwo.text.toString());
                  },
                ),
              ],
            );
          });
        });
  }
}

class MessageBorder extends ShapeBorder {
  final bool usePadding;

  MessageBorder({this.usePadding = true});

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: usePadding ? 20 : 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) => null;

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    rect = Rect.fromPoints(rect.topLeft, rect.bottomRight - Offset(0, 20));
    return Path()
      ..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)))
      ..moveTo(rect.topCenter.dx - 10, rect.topCenter.dy)
      ..relativeLineTo(10, -10)
      ..relativeLineTo(10, 10)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
