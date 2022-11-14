import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glimpsegardens/screens/loading.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/VideoPlayerScreen.dart';
import 'package:glimpsegardens/services/camera/display_picture_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:glimpsegardens/screens/settings/settings.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:glimpsegardens/screens/maps.dart';
import 'package:glimpsegardens/screens/MapsHelper.dart';
import 'package:glimpsegardens/models/camera/camera_preview.dart';
import 'package:glimpsegardens/models/camera/camera_tutorial.dart';
import 'package:glimpsegardens/screens/errorscreen.dart';
import 'package:glimpsegardens/models/camera/camera_countdown.dart';

// GET IMAGE GALLERY NOT WORKING AND I HAD TO CHANGE THE CAMERA STUFF DUE TO PLUGIN UPGRADES TODO:

// ignore: constant_identifier_names
enum PermissionLevels { None, JustMicroPhone, JustCamera, Both }

// A screen that allows users to take a picture using a given camera.
class Camera extends StatefulWidget {
  static bool hasRunRequest = false;
  static bool cancelLoading = false;

  const Camera({
    Key key,
  }) : super(key: key);

  @override
  CameraState createState() => CameraState();
}

class CameraState extends State<Camera> with SingleTickerProviderStateMixin {
  String permissionMessage = currentLanguage[174];

  bool hasRunInit = false;
  List<CameraDescription> cameras;

  CameraController _controller;
  CameraTutorial cameraTutorialWidget;
  CameraCountdown cameraCountdownWidget;
  Future<void> _initializeControllerFuture;

  AnimationController _animationController;
  Animation<double> _sizeAnimation;

  String _pathCopy;
  XFile _pathFile;
  String _userName;

  bool _isAbsorbing = false;
  bool _frontCameraActive = true;
  bool _cameraBtnVisible = false;

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  Future<PermissionLevels> gettingCameraPermission() async {
    var CameraStatus = await Permission.camera.request();
    var MicrophoneStatus = await Permission.microphone.request();

    if (CameraStatus.isGranted && MicrophoneStatus.isGranted) {
      return PermissionLevels.Both;
    } else if (CameraStatus.isGranted) {
      return PermissionLevels.JustCamera;
    } else if (MicrophoneStatus.isGranted) {
      return PermissionLevels.JustMicroPhone;
    } else {
      return PermissionLevels.None;
    }
  }

  Future<bool> gettingCameraPermissionStatus() async {
    var newStatus = null;
    if (!Camera.hasRunRequest) {
      // Not Running Twice.
      Camera.hasRunRequest = true;
      newStatus = await gettingCameraPermission();
    }

    // For only the first loop.
    if (newStatus != null) {
      if (newStatus == PermissionLevels.Both) {
        return true;
      } else {
        Camera.cancelLoading = true;
        return false;
      }
    }

    var status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (Camera.cancelLoading) {
      // means both permission levels were denied.
      return false;
    }

    // We continue to wait.
    return null;
  }

  void beginCameraInit() async {
    hasRunInit = true;

    // Ensure that plugin services are initialized so that `availableCameras()`
    // can be called before `runApp()`
    WidgetsFlutterBinding.ensureInitialized();

    // Obtain a list of the available cameras on the device.

    Stopwatch stopwatch = new Stopwatch()..start();
    cameras = await availableCameras();
    print('availableCameras() executed in ${stopwatch.elapsed}');

    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      cameras[0],
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    Stopwatch stopwatch2 = new Stopwatch()..start();
    _initializeControllerFuture =
        _controller.initialize().then((value) => setState(() {
              _cameraBtnVisible = true;
            }));
    print('initialize() executed in ${stopwatch2.elapsed}');
  }

  @override
  void initState() {
    // Lock orientation to portrait - GOOD.
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    // Check if user is anonymous - GOOD.
    anonCheck();

    _animationController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);

    _animationController.addListener(() {
      setState(() {});
    });

    _sizeAnimation =
        Tween<double>(begin: 60, end: 85).animate(_animationController);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  // Function is for when a navigation icon is tapped
  void onTabTapped(int index) {
    if (index == 0) {
      HapticFeedback.heavyImpact();
      MapsPage.answering = false;
      MapsPage.requestID = "";
      MapsHelper.message = "Hello!";
      Navigator.of(context).popUntil((route) => route.isFirst);
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

  void _takePicture() async {
    try {
      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      // Construct the path where the image should be saved
      final path = join(
        // Store the picture in the temp directory.
        // Find the temp directory using the `path_provider` plugin.
        (await getTemporaryDirectory()).path,
        '${DateTime.now().toIso8601String()}.jpeg',
      );

      // Attempt to take a photo and log where it's been saved.
      // Make a copy of path so it doesn't get overridden every
      // time the button gets pressed.
      _pathCopy = path; //So path doesn't change @ every press.
      _pathFile = await _controller.takePicture();
      _pathCopy = _pathFile.path;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            imagePath: _pathCopy,
            imageUrl: null,
            imageMessage: "",
            simplify: false,
            tags: [],
          ),
        ),
      );
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  void startRecording() async {
    // Take the Picture in a try / catch block. If anything goes wrong,
    // catch the error.
    try {
      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      // Construct the path where the video should be saved
      final path = join(
        // Store the video in the temp directory.
        // Find the temp directory using the `path_provider` plugin.
        (await getTemporaryDirectory()).path,
        '${DateTime.now().toIso8601String()}.mp4',
      );

      // Attempt to take a video and log where it's been saved.
      // Make a copy of path so it doesn't get overridden every
      // time the button gets pressed.
      _pathCopy = path; //So path doesn't change @ every press.
      await _controller.startVideoRecording();
      Fluttertoast.showToast(msg: currentLanguage[222]);
      startTimer();
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  // Reset all the variables so the timer works correctly
  // Also make the timer invisible again
  void stopRecordingAndOpenVideoPlayer() async {
    print("Stopped Recording");
    setState(() {
      _isAbsorbing = false;
    });

    try {
      // Ensure that the camera is initialized.
      print("Initialization Beginning");
      await _initializeControllerFuture;
      print("Initialization Ended");
      print("Awaiting Stop Video");
      _pathFile = await _controller.stopVideoRecording();
      _pathCopy = _pathFile.path;
      print("Showing Toast");
      Fluttertoast.showToast(msg: currentLanguage[223]);
      print("Callback Timer");
      cameraCountdownWidget.callbackStopTimer();
      print("Pushing New Screen");
      // If the video was taken, display it on a new screen.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoPath: _pathCopy,
            videoUrl: null,
            videoMessage: "",
            simplify: false,
          ),
        ),
      );
    } catch (e) {
      print("Catching e.");
      print(e.toString());
    }
  }

  // Increments the timer for us. Some real big brain stuff.
  void startTimer() async {
    bool finished = await cameraCountdownWidget.callbackTimer();

    if (finished) {
      _isAbsorbing = true;

      await Future.delayed(Duration(milliseconds: 500));

      stopRecordingAndOpenVideoPlayer();
    }
  }

  // Stolen from the login page
  showAlertDialog(BuildContext context, String title, String msg) {
    Widget okButton = TextButton(
      style: flatButtonStyle,
      child: Text(currentLanguage[13]),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(msg),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      actions: <Widget>[okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // Check if the user is anonymous and disable camera button if so
  void anonCheck() async {
    _userName = await PreferencesHelper().getFirstName();

    if (_userName == 'Anonymous') {
      setState(() {
        _isAbsorbing = true;
      });

      showAlertDialog(context, "Attention",
          "Anonymous users cannot record and upload videos.");
    }
  }

  void _swapCameras(bool frontCameraActive) async {
    final lensDirection = _controller.description.lensDirection;
    CameraDescription newDescription;

    // Find the new camera description
    if (lensDirection == CameraLensDirection.front) {
      newDescription = cameras?.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.back);
    } else {
      newDescription = cameras?.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.front);
    }

    // Dispose of the controller
    if (_controller != null) {
      await _controller.dispose();
    }

    // Set up a new controller
    _controller = CameraController(
      newDescription,
      ResolutionPreset.medium,
    );

    // initialize
    try {
      await _controller.initialize();
    } catch (e) {
      print(e);
    }

    // Rebuild the view
    if (mounted) {
      setState(() {});
    }
  }

/*
  // Function that opens an image picker and allows the user to pick an image
  Future<void> _getImageFromGallery() async {
    final _picker = ImagePicker();
    // Pick an image from the gallery
    PickedFile _pickedImage =
        await _picker.getImage(source: ImageSource.gallery);

    if (_pickedImage == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisplayPictureScreen(
          imagePath: _pickedImage.path,
          imageUrl: null,
          imageMessage: "",
          simplify: false,
          tags: [],
        ),
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    if (cameraTutorialWidget == null) cameraTutorialWidget = CameraTutorial();
    if (cameraCountdownWidget == null)
      cameraCountdownWidget = CameraCountdown();

    return Scaffold(
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: Stack(
        children: [
          FutureBuilder<bool>(
            future: gettingCameraPermissionStatus(),
            builder: (context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) {
                final status = snapshot.data;
                if (status != null && status) {
                  print("Loading Data.");
                  if (!hasRunInit) {
                    beginCameraInit();
                  }

                  return _initializeControllerFuture != null
                      ? CameraPreviewWidget(_controller)
                      : LoadingScreen(isUploading: false);
                } else {
                  return ErrorScreen(permissionMessage);
                }
              } else {
                print("Loading No Data.");
                // Otherwise, display a loading indicator.
                return LoadingScreen(isUploading: false);
              }
            },
          ),
          Align(alignment: Alignment(0, .6), child: cameraCountdownWidget),
          Visibility(
            visible: _cameraBtnVisible,
            child: Align(
                alignment: Alignment(.85, .935),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: buttonsBorders),
                  child: IconButton(
                    color: Colors.white,
                    icon: Icon(
                      Icons.switch_camera,
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _swapCameras(_frontCameraActive);
                    },
                  ),
                )),
          ),
          /*Align(
            alignment: Alignment(-.85, .935),
            child: AbsorbPointer(
              absorbing: _isAbsorbing,
              child: Container(
                height: 50, // default is 60
                width: 50, // default is 60
                child: FittedBox(
                  child: FloatingActionButton(
                    child: Icon(Icons.library_add),
                    heroTag: "ImageGallery",
                    backgroundColor: buttonsBorders,
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      // _getImageFromGallery();
                    },
                  ),
                ),
              ),
            ),
          ),
          */
          Visibility(
            visible: _cameraBtnVisible,
            child: cameraTutorialWidget,
          ),
        ],
      ),

      bottomNavigationBar: _initializeControllerFuture == null
          ? null
          : BottomNavigationBar(
              items: navBottomList,

              // For some reason, setting this to the index variable doesn't do shit
              showSelectedLabels: false,
              showUnselectedLabels: false,
              currentIndex: 1,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.5),
              backgroundColor: buttonsBorders,
              onTap: onTabTapped,
            ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Visibility(
          visible: _cameraBtnVisible,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            AbsorbPointer(
              absorbing: _isAbsorbing,
              child: GestureDetector(
                onLongPress: () async {
                  cameraTutorialWidget.callbackUpdateTutorial(true);
                  HapticFeedback.heavyImpact();
                  _animationController
                      .forward()
                      .then((value) => startRecording());
                },
                onLongPressUp: () async {
                  _animationController
                      .reverse()
                      .then((value) => stopRecordingAndOpenVideoPlayer());
                },
                child: Container(
                  height: _sizeAnimation.value, // default is 60
                  width: _sizeAnimation.value, // default is 60
                  child: FittedBox(
                    child: FloatingActionButton(
                      heroTag: "TakePic",
                      child: Icon(Icons.camera_alt),
                      backgroundColor: buttonsBorders,
                      onPressed: () async {
                        HapticFeedback.heavyImpact();
                        _takePicture();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ])),
    );
  }
}
