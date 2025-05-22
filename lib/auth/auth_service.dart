import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:luyip_website_edu/auth/loginscreen.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:luyip_website_edu/main.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Logout functionality
  Future<void> logout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Sign out from Firebase Auth
      await _auth.signOut();

      // Clear any stored user data in SharedPreferences

      // Navigate to login screen and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const EducationApp()),
          (route) => false,
        );
      }

      Utils().toastMessage('Logged out successfully');
    } catch (e) {
      // Close loading dialog if error occurs
      if (context.mounted) {
        Navigator.of(context).pop();
        Utils().toastMessage('Error during logout: ${e.toString()}');
      }
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
