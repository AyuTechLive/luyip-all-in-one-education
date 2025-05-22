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
    String? franchiseName,
    double? franchiseCommission,
  }) async {
    Map<String, dynamic> courseData = {
      'courseName': courseName,
      'enrollmentDate': DateTime.now(),
    };

    // Add franchise data if applicable
    if (franchiseName != null) {
      courseData['franchiseName'] = franchiseName;
      courseData['addedByFranchise'] = true;
      if (franchiseCommission != null) {
        courseData['franchiseCommission'] = franchiseCommission;
      }
    }

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
    String? franchiseName,
    double? franchiseCommission,
  }) async {
    Map<String, dynamic> membershipData = {
      'membershipId': membershipId,
      'startDate': startDate,
      'expiryDate': expiryDate,
    };

    // Add franchise data if applicable
    if (franchiseName != null) {
      membershipData['franchiseName'] = franchiseName;
      membershipData['addedByFranchise'] = true;
      if (franchiseCommission != null) {
        membershipData['franchiseCommission'] = franchiseCommission;
      }
    }

    await _recordTransaction(
      transactionId: transactionId,
      amount: amount,
      currency: currency,
      type: 'membership', // Identify as membership transaction
      additionalData: membershipData,
    );
  }

  // Record franchise commission
  Future<void> recordFranchiseCommission({
    required String transactionId,
    required String franchiseName,
    required double commissionAmount,
    required double originalAmount,
    required double commissionPercentage,
    required String studentEmail,
    required String type, // 'membership' or 'course'
    String? courseName,
  }) async {
    try {
      Map<String, dynamic> commissionData = {
        'transactionId': transactionId,
        'franchiseName': franchiseName,
        'commissionAmount': commissionAmount,
        'originalAmount': originalAmount,
        'commissionPercentage': commissionPercentage,
        'studentEmail': studentEmail,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'earned',
      };

      if (courseName != null) {
        commissionData['courseName'] = courseName;
      }

      await _firestore
          .collection('FranchiseCommissions')
          .doc(transactionId)
          .set(commissionData);
    } catch (e) {
      throw Exception('Failed to record franchise commission: $e');
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

  // Complete course enrollment process after payment
  Future<void> completeEnrollment({
    required String transactionId,
    required double amount,
    required String courseName,
    required String currency,
    String? franchiseName,
    double? franchiseCommission,
  }) async {
    try {
      // Record the transaction first
      await recordCourseTransaction(
        transactionId: transactionId,
        amount: amount,
        courseName: courseName,
        currency: currency,
        franchiseName: franchiseName,
        franchiseCommission: franchiseCommission,
      );

      // Then enroll the user
      await enrollUserInCourse(courseName);

      // Record franchise commission if applicable
      if (franchiseName != null && franchiseCommission != null) {
        await recordFranchiseCommission(
          transactionId: transactionId,
          franchiseName: franchiseName,
          commissionAmount: franchiseCommission,
          originalAmount: amount + franchiseCommission,
          commissionPercentage:
              (franchiseCommission / (amount + franchiseCommission)) * 100,
          studentEmail: _auth.currentUser!.email!,
          type: 'course',
          courseName: courseName,
        );
      }

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
    String? franchiseName,
    double? franchiseCommission,
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
        franchiseName: franchiseName,
        franchiseCommission: franchiseCommission,
      );

      // Update user document with membership info
      Map<String, dynamic> membershipData = {
        'isActive': true,
        'startDate': startDate,
        'expiryDate': expiryDate,
        'membershipId': membershipId,
        'transactionId': transactionId,
      };

      // Add franchise info if applicable
      if (franchiseName != null) {
        membershipData['addedByFranchise'] = true;
        membershipData['franchiseName'] = franchiseName;
      }

      await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(currentUser.email)
          .update({
        'membership': membershipData,
      });

      // Record franchise commission if applicable
      if (franchiseName != null && franchiseCommission != null) {
        await recordFranchiseCommission(
          transactionId: transactionId,
          franchiseName: franchiseName,
          commissionAmount: franchiseCommission,
          originalAmount: amount + franchiseCommission,
          commissionPercentage:
              (franchiseCommission / (amount + franchiseCommission)) * 100,
          studentEmail: currentUser.email!,
          type: 'membership',
        );
      }

      return true;
    } catch (e) {
      print("Error activating membership: $e");
      return false;
    }
  }

  // Activate membership for franchise student (no payment required)
  Future<bool> activateFranchiseMembership({
    required String studentEmail,
    required String transactionId,
    required String franchiseName,
    required double membershipFee,
    required double franchiseCommission,
  }) async {
    try {
      // Create membership start and expiry dates
      DateTime startDate = DateTime.now();
      DateTime expiryDate = startDate.add(const Duration(days: 365));

      // Generate membership ID
      String membershipId =
          'MEM-${startDate.day}${startDate.month}${startDate.year}-FRANCHISE';

      // Calculate net amount (membership fee - commission)
      double netAmount = membershipFee - franchiseCommission;

      // Record membership transaction
      await recordMembershipTransaction(
        transactionId: transactionId,
        amount: netAmount,
        currency: 'INR',
        membershipId: membershipId,
        startDate: startDate,
        expiryDate: expiryDate,
        franchiseName: franchiseName,
        franchiseCommission: franchiseCommission,
      );

      // Update student document with membership info
      await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(studentEmail)
          .update({
        'membership': {
          'isActive': true,
          'startDate': startDate,
          'expiryDate': expiryDate,
          'membershipId': membershipId,
          'transactionId': transactionId,
          'addedByFranchise': true,
          'franchiseName': franchiseName,
        }
      });

      // Record franchise commission
      await recordFranchiseCommission(
        transactionId: transactionId,
        franchiseName: franchiseName,
        commissionAmount: franchiseCommission,
        originalAmount: membershipFee,
        commissionPercentage: (franchiseCommission / membershipFee) * 100,
        studentEmail: studentEmail,
        type: 'membership',
      );

      return true;
    } catch (e) {
      print("Error activating franchise membership: $e");
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

  // Get franchise commissions
  Future<List<Map<String, dynamic>>> getFranchiseCommissions(
      String franchiseName) async {
    try {
      final querySnapshot = await _firestore
          .collection('FranchiseCommissions')
          .where('franchiseName', isEqualTo: franchiseName)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch franchise commissions: $e');
    }
  }

  // Get franchise commission summary
  Future<Map<String, dynamic>> getFranchiseCommissionSummary(
      String franchiseName) async {
    try {
      final querySnapshot = await _firestore
          .collection('FranchiseCommissions')
          .where('franchiseName', isEqualTo: franchiseName)
          .where('status', isEqualTo: 'earned')
          .get();

      double totalCommission = 0;
      int membershipCommissions = 0;
      int courseCommissions = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalCommission += (data['commissionAmount'] as num).toDouble();

        if (data['type'] == 'membership') {
          membershipCommissions++;
        } else if (data['type'] == 'course') {
          courseCommissions++;
        }
      }

      return {
        'totalCommission': totalCommission,
        'totalTransactions': querySnapshot.docs.length,
        'membershipCommissions': membershipCommissions,
        'courseCommissions': courseCommissions,
      };
    } catch (e) {
      throw Exception('Failed to fetch commission summary: $e');
    }
  }

  // Update franchise revenue data
  Future<void> updateFranchiseRevenue({
    required String franchiseEmail,
    required String transactionId,
    required double commissionAmount,
    required String studentEmail,
    required String studentName,
    required String type,
  }) async {
    try {
      DocumentReference franchiseRef = _firestore
          .collection('Users')
          .doc('franchise')
          .collection('accounts')
          .doc(franchiseEmail);

      DocumentSnapshot franchiseDoc = await franchiseRef.get();

      if (franchiseDoc.exists) {
        Map<String, dynamic> franchiseData =
            franchiseDoc.data() as Map<String, dynamic>;

        // Get current revenue data or initialize
        Map<String, dynamic> revenueData =
            franchiseData['revenue'] as Map<String, dynamic>? ?? {};

        // Calculate new totals
        double currentTotalRevenue =
            (revenueData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        int currentTotalStudents =
            (revenueData['totalStudentsAdded'] as int?) ?? 0;
        List<dynamic> currentTransactions =
            revenueData['recentTransactions'] as List? ?? [];

        // Update totals
        double newTotalRevenue = currentTotalRevenue + commissionAmount;
        int newTotalStudents =
            currentTotalStudents + (type == 'membership' ? 1 : 0);

        // Add new transaction to recent transactions (keep last 15)
        Map<String, dynamic> newTransaction = {
          'transactionId': transactionId,
          'amount': commissionAmount,
          'type': '${type}_commission',
          'studentEmail': studentEmail,
          'studentName': studentName,
          'date': FieldValue.serverTimestamp(),
        };

        currentTransactions.insert(0, newTransaction);
        if (currentTransactions.length > 15) {
          currentTransactions = currentTransactions.take(15).toList();
        }

        // Get current month/year for monthly tracking
        DateTime now = DateTime.now();
        String monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

        Map<String, dynamic> monthlyRevenue =
            revenueData['monthlyRevenue'] as Map<String, dynamic>? ?? {};
        double currentMonthRevenue =
            (monthlyRevenue[monthKey] as num?)?.toDouble() ?? 0.0;
        monthlyRevenue[monthKey] = currentMonthRevenue + commissionAmount;

        // Update franchise document with new revenue data
        await franchiseRef.update({
          'revenue': {
            'totalRevenue': newTotalRevenue,
            'totalStudentsAdded': newTotalStudents,
            'recentTransactions': currentTransactions,
            'monthlyRevenue': monthlyRevenue,
            'lastUpdated': FieldValue.serverTimestamp(),
            'currency': 'INR',
            'averageCommissionPerStudent':
                newTotalStudents > 0 ? newTotalRevenue / newTotalStudents : 0,
          }
        });
      }
    } catch (e) {
      throw Exception('Failed to update franchise revenue: $e');
    }
  }
}
