import 'dart:async';
import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:glimpsegardens/models/businessInformation.dart';
import 'package:glimpsegardens/models/user.dart' as basic;
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:glimpsegardens/services/database.dart';
import 'package:glimpsegardens/services/preferences_helper.dart';
import 'package:glimpsegardens/screens/mapshelper.dart';
import 'package:glimpsegardens/screens/start_up/authenticate/business/businessInfoRegistration.dart';
import 'package:glimpsegardens/shared/constants.dart';
import 'package:glimpsegardens/screens/maps.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static bool appleSignInAvailable;

  final fba.FirebaseAuth _auth = fba.FirebaseAuth.instance;

  /*
  Future<basic.User> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final fba.OAuthCredential facebookAuthCredential =
        fba.FacebookAuthProvider.credential(loginResult.accessToken.token);

    fba.UserCredential userCredential = await fba.FirebaseAuth.instance
        .signInWithCredential(facebookAuthCredential);

    basic.User user = _userFromFirebaseUser(userCredential.user);

    // create a new database document for the user with their uid
    await DatabaseService(uid: user.uid).updateUserData(
      userCredential.user.email,
      userCredential.user.displayName,
    );

    if (user != null) {
      QuerySnapshot snapshot = await DatabaseService()
          .userCollection
          .where('email', isEqualTo: userCredential.user.email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        snapshot.docs.forEach((element) {
          PreferencesHelper()
              .setFirstName(element['firstName'])
              .whenComplete(() => print("first name set"));
        });

        PreferencesHelper().setFinishedTutorial(true);
      } else {
        PreferencesHelper().setFinishedTutorial(false);
        PreferencesHelper().setFirstName(userCredential.user.displayName);
      }
    }

    PreferencesHelper().setUid(user.uid);

    // Once signed in, return the UserCredential
    return user;
  }
  */

  Future<basic.User> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser =
        await GoogleSignIn(scopes: ['email', 'profile']).signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = fba.GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    fba.UserCredential userCredential =
        await fba.FirebaseAuth.instance.signInWithCredential(credential);

    basic.User user = _userFromFirebaseUser(userCredential.user);

    if (user != null) {
      QuerySnapshot snapshot = await DatabaseService()
          .userCollection
          .where('email', isEqualTo: userCredential.user.email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        snapshot.docs.forEach((element) {
          PreferencesHelper()
              .setFirstName(element['firstName'])
              .whenComplete(() => print("first name set"));
        });

        PreferencesHelper().setFinishedTutorial(true);
      } else {
        PreferencesHelper().setFinishedTutorial(false);
        PreferencesHelper().setFirstName(userCredential.user.displayName);
      }
    }

    PreferencesHelper().setUid(user.uid);

    // create a new database document for the user with the uid
    await DatabaseService(uid: user.uid).updateUserData(
      userCredential.user.email,
      userCredential.user.displayName,
    );

    return user;
  }

  // create user object based on FirebaseUser
  // IF AUTH IS BROKE THEN THIS MIGHT BE THE CAUSE
  // I CHANGED THE PARAMETER USER TO FBA.USER
  basic.User _userFromFirebaseUser(fba.User user) {
    bool thirdPartySignIn = false;

    for (var v in user.providerData) {
      print("PROVIDER: ${v.providerId}");
      if (v.providerId == "facebook.com") {
        thirdPartySignIn = true;
      }
    }

    print("LOADED USER + Third Party Sign In: $thirdPartySignIn");
    if (user != null && user.emailVerified)
      accountCodeSync(user.uid); // TODO: ?

    return user != null
        ? basic.User(
            uid: user.uid,
            isEmailVerified: user.emailVerified,
            isAnonymous: user.isAnonymous,
            isThirdParty: thirdPartySignIn)
        : null;
  }

  Future<bool> accountCodeSync(String userId) async {
    DocumentSnapshot user =
        await DatabaseService().userCollection.doc(userId).get();

    Map<String, dynamic> tester = user.data();

    if (tester == null) return false;

    if (tester.containsKey("currentParent")) {
      if (user['currentParent'] == "") {
        print("User had a code but not anymore.");
      } else {
        print("User has an active code: " + user['currentParent'].toString());
        // Grab the code and compare it to the time it was activated to

        DocumentSnapshot codeSnapshot = await DatabaseService()
            .codesCollection
            .doc(user['currentParent'])
            .get();

        DocumentSnapshot infoDoc = await codeSnapshot.reference
            .collection("Event Info")
            .doc("Info")
            .get();

        int timestamp = int.parse(user['timestamp']);
        print("User has an active code: " + timestamp.toString());

        DateTime now = new DateTime.now();
        DateTime convertedTimestamp =
            new DateTime.fromMillisecondsSinceEpoch(timestamp);
        Duration difference = now.difference(convertedTimestamp);
        print("User has an active code: " + difference.inMinutes.toString());
        if (double.parse(difference.inMinutes.toString()) / 60.0 >=
            infoDoc['Length']) {
          print("User has an active code that is expired.");
          firestore.runTransaction((Transaction myTransaction) async {
            myTransaction.update(user.reference, {'currentParent': ""});
            myTransaction.update(user.reference, {'currentCodeType': -1});
            myTransaction.update(user.reference, {'timestamp': ""});
            myTransaction.update(user.reference, {'enteredCode': ""});
          });
          MapsHelper.removeCodeMaterials();
        } else {
          CodeType type = convertIndexToCodeType(user['currentCodeType']);

          MapsHelper.gatherCodeMaterials(
              codeSnapshot, type, user['enteredCode']);
          const oneMin = const Duration(minutes: 1);
          // codeTimer is in Constants.dart
          if (codeTimer != null && codeTimer.isActive) codeTimer.cancel();
          codeTimer = new Timer.periodic(oneMin,
              (Timer t) => testCodeLinkedToAccount(codeSnapshot, userId, type));
        }
      }
    } else {
      print("User has not activated a code.");
    }

    return true;
  }

  // auth change user stream
  // set up a stream so that every time someone signs in/out, we get a response
  // down the stream
  Stream<basic.User> get user {
    return _auth
        .authStateChanges()
        .map(_userFromFirebaseUser); // same as line above
  }

  Future<fba.User> getUser() async {
    return await _auth.currentUser;
  }

  // sign in with email & password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      fba.UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      fba.User user = result.user;

      if (user != null && user.emailVerified) {
        QuerySnapshot snapshot = await DatabaseService()
            .userCollection
            .where('email', isEqualTo: user.email)
            .get();

        snapshot.docs.forEach((element) {
          PreferencesHelper()
              .setFirstName(element['firstName'])
              .whenComplete(() => print("first name set"));
        });

        PreferencesHelper().setUid(user.uid);
        PreferencesHelper().setFinishedTutorial(false);
      } else {
        print("User is null or not verified");
      }

      // Provide the ability to resend the email
      // AKA return the user as well as whether or not they're verified
      // There's probably a better way to do this
      return [_userFromFirebaseUser(user), user.emailVerified];
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future signInWithApple() async {
    final AuthorizationResult result = await AppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);

    switch (result.status) {
      case AuthorizationStatus.authorized:
        final appleIdCredential = result.credential;
        final oAuthProvider = fba.OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
            idToken: String.fromCharCodes(appleIdCredential.identityToken),
            accessToken:
                String.fromCharCodes(appleIdCredential.authorizationCode));
        final authResult = await _auth.signInWithCredential(credential);
        final user = authResult.user;

        // These two strings are just for null safety w/ names
        String realFirstName = '';
        if (result.credential.fullName.givenName == null) {
          realFirstName = 'Wumbo';
        } else {
          realFirstName = result.credential.fullName.givenName;
        }

        // create a new database document for the user with their uid
        await DatabaseService(uid: user.uid).updateUserData(
          result.credential.email,
          realFirstName,
        );

        PreferencesHelper().setFirstName(result.credential.fullName.givenName);
        PreferencesHelper().setUid(user.uid);
        PreferencesHelper().setFinishedTutorial(false);

        return _userFromFirebaseUser(user);

      case AuthorizationStatus.error:
        print(result.error.toString());
        return null;

      case AuthorizationStatus.cancelled:
        print('ERROR_APPLE_SIGNIN_ABORTED_BY_USER: Sign in aborted by user');
        return null;
    }

    return;
  }

  // register with email & password
  // If registration is successful, the user will be redirected to the login page
  // They cannot log in unless they verify.
  // The user gets logged out under register.dart after running this function
  Future<String> registerWithEmailAndPasswordBusiness(String email,
      String password, String firstName, BusinessInformation bInfo) async {
    try {
      fba.UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      fba.User user = result.user;

      // create a new database document for the user with the uid
      await DatabaseService(uid: user.uid).updateUserDataBusiness(
        email,
        firstName,
        bInfo,
      );

      if (user != null) {
        // create a new database document for the user with the uid
        await DatabaseService(uid: user.uid).createBusinessPin(
          user.uid,
          bInfo,
        );

        // Send email verificaton
        try {
          await user.sendEmailVerification();
        } catch (e) {
          print("An error occured while trying to send email verification");
          print(e.toString());
        }
      }

      await _userFromFirebaseUser(user);

      return "";
    } on fba.FirebaseAuthException catch (fba) {
      switch (fba.code) {
        case "email-already-in-use":
          return "Email Already In Use";
          break;
        case "invalid-email":
          return "Invalid Email";
          break;
        case "operation-not-allowed":
          return "operation-not-allowed";
          break;
        case "weak-password":
          return "Weak Password";
          break;
      }
    } catch (general) {
      // Some type of our error.
      return "Writing to Database Error";
    }

    return "Try-Catch Error";
  }

  // register with email & password
  // If registration is successful, the user will be redirected to the login page
  // They cannot log in unless they verify.
  // The user gets logged out under register.dart after running this function
  Future<String> registerWithEmailAndPassword(
      String email, String password, String firstName) async {
    try {
      fba.UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      fba.User user = result.user;

      // create a new database document for the user with the uid
      await DatabaseService(uid: user.uid).updateUserData(
        email,
        firstName,
      );

      if (user != null) {
        // Send email verificaton
        try {
          await user.sendEmailVerification();
        } catch (e) {
          print("An error occured while trying to send email verification");
          print(e.toString());
        }
      }

      await _userFromFirebaseUser(user);

      return "";
    } on fba.FirebaseAuthException catch (fba) {
      switch (fba.code) {
        case "email-already-in-use":
          return "Email Already In Use";
          break;
        case "invalid-email":
          return "Invalid Email";
          break;
        case "operation-not-allowed":
          return "operation-not-allowed";
          break;
        case "weak-password":
          return "Weak Password";
          break;
      }
    } catch (general) {
      // Some type of our error.
      return "Writing to Database Error";
    }

    return "Try-Catch Error";
  }

// sign out
  Future signOut() async {
    // MapsPage.cancelRepeatingPositionTimer(); // TODO:
    // if (codeTimer != null && codeTimer.isActive) codeTimer.cancel(); // TODO:
    // MapsHelper.removeCodeMaterials(); // TODO:
    try {
      // Empty all data in preferences_helper before logout
      PreferencesHelper().setFirstName("");
      PreferencesHelper().setUid("");
      PreferencesHelper().setBlockedUsers(List.empty());
      PreferencesHelper().setFinishedTutorial(false);
      await _auth.signOut();
    } catch (e) {
      return null;
    }
  }
}
