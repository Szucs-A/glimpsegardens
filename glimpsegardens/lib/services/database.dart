import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glimpsegardens/models/businessInformation.dart';
import 'package:glimpsegardens/services/push_notification_service.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

class DatabaseService {
  final String uid;

  DatabaseService({this.uid});

  // collection reference
  final CollectionReference userCollection = firestore.collection('users');

  final CollectionReference requestsCollection =
      firestore.collection('requests');

  final CollectionReference reportsCollection = firestore.collection('reports');

  final CollectionReference videoCollection = firestore.collection('videos');

  final CollectionReference keyCollection = firestore.collection('keys');

  final CollectionReference codesCollection = firestore.collection('codes');

  final CollectionReference businessCollection =
      firestore.collection('businesses');

  final CollectionReference deadZoneCollection =
      firestore.collection('deadzones');

  Future updateUserData(String email, String firstName) async {
    var doc = await userCollection.doc(uid).get();
    if (doc.exists) return;

    return await userCollection.doc(uid).set({
      'email': email,
      'firstName': firstName,
      'followUids': "",
      'contentAvailable': false,
    });
  }

  Future createBusinessPin(String uid, BusinessInformation bInfo) async {
    var doc = await businessCollection.doc(uid).get();
    if (doc.exists) return;
    String deviceToken = await PushNotificationService.getDeviceToken();

    return await businessCollection.doc(uid).set({
      'uid': uid,
      'bType': bInfo.type,
      'latitude': bInfo.pos.latitude,
      'longitude': bInfo.pos.longitude,
      'tokenDevice': deviceToken,
      'followUids': "",
      'followDevices': "",
      'newPost': "2022-04-12T10:47:14.065160",
    });
  }

  Future updateUserDataBusiness(
      String email, String firstName, BusinessInformation bInfo) async {
    var doc = await userCollection.doc(uid).get();
    if (doc.exists) return;

    return await userCollection.doc(uid).set({
      'followUids': "",
      'email': email,
      'firstName': firstName,
      'bName': bInfo.bname,
      'bAddress': bInfo.address,
      'bWebsite': bInfo.website,
      'bType': bInfo.type,
      'contentAvailable': false,
      'bNumber': bInfo.number,
      'latitude': bInfo.pos.latitude,
      'longitude': bInfo.pos.longitude,
      'Monday': bInfo.hours.week[0] == null
          ? "Closed"
          : bInfo.hours.week[0].printMeBusiness(),
      'Tuesday': bInfo.hours.week[1] == null
          ? "Closed"
          : bInfo.hours.week[1].printMeBusiness(),
      'Wednesday': bInfo.hours.week[2] == null
          ? "Closed"
          : bInfo.hours.week[2].printMeBusiness(),
      'Thursday': bInfo.hours.week[3] == null
          ? "Closed"
          : bInfo.hours.week[3].printMeBusiness(),
      'Friday': bInfo.hours.week[4] == null
          ? "Closed"
          : bInfo.hours.week[4].printMeBusiness(),
      'Saturday': bInfo.hours.week[5] == null
          ? "Closed"
          : bInfo.hours.week[5].printMeBusiness(),
      'Sunday': bInfo.hours.week[6] == null
          ? "Closed"
          : bInfo.hours.week[6].printMeBusiness(),
    });
  }

  Future<String> getField(String _uid, String field) async {
    String _field;

    DocumentSnapshot value = await firestore.doc('users/$_uid').get();

    _field = value[field];

    return _field;
  }

  Stream<QuerySnapshot> get reports {
    return reportsCollection.snapshots();
  }

  // get users stream
  Stream<QuerySnapshot> get users {
    return userCollection.snapshots();
  }

  Stream<QuerySnapshot> get requests {
    return requestsCollection.snapshots();
  }

  Stream<QuerySnapshot> get videos {
    return videoCollection.snapshots();
  }

  Stream<QuerySnapshot> get codes {
    return codesCollection.snapshots();
  }

  Stream<QuerySnapshot> get deadzones {
    return deadZoneCollection.snapshots();
  }
}
