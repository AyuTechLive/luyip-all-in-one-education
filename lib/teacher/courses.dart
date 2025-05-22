import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:luyip_website_edu/Courses/course_deatils.dart';
import 'package:luyip_website_edu/Courses/course_details/course_details.dart';
import 'package:luyip_website_edu/Courses/widget/coursecardview.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class TeacherCoursesContent extends StatefulWidget {
  const TeacherCoursesContent({Key? key}) : super(key: key);

  @override
  State<TeacherCoursesContent> createState() => _TeacherCoursesContentState();
}

class _TeacherCoursesContentState extends State<TeacherCoursesContent> {
  final searchFilterController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool loading = false;
  String teacherEmail = '';
  List<String> teacherCourses = [];
  bool isLoadingCourses = true;
  String? errorMessage;

  // For responsive grid view
  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _loadTeacherAndCourses();
  }

  Future<void> _loadTeacherAndCourses() async {
    try {
      setState(() {
        isLoadingCourses = true;
        errorMessage = null;
      });

      // Get current user email
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        setState(() {
          errorMessage = 'User not authenticated';
          isLoadingCourses = false;
        });
        return;
      }

      teacherEmail = currentUser.email ?? '';

      // Find the teacher in Firestore and get their assigned courses
      final QuerySnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc('teacher')
          .collection('accounts')
          .where('Email', isEqualTo: teacherEmail)
          .limit(1)
          .get();

      if (teacherDoc.docs.isEmpty) {
        setState(() {
          errorMessage = 'Teacher profile not found';
          isLoadingCourses = false;
        });
        return;
      }

      // Get the list of courses assigned to this teacher
      final teacherData = teacherDoc.docs.first.data() as Map<String, dynamic>;
      final courses = teacherData['My Courses'];

      if (courses != null && courses is List) {
        teacherCourses = List<String>.from(courses);
      }

      setState(() {
        isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading courses: ${e.toString()}';
        isLoadingCourses = false;
      });
    }
  }

  void _refreshCourses() {
    _loadTeacherAndCourses();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Courses',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your assigned courses and materials',
            style: TextStyle(fontSize: 16, color: ColorManager.textMedium),
          ),
          const SizedBox(height: 16),

          // Search bar
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: searchFilterController,
              cursorColor: const Color(0xFF5E4DCD),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFF5E4DCD),
                ),
                hintText: 'Search your courses...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 24),

          // Courses grid
          Expanded(
            child: _buildCoursesContent(width),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesContent(double width) {
    // Show loading spinner while courses are being loaded
    if (isLoadingCourses) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5E4DCD),
        ),
      );
    }

    // Show error message if there's an error
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E4DCD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _refreshCourses,
            ),
          ],
        ),
      );
    }

    // Show empty state if no courses assigned
    if (teacherCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              color: Colors.grey.shade400,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'No courses assigned to you yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact an administrator to get courses assigned to you',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Stream builder to get assigned courses
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('All Courses').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF5E4DCD),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E4DCD),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _refreshCourses,
                ),
              ],
            ),
          );
        }

        // Filter courses based on teacher's assigned courses and search text
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final courseName = doc['Course Name'].toString();
          final searchText = searchFilterController.text.toLowerCase();

          // Check if course is in teacher's list and matches search filter
          return teacherCourses.contains(courseName) &&
              (searchText.isEmpty ||
                  courseName.toLowerCase().contains(searchText));
        }).toList();

        // Show no search results state
        if (filteredDocs.isEmpty && searchFilterController.text.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  color: Colors.grey.shade400,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'No courses match your search',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    searchFilterController.clear();
                    setState(() {});
                  },
                  child: const Text('Clear search'),
                ),
              ],
            ),
          );
        }

        // Show grid of courses
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = _calculateCrossAxisCount(
              constraints.maxWidth,
            );

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: width > 600 ? 0.9 : 0.8,
              ),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                return Coursecardview(
                  loading: loading,
                  courseName: doc['Course Name'].toString(),
                  coursePrice: doc['Course Price'].toString(),
                  courseImgLink: doc['Course Img Link'].toString(),
                  courseDiscription: doc['Course Discription'].toString(),
                  ontap: () {
                    setState(() {
                      loading = true;
                    });

                    // Navigate to course details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetails(
                          userRole: 'teacher',
                          coursename: doc['Course Name'].toString(),
                        ),
                      ),
                    ).then((_) {
                      setState(() {
                        loading = false;
                      });
                    }).catchError((error) {
                      setState(() {
                        loading = false;
                      });
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    searchFilterController.dispose();
    super.dispose();
  }
}
