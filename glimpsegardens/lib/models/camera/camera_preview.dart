// ignore_for_file: prefer_conditional_assignment, avoid_unnecessary_containers

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CameraPreviewWidget extends StatefulWidget {
  // ignore: prefer_final_fields
  CameraController _controller;

  // ignore: use_key_in_widget_constructors
  CameraPreviewWidget(this._controller);

  @override
  _CameraPreviewWidget createState() => _CameraPreviewWidget();
}

class _CameraPreviewWidget extends State<CameraPreviewWidget> {
  Size size;

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    widget._controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (size == null) {
      size = MediaQuery.of(context).size;
    }

    return Container(
      child: Transform.scale(
        scale: widget._controller.value.aspectRatio / size.aspectRatio,
        child: Center(
          child: AspectRatio(
            aspectRatio: widget._controller.value.aspectRatio,
            child: CameraPreview(widget._controller),
          ),
        ),
      ),
    );
  }
}
