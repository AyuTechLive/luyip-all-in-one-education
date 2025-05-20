import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_network/image_network.dart';
import 'package:luyip_website_edu/Courses/allcourses.dart';
import 'package:luyip_website_edu/Membership/membership_screen.dart';
import 'package:luyip_website_edu/Membership/membership_service.dart';
import 'package:luyip_website_edu/certificate/student_certificate_page.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/student_dashboard/dashboard_controller.dart';
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

class StudentDashboardContent extends StatefulWidget {
  const StudentDashboardContent({Key? key}) : super(key: key);

  @override
  State<StudentDashboardContent> createState() =>
      _StudentDashboardContentState();
}

class _StudentDashboardContentState extends State<StudentDashboardContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MembershipService _membershipService = MembershipService();
  final StudentDashboardController _dashboardController =
      StudentDashboardController();

  late Future<Map<String, dynamic>> _dashboardDataFuture;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _dashboardDataFuture = _fetchDashboardData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    return await _dashboardController.getAllDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: ColorManager.primary,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'Failed to load dashboard data. Please try again.',
              style: TextStyle(color: ColorManager.textMedium),
            ),
          );
        }

        final dashboardData = snapshot.data!;
        final userProfile =
            dashboardData['userProfile'] as Map<String, dynamic>;
        final enrolledCourses = dashboardData['enrolledCourses'] as List;
        final completedCourses = dashboardData['completedCourses'] as List;
        final testsTaken = dashboardData['testsTaken'] as List;
        final upcomingEvents = dashboardData['upcomingEvents'] as List;
        final announcements = dashboardData['announcements'] as List;
        final testimonials = dashboardData['testimonials'] as List;
        final isMember = dashboardData['isMember'] as bool;

        final String userName = userProfile['Name'] ?? 'Student';
        final String userCourse = userProfile['Role'] ?? 'Student';

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: _scrollController,
            children: [
              // Welcome section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $userName!',
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AllCoursesScreen(userType: "student"),
                        ),
                      );
                    },
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

              // Membership status card (if not a member)
              if (!isMember) _buildMembershipPromoCard(),
              if (!isMember) const SizedBox(height: 24),

              // Quick action buttons
              Row(
                children: [
                  _buildQuickActionButton(
                    'Continue Learning',
                    Icons.play_circle_outline,
                    ColorManager.primary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AllCoursesScreen(userType: "student"),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildQuickActionButton(
                    'View Assignments',
                    Icons.assignment_outlined,
                    ColorManager.warning,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AllCoursesScreen(userType: "student"),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildQuickActionButton(
                    'Join Live Class',
                    Icons.videocam_outlined,
                    ColorManager.error,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AllCoursesScreen(userType: "student"),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Current progress section
              if (enrolledCourses.isNotEmpty) ...[
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Continue Your Learning',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AllCoursesScreen(
                                      userType: "student"),
                                ),
                              );
                            },
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
                      const SizedBox(height: 20),
                      // Display the first 3 enrolled courses (or fewer if less than 3)
                      ...List.generate(
                        enrolledCourses.length > 3 ? 3 : enrolledCourses.length,
                        (index) {
                          final course = enrolledCourses[index];
                          final courseName =
                              course['Course Name'] ?? 'Unknown Course';
                          final courseDescription =
                              course['Course Discription'] ?? '';
                          final progress = course['progress'] as double;
                          final lastAccessed =
                              course['lastAccessed'] as DateTime?;
                          final color = [
                            ColorManager.primary,
                            ColorManager.secondary,
                            ColorManager.info,
                          ][index % 3];

                          String moduleText = 'In progress';
                          if (courseDescription.isNotEmpty) {
                            final words = courseDescription.split(' ');
                            moduleText = words.length > 5
                                ? 'Module: ${words.take(5).join(' ')}...'
                                : courseDescription;
                          }

                          return Column(
                            children: [
                              _buildCourseProgressItem(
                                courseName,
                                moduleText,
                                progress,
                                color,
                                lastAccessed,
                              ),
                              if (index <
                                  (enrolledCourses.length > 3
                                          ? 3
                                          : enrolledCourses.length) -
                                      1)
                                const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                      if (enrolledCourses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 48,
                                  color: ColorManager.textLight,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No courses enrolled yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ColorManager.textMedium,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Join a course to start your learning journey',
                                  style: TextStyle(
                                    color: ColorManager.textLight,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AllCoursesScreen(
                                                userType: "student"),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorManager.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Browse Courses'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Announcements section if available
              if (announcements.isNotEmpty) ...[
                _buildAnnouncementsSection(announcements),
                const SizedBox(height: 32),
              ],

              // Statistics and upcoming events layout
              Row(
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
                                '${enrolledCourses.length}',
                                Icons.book_outlined,
                                ColorManager.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Completed',
                                '${completedCourses.length}',
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
                                '${completedCourses.length}',
                                Icons.card_membership_outlined,
                                ColorManager.warning,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Tests Taken',
                                '${testsTaken.length}',
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AllCoursesScreen(
                                            userType: "student"),
                                  ),
                                );
                              },
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
                        Container(
                          height: 320,
                          child: upcomingEvents.isNotEmpty
                              ? ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: upcomingEvents.length > 4
                                      ? 4
                                      : upcomingEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = upcomingEvents[index];
                                    final String category =
                                        event['category'] ?? 'General';
                                    final String title =
                                        event['title'] ?? 'Event';
                                    final String time =
                                        event['time'] ?? 'Upcoming';
                                    final Color color =
                                        _getCategoryColor(category);

                                    return Column(
                                      children: [
                                        _buildEventCard(
                                          category,
                                          title,
                                          time,
                                          color,
                                        ),
                                        if (index < upcomingEvents.length - 1)
                                          const SizedBox(height: 12),
                                      ],
                                    );
                                  },
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_note,
                                        size: 48,
                                        color: ColorManager.textLight,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No upcoming events',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: ColorManager.textMedium,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Check back later for new events',
                                        style: TextStyle(
                                          color: ColorManager.textLight,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Testimonials section
              if (testimonials.isNotEmpty) ...[
                _buildTestimonialsSection(testimonials),
                const SizedBox(height: 32),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembershipPromoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorManager.secondary.withOpacity(0.9),
            ColorManager.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorManager.secondary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_membership,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock Premium Benefits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get discounts on courses, access to exclusive content, and more!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MembershipScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ColorManager.secondary,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            child: const Text(
              'JOIN NOW',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(List announcements) {
    return Container(
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
          Row(
            children: [
              Icon(
                Icons.campaign,
                color: ColorManager.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...announcements.take(3).map((announcement) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorManager.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorManager.primary.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        announcement['title'] ?? 'Announcement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        announcement['date'] ?? 'Recent',
                        style: TextStyle(
                          color: ColorManager.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    announcement['content'] ?? '',
                    style: TextStyle(
                      color: ColorManager.textMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(List testimonials) {
    return Container(
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
            'What Our Students Say',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: testimonials.length,
              itemBuilder: (context, index) {
                final testimonial = testimonials[index];
                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorManager.primary.withOpacity(0.05),
                        ColorManager.primary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ColorManager.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorManager.primary.withOpacity(0.1),
                            ),
                            child: testimonial['photoUrl'] != null &&
                                    testimonial['photoUrl'].isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: ImageNetwork(
                                      image: testimonial['photoUrl'],
                                      height: 50,
                                      width: 50,
                                      fitAndroidIos: BoxFit.cover,
                                      onLoading: Center(
                                        child: CircularProgressIndicator(
                                          color: ColorManager.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      onError: Icon(
                                        Icons.person,
                                        color: ColorManager.primary,
                                        size: 30,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: ColorManager.primary,
                                    size: 30,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testimonial['name'] ?? 'Student',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ColorManager.textDark,
                                ),
                              ),
                              Text(
                                testimonial['courseName'] ?? 'Student',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorManager.textMedium,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < (testimonial['rating'] ?? 5)
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Text(
                          testimonial['content'] ??
                              'Great learning experience!',
                          style: TextStyle(
                            color: ColorManager.textMedium,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: ColorManager.textDark,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
    DateTime? lastAccessed,
  ) {
    String lastAccessedText = 'Not started yet';
    if (lastAccessed != null) {
      final now = DateTime.now();
      final difference = now.difference(lastAccessed);

      if (difference.inHours < 24) {
        lastAccessedText = 'Last accessed: Today';
      } else if (difference.inDays == 1) {
        lastAccessedText = 'Last accessed: Yesterday';
      } else {
        lastAccessedText = 'Last accessed: ${difference.inDays} days ago';
      }
    }

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: ColorManager.textMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AllCoursesScreen(userType: "student"),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Continue'),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              Text(
                lastAccessedText,
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'web development':
        return ColorManager.primary;
      case 'data structures':
        return ColorManager.error;
      case 'ui/ux design':
        return ColorManager.warning;
      case 'general':
        return ColorManager.info;
      default:
        return ColorManager.secondary;
    }
  }
}
