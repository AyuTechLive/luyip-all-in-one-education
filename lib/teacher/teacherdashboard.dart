import 'package:flutter/material.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/auth/auth_service.dart';
import 'package:luyip_website_edu/teacher/courses.dart';
import 'package:luyip_website_edu/teacher/enrolled_students.dart';
import 'package:luyip_website_edu/teacher/side_bar.dart';

// Main Teacher Dashboard Class
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key, this.initialPage = 'Dashboard'})
      : super(key: key);

  final String initialPage;

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late String _currentPage;
  late Widget _currentContent;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _currentContent = _getContentForPage(_currentPage);
  }

  Widget _getContentForPage(String pageName) {
    // Return the appropriate content widget based on page name
    switch (pageName) {
      case 'Dashboard':
        return const TeacherDashboardContent();
      case 'My Courses':
        return const TeacherCoursesContent();
      case 'Students':
        return const TeacherStudentsContent();
      case 'Assignments':
        return const TeacherAssignmentsContent();
      case 'Attendance':
        return const TeacherAttendanceContent();
      case 'Grades':
        return const TeacherGradesContent();
      case 'Calendar':
        return const TeacherCalendarContent();
      case 'Resources':
        return const TeacherResourcesContent();
      case 'Messages':
        return const TeacherMessagesContent();
      case 'Profile':
        return const TeacherProfileContent();
      case 'Settings':
        return const TeacherSettingsContent();
      default:
        return const TeacherDashboardContent();
    }
  }

  void _changePage(String pageName) {
    setState(() {
      _currentPage = pageName;
      _currentContent = _getContentForPage(pageName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Teacher Dashboard - $_currentPage',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF5E4DCD),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CircleAvatar(
              backgroundColor: ColorManager.secondaryLight,
              child: IconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: ColorManager.secondaryDark,
                ),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: ColorManager.background,
        child: Row(
          children: [
            // Pass the current page and page change callback to sidebar
            TeacherDashboardSidebar(
              selectedPage: _currentPage,
              onPageChanged: _changePage,
            ),

            // Dynamic content area based on selected page
            Expanded(child: _currentContent),
          ],
        ),
      ),
    );
  }
}

// Teacher Dashboard Sidebar

// Dashboard Content Widget
class TeacherDashboardContent extends StatelessWidget {
  const TeacherDashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Teacher',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here\'s an overview of your teaching activities',
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorManager.textMedium,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Add new content
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Content'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.secondary,
                  foregroundColor: Colors.white,
                  elevation: 2,
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
          const SizedBox(height: 24),

          // Quick action buttons
          Row(
            children: [
              _buildQuickActionButton(
                'Take Attendance',
                Icons.fact_check_outlined,
                ColorManager.info,
              ),
              const SizedBox(width: 16),
              _buildQuickActionButton(
                'Grade Assignments',
                Icons.grading_outlined,
                ColorManager.warning,
              ),
              const SizedBox(width: 16),
              _buildQuickActionButton(
                'Schedule Class',
                Icons.event_outlined,
                ColorManager.success,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Dashboard content - just placeholders
          Expanded(
            child: Center(
              child: Text(
                'Teacher Dashboard Content',
                style: TextStyle(
                  fontSize: 24,
                  color: ColorManager.textMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: ColorManager.dark.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          label: Text(
            label,
            style: TextStyle(
              color: ColorManager.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder content widgets for other pages

class TeacherAssignmentsContent extends StatelessWidget {
  const TeacherAssignmentsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assignments',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create and manage assignments for your courses',
            style: TextStyle(fontSize: 16, color: ColorManager.textMedium),
          ),
          const SizedBox(height: 32),
          // Assignments list placeholder
          Expanded(
            child: Center(
              child: Text(
                'Assignments will be displayed here',
                style: TextStyle(fontSize: 18, color: ColorManager.textMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherAttendanceContent extends StatelessWidget {
  const TeacherAttendanceContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Attendance Content'));
  }
}

class TeacherGradesContent extends StatelessWidget {
  const TeacherGradesContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Grades Content'));
  }
}

class TeacherCalendarContent extends StatelessWidget {
  const TeacherCalendarContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Calendar Content'));
  }
}

class TeacherResourcesContent extends StatelessWidget {
  const TeacherResourcesContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Resources Content'));
  }
}

class TeacherMessagesContent extends StatelessWidget {
  const TeacherMessagesContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Messages Content'));
  }
}

class TeacherProfileContent extends StatelessWidget {
  const TeacherProfileContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile Content'));
  }
}

class TeacherSettingsContent extends StatelessWidget {
  const TeacherSettingsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Content'));
  }
}
