import 'dart:core';
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoder/geocoder.dart';
import 'package:glimpsegardens/services/remote_config.dart';

class Favorite {
  String city; // Locality
  String country; // CountryName
  String address; // AddressLine
  LatLng coordinate;

  Favorite(String city, String country, String address, LatLng coo) {
    this.city = city;
    this.address = address;
    this.country = country;
    coordinate = coo;
  }

  //City@address@country@coordinate
  static Favorite parseFavoriteString(String favorite) {
    List<String> object = favorite.split('@');

    if (object.length != 4) {
      return null;
    }

    List<String> latlong = object.elementAt(3).split(",");
    double latitude = double.parse(latlong.elementAt(0));
    double longitude = double.parse(latlong.elementAt(1));

    LatLng lat = new LatLng(latitude, longitude);

    Favorite f = new Favorite(
        object.elementAt(0), object.elementAt(2), object.elementAt(1), lat);

    return f;
  }

  static Future<Address> getInformation(LatLng lat) async {
    final coordinates = new Coordinates(lat.latitude, lat.longitude);

    String apiKey = "";

    if (Platform.isAndroid) {
      apiKey = RemoteConfigInit.remoteConfig.getString('androidGeocoderAPI');
    } else {
      apiKey = RemoteConfigInit.remoteConfig.getString('iOSGeocoderAPI');
    }

// TODO: BUMP RATE LIMIT.
/*
    List<Address> addresses =
        await Geocoder.google(apiKey).findAddressesFromCoordinates(coordinates);

*/
    // EDITED: TODO:

    List<Address> addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);

    //var first = addresses.first;
    //print(
    //    ' Locality: ${first.locality}, AdminArea: ${first.adminArea}, subLocality: ${first.subLocality}, subAdminArea: ${first.subAdminArea}, addressLine: ${first.addressLine}, featureName: ${first.featureName}, thoroughFare: ${first.thoroughfare}, subThoroughFare: ${first.subThoroughfare},');

    print(addresses.length);

    return addresses.first;
  }
}
