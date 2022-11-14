// ignore_for_file: await_only_futures, unnecessary_string_interpolations, sized_box_for_whitespace, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:io';
import 'package:exif/exif.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glimpsegardens/screens/maps.dart';
import 'package:glimpsegardens/services/mapshelper.dart';
import 'package:glimpsegardens/screens/loading.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/settings/settings.dart' as mine;
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final String imageUrl;
  final String imageMessage;
  final bool simplify;
  final List<dynamic> tags;

  const DisplayPictureScreen({
    Key key,
    @required this.imagePath,
    @required this.imageUrl,
    @required this.imageMessage,
    @required this.simplify,
    @required this.tags,
  }) : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  final textEditingController = TextEditingController();
  final textEditingControllerTwo = TextEditingController();

  // We don't use the video player here other than for its size values
  Future<void> _initDecodedImage;

  double _opacity = 1.0;
  int numberOfTags = 0;

  bool _isAbsorbing = false;
  bool _isShareButtonVisible = false;
  bool loading = false;
  bool finishedInitialization = false;

  Icon _uploadButtonIcon = const Icon(Icons.file_upload);

  var _image;
  var imageAspectRatio;

  List<StatefulDragArea> hashtags = [];

  Widget chatOverlay = Column(
    children: <Widget>[
      Expanded(
          flex: 4,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const <Widget>[])),
      Expanded(
        flex: 6,
        child: Container(),
      ),
    ],
  );

  @override
  void initState() {
    if (widget.imagePath == null) {
      _image = Image.network(widget.imageUrl);
      _opacity = 0.75;
      _isAbsorbing = true;
      _isShareButtonVisible = true;
      if (widget.imageMessage != "") {
        setOverlayChat();
      }

      if (widget.tags != null) {
        setTags();
      }

      _initDecodedImage =
          decodeImage(isPath: false).then((value) => setState(() {
                finishedInitialization = true;
              }));
    } else {
      _image = File(widget.imagePath);
      _initDecodedImage =
          decodeImage(isPath: true).then((value) => setState(() {
                finishedInitialization = true;
              }));
    }

    super.initState();
  }

  void setTags() {
    // gets elements.
    for (int i = 0; i < widget.tags.length; i++) {
      Size size =
          Size((widget.tags[i]['positionx']), (widget.tags[i]['positiony']));

      hashtags.add(StatefulDragArea(
          fullsize: size,
          message: widget.tags[i]['message'],
          index: numberOfTags,
          isDraggable: false,
          child: Container(
              child: Center(
                  child: DefaultTextStyle(
                style: const TextStyle(
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
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          widget.imageMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
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

  // Convert the image into a file that can be decoded to determine aspect ratio
  Future<void> decodeImage({bool isPath}) async {
    final Completer<void> decoderCompleter = Completer<void>();

    if (isPath) {
      await decodeImageFromList(_image.readAsBytesSync())
          .then((value) => imageAspectRatio = value.width / value.height);
      decoderCompleter.complete();
    } else {
      _image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((ImageInfo _image, bool synchronousCall) {
        var myImage = _image.image;
        imageAspectRatio = myImage.width / myImage.height;
        decoderCompleter.complete();
      }));
    }

    setState(() {
      finishedInitialization = true;
    });

    return decoderCompleter.future;
  }

  // Stole this from the internet
  Future<File> fixExifRotation(String imagePath) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    final originalImage = img.decodeImage(imageBytes);

    final height = originalImage?.height;
    final width = originalImage?.width;

    // Let's check for the image size
    // This will be true also for upside-down photos but it's ok for me
    if (height >= width) {
      // I'm interested in portrait photos so
      // I'll just return here
      return originalFile;
    }

    // We'll use the exif package to read exif data
    // This is map of several exif properties
    // Let's check 'Image Orientation'
    final exifData = await readExifFromBytes(imageBytes);

    img.Image fixedImage;

    if (height < width) {
      // print('Rotating image necessary');
      // rotate
      if (exifData['Image Orientation'].printable.contains('Horizontal')) {
//        print("exifprint 1");
        fixedImage = img.copyRotate(originalImage, 90);
      } else if (exifData['Image Orientation'].printable.contains('180')) {
//        print("exifprint 2");
        fixedImage = img.copyRotate(originalImage, -90);
      } else if (exifData['Image Orientation'].printable.contains('CCW')) {
        // print("exifprint 3 - nothing to see here");
//        fixedImage = img.copyRotate(originalImage, 180);
        // Chloe's Code Here
        return originalFile;
      } else {
        //print("exifprint 4 - nothing to see here");
//        fixedImage = img.copyRotate(originalImage, 0);
        return originalFile;
      }
    }

    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));

    return fixedFile;
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
                            padding: const EdgeInsets.all(6),
                            child: Text(MapsHelper.message,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
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
                    children: const <Widget>[])),
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
  void dispose() {
    // Ensure disposing of the class.
    // Pretty sure this can be deleted if need be.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    File pathToFile; // placeholder for null safety

    if (widget.imagePath != null) {
      pathToFile = File(widget.imagePath);
      // fixExifRotation(widget.imagePath).then((value) => pathToFile = value);
    }

    void onTabTapped(int index) {
      selectedPinType = 0;
      completedDateTime = null;
      if (index == 0) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).popUntil((route) => route.isFirst);

        MapsHelper.message = "Hello!";
        MapsPage.answering = false;
        MapsPage.requestID = "";
      }
      if (index == 1) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context);
      }
      if (index == 2) {
        HapticFeedback.heavyImpact();
        Route route = MaterialPageRoute(builder: (context) => mine.Settings());
        Navigator.pushReplacement(context, route);

        MapsHelper.message = "Hello!";
        MapsPage.answering = false;
        MapsPage.requestID = "";
      }
    }

    @override
    void setState(fn) {
      if (mounted) {
        super.setState(fn);
      }
    }

    void messageDialog() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                title: Text(currentLanguage[175]),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(currentLanguage[176]),
                    TextField(
                      controller: textEditingController,
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
                      }),
                  TextButton(
                    style: flatButtonStyle,
                    child: Text(currentLanguage[10]),
                    onPressed: () {
                      MapsHelper.message =
                          textEditingController.text.toString();
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

    Future<void> _uploadPicture() async {
      setState(() {
        loading = true;
      });

      File file = File(widget.imagePath);
      User user = await FirebaseAuth.instance.currentUser;
      String uid = user.uid;
      DateTime now = DateTime.now().toUtc();
      String time =
          '${now.hour}:' '${now.minute}:' '${now.second}:' '${now.millisecond}';
      String storagePath = join('$uid', 'pictures', '${now.year}',
          '${now.month}', '${now.day}', '$time.jpeg');

      Reference storageReference =
          FirebaseStorage.instance.ref().child(storagePath);

      final UploadTask uploadTask = storageReference.putFile(file);
      final TaskSnapshot downloadUrl = (await uploadTask);
      final String url = (await downloadUrl.ref.getDownloadURL());

      bool toast = await MapsHelper.createVideoMarker(
          url, false, selectedPinType, completedDateTime, hashtags);

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

    return loading
        ? LoadingScreen(isUploading: true)
        : Scaffold(
            backgroundColor: fadedOutButtons,
            body: Stack(
              children: [
                FutureBuilder(
                    future: _initDecodedImage,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        // ignore: avoid_unnecessary_containers
                        return Container(
                          child: Center(
                            child: widget.imagePath != null
                                ? Image(
                                    image: FileImage(pathToFile),
                                    fit: BoxFit.contain,
                                  )
                                : Image(
                                    image: NetworkImage(widget.imageUrl),
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        );
                      } else {
                        return LoadingScreen(isUploading: false);
                      }
                    }),
                widget.simplify
                    ? Container()
                    : Align(
                        alignment: const Alignment(.9, -.90),
                        child: AbsorbPointer(
                          absorbing: _isAbsorbing || loading,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: _opacity,
                            child:

                                //MapsHelper.getCodeString() != "" &&
                                //MapsHelper.getCodeType() == CodeType.employee &&
                                //!MapsPage.answering
                                !MapsPage.answering &&
                                        ConstantsClass.businessAccount
                                    ? FloatingActionButton(
                                        heroTag: 'setPinTimeButton',
                                        child: const Icon(Icons.timelapse),
                                        backgroundColor: buttonsBorders,
                                        onPressed: () {
                                          HapticFeedback.heavyImpact();
                                          // Show message dialog.
                                          showPinTimeDialog(context);
                                        },
                                      )
                                    : Container(),
                          ),
                        ),
                      ),
                widget.simplify
                    ? Container()
                    : Align(
                        alignment: const Alignment(-.9, -.90),
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
                                    child: const Icon(Icons.public),
                                    backgroundColor: buttonsBorders,
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();
                                      // Show message dialog.
                                      showPinTypeDialog(context);
                                    },
                                  )
                                : Container(),
                          ),
                        ),
                      ),
                widget.simplify
                    ? Container()
                    : Align(
                        alignment: const Alignment(-.9, .95),
                        child: AbsorbPointer(
                          absorbing: _isAbsorbing || loading,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: _opacity,
                            child: FloatingActionButton(
                              heroTag: 'setMessageButton',
                              child: const Icon(Icons.chat),
                              backgroundColor: buttonsBorders,
                              onPressed: () {
                                HapticFeedback.heavyImpact();
                                // Show message dialog.
                                messageDialog();
                              },
                            ),
                          ),
                        ),
                      ),
                widget.simplify
                    ? Container()
                    : Align(
                        alignment: const Alignment(.9, .95),
                        child: AbsorbPointer(
                          absorbing: _isAbsorbing || loading,
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
                                  _uploadButtonIcon = const Icon(Icons.check);
                                });

                                // Upload the video & enable loading screen
                                _uploadPicture();
                              },
                            ),
                          ),
                        ),
                      ),
                widget.simplify
                    ? Container()
                    : Visibility(
                        visible: _isShareButtonVisible,
                        child: Align(
                          alignment: const Alignment(-.9, .7),
                          child: FloatingActionButton(
                            heroTag: 'shareButton',
                            child: const Icon(Icons.share),
                            backgroundColor: buttonsBorders,
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              Share.share(
                                '${widget.imageUrl}',
                              );
                            },
                          ),
                        ),
                      ),
                !ConstantsClass.businessAccount || widget.simplify
                    ? Container()
                    : Align(
                        alignment: const Alignment(-.9, .72),
                        child: AbsorbPointer(
                          absorbing: _isAbsorbing || loading,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: _opacity,
                            child: FloatingActionButton(
                              heroTag: null,
                              child: const Icon(Icons.tag),
                              backgroundColor: buttonsBorders,
                              onPressed: () async {
                                HapticFeedback.heavyImpact();
                                // Show message dialog.

                                String value = await hashtagDialog(context);
                                if (value != "") {
                                  setState(() {
                                    hashtags.add(StatefulDragArea(
                                        fullsize: size,
                                        message: value,
                                        index: numberOfTags,
                                        isDraggable: true,
                                        child: Container(
                                            child: Center(
                                                child: DefaultTextStyle(
                                              style: const TextStyle(
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
                chatOverlay,
                Container(
                    width: size.width,
                    height: size.height,
                    child: Stack(children: hashtags)),
                !ConstantsClass.businessAccount || widget.simplify
                    ? Container()
                    : Align(
                        alignment: const Alignment(.88, .71),
                        child: DragTarget<int>(
                          builder: (context, List<dynamic> candidateData,
                              rejectedData) {
                            return Container(
                                height: 50.0,
                                width: 50.0,
                                child: const Icon(Icons.delete_forever,
                                    size: 50.0,
                                    color: Color.fromRGBO(0, 0, 0, 0.5)));
                          },
                          onWillAccept: (data) {
                            return true;
                          },
                          onAccept: (data) {
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
            bottomNavigationBar: !finishedInitialization || widget.simplify
                ? null
                : BottomNavigationBar(
                    items: <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.map),
                        label: currentLanguage[219],
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.arrow_back),
                        label: currentLanguage[214],
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.settings),
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
                  ),
          );
  }

  int selectedPinType = 0;
  showPinTypeDialog(BuildContext context) {
    final _dialogKey = GlobalKey<FormState>();

    String dropDownValue;
    String dropDownHint = currentLanguage[193];

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              title: Text(currentLanguage[194]),
              content: Form(
                key: _dialogKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      hint: Text(dropDownHint),
                      validator: (value) =>
                          value == null ? currentLanguage[195] : null,
                      items: <String>['Public', 'Geocached', 'VIP']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      value: dropDownValue,
                      onChanged: (changedValue) {
                        if (mounted) {
                          setState(() {
                            dropDownValue = changedValue;
                          });
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

  DateTime completedDateTime;
  showPinTimeDialog(BuildContext context) {
    final _dialogKey = GlobalKey<FormState>();

    TextStyle popupStyle = const TextStyle(fontSize: 18);

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
              shape: const RoundedRectangleBorder(
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
                            onChanged: (date) {}, onConfirm: (date) {
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
                    const SizedBox(height: 25),
                    timePickerText,
                    TextButton(
                      style: flatButtonStyleExtra,
                      child: Text(currentLanguage[179]),
                      onPressed: () {
                        DatePicker.showTime12hPicker(context,
                            showTitleActions: true,
                            onChanged: (date) {}, onConfirm: (date) {
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
              shape: const RoundedRectangleBorder(
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

// ignore: must_be_immutable
class StatefulDragArea extends StatefulWidget {
  Widget child;
  final String message;
  final Size fullsize;
  final int index;
  double positionx;
  double positiony;
  final bool isDraggable;
  bool hasRunOnce = false;
  Offset position = const Offset(0, 0);
  bool isVisible = true;

  StatefulDragArea(
      {Key key,
      this.child,
      @required this.fullsize,
      @required this.index,
      @required this.isDraggable,
      @required this.message})
      : super(key: key);

  @override
  _DragAreaStateStateful createState() => _DragAreaStateStateful();
}

class _DragAreaStateStateful extends State<StatefulDragArea> {
  void updatePosition(Offset newPosition) {
    setState(() => widget.position = newPosition);
    widget.positionx = widget.position.dx;
    widget.positiony = widget.position.dy;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasRunOnce == false && widget.isDraggable) {
      widget.position = Offset((widget.fullsize.width / 2.0) - 100,
          (widget.fullsize.height / 2.0) - 50);

      widget.positionx = widget.position.dx;
      widget.positiony = widget.position.dy;
      widget.hasRunOnce = true;
    } else if (widget.hasRunOnce == false && !widget.isDraggable) {
      widget.position =
          Offset((widget.fullsize.width), (widget.fullsize.height));

      widget.positionx = widget.position.dx;
      widget.positiony = widget.position.dy;
      widget.hasRunOnce = true;
    }

    return widget.isVisible != true
        ? Container()
        : Positioned(
            left: widget.position.dx,
            top: widget.position.dy,
            child: widget.isDraggable == false
                ? widget.child
                : Draggable<int>(
                    data: widget.index,
                    maxSimultaneousDrags: 1,
                    feedback: widget.child,
                    childWhenDragging: Opacity(
                      opacity: .3,
                      child: widget.child,
                    ),
                    onDragEnd: (details) => updatePosition(details.offset),
                    child: widget.child),
          );
  }
}

class MessageBorder extends ShapeBorder {
  final bool usePadding;

  // ignore: prefer_const_constructors_in_immutables
  MessageBorder({this.usePadding = true});

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: usePadding ? 20 : 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) => null;

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    rect =
        Rect.fromPoints(rect.topLeft, rect.bottomRight - const Offset(0, 20));
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
