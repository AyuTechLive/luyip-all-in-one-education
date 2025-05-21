import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Record a generic transaction (base method)
  Future<void> _recordTransaction({
    required String transactionId,
    required double amount,
    required String currency,
    required String type, // 'course' or 'membership'
    required Map<String, dynamic> additionalData,
    String status = 'completed',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Base transaction data
      Map<String, dynamic> transactionData = {
        'transactionId': transactionId,
        'userId': user.uid,
        'userEmail': user.email,
        'amount': amount,
        'currency': currency,
        'timestamp': FieldValue.serverTimestamp(),
        'status': status,
        'type': type, // Transaction type identifier
      };

      // Add additional data specific to the transaction type
      transactionData.addAll(additionalData);

      // Create transaction document
      await _firestore
          .collection('Transactions')
          .doc(transactionId)
          .set(transactionData);
    } catch (e) {
      throw Exception('Failed to record transaction: $e');
    }
  }

  // Record a course purchase transaction
  Future<void> recordCourseTransaction({
    required String transactionId,
    required double amount,
    required String courseName,
    required String currency,
  }) async {
    Map<String, dynamic> courseData = {
      'courseName': courseName,
      'enrollmentDate': DateTime.now(),
    };

    await _recordTransaction(
      transactionId: transactionId,
      amount: amount,
      currency: currency,
      type: 'course', // Identify as course transaction
      additionalData: courseData,
    );
  }

  // Record a membership transaction
  Future<void> recordMembershipTransaction({
    required String transactionId,
    required double amount,
    required String currency,
    required String membershipId,
    required DateTime startDate,
    required DateTime expiryDate,
  }) async {
    Map<String, dynamic> membershipData = {
      'membershipId': membershipId,
      'startDate': startDate,
      'expiryDate': expiryDate,
    };

    await _recordTransaction(
      transactionId: transactionId,
      amount: amount,
      currency: currency,
      type: 'membership', // Identify as membership transaction
      additionalData: membershipData,
    );
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

  // Complete course enrollment process after payment
  Future<void> completeEnrollment({
    required String transactionId,
    required double amount,
    required String courseName,
    required String currency,
  }) async {
    try {
      // Record the transaction first
      await recordCourseTransaction(
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

  // Activate membership after successful payment
  Future<bool> activateMembership({
    required String transactionId,
    required double amount,
    required String currency,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Create membership start and expiry dates
      DateTime startDate = DateTime.now();
      DateTime expiryDate = startDate.add(const Duration(days: 365));

      // Generate membership ID
      String membershipId =
          'MEM-${startDate.day}${startDate.month}${startDate.year}-${currentUser.uid.substring(0, 4)}';

      // Record membership transaction
      await recordMembershipTransaction(
        transactionId: transactionId,
        amount: amount,
        currency: currency,
        membershipId: membershipId,
        startDate: startDate,
        expiryDate: expiryDate,
      );

      // Update user document with membership info
      await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(currentUser.email)
          .update({
        'membership': {
          'isActive': true,
          'startDate': startDate,
          'expiryDate': expiryDate,
          'membershipId': membershipId,
          'transactionId': transactionId,
        }
      });

      return true;
    } catch (e) {
      print("Error activating membership: $e");
      return false;
    }
  }

  // Get all transactions for current user
  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      final querySnapshot = await _firestore
          .collection('Transactions')
          .where('userEmail', isEqualTo: user.email)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  // Get transactions by type for current user (course or membership)
  Future<List<Map<String, dynamic>>> getUserTransactionsByType(
      String type) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      final querySnapshot = await _firestore
          .collection('Transactions')
          .where('userEmail', isEqualTo: user.email)
          .where('type', isEqualTo: type)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }
}
