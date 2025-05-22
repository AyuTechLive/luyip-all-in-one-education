import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class TeacherStudentsContent extends StatefulWidget {
  const TeacherStudentsContent({Key? key}) : super(key: key);

  @override
  State<TeacherStudentsContent> createState() => _TeacherStudentsContentState();
}

class _TeacherStudentsContentState extends State<TeacherStudentsContent> {
  final searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _teacherCourses = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  String _selectedCourse = 'All Courses';

  @override
  void initState() {
    super.initState();
    _fetchTeacherCoursesAndStudents();
  }

  Future<void> _fetchTeacherCoursesAndStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current teacher's email
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final String teacherEmail = currentUser.email ?? '';

      // Find the teacher document
      final QuerySnapshot teacherSnapshot = await _firestore
          .collection('Users')
          .doc('teacher')
          .collection('accounts')
          .where('Email', isEqualTo: teacherEmail)
          .limit(1)
          .get();

      if (teacherSnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Teacher profile not found';
          _isLoading = false;
        });
        return;
      }

      // Get teacher's assigned courses
      final Map<String, dynamic> teacherData =
          teacherSnapshot.docs.first.data() as Map<String, dynamic>;

      final List<dynamic> assignedCourses = teacherData['My Courses'] ?? [];

      if (assignedCourses.isEmpty) {
        setState(() {
          _errorMessage = 'No courses assigned to this teacher';
          _isLoading = false;
        });
        return;
      }

      // Get details of all assigned courses
      List<Map<String, dynamic>> courseDetails = [];

      for (String courseName in assignedCourses) {
        final DocumentSnapshot courseDoc =
            await _firestore.collection('All Courses').doc(courseName).get();

        if (courseDoc.exists) {
          Map<String, dynamic> course =
              courseDoc.data() as Map<String, dynamic>;
          course['Course Name'] = courseName;
          courseDetails.add(course);
        }
      }

      _teacherCourses = courseDetails;

      // Get all students
      final QuerySnapshot studentsSnapshot = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .get();

      List<Map<String, dynamic>> allStudents = [];

      for (var doc in studentsSnapshot.docs) {
        Map<String, dynamic> student = doc.data() as Map<String, dynamic>;

        // Check if student is enrolled in any of the teacher's courses
        List<dynamic> studentCourses = student['My Courses'] ?? [];

        // Create a new field to track which of the teacher's courses this student is enrolled in
        List<String> enrolledInTeacherCourses = [];

        for (String courseName in assignedCourses) {
          if (studentCourses.contains(courseName)) {
            enrolledInTeacherCourses.add(courseName);
          }
        }

        // Only add students who are enrolled in at least one of the teacher's courses
        if (enrolledInTeacherCourses.isNotEmpty) {
          student['EnrolledInTeacherCourses'] = enrolledInTeacherCourses;
          allStudents.add(student);
        }
      }

      setState(() {
        _students = allStudents;
        _filteredStudents = allStudents;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load data: ${error.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    final String searchText = searchController.text.toLowerCase();

    setState(() {
      if (_selectedCourse == 'All Courses') {
        // Filter only by search text
        _filteredStudents = _students.where((student) {
          final String name = student['Name']?.toString().toLowerCase() ?? '';
          final String email = student['Email']?.toString().toLowerCase() ?? '';

          return name.contains(searchText) || email.contains(searchText);
        }).toList();
      } else {
        // Filter by selected course and search text
        _filteredStudents = _students.where((student) {
          // First check if student is enrolled in the selected course
          List<dynamic> enrolledCourses =
              student['EnrolledInTeacherCourses'] ?? [];
          bool isInSelectedCourse = enrolledCourses.contains(_selectedCourse);

          if (!isInSelectedCourse) return false;

          // Then check search text
          if (searchText.isEmpty) return true;

          final String name = student['Name']?.toString().toLowerCase() ?? '';
          final String email = student['Email']?.toString().toLowerCase() ?? '';

          return name.contains(searchText) || email.contains(searchText);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'My Students',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage students enrolled in your courses',
            style: TextStyle(fontSize: 16, color: ColorManager.textMedium),
          ),
          const SizedBox(height: 16),

          // Search and filter controls
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search students by name or email...',
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF5E4DCD)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    _filterStudents();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildCourseDropdown(),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                color: const Color(0xFF5E4DCD),
                onPressed: _fetchTeacherCoursesAndStudents,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Student count display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5E4DCD).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, color: Color(0xFF5E4DCD)),
                const SizedBox(width: 8),
                Text(
                  'Showing ${_filteredStudents.length} of ${_students.length} students',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5E4DCD),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Students list
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown() {
    List<String> courseOptions = ['All Courses'];

    for (var course in _teacherCourses) {
      courseOptions.add(course['Course Name'] ?? '');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCourse,
          isExpanded: true,
          icon: const Icon(Icons.filter_list),
          hint: const Text('Filter by Course'),
          items: courseOptions.map((String courseName) {
            return DropdownMenuItem<String>(
              value: courseName,
              child: Text(
                courseName,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCourse = newValue;
              });
              _filterStudents();
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5E4DCD),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 16,
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
              onPressed: _fetchTeacherCoursesAndStudents,
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.grey.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              'No students found in your courses',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You currently have no students enrolled in your courses',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.grey.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              'No students match your filter criteria',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              onPressed: () {
                searchController.clear();
                setState(() {
                  _selectedCourse = 'All Courses';
                  _filteredStudents = _students;
                });
              },
            ),
          ],
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 80,
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: MaterialStateProperty.all(
                        const Color(0xFF5E4DCD).withOpacity(0.1),
                      ),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5E4DCD),
                      ),
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 64,
                      columns: const [
                        DataColumn(label: Text('Profile')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Enrolled Courses')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredStudents.map((student) {
                        // Get the teacher's courses this student is enrolled in
                        List<dynamic> enrolledCourses =
                            student['EnrolledInTeacherCourses'] ?? [];

                        return DataRow(
                          cells: [
                            DataCell(
                              CircleAvatar(
                                backgroundImage:
                                    student['ProfilePicURL'] != null
                                        ? NetworkImage(student['ProfilePicURL'])
                                        : null,
                                child: student['ProfilePicURL'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                            ),
                            DataCell(Text(student['Name'] ?? 'N/A')),
                            DataCell(Text(student['Email'] ?? 'N/A')),
                            DataCell(
                              enrolledCourses.isEmpty
                                  ? const Text('None')
                                  : Wrap(
                                      spacing: 4,
                                      children:
                                          enrolledCourses.map<Widget>((course) {
                                        return Chip(
                                          label: Text(
                                            course.toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor:
                                              const Color(0xFF5E4DCD),
                                          padding: const EdgeInsets.all(4),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Color(0xFF5E4DCD),
                                    ),
                                    tooltip: 'View Details',
                                    onPressed: () {
                                      _showStudentDetails(context, student);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.grade_outlined,
                                      color: Colors.amber,
                                    ),
                                    tooltip: 'Manage Grades',
                                    onPressed: () {
                                      // Implement grade management
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.message_outlined,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Message Student',
                                    onPressed: () {
                                      // Implement messaging functionality
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
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> student) {
    // Get the teacher's courses this student is enrolled in
    List<dynamic> enrolledCourses = student['EnrolledInTeacherCourses'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF5E4DCD)),
            const SizedBox(width: 8),
            Text(
              'Student Details',
              style: TextStyle(color: const Color(0xFF5E4DCD)),
            ),
          ],
        ),
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
                    backgroundImage: student['ProfilePicURL'] != null
                        ? NetworkImage(student['ProfilePicURL'])
                        : null,
                    child: student['ProfilePicURL'] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Name', student['Name'] ?? 'N/A'),
                _buildDetailRow('Email', student['Email'] ?? 'N/A'),
                _buildDetailRow('Joined Date', student['DOJ'] ?? 'N/A'),
                const SizedBox(height: 16),
                const Text(
                  'Enrolled in Your Courses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF5E4DCD),
                  ),
                ),
                const SizedBox(height: 8),
                ...enrolledCourses.map((course) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.book, color: Color(0xFF5E4DCD)),
                      title: Text(course.toString()),
                      dense: true,
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                _buildDetailSection('Performance', [
                  _buildDetailRow(
                      'Attendance', '${(student['Attendance'] ?? 75)}%'),
                  _buildDetailRow('Assignments',
                      '${(student['CompletedAssignments'] ?? 5)}/${(student['TotalAssignments'] ?? 10)}'),
                  _buildDetailRow('Average Grade',
                      student['AverageGrade'] ?? 'Not Available'),
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('Contact Information', [
                  _buildDetailRow('Phone', student['Phone'] ?? 'Not Available'),
                  _buildDetailRow(
                      'Address', student['Address'] ?? 'Not Available'),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.message),
            label: const Text('Message'),
            onPressed: () {
              // Implement messaging functionality
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E4DCD),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF5E4DCD),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
