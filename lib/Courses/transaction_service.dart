import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Record successful transaction in Firestore
  Future<void> recordTransaction({
    required String transactionId,
    required double amount,
    required String courseName,
    required String currency,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Create transaction document
      await _firestore.collection('Transactions').doc(transactionId).set({
        'transactionId': transactionId,
        'userId': user.uid,
        'userEmail': user.email,
        'amount': amount,
        'currency': currency,
        'courseName': courseName,
        'date': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    } catch (e) {
      throw Exception('Failed to record transaction: $e');
    }
  }

  // Enroll user in course after successful payment
  Future<void> enrollUserInCourse(String courseName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(user.email)
          .update({
            'My Courses': FieldValue.arrayUnion([courseName]),
          });
    } catch (e) {
      throw Exception('Failed to enroll user in course: $e');
    }
  }

  // Complete enrollment process after payment
  Future<void> completeEnrollment({
    required String transactionId,
    required double amount,
    required String courseName,
    required String currency,
  }) async {
    try {
      // Record the transaction first
      await recordTransaction(
        transactionId: transactionId,
        amount: amount,
        courseName: courseName,
        currency: currency,
      );

      // Then enroll the user
      await enrollUserInCourse(courseName);

      return;
    } catch (e) {
      throw Exception('Enrollment process failed: $e');
    }
  }
}
