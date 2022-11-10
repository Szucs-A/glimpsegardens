// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:glimpsegardens/services/remote_config.dart';

// ignore: use_key_in_widget_constructors
class CameraCountdown extends StatefulWidget {
  Function() callbackTimer;
  Function() callbackStopTimer;

  @override
  _CameraCountdown createState() => _CameraCountdown();
}

class _CameraCountdown extends State<CameraCountdown> {
  String _countDownStr = '1';
  int _countDownNum = 0;
  bool _loopActive = false;
  bool _isRecording = true;
  double _timerOpacity = 0.0;
  int maxTimerValue = 30;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    widget.callbackTimer = incrementTimer;
    widget.callbackStopTimer = turnOffTimer;
    maxTimerValue = RemoteConfigInit.remoteConfig.getInt('videoTimeLimit');

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _timerOpacity, // 0 = invisible, 1 = opaque
        child: Text(
          // ignore: unnecessary_string_interpolations
          '$_countDownStr',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 48),
        ));
  }

  // Increments the timer for us. Some real big brain stuff.
  Future<bool> incrementTimer() async {
    if (_loopActive) {
      return false;
    }

    _loopActive = true;
    _isRecording = true;
    // Resetting the components.
    _countDownStr = '1';
    _countDownNum = 0;
    _timerOpacity = 1.0;

    while (_isRecording) {
      if (_countDownNum == maxTimerValue) {
        setState(() {
          _countDownStr = 'Done!';
        });

        return true;
      }

      _countDownNum += 1;
      setState(() {
        _countDownStr = '$_countDownNum';
      });

      await Future.delayed(const Duration(seconds: 1));
    }

    return false;
  }

  void turnOffTimer() {
    setState(() {
      _isRecording = false;
      _loopActive = false;
      _timerOpacity = 0.0;
    });
  }
}
