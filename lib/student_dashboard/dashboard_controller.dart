import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:luyip_website_edu/membership/membership_service.dart';

class StudentDashboardController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MembershipService _membershipService = MembershipService();

  // Get current user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {};
      }

      final userDoc = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(currentUser.email)
          .get();

      if (userDoc.exists) {
        return userDoc.data() ?? {};
      }

      return {};
    } catch (e) {
      print('Error fetching user profile: $e');
      return {};
    }
  }

  // Get enrolled courses with progress
  Future<List<Map<String, dynamic>>> getEnrolledCourses() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final userProfile = await getUserProfile();
      List myCourses = userProfile['My Courses'] ?? [];

      List<Map<String, dynamic>> enrolledCourses = [];

      // Get course completion data
      final completionsSnapshot = await _firestore
          .collection('CourseCompletions')
          .where('studentEmail', isEqualTo: currentUser.email)
          .get();

      List<String> completedCourseNames = completionsSnapshot.docs
          .map((doc) => doc.data()['courseName'] as String)
          .toList();

      // Fetch course progress data
      final progressSnapshot = await _firestore
          .collection('CourseProgress')
          .doc(currentUser.email)
          .get();

      Map<String, dynamic> progressData = {};
      if (progressSnapshot.exists) {
        progressData = progressSnapshot.data() ?? {};
      }

      // Fetch courses details
      for (String courseName in myCourses) {
        final courseDoc =
            await _firestore.collection('All Courses').doc(courseName).get();

        if (courseDoc.exists) {
          final courseData = courseDoc.data() as Map<String, dynamic>;

          // Get progress for this course
          final isCompleted = completedCourseNames.contains(courseName);
          double progress = 0.0;
          DateTime? lastAccessed;

          if (progressData.containsKey(courseName)) {
            Map<String, dynamic> courseProgress = progressData[courseName];
            progress = courseProgress['progress'] ?? 0.0;

            if (courseProgress.containsKey('lastAccessed')) {
              lastAccessed =
                  (courseProgress['lastAccessed'] as Timestamp).toDate();
            }
          } else {
            // If no progress data, create default values
            progress = isCompleted ? 1.0 : 0.1;
          }

          final course = {
            ...courseData,
            'progress': progress,
            'isCompleted': isCompleted,
            'lastAccessed': lastAccessed ??
                DateTime.now().subtract(const Duration(days: 1)),
          };

          enrolledCourses.add(course);
        }
      }

      return enrolledCourses;
    } catch (e) {
      print('Error fetching enrolled courses: $e');
      return [];
    }
  }

  // Get completed courses
  Future<List<Map<String, dynamic>>> getCompletedCourses() async {
    try {
      List<Map<String, dynamic>> allCourses = await getEnrolledCourses();
      return allCourses
          .where((course) => course['isCompleted'] == true)
          .toList();
    } catch (e) {
      print('Error fetching completed courses: $e');
      return [];
    }
  }

  // Get recent test results
  Future<List<Map<String, dynamic>>> getRecentTests() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      // Query tests where this student is a taker
      final testsSnapshot = await _firestore
          .collection('Tests')
          .where('takers', arrayContains: currentUser.email)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> tests = [];
      for (var doc in testsSnapshot.docs) {
        final testData = doc.data();

        // Get test submission details
        final submissionsQuery = await _firestore
            .collection('TestSubmissions')
            .doc(doc.id)
            .collection('submissions')
            .where('studentEmail', isEqualTo: currentUser.email)
            .limit(1)
            .get();

        if (submissionsQuery.docs.isNotEmpty) {
          final submissionData = submissionsQuery.docs.first.data();

          tests.add({
            'id': doc.id,
            'title': testData['title'] ?? 'Test',
            'description': testData['description'] ?? '',
            'totalMarks': testData['totalMarks'] ?? 0,
            'autoMarks': submissionData['autoMarks'] ?? 0,
            'manualMarks': submissionData['manualMarks'],
            'isEvaluated': submissionData['isEvaluated'] ?? false,
            'submittedAt': submissionData['submittedAt'],
            'submissionId': submissionsQuery.docs.first.id,
          });
        }
      }

      return tests;
    } catch (e) {
      print('Error fetching recent tests: $e');
      return [];
    }
  }

  // Get membership status
  Future<Map<String, dynamic>> getMembershipStatus() async {
    try {
      return await _membershipService.getMembershipStatus();
    } catch (e) {
      print('Error fetching membership status: $e');
      return {
        'isMember': false,
        'membershipDetails': {},
      };
    }
  }

  // Get website general data like announcements, testimonials, etc.
  Future<Map<String, dynamic>> getWebsiteGeneralData() async {
    try {
      final doc =
          await _firestore.collection('website_general').doc('dashboard').get();

      if (doc.exists) {
        return doc.data() ?? {};
      }

      return {};
    } catch (e) {
      print('Error fetching website general data: $e');
      return {};
    }
  }

  // Get upcoming events
  Future<List<Map<String, dynamic>>> getUpcomingEvents() async {
    try {
      // First try to get events from website_general
      final websiteData = await getWebsiteGeneralData();
      if (websiteData.containsKey('upcomingEvents') &&
          (websiteData['upcomingEvents'] as List).isNotEmpty) {
        return List<Map<String, dynamic>>.from(websiteData['upcomingEvents']);
      }

      // If no events in website_general, try to get from enrolled courses
      List<Map<String, dynamic>> events = [];
      final enrolledCourses = await getEnrolledCourses();

      for (var course in enrolledCourses) {
        if (course.containsKey('upcomingClasses')) {
          List classes = course['upcomingClasses'] ?? [];
          for (var classEvent in classes) {
            if (classEvent is Map<String, dynamic>) {
              // Add course name to event
              classEvent['courseName'] = course['Course Name'];
              events.add(classEvent);
            }
          }
        }
      }

      // If still no events, create some example events
      if (events.isEmpty) {
        final now = DateTime.now();

        // Example events based on enrolled courses
        for (int i = 0; i < enrolledCourses.length && i < 3; i++) {
          final course = enrolledCourses[i];
          final eventDate = now.add(Duration(days: i + 1));
          final formattedDate =
              '${_getMonthName(eventDate.month)} ${eventDate.day}';

          events.add({
            'title': 'Live Class: ${course['Course Name']} Session',
            'category': course['Category'] ?? 'General',
            'time': '$formattedDate, ${3 + i}:00 PM',
            'date': Timestamp.fromDate(eventDate),
          });
        }
      }

      // Sort by date
      events.sort((a, b) {
        DateTime aDate = a['date'] is Timestamp
            ? (a['date'] as Timestamp).toDate()
            : DateTime.now();
        DateTime bDate = b['date'] is Timestamp
            ? (b['date'] as Timestamp).toDate()
            : DateTime.now();
        return aDate.compareTo(bDate);
      });

      return events;
    } catch (e) {
      print('Error fetching upcoming events: $e');
      return [];
    }
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  // Get all dashboard data in one call
  Future<Map<String, dynamic>> getAllDashboardData() async {
    try {
      final userProfile = await getUserProfile();
      final enrolledCourses = await getEnrolledCourses();
      final completedCourses = enrolledCourses
          .where((course) => course['isCompleted'] == true)
          .toList();
      final inProgressCourses = enrolledCourses
          .where((course) => course['isCompleted'] == false)
          .toList();
      final recentTests = await getRecentTests();
      final membershipStatus = await getMembershipStatus();
      final websiteGeneralData = await getWebsiteGeneralData();
      final upcomingEvents = await getUpcomingEvents();

      // Get testimonials
      List testimonials = [];
      if (websiteGeneralData.containsKey('testimonials')) {
        testimonials = websiteGeneralData['testimonials'];
      }

      // Get announcements
      List announcements = [];
      if (websiteGeneralData.containsKey('announcements')) {
        announcements = websiteGeneralData['announcements'];
      }

      return {
        'userProfile': userProfile,
        'enrolledCourses': inProgressCourses,
        'completedCourses': completedCourses,
        'testsTaken': recentTests,
        'upcomingEvents': upcomingEvents,
        'isMember': membershipStatus['isMember'] ?? false,
        'membershipDetails': membershipStatus,
        'testimonials': testimonials,
        'announcements': announcements,
      };
    } catch (e) {
      print('Error fetching all dashboard data: $e');
      return {
        'userProfile': {},
        'enrolledCourses': [],
        'completedCourses': [],
        'testsTaken': [],
        'upcomingEvents': [],
        'isMember': false,
        'membershipDetails': {},
        'testimonials': [],
        'announcements': [],
      };
    }
  }
}
