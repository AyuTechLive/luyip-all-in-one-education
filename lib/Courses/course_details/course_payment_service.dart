import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_web/razorpay_web.dart';
import 'package:luyip_website_edu/Courses/transaction_service.dart';

class CoursePaymentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();
  late Razorpay _razorpay;

  final BuildContext context;
  final Function(bool) onEnrollmentStatusChanged;
  final Function(bool) onProcessingStatusChanged;

  CoursePaymentService({
    required this.context,
    required this.onEnrollmentStatusChanged,
    required this.onProcessingStatusChanged,
  });

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<bool> checkEnrollmentStatus(String courseName) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(user.email)
          .get();
      if (userDoc.exists) {
        final myCourses = userDoc.data()?['My Courses'] as List<dynamic>? ?? [];
        return myCourses.contains(courseName);
      }
    }
    return false;
  }

  Future<void> handleEnrollment(String courseName, double price, bool isMember,
      double discountedPrice) async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to enroll'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (price <= 0) {
      // If course is free, directly enroll without payment
      try {
        await _transactionService.enrollUserInCourse(courseName);
        onEnrollmentStatusChanged(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully enrolled in $courseName'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enroll: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // If course has a price, start payment flow with appropriate price
      double finalPrice = isMember ? discountedPrice : price;
      startPayment(finalPrice, courseName);
    }
  }

  void startPayment(double amount, String courseName) async {
    onProcessingStatusChanged(true);

    try {
      var options = {
        'key':
            'rzp_test_OIvgwDrw6v8gWS', // Replace with your actual Razorpay key
        'amount':
            (amount * 100).toInt(), // Amount in smallest currency unit (paise)
        'name': 'LuYip Education',
        'description': 'Enrollment for $courseName',
        'prefill': {'email': _auth.currentUser?.email ?? ''},
        'external': {
          'wallets': ['paytm'],
        },
      };

      _razorpay.open(options);
    } catch (e) {
      onProcessingStatusChanged(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    onProcessingStatusChanged(false);

    try {
      String courseName = response.orderId ?? "";
      double amount =
          double.tryParse(response.data?['amount'].toString() ?? "0") ?? 0;
      amount = amount / 100; // Convert from paise to rupees

      // Use the transaction service method
      await _transactionService.completeEnrollment(
        transactionId: response.paymentId!,
        amount: amount,
        courseName: courseName,
        currency: 'INR',
      );

      onEnrollmentStatusChanged(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment successful! You are now enrolled in $courseName',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing enrollment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onProcessingStatusChanged(false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onProcessingStatusChanged(false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
