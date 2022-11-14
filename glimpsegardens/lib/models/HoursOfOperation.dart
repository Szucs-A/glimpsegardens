import 'package:glimpsegardens/models/TimeRanges.dart';

class HoursOfOperation {
  // Set to null for not open.
  final List<TimeRanges> week;

  HoursOfOperation({
    this.week,
  });
}
