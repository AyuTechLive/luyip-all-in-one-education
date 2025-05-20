import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/certificate/certificate_service.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class MarkCourseCompletePage extends StatefulWidget {
  final String courseName;

  const MarkCourseCompletePage({super.key, required this.courseName});

  @override
  State<MarkCourseCompletePage> createState() => _MarkCourseCompletePageState();
}

class _MarkCourseCompletePageState extends State<MarkCourseCompletePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CertificateService _certificateService = CertificateService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isCourseCompleted = false;
  int _enrolledStudentsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkCourseStatus();
  }

  // In MarkCourseCompletePage _checkCourseStatus method:
  Future<void> _checkCourseStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if course is already marked as completed
      final isCourseCompleted =
          await _certificateService.isCourseCompleted(widget.courseName);

      // Count enrolled students
      final studentsSnapshot = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .where('My Courses', arrayContains: widget.courseName)
          .count()
          .get();

      setState(() {
        _isCourseCompleted = isCourseCompleted;
        _enrolledStudentsCount =
            studentsSnapshot.count ?? 0; // Handle nullable with ?? 0
        _isLoading = false;
      });
    } catch (e) {
      Utils().toastMessage('Error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markCourseAsComplete() async {
    if (_isSubmitting) return;

    // Get confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark Course as Complete?'),
        content: Text(
            'This will mark the course as completed. Once a course is marked as complete, '
            'students who have passed at least 70% of tests will be able to generate their certificates. '
            '\n\nThis action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You need to be logged in to perform this action');
      }

      final completedBy = currentUser.email ?? 'Instructor';

      // Mark the course as completed in Firestore
      await _firestore.collection('All Courses').doc(widget.courseName).update({
        'isCompleted': true,
        'completedDate': FieldValue.serverTimestamp(),
        'completedBy': completedBy,
      });

      Utils().toastMessage('Course marked as completed successfully');
      setState(() {
        _isCourseCompleted = true;
      });
    } catch (e) {
      Utils().toastMessage('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('Mark Course Complete'),
        backgroundColor: Colors.white,
        foregroundColor: ColorManager.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course: ${widget.courseName}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Total Students Enrolled: $_enrolledStudentsCount',
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorManager.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 32),
                  _buildStatusCard(),
                  SizedBox(height: 40),
                  if (!_isCourseCompleted)
                    Roundbuttonnew(
                      loading: _isSubmitting,
                      title: 'Mark Course as Complete',
                      ontap: _markCourseAsComplete,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorManager.textDark,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCourseCompleted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCourseCompleted
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCourseCompleted
                        ? Icons.check_circle
                        : Icons.info_outline,
                    size: 32,
                    color: _isCourseCompleted ? Colors.green : Colors.orange,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCourseCompleted
                              ? 'Course Completed'
                              : 'Course Not Completed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isCourseCompleted
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _isCourseCompleted
                              ? 'Students who passed at least 70% of tests can now generate their certificates.'
                              : 'Mark this course as complete to allow eligible students to generate certificates.',
                          style: TextStyle(
                            color: _isCourseCompleted
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isCourseCompleted) ...[
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Certificate Generation',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Students who pass at least 70% of tests will be able to generate their own certificates. This includes both current and future students who enroll in this course.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
