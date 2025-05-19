import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:luyip_website_edu/certificate/certificate_generator.dart';
import 'package:luyip_website_edu/certificate/certificate_model.dart';
// Import the fixed certificate generator
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mark a course as complete for a student
  Future<bool> markCourseAsComplete({
    required String userId,
    required String userEmail,
    required String courseName,
    required String completedBy,
  }) async {
    try {
      // First, check if all tests or 80% of tests are passed
      final testResults = await _getTestResults(userId, courseName);
      final testPassPercentage = _calculateTestPassPercentage(testResults);

      print('Test pass percentage: $testPassPercentage'); // Debug log

      // Create course completion record
      final courseCompletion = CourseCompletion(
        userId: userId,
        courseName: courseName,
        isCompleted: true,
        completedDate: DateTime.now(),
        completedBy: completedBy,
        passedTestIds: testResults['passedTests'] ?? [],
        testPassPercentage: testPassPercentage,
        certificateIssued: false, // Will be updated if certificate is issued
      );

      // Save to Firestore
      await _firestore
          .collection('CourseCompletions')
          .doc('${userId}_${courseName}')
          .set(courseCompletion.toMap());

      // Update user's course status
      await _firestore
          .collection('Users')
          .doc(userEmail.split('@')[0])
          .collection('accounts')
          .doc(userEmail)
          .update({
        courseName: [2], // Assuming 2 is the status code for completed courses
      });

      // If test pass percentage is >= 80%, auto-generate certificate
      if (testPassPercentage >= 80.0) {
        print(
            'Generating certificate for user: $userId, course: $courseName'); // Debug log
        final certificate = await generateCertificate(
          userId: userId,
          userEmail: userEmail,
          courseName: courseName,
          percentageScore: testPassPercentage,
        );

        return certificate != null;
      }

      return true;
    } catch (e) {
      print('Error marking course as complete: $e');
      return false;
    }
  }

  // Calculate what percentage of tests were passed
  double _calculateTestPassPercentage(Map<String, dynamic> testResults) {
    final List<String> passedTests = testResults['passedTests'] as List<String>;
    final int totalTests = testResults['totalTests'] as int;

    if (totalTests == 0) return 0.0;
    return (passedTests.length / totalTests) * 100;
  }

  // Get test results for a user in a course
  Future<Map<String, dynamic>> _getTestResults(
      String userId, String courseName) async {
    try {
      List<String> passedTests = [];
      List<String> allTests = [];

      // Fetch all tests for the course
      final testSnapshot =
          await _database.ref(courseName).child('SUBJECTS').once();

      if (testSnapshot.snapshot.value != null) {
        final subjects = testSnapshot.snapshot.value as Map<dynamic, dynamic>;

        // For each subject, get all tests
        for (var subject in subjects.values) {
          if (subject is Map && subject.containsKey('Tests')) {
            final tests = subject['Tests'] as Map<dynamic, dynamic>;

            // Add all test IDs to allTests
            allTests.addAll(tests.keys.map((k) => k.toString()).toList());

            // For each test, check if user passed
            for (var testId in tests.keys) {
              // Check if user took this test
              final userTestSnapshot = await _database
                  .ref('UserTestResults')
                  .child(userId)
                  .child(testId.toString())
                  .once();

              if (userTestSnapshot.snapshot.value != null) {
                final testData =
                    userTestSnapshot.snapshot.value as Map<dynamic, dynamic>;

                // Check if user passed (assuming 70% is passing grade)
                final totalMarks = testData['totalMarks'] ?? 0;
                final userMarks =
                    testData['manualMarks'] ?? testData['autoMarks'] ?? 0;

                if (totalMarks > 0 && (userMarks / totalMarks) >= 0.7) {
                  passedTests.add(testId.toString());
                }
              }
            }
          }
        }
      }

      print(
          'Passed tests: ${passedTests.length}, Total tests: ${allTests.length}'); // Debug log

      return {
        'passedTests': passedTests,
        'totalTests': allTests.length,
      };
    } catch (e) {
      print('Error getting test results: $e');
      return {
        'passedTests': <String>[],
        'totalTests': 0,
      };
    }
  }

  // Generate a certificate for a student
  Future<Certificate?> generateCertificate({
    required String userId,
    required String userEmail,
    required String courseName,
    required double percentageScore,
  }) async {
    try {
      print('Starting certificate generation process...'); // Debug log

      // Get user information
      final userDoc = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(userEmail)
          .get();

      if (!userDoc.exists) {
        print('User document not found for email: $userEmail'); // Debug log

        // Try to find user with alternative query if the standard path fails
        final userQuerySnapshot = await _firestore
            .collection('Users')
            .where('Email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (userQuerySnapshot.docs.isEmpty) {
          throw Exception('User not found');
        }

        // Use the first document found
        final userData = userQuerySnapshot.docs.first.data();
        final userName = userData['Name'] ?? 'Student';

        print('Found user via query: $userName'); // Debug log

        // Continue with certificate generation using this user data
        return await _generateCertificateWithUserName(
          userId: userId,
          userEmail: userEmail,
          userName: userName,
          courseName: courseName,
          percentageScore: percentageScore,
        );
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['Name'] ?? 'Student';

      return await _generateCertificateWithUserName(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        courseName: courseName,
        percentageScore: percentageScore,
      );
    } catch (e) {
      print('Error generating certificate: $e');
      return null;
    }
  }

  // Helper method to generate certificate once user name is determined
  Future<Certificate?> _generateCertificateWithUserName({
    required String userId,
    required String userEmail,
    required String userName,
    required String courseName,
    required double percentageScore,
  }) async {
    try {
      // Generate unique certificate number
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final certificateNumber =
          'CERT-${courseName.substring(0, 3).toUpperCase()}-$userId-$timestamp';

      print('Generated certificate number: $certificateNumber'); // Debug log

      // Generate actual certificate PDF using our improved certificate generator
      final certificateBytes =
          await CertificateGenerator.generateCertificatePdf(
        studentName: userName,
        courseName: courseName,
        certificateNumber: certificateNumber,
        issuerName: _auth.currentUser?.displayName ?? 'Course Instructor',
        issueDate: DateTime.now(),
        percentageScore: percentageScore,
      );

      // Upload the certificate to Firebase Storage
      final certificateUrl = await CertificateGenerator.uploadCertificate(
        certificateNumber: certificateNumber,
        pdfBytes: certificateBytes,
      );

      print('Uploaded certificate to: $certificateUrl'); // Debug log

      // Create certificate record
      final certificate = Certificate(
        id: certificateNumber,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        courseName: courseName,
        certificateNumber: certificateNumber,
        issueDate: DateTime.now(),
        issuedBy: _auth.currentUser?.email ?? 'System',
        percentageScore: percentageScore,
        certificateUrl: certificateUrl,
        status: 'issued',
      );

      // Save to Firestore
      await _firestore
          .collection('Certificates')
          .doc(certificateNumber)
          .set(certificate.toMap());

      print('Saved certificate to Firestore'); // Debug log

      // Update course completion record
      await _firestore
          .collection('CourseCompletions')
          .doc('${userId}_${courseName}')
          .update({
        'certificateIssued': true,
        'certificateId': certificateNumber,
      });

      print('Updated course completion record'); // Debug log

      // Add certificate to user's profile
      await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(userEmail)
          .update({
        'Certificates': FieldValue.arrayUnion([certificateNumber]),
      });

      print('Added certificate to user profile'); // Debug log

      return certificate;
    } catch (e) {
      print('Error in _generateCertificateWithUserName: $e');
      return null;
    }
  }

  // Get all certificates for a user
  Future<List<Certificate>> getUserCertificates(String userId) async {
    try {
      final certificatesSnapshot = await _firestore
          .collection('Certificates')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'issued')
          .get();

      return certificatesSnapshot.docs
          .map((doc) => Certificate.fromDocSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error getting user certificates: $e');
      return [];
    }
  }

  // Verify a certificate by certificate number
  Future<Certificate?> verifyCertificate(String certificateNumber) async {
    try {
      final certificateDoc = await _firestore
          .collection('Certificates')
          .doc(certificateNumber)
          .get();

      if (!certificateDoc.exists) {
        return null;
      }

      return Certificate.fromDocSnapshot(certificateDoc);
    } catch (e) {
      print('Error verifying certificate: $e');
      return null;
    }
  }

  // Check if a user is eligible for a certificate
  Future<bool> isEligibleForCertificate(
      String userId, String courseName) async {
    try {
      final testResults = await _getTestResults(userId, courseName);
      final testPassPercentage = _calculateTestPassPercentage(testResults);

      return testPassPercentage >= 80.0;
    } catch (e) {
      print('Error checking certificate eligibility: $e');
      return false;
    }
  }
}
