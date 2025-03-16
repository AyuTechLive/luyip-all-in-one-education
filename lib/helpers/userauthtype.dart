import 'package:firebase_auth/firebase_auth.dart';

String checkUserAuthenticationType() {
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;

  if (user != null) {
    bool hasEmail = user.email?.isNotEmpty ?? false;
    bool hasPhone = user.phoneNumber?.isNotEmpty ?? false;

    if (hasEmail && !hasPhone) {
      return user.email!;
      // User is logged in with email
    } else if (hasPhone && !hasEmail) {
      return user.phoneNumber!;
      // User is logged in with phone number
    }
  }
  return 'Null';
}
