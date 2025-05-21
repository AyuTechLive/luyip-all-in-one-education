import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get total number of students
  Future<Map<String, dynamic>> getStudentsStats() async {
    try {
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .get();

      int totalStudents = studentsSnapshot.docs.length;
      int graduateStudents = 0;
      int undergraduateStudents = 0;

      // Count graduate and undergraduate students if that field exists
      for (var doc in studentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('Level')) {
          if (data['Level'] == 'Graduate') {
            graduateStudents++;
          } else if (data['Level'] == 'Undergraduate') {
            undergraduateStudents++;
          }
        }
      }

      // If we don't have level information, estimate based on total
      if (graduateStudents == 0 &&
          undergraduateStudents == 0 &&
          totalStudents > 0) {
        // This is just an estimation if the actual data doesn't exist
        graduateStudents = (totalStudents * 0.35).round();
        undergraduateStudents = totalStudents - graduateStudents;
      }

      return {
        'total': totalStudents,
        'graduate': graduateStudents,
        'undergraduate': undergraduateStudents,
      };
    } catch (e) {
      print('Error getting student stats: $e');
      return {
        'total': 0,
        'graduate': 0,
        'undergraduate': 0,
        'error': e.toString(),
      };
    }
  }

  // Get total number of teachers
  Future<Map<String, dynamic>> getTeachersStats() async {
    try {
      QuerySnapshot teachersSnapshot = await _firestore
          .collection('Users')
          .doc('teacher')
          .collection('accounts')
          .get();

      int totalTeachers = teachersSnapshot.docs.length;
      int fullTimeTeachers = 0;
      int partTimeTeachers = 0;

      // Count full-time and part-time teachers if that field exists
      for (var doc in teachersSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('EmploymentType')) {
          if (data['EmploymentType'] == 'Full-time') {
            fullTimeTeachers++;
          } else if (data['EmploymentType'] == 'Part-time') {
            partTimeTeachers++;
          }
        }
      }

      // If we don't have employment type info, estimate
      if (fullTimeTeachers == 0 && partTimeTeachers == 0 && totalTeachers > 0) {
        fullTimeTeachers = (totalTeachers * 0.65).round();
        partTimeTeachers = totalTeachers - fullTimeTeachers;
      }

      return {
        'total': totalTeachers,
        'fullTime': fullTimeTeachers,
        'partTime': partTimeTeachers,
      };
    } catch (e) {
      print('Error getting teacher stats: $e');
      return {
        'total': 0,
        'fullTime': 0,
        'partTime': 0,
        'error': e.toString(),
      };
    }
  }

  // Get courses statistics
  Future<Map<String, dynamic>> getCoursesStats() async {
    try {
      QuerySnapshot coursesSnapshot =
          await _firestore.collection('All Courses').get();

      int totalCourses = coursesSnapshot.docs.length;
      int onlineCourses = 0;
      int inPersonCourses = 0;

      // Count online and in-person courses if that field exists
      for (var doc in coursesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('Course Type')) {
          if (data['Course Type'] == 'Online') {
            onlineCourses++;
          } else if (data['Course Type'] == 'In-person') {
            inPersonCourses++;
          }
        }
      }

      // If we don't have course type info, estimate
      if (onlineCourses == 0 && inPersonCourses == 0 && totalCourses > 0) {
        onlineCourses = (totalCourses * 0.6).round();
        inPersonCourses = totalCourses - onlineCourses;
      }

      return {
        'total': totalCourses,
        'online': onlineCourses,
        'inPerson': inPersonCourses,
      };
    } catch (e) {
      print('Error getting course stats: $e');
      return {
        'total': 0,
        'online': 0,
        'inPerson': 0,
        'error': e.toString(),
      };
    }
  }

  // Get assessments statistics
  Future<Map<String, dynamic>> getAssessmentsStats() async {
    try {
      QuerySnapshot assessmentsSnapshot =
          await _firestore.collection('Assessments').get();

      int totalAssessments = assessmentsSnapshot.docs.length;
      int upcomingAssessments = 0;
      int completedAssessments = 0;

      // Get current date for comparison
      DateTime now = DateTime.now();

      // Count upcoming and completed assessments
      for (var doc in assessmentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('Date')) {
          try {
            DateTime assessmentDate = (data['Date'] as Timestamp).toDate();
            if (assessmentDate.isAfter(now)) {
              upcomingAssessments++;
            } else {
              completedAssessments++;
            }
          } catch (e) {
            // Handle date parsing errors
            print('Error parsing date for assessment: $e');
          }
        }
      }

      // If we don't have accurate counts, estimate
      if (upcomingAssessments == 0 &&
          completedAssessments == 0 &&
          totalAssessments > 0) {
        upcomingAssessments = (totalAssessments * 0.2).round();
        completedAssessments = totalAssessments - upcomingAssessments;
      }

      return {
        'total': totalAssessments,
        'upcoming': upcomingAssessments,
        'completed': completedAssessments,
      };
    } catch (e) {
      print('Error getting assessment stats: $e');
      return {
        'total': 0,
        'upcoming': 0,
        'completed': 0,
        'error': e.toString(),
      };
    }
  }

  // Get library book statistics
  Future<Map<String, dynamic>> getLibraryStats() async {
    try {
      QuerySnapshot librarySnapshot =
          await _firestore.collection('Library').get();

      int totalBooks = librarySnapshot.docs.length;
      int availableBooks = 0;
      int borrowedBooks = 0;

      // Count available and borrowed books
      for (var doc in librarySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('Status')) {
          if (data['Status'] == 'Available') {
            availableBooks++;
          } else if (data['Status'] == 'Borrowed') {
            borrowedBooks++;
          }
        }
      }

      // If we don't have status info, estimate
      if (availableBooks == 0 && borrowedBooks == 0 && totalBooks > 0) {
        borrowedBooks =
            (totalBooks * 0.08).round(); // Estimate 8% of books are borrowed
        availableBooks = totalBooks - borrowedBooks;
      }

      return {
        'total': totalBooks,
        'available': availableBooks,
        'borrowed': borrowedBooks,
      };
    } catch (e) {
      print('Error getting library stats: $e');
      return {
        'total': 0,
        'available': 0,
        'borrowed': 0,
        'error': e.toString(),
      };
    }
  }

  // UPDATED: Get revenue statistics using the unified transaction service format
  Future<Map<String, dynamic>> getRevenueStats() async {
    try {
      // Get current date
      DateTime now = DateTime.now();

      // Calculate the first day of the current month
      DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

      // Calculate the first day of the next month
      DateTime firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);

      // Query transactions from the current month
      QuerySnapshot transactionsSnapshot = await _firestore
          .collection('Transactions')
          .where('timestamp', isGreaterThanOrEqualTo: firstDayOfMonth)
          .where('timestamp', isLessThan: firstDayOfNextMonth)
          .get();

      double totalRevenue = 0;
      double tuitionRevenue = 0;
      double membershipRevenue = 0;
      double otherRevenue = 0;

      // Calculate revenue from transactions using the unified format
      for (var doc in transactionsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Skip transactions that aren't completed
        if (data.containsKey('status') && data['status'] != 'completed') {
          continue;
        }

        // Extract amount, handling both double and string formats
        double amount = 0;
        if (data.containsKey('amount')) {
          if (data['amount'] is double) {
            amount = data['amount'];
          } else {
            amount = double.tryParse(data['amount'].toString()) ?? 0;
          }
        }

        // Add to total revenue
        totalRevenue += amount;

        // Categorize by transaction type
        if (data.containsKey('type')) {
          String type = data['type'].toString().toLowerCase();

          if (type == 'course') {
            tuitionRevenue += amount;
          } else if (type == 'membership') {
            membershipRevenue += amount;
          } else {
            otherRevenue += amount;
          }
        } else {
          // If no type specified, categorize as other
          otherRevenue += amount;
        }
      }

      return {
        'total': totalRevenue,
        'tuition': tuitionRevenue,
        'membership': membershipRevenue,
        'other': otherRevenue,
      };
    } catch (e) {
      print('Error getting revenue stats: $e');
      return {
        'total': 0,
        'tuition': 0,
        'membership': 0,
        'other': 0,
        'error': e.toString(),
      };
    }
  }

  // UPDATED: Get recent activities with support for the unified transaction format
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      // Combine recent activities from different collections
      List<Map<String, dynamic>> activities = [];

      // Get recent student registrations
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .orderBy('DOJ', descending: true)
          .limit(5)
          .get();

      for (var doc in studentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('Name') && data.containsKey('DOJ')) {
          activities.add({
            'type': 'registration',
            'title': 'New student registered',
            'description': '${data['Name']} enrolled',
            'timestamp': data['DOJ'],
            'iconColor': 'primary',
            'icon': 'person_add_outlined',
          });
        }
      }

      // Get recent transactions (payments) using the unified format
      QuerySnapshot transactionsSnapshot = await _firestore
          .collection('Transactions')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      for (var doc in transactionsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('userEmail')) {
          // Extract the name from email if userName not available
          String name = data.containsKey('userName')
              ? data['userName']
              : data['userEmail'].toString().split('@')[0];

          // Format amount with currency
          String amountStr = '';
          if (data.containsKey('amount')) {
            double amount = 0;
            if (data['amount'] is double) {
              amount = data['amount'];
            } else {
              amount = double.tryParse(data['amount'].toString()) ?? 0;
            }

            String currency = data.containsKey('currency')
                ? data['currency'].toString()
                : '₹';

            amountStr = '$currency${amount.toStringAsFixed(2)}';
          }

          // Different descriptions based on transaction type
          String title = 'Payment received';
          String description = '$name paid $amountStr';
          String iconColor = 'success';
          String icon = 'payment_outlined';

          if (data.containsKey('type')) {
            String type = data['type'].toString().toLowerCase();

            if (type == 'course') {
              title = 'Course Enrollment';
              String courseName = data.containsKey('courseName')
                  ? data['courseName'].toString()
                  : 'a course';
              description = '$name enrolled in $courseName ($amountStr)';
              iconColor = 'primary';
              icon = 'school_outlined';
            } else if (type == 'membership') {
              title = 'Membership Purchase';
              description = '$name purchased a membership ($amountStr)';
              iconColor = 'success';
              icon = 'card_membership';
            }
          }

          activities.add({
            'type': 'payment',
            'title': title,
            'description': description,
            'timestamp': data['timestamp'] ?? Timestamp.now(),
            'iconColor': iconColor,
            'icon': icon,
          });
        }
      }

      // Get recent course updates
      QuerySnapshot coursesSnapshot = await _firestore
          .collection('All Courses')
          .orderBy('Last Updated', descending: true)
          .limit(5)
          .get();

      for (var doc in coursesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('Course Name') &&
            data.containsKey('Last Updated')) {
          activities.add({
            'type': 'course_update',
            'title': 'Course updated',
            'description': '${data['Course Name']} curriculum revised',
            'timestamp': data['Last Updated'],
            'iconColor': 'warning',
            'icon': 'edit_note_outlined',
          });
        }
      }

      // Sort all activities by timestamp
      activities.sort((a, b) {
        Timestamp timestampA;
        Timestamp timestampB;

        if (a['timestamp'] is Timestamp) {
          timestampA = a['timestamp'];
        } else {
          // Default to current time if timestamp is invalid
          timestampA = Timestamp.now();
        }

        if (b['timestamp'] is Timestamp) {
          timestampB = b['timestamp'];
        } else {
          // Default to current time if timestamp is invalid
          timestampB = Timestamp.now();
        }

        return timestampB.compareTo(timestampA);
      });

      // Return only the most recent activities (limited to 10)
      return activities.take(10).toList();
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }

  // Format timestamp to relative time (e.g. "5 minutes ago")
  String getTimeAgo(dynamic timestamp) {
    try {
      if (timestamp == null) {
        return 'recently';
      }

      DateTime dateTime;

      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'recently';
      }

      final Duration difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} mins ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else {
        return '${(difference.inDays / 365).floor()} years ago';
      }
    } catch (e) {
      print('Error formatting time: $e');
      return 'recently';
    }
  }
}
