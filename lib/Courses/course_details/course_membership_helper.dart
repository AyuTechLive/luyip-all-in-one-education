import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:luyip_website_edu/membership/membership_service.dart';

class CourseMembershipHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MembershipService _membershipService = MembershipService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> checkMembershipStatus(String courseName) async {
    try {
      // Check if user is franchise - they get free access to all courses
      String? userRole = await _getCurrentUserRole();
      if (userRole == 'franchise') {
        return {
          'isMember': true, // Treat franchise as member for access purposes
          'discountPercentage': 100.0, // 100% discount (free access)
          'originalPrice': 0.0,
          'discountedPrice': 0.0,
        };
      }

      // Get membership status for other users
      final membershipStatus = await _membershipService.getMembershipStatus();
      bool isMember = membershipStatus['isMember'] ?? false;

      // Get course info to check discount percentage
      final courseDoc =
          await _firestore.collection('All Courses').doc(courseName).get();

      if (!courseDoc.exists) {
        return {
          'isMember': isMember,
          'discountPercentage': 0.0,
          'originalPrice': 0.0,
          'discountedPrice': 0.0,
        };
      }

      // Get course price and discount
      Map<String, dynamic> courseData =
          courseDoc.data() as Map<String, dynamic>;
      String priceStr = courseData['Course Price'] ?? '0';

      // Remove currency symbol and convert to double
      double originalPrice =
          double.tryParse(priceStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

      // Get membership discount percentage
      String discountStr = courseData['Membership Discount'] ?? '0';
      double discountPercentage = double.tryParse(discountStr) ?? 0.0;

      // Calculate discounted price if member
      double discountedPrice = originalPrice;
      if (isMember && discountPercentage > 0) {
        double discountAmount = originalPrice * (discountPercentage / 100);
        discountedPrice = originalPrice - discountAmount;
      }

      return {
        'isMember': isMember,
        'discountPercentage': discountPercentage,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
      };
    } catch (e) {
      print("Error checking membership status: $e");
      return {
        'isMember': false,
        'discountPercentage': 0.0,
        'originalPrice': 0.0,
        'discountedPrice': 0.0,
      };
    }
  }

  Future<String?> _getCurrentUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Check in different user role collections
      final userTypes = ['student', 'teacher', 'admin', 'franchise'];

      for (String userType in userTypes) {
        final userDoc = await _firestore
            .collection('Users')
            .doc(userType)
            .collection('accounts')
            .doc(user.email)
            .get();

        if (userDoc.exists) {
          return userType;
        }
      }

      return null;
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }
}
