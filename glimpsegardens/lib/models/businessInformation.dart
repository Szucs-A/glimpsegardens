import 'package:glimpsegardens/models/HoursOfOperation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusinessInformation {
  final String bname;
  final String address;
  final String website;
  final String number;
  final HoursOfOperation hours;
  final int type;
  final LatLng pos;

  BusinessInformation({
    this.bname,
    this.address,
    this.website,
    this.hours,
    this.type,
    this.pos,
    this.number,
  });
}
