import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/Courses/add_test.dart';
import 'package:luyip_website_edu/exams/test_list_page.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

import 'package:intl/intl.dart';

class ManageTestsPage extends StatefulWidget {
  final String role;

  const ManageTestsPage({super.key, required this.role});

  @override
  State<ManageTestsPage> createState() => _ManageTestsPageState();
}

class _ManageTestsPageState extends State<ManageTestsPage> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _fetchCourses();
  }

  Future<List<Map<String, dynamic>>> _fetchCourses() async {
    List<Map<String, dynamic>> courses = [];

    try {
      var querySnapshot =
          await FirebaseFirestore.instance.collection('All Courses').get();

      for (var doc in querySnapshot.docs) {
        final courseId = doc.id;
        final courseData = doc.data();

        // Fetch test counts for each course
        int testCount = 0;

        try {
          final courseRef = FirebaseDatabase.instance.ref(courseId);
          final subjectsSnapshot = await courseRef.child('SUBJECTS').once();

          if (subjectsSnapshot.snapshot.value != null) {
            final subjectsData =
                subjectsSnapshot.snapshot.value as Map<dynamic, dynamic>;

            for (var subjectData in subjectsData.values) {
              if (subjectData is Map && subjectData.containsKey('Tests')) {
                final tests = subjectData['Tests'] as Map<dynamic, dynamic>;
                testCount += tests.length;
              }
            }
          }
        } catch (e) {
          print('Error fetching test count for $courseId: ${e.toString()}');
        }

        courses.add({
          'id': courseId,
          'name': courseId,
          'price': courseData['Price'] ?? 'Free',
          'description': courseData['Description'] ?? 'No description',
          'image': courseData['Image URL'] ?? '',
          'testCount': testCount,
        });
      }

      return courses;
    } catch (e) {
      Utils().toastMessage('Error fetching courses: ${e.toString()}');
      return [];
    }
  }

  void _navigateToSubjects(String courseName) async {
    try {
      final databaseRef =
          FirebaseDatabase.instance.ref(courseName).child('SUBJECTS');
      DatabaseEvent event = await databaseRef.once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> subjectsData =
            event.snapshot.value as Map<dynamic, dynamic>;

        List<String> subjects =
            subjectsData.keys.map((key) => key.toString()).toList();

        if (mounted) {
          _showSubjectsDialog(courseName, subjects);
        }
      } else {
        Utils().toastMessage('No subjects found for this course');
      }
    } catch (e) {
      Utils().toastMessage('Error fetching subjects: ${e.toString()}');
    }
  }

  void _showSubjectsDialog(String courseName, List<String> subjects) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$courseName Subjects'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(subjects[index]),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestListPage(
                        courseName: courseName,
                        subjectName: subjects[index],
                        userRole: widget.role,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Manage Tests',
          style: TextStyle(
            color: ColorManager.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textDark),
        actions: [
          if (widget.role == 'admin' || widget.role == 'teacher')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTestAdmin(),
                  ),
                ).then((_) {
                  // Refresh the list when returning from add test page
                  setState(() {
                    _coursesFuture = _fetchCourses();
                  });
                });
              },
              tooltip: 'Create New Test',
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: ColorManager.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading courses: ${snapshot.error}',
                style: TextStyle(color: ColorManager.textMedium),
              ),
            );
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 64,
                    color: ColorManager.textMedium.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No courses available',
                    style: TextStyle(color: ColorManager.textMedium),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final testCount = course['testCount'] as int;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _navigateToSubjects(course['id']),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course Title and Test Count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                course['name'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorManager.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: testCount > 0
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$testCount Tests',
                                style: TextStyle(
                                  color: testCount > 0
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Course Description
                        Text(
                          course['description'],
                          style: TextStyle(
                            color: ColorManager.textMedium,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 16),

                        // View Subjects button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff321f73),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _navigateToSubjects(course['id']),
                            icon: const Icon(Icons.folder),
                            label: const Text('View Subjects'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.role == 'admin' || widget.role == 'teacher'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTestAdmin(),
                  ),
                ).then((_) {
                  // Refresh the list when returning from add test page
                  setState(() {
                    _coursesFuture = _fetchCourses();
                  });
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Test'),
              backgroundColor: const Color(0xff321f73),
            )
          : null,
    );
  }
}
