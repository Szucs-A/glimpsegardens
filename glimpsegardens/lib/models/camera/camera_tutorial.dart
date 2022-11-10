import 'package:flutter/material.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';

// ignore: must_be_immutable, use_key_in_widget_constructors
class CameraTutorial extends StatefulWidget {
  bool _tutorialComplete = true;
  Function(bool) callbackUpdateTutorial;

  @override
  _CameraTutorial createState() => _CameraTutorial();
}

class _CameraTutorial extends State<CameraTutorial> {
  @override
  void initState() {
    widget.callbackUpdateTutorial = updateTutorial;

    _getTutorialComplete();

    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !widget._tutorialComplete,
      child: Align(
        alignment: const Alignment(0, .9),
        child: Image.asset(
          'assets/drawable/doot.gif',
          width: 200,
          height: 150,
        ),
      ),
    );
  }

  void updateTutorial(bool tutorialComplete) {
    setState(() {
      widget._tutorialComplete = tutorialComplete;
    });

    PreferencesHelper().setFinishedTutorial(true);
  }

  // Sets variable '_tutorialGifVisible' to whether or not the user has finished
  // the 'tutorial' (aka swipe on the button)
  Future _getTutorialComplete() async {
    bool _tmpTutorialComplete = await PreferencesHelper().getFinishedTutorial();

    if (_tmpTutorialComplete != null) {
      setState(() {
        widget._tutorialComplete = _tmpTutorialComplete;
      });
    }
  }
}
