import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/add_student.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/add_teachers.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class TeachersContent extends StatefulWidget {
  const TeachersContent({Key? key}) : super(key: key);

  @override
  State<TeachersContent> createState() => _TeachersContentState();
}

class _TeachersContentState extends State<TeachersContent> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Access the student collection based on your Firebase structure
      final QuerySnapshot studentSnapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc('teacher')
              .collection('accounts')
              .get();

      final List<Map<String, dynamic>> studentsList =
          studentSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

      setState(() {
        _students = studentsList;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load teacher: ${error.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Teacher Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textDark,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Teacher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => AddTeacherPage(
                            onTeacherAdded: () {
                              _fetchStudents(); // Refresh the list after adding
                            },
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage all Teacher information',
            style: TextStyle(fontSize: 16, color: ColorManager.textMedium),
          ),
          const SizedBox(height: 16),

          // Search and refresh controls
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Teachers...',
                    prefixIcon: Icon(Icons.search, color: ColorManager.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    // Implement search functionality
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _fetchStudents,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Display data or loading indicator
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStudents,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Text(
          'No teachers found',
          style: TextStyle(fontSize: 18, color: ColorManager.textMedium),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Teachers List',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                Text(
                  '${_students.length} Teachers',
                  style: TextStyle(color: ColorManager.textMedium),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor: MaterialStateProperty.all(
                      ColorManager.primary.withOpacity(0.1),
                    ),
                    columns: const [
                      DataColumn(label: Text('Profile')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Joined Date')),
                      DataColumn(label: Text('Courses')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows:
                        _students.map((student) {
                          List<dynamic> courses = student['My Courses'] ?? [];

                          return DataRow(
                            cells: [
                              DataCell(
                                CircleAvatar(
                                  backgroundImage:
                                      student['ProfilePicURL'] != null
                                          ? NetworkImage(
                                            student['ProfilePicURL'],
                                          )
                                          : null,
                                  child:
                                      student['ProfilePicURL'] == null
                                          ? const Icon(Icons.person)
                                          : null,
                                ),
                              ),
                              DataCell(Text(student['Name'] ?? 'N/A')),
                              DataCell(Text(student['Email'] ?? 'N/A')),
                              DataCell(Text(student['DOJ'] ?? 'N/A')),
                              DataCell(
                                Text(
                                  courses.isEmpty
                                      ? 'No courses'
                                      : '${courses.length} courses',
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.visibility,
                                        color: ColorManager.primary,
                                      ),
                                      tooltip: 'View Details',
                                      onPressed: () {
                                        _showStudentDetails(context, student);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.amber,
                                      ),
                                      tooltip: 'Edit',
                                      onPressed: () {
                                        // Implement edit functionality
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Student Details'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            student['ProfilePicURL'] != null
                                ? NetworkImage(student['ProfilePicURL'])
                                : null,
                        child:
                            student['ProfilePicURL'] == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Name', student['Name'] ?? 'N/A'),
                    _buildDetailRow('Email', student['Email'] ?? 'N/A'),
                    _buildDetailRow('Joined Date', student['DOJ'] ?? 'N/A'),
                    _buildDetailRow('User ID', student['UID'] ?? 'N/A'),
                    const SizedBox(height: 16),
                    const Text(
                      'Enrolled Courses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildCoursesList(student['My Courses']),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<Widget> _buildCoursesList(List<dynamic>? courses) {
    if (courses == null || courses.isEmpty) {
      return [const Text('No courses enrolled')];
    }

    return courses.map((course) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            const Icon(Icons.book, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(course.toString())),
          ],
        ),
      );
    }).toList();
  }
}

// Add Student Page
