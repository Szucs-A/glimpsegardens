// ignore_for_file: prefer_initializing_formals
import 'dart:core';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoder/geocoder.dart';

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

  static Future<Address> getInformation(LatLng lat) async {
    final coordinates = Coordinates(lat.latitude, lat.longitude);

    List<Address> addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);

    return addresses.first;
  }
}
