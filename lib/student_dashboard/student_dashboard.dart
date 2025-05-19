import 'package:flutter/material.dart';
import 'package:luyip_website_edu/Courses/allcourses.dart';
import 'package:luyip_website_edu/certificate/student_certificate_page.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/student_dashboard/membership_card.dart';
import 'package:luyip_website_edu/student_dashboard/sidebar_student.dart';

// Main container widget for the student dashboard
class StudentDashboardContainer extends StatefulWidget {
  const StudentDashboardContainer({Key? key, this.initialPage = 'Dashboard'})
      : super(key: key);

  final String initialPage;

  @override
  State<StudentDashboardContainer> createState() =>
      _StudentDashboardContainerState();
}

class _StudentDashboardContainerState extends State<StudentDashboardContainer> {
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
        return const StudentDashboardContent();
      case 'My Batches':
        return const AllCoursesScreen(userType: "student");
      case 'All Courses':
        return const AllCoursesScreen(userType: "student");
      case 'Certificates':
        return const CertificatesPage();
      case 'Take Membership':
        return const StudentIDCardScreen();
      case 'Schedule':
        return const StudentDashboardContent();
      case 'Assignments':
        return const StudentDashboardContent();
      case 'Library':
        return const StudentDashboardContent();
      case 'Messages':
        return const StudentDashboardContent();
      case 'Settings':
        return const StudentDashboardContent();
      default:
        return const StudentDashboardContent();
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
          'Luyip Student Portal - $_currentPage',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ColorManager.primary,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CircleAvatar(
              backgroundColor: ColorManager.primaryLight,
              child: IconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: ColorManager.primaryDark,
                ),
                onPressed: () {},
                tooltip: 'Profile',
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
            StudentSidebar(
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

class StudentDashboardContent extends StatelessWidget {
  const StudentDashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Sarah!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your learning journey continues. Here\'s what\'s new today.',
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorManager.textMedium,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Join Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
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
          const SizedBox(height: 32),

          // Quick action buttons
          Row(
            children: [
              _buildQuickActionButton(
                'Continue Learning',
                Icons.play_circle_outline,
                ColorManager.primary,
              ),
              const SizedBox(width: 16),
              _buildQuickActionButton(
                'View Assignments',
                Icons.assignment_outlined,
                ColorManager.warning,
              ),
              const SizedBox(width: 16),
              _buildQuickActionButton(
                'Join Live Class',
                Icons.videocam_outlined,
                ColorManager.error,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Current progress section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ColorManager.dark.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue Your Learning',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                _buildCourseProgressItem(
                  'Web Development with Flutter',
                  'Module 3: State Management',
                  0.68,
                  ColorManager.primary,
                ),
                const SizedBox(height: 16),
                _buildCourseProgressItem(
                  'Data Structures & Algorithms',
                  'Module 2: Linked Lists',
                  0.45,
                  ColorManager.secondary,
                ),
                const SizedBox(height: 16),
                _buildCourseProgressItem(
                  'UI/UX Design Fundamentals',
                  'Module 1: Wireframing',
                  0.25,
                  ColorManager.info,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Statistics and upcoming events layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics cards
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Enrolled Courses',
                              '5',
                              Icons.book_outlined,
                              ColorManager.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Completed',
                              '2',
                              Icons.check_circle_outline,
                              ColorManager.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Certificates',
                              '2',
                              Icons.card_membership_outlined,
                              ColorManager.warning,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Learning Hours',
                              '48',
                              Icons.access_time_outlined,
                              ColorManager.info,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Upcoming events
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upcoming Schedule',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: ColorManager.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _buildEventCard(
                              'Web Development',
                              'Live Class: Building Responsive UIs',
                              'Today, 3:00 PM',
                              ColorManager.primary,
                            ),
                            const SizedBox(height: 12),
                            _buildEventCard(
                              'Data Structures',
                              'Assignment Due: Linked List Implementation',
                              'Tomorrow, 11:59 PM',
                              ColorManager.error,
                            ),
                            const SizedBox(height: 12),
                            _buildEventCard(
                              'UI/UX Design',
                              'Group Project Discussion',
                              'March 19, 2:00 PM',
                              ColorManager.warning,
                            ),
                            const SizedBox(height: 12),
                            _buildEventCard(
                              'General',
                              'Career Counseling Session',
                              'March 20, 4:00 PM',
                              ColorManager.info,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color) {
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

  Widget _buildCourseProgressItem(
    String title,
    String subtitle,
    double progress,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorManager.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: ColorManager.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Continue'),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              Text(
                progress >= 0.5
                    ? 'Last accessed: Today'
                    : 'Last accessed: Yesterday',
                style: TextStyle(fontSize: 12, color: ColorManager.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorManager.dark.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ColorManager.textMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    String category,
    String title,
    String time,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: ColorManager.dark.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: ColorManager.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorManager.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
