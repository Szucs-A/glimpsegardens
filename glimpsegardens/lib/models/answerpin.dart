import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

class AnswerPin {
  final String email;
  final String time;
  final String userID;
  final String url;
  final String message;
  final String name;
  final bool isVideo;

  AnswerPin({
    @required this.email,
    @required this.time,
    @required this.userID,
    @required this.url,
    @required this.message,
    @required this.name,
    @required this.isVideo,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'time': time,
        'userid': userID,
        'url': url,
        'message': message,
        'name': name,
        'isVideo': isVideo,
      };
}
