import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/membership/membership_service.dart';

class CourseMembershipHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MembershipService _membershipService = MembershipService();

  Future<Map<String, dynamic>> checkMembershipStatus(String courseName) async {
    try {
      // Get membership status
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
}
