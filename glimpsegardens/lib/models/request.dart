import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

class Request {
  final String email;
  final String message;
  final double latitude;
  final double longitude;
  final String time;
  final String userToken;
  final int likes;
  final String city;
  final String country;
  final List<String> followTokens;
  final List<String> likedAccounts;
  final List<String> followAccounts;
  final String pinUrl;
  final String name;
  final int type;
  final String codeSnippet;
  final double radius;

  Request({
    @required this.email,
    @required this.latitude,
    @required this.longitude,
    @required this.message,
    @required this.time,
    @required this.userToken,
    @required this.likes,
    @required this.city,
    @required this.country,
    @required this.followTokens,
    @required this.followAccounts,
    @required this.likedAccounts,
    @required this.pinUrl,
    @required this.name,
    @required this.type,
    @required this.codeSnippet,
    @required this.radius,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'latitude': latitude,
        'longitude': longitude,
        'message': message,
        'time': time,
        'token': userToken,
        'likes': likes,
        'country': country,
        'city': city,
        'followtokens': followTokens,
        'likedaccounts': likedAccounts,
        'followaccounts': followAccounts,
        'pinUrl': pinUrl,
        'name': name,
        'type': type,
        'codesnippet': codeSnippet,
        'radius': radius,
      };
}
