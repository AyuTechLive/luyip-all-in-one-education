import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/certificate/certificate_service.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class MarkCourseCompletePage extends StatefulWidget {
  final String courseName;

  const MarkCourseCompletePage({super.key, required this.courseName});

  @override
  State<MarkCourseCompletePage> createState() => _MarkCourseCompletePageState();
}

class _MarkCourseCompletePageState extends State<MarkCourseCompletePage> {
  final _firestore = FirebaseFirestore.instance;
  final _certificateService = CertificateService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  Set<String> _selectedStudents = {};
  bool _processingRequest = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all students enrolled in this course
      final querySnapshot = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .get();

      List<Map<String, dynamic>> enrolledStudents = [];

      for (var doc in querySnapshot.docs) {
        final userData = doc.data();

        // Check if student is enrolled in this course
        if (userData.containsKey(widget.courseName) &&
            userData[widget.courseName] is List) {
          // Add student to list
          enrolledStudents.add({
            'id': doc.id,
            'name': userData['Name'] ?? 'Unknown Student',
            'email': doc.id,
            'status': userData[widget.courseName]
                [0], // 0: enrolled, 1: in progress, 2: completed
            'certificateIssued': userData['Certificates'] != null &&
                userData['Certificates'] is List &&
                (userData['Certificates'] as List).isNotEmpty,
          });
        }
      }

      setState(() {
        _students = enrolledStudents;
        _isLoading = false;
      });
    } catch (e) {
      Utils().toastMessage('Error loading students: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsComplete() async {
    if (_selectedStudents.isEmpty) {
      Utils().toastMessage('Please select at least one student');
      return;
    }

    setState(() {
      _processingRequest = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You need to be logged in to perform this action');
      }

      final completedBy = currentUser.email ?? 'Unknown Admin';

      // Process each selected student
      for (var studentEmail in _selectedStudents) {
        final studentData =
            _students.firstWhere((s) => s['email'] == studentEmail);
        final userId = FirebaseAuth.instance.currentUser?.uid ?? studentEmail;

        // Mark course as complete
        await _certificateService.markCourseAsComplete(
          userId: userId,
          userEmail: studentEmail,
          courseName: widget.courseName,
          completedBy: completedBy,
        );
      }

      Utils().toastMessage('Course marked as complete for selected students');
      // Refresh student list
      await _loadStudents();
    } catch (e) {
      Utils().toastMessage('Error marking course as complete: ${e.toString()}');
    } finally {
      setState(() {
        _processingRequest = false;
        _selectedStudents.clear();
      });
    }
  }

  void _toggleStudentSelection(String email) {
    setState(() {
      if (_selectedStudents.contains(email)) {
        _selectedStudents.remove(email);
      } else {
        _selectedStudents.add(email);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Course Complete - ${widget.courseName}'),
        backgroundColor: ColorManager.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _students.isEmpty
                      ? _buildNoStudentsView()
                      : _buildStudentsList(),
                ),
                if (_students.isNotEmpty) _buildActionButtons(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mark Course as Complete',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select students who have completed the "${widget.courseName}" course. '
            'Students who pass at least 80% of tests will automatically receive a completion certificate.',
            style: TextStyle(
              color: ColorManager.textMedium,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorManager.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ColorManager.info,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Certificate eligibility is based on test performance. '
                          'Students must pass at least 80% of tests to qualify.',
                          style: TextStyle(
                            color: ColorManager.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoStudentsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No students enrolled in this course',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final isSelected = _selectedStudents.contains(student['email']);
        final isCompleted = student['status'] == 2;
        final hasCertificate = student['certificateIssued'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? ColorManager.primary
                  : isCompleted
                      ? Colors.green.withOpacity(0.5)
                      : Colors.transparent,
              width: isSelected || isCompleted ? 2 : 0,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: isCompleted
                ? null // Disable checkbox if already completed
                : (value) {
                    if (value != null) {
                      _toggleStudentSelection(student['email']);
                    }
                  },
            title: Text(
              student['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student['email']),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusBadge(student['status'], hasCertificate),
                  ],
                ),
              ],
            ),
            secondary: CircleAvatar(
              backgroundColor: isCompleted
                  ? Colors.green.withOpacity(0.1)
                  : ColorManager.primary.withOpacity(0.1),
              child: Icon(
                isCompleted ? Icons.check : Icons.person,
                color: isCompleted ? Colors.green : ColorManager.primary,
              ),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(int status, bool hasCertificate) {
    String text;
    Color color;

    switch (status) {
      case 0:
        text = 'Enrolled';
        color = ColorManager.warning;
        break;
      case 1:
        text = 'In Progress';
        color = ColorManager.info;
        break;
      case 2:
        text = hasCertificate ? 'Completed with Certificate' : 'Completed';
        color = Colors.green;
        break;
      default:
        text = 'Unknown';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 2
                ? hasCertificate
                    ? Icons.card_membership
                    : Icons.check_circle
                : status == 1
                    ? Icons.timelapse
                    : Icons.school,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedStudents.length} students selected',
              style: TextStyle(
                color: ColorManager.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _processingRequest ? null : _markAsComplete,
            icon: _processingRequest
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle),
            label:
                Text(_processingRequest ? 'Processing...' : 'Mark as Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
