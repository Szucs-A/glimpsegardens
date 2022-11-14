class TimeRanges {
  String openTime;
  String closeTime;

  printMe() {
    // ignore: avoid_print
    print("openTime: " + openTime + " closeTime: " + closeTime);
  }

  String printMeBusiness() {
    return "Open: " + openTime + " to " + closeTime;
  }

  TimeRanges({
    this.openTime = "12:00 am",
    this.closeTime = "12:00 am",
  });
}
