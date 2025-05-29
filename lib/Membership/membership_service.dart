import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_web/razorpay_web.dart';
// Import the unified transaction service
import 'package:luyip_website_edu/Courses/transaction_service.dart'; // Update path if needed

class MembershipService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService =
      TransactionService(); // Add this
  Future<double> getMembershipFee() async {
    try {
      final doc =
          await _firestore.collection('website_general').doc('dashboard').get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final websiteContent = data['websiteContent'] as Map<String, dynamic>?;

        if (websiteContent != null &&
            websiteContent.containsKey('membershipFee')) {
          return (websiteContent['membershipFee'] as num?)?.toDouble() ??
              1000.0;
        }
      }
      return 1000.0; // Default fallback
    } catch (e) {
      print('Error fetching membership fee: $e');
      return 1000.0; // Default fallback
    }
  }

  // Get current user's membership status
  Future<Map<String, dynamic>> getMembershipStatus() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Fetch user document
      DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(currentUser.email)
          .get();

      if (!userDoc.exists) {
        return {
          'isMember': false,
          'expiryDate': null,
          'membershipId': null,
        };
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Check if user has membership data
      if (!userData.containsKey('membership') ||
          userData['membership'] == null) {
        return {
          'isMember': false,
          'expiryDate': null,
          'membershipId': null,
        };
      }

      Map<String, dynamic> membershipData = userData['membership'];
      bool isActive = membershipData['isActive'] ?? false;

      // Check if membership is expired
      DateTime? expiryDate;
      if (membershipData.containsKey('expiryDate') &&
          membershipData['expiryDate'] != null) {
        expiryDate = (membershipData['expiryDate'] as Timestamp).toDate();

        // If expired, update the status in Firestore
        if (expiryDate.isBefore(DateTime.now()) && isActive) {
          await _firestore
              .collection('Users')
              .doc('student')
              .collection('accounts')
              .doc(currentUser.email)
              .update({
            'membership.isActive': false,
          });
          isActive = false;
        }
      }

      return {
        'isMember': isActive,
        'expiryDate': expiryDate,
        'membershipId': membershipData['membershipId'],
        'startDate': membershipData.containsKey('startDate')
            ? (membershipData['startDate'] as Timestamp).toDate()
            : null,
      };
    } catch (e) {
      print("Error getting membership status: $e");
      return {
        'isMember': false,
        'expiryDate': null,
        'membershipId': null,
        'error': e.toString(),
      };
    }
  }

  // Purchase a new membership
  Future<bool> purchaseMembership(
    BuildContext context, {
    required Function(PaymentSuccessResponse) onPaymentSuccess,
    required Function(PaymentFailureResponse) onPaymentError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Get dynamic membership fee
      double membershipFee = await getMembershipFee();

      Razorpay razorpay = Razorpay();
      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onPaymentSuccess);
      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onPaymentError);
      razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);

      var options = {
        'key': 'rzp_test_OIvgwDrw6v8gWS',
        'amount': (membershipFee * 100).toInt(), // Convert to paise
        'name': 'LuYip Education',
        'description': 'Yearly Membership',
        'prefill': {'email': currentUser.email ?? ''},
        'external': {
          'wallets': ['paytm'],
        },
      };

      razorpay.open(options);
      return true;
    } catch (e) {
      print("Error purchasing membership: $e");
      return false;
    }
  }

  // Activate membership after successful payment - DEPRECATED
  // This method is kept for backward compatibility but delegates to the TransactionService
  Future<bool> activateMembership(String transactionId) async {
    try {
      double membershipFee = await getMembershipFee();

      return await _transactionService.activateMembership(
        transactionId: transactionId,
        amount: membershipFee, // Use dynamic fee
        currency: 'INR',
      );
    } catch (e) {
      print("Error activating membership: $e");
      return false;
    }
  }

  // Calculate discounted price based on membership status
  Future<double> calculateDiscountedPrice(
      String courseName, double originalPrice) async {
    try {
      // First check if user is a member
      Map<String, dynamic> membershipStatus = await getMembershipStatus();
      if (!membershipStatus['isMember']) {
        return originalPrice;
      }

      // Fetch course discount percentage
      DocumentSnapshot courseDoc =
          await _firestore.collection('All Courses').doc(courseName).get();

      if (!courseDoc.exists) {
        return originalPrice;
      }

      Map<String, dynamic> courseData =
          courseDoc.data() as Map<String, dynamic>;

      // Get membership discount percentage
      String discountStr = courseData['Membership Discount'] ?? '0';
      double discountPercentage = double.tryParse(discountStr) ?? 0.0;

      if (discountPercentage <= 0) {
        return originalPrice;
      }

      // Calculate discounted price
      double discountAmount = originalPrice * (discountPercentage / 100);
      return originalPrice - discountAmount;
    } catch (e) {
      print("Error calculating discounted price: $e");
      return originalPrice;
    }
  }

  // Cancel membership (for admin use or testing)
  Future<bool> cancelMembership() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(currentUser.email)
          .update({
        'membership.isActive': false,
      });

      return true;
    } catch (e) {
      print("Error canceling membership: $e");
      return false;
    }
  }
}
