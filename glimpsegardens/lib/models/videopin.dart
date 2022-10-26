import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

class VideoPin {
  final String email;
  final String message;
  final double latitude;
  final double longitude;
  final String time;
  final String url;
  final String userid;
  final int likes;
  final String city;
  final String country;
  final bool isVideo;
  final String myToken;
  final List<String> likedAccounts;
  final String pinUrl;
  final String name;
  final int type;
  final String codeSnippet;
  final double radius;
  final String endTime;

  VideoPin({
    @required this.email,
    @required this.latitude,
    @required this.longitude,
    @required this.message,
    @required this.time,
    @required this.url,
    @required this.userid,
    @required this.likes,
    @required this.city,
    @required this.country,
    @required this.isVideo,
    @required this.myToken,
    @required this.likedAccounts,
    @required this.pinUrl,
    @required this.name,
    @required this.type,
    @required this.codeSnippet,
    @required this.radius,
    @required this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'latitude': latitude,
        'longitude': longitude,
        'message': message,
        'time': time,
        'url': url,
        'userid': userid,
        'likes': likes,
        'city': city,
        'country': country,
        'isVideo': isVideo,
        'token': myToken,
        'likedaccounts': likedAccounts,
        'pinUrl': pinUrl,
        'name': name,
        'type': type,
        'codesnippet': codeSnippet,
        'radius': radius,
        'endTime': endTime,
      };
}
