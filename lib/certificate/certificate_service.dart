import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:luyip_website_edu/certificate/certificate_generator.dart';
import 'package:luyip_website_edu/certificate/certificate_model.dart';
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

  // Check if certificate is already issued
  Future<Certificate?> getExistingCertificate(
      String userId, String courseName) async {
    try {
      final certificateQuery = await _firestore
          .collection('Certificates')
          .where('userId', isEqualTo: userId)
          .where('courseName', isEqualTo: courseName)
          .where('status', isEqualTo: 'issued')
          .limit(1)
          .get();

      if (certificateQuery.docs.isEmpty) {
        return null;
      }

      return Certificate.fromDocSnapshot(certificateQuery.docs.first);
    } catch (e) {
      print('Error getting existing certificate: $e');
      return null;
    }
  }

  // Check if a course is marked as completed
  Future<bool> isCourseCompleted(String courseName) async {
    try {
      final courseDoc =
          await _firestore.collection('All Courses').doc(courseName).get();

      return courseDoc.exists && (courseDoc.data()?['isCompleted'] ?? false);
    } catch (e) {
      print('Error checking if course is completed: $e');
      return false;
    }
  }

  // Calculate what percentage of tests were passed by a student
  Future<double> calculateTestPassPercentage(
      String userId, String courseName) async {
    try {
      // Get test results for user in course
      final testResults = await _getTestResults(userId, courseName);

      final List<String> passedTests =
          testResults['passedTests'] as List<String>;
      final int totalTests = testResults['totalTests'] as int;

      if (totalTests == 0) return 0.0;
      return (passedTests.length / totalTests) * 100;
    } catch (e) {
      print('Error calculating test pass percentage: $e');
      return 0.0;
    }
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

  // Check if a user is eligible for a certificate
  Future<Map<String, dynamic>> checkCertificateEligibility(
      String userId, String courseName) async {
    try {
      // First check if course is marked as completed
      final isCourseCompleted = await this.isCourseCompleted(courseName);

      // Then check if they've passed enough tests
      final percentageScore =
          await calculateTestPassPercentage(userId, courseName);

      // Check if certificate already exists
      final existingCertificate =
          await getExistingCertificate(userId, courseName);

      return {
        'isCourseCompleted': isCourseCompleted,
        'testPassPercentage': percentageScore,
        'isEligible': isCourseCompleted &&
            percentageScore >= 70.0 &&
            existingCertificate == null,
        'certificateIssued': existingCertificate != null,
        'certificate': existingCertificate,
      };
    } catch (e) {
      print('Error checking certificate eligibility: $e');
      return {
        'isCourseCompleted': false,
        'testPassPercentage': 0.0,
        'isEligible': false,
        'certificateIssued': false,
        'certificate': null,
      };
    }
  }

  // Generate a certificate for a student
  Future<Certificate?> generateCertificate({
    required String userId,
    required String userEmail,
    required String courseName,
  }) async {
    try {
      print('Starting certificate generation process...'); // Debug log

      // Check if certificate already exists
      final existingCertificate =
          await getExistingCertificate(userId, courseName);
      if (existingCertificate != null) {
        // Certificate already exists, return it
        return existingCertificate;
      }

      // Check if course is officially completed
      final isCourseCompleted = await this.isCourseCompleted(courseName);

      if (!isCourseCompleted) {
        throw Exception(
            'This course has not been marked as completed by an instructor yet');
      }

      // Calculate the student's test pass percentage
      final percentageScore =
          await calculateTestPassPercentage(userId, courseName);

      // Check if student has passed at least 70% of tests
      if (percentageScore < 70.0) {
        throw Exception(
            'You need to pass at least 70% of tests to generate a certificate');
      }

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
      rethrow; // Rethrow to allow UI to display the specific error
    }
  }

  // Helper method to generate certificate once user name is determined
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
          'CERT-${courseName.substring(0, min(3, courseName.length)).toUpperCase()}-$userId-$timestamp';

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

      // Save to Firestore for verification purposes
      await _firestore
          .collection('Certificates')
          .doc(certificateNumber)
          .set(certificate.toMap());

      print('Saved certificate to Firestore'); // Debug log

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

  int min(int a, int b) {
    return a < b ? a : b;
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
}
