import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luyip_website_edu/Courses/allcourses.dart';
import 'package:luyip_website_edu/Courses/transaction_service.dart';
import 'package:luyip_website_edu/franchise_dahsboard/add_student.dart';
import 'package:luyip_website_edu/franchise_dahsboard/side_bar.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/auth/auth_service.dart';

// Main Franchise Dashboard Class
class FranchiseDashboard extends StatefulWidget {
  const FranchiseDashboard({Key? key, this.initialPage = 'Dashboard'})
      : super(key: key);

  final String initialPage;

  @override
  State<FranchiseDashboard> createState() => _FranchiseDashboardState();
}

class _FranchiseDashboardState extends State<FranchiseDashboard> {
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
        return const FranchiseRevenueContent();
      case 'Franchise Centers':
        return const FranchiseCentersContent();
      case 'Teachers':
        return const FranchiseTeachersContent();
      case 'Students':
        return const FranchiseStudentsContent();
      case 'Courses':
        return const AllCoursesScreen(userType: 'franchise');
      case 'Reports':
        return const FranchiseStudentsContent();
      case 'Revenue':
        return const FranchiseRevenueContent();
      case 'Marketing':
        return const FranchiseMarketingContent();
      case 'Analytics':
        return const FranchiseAnalyticsContent();
      case 'Support':
        return const FranchiseSupportContent();
      case 'Profile':
        return const FranchiseProfileContent();
      case 'Settings':
        return const FranchiseSettingsContent();
      default:
        return const FranchiseDashboardContent();
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
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          'Franchise Dashboard - $_currentPage',
          style:
              const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32), // Green theme for franchise
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
            FranchiseDashboardSidebar(
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

// Dashboard Content Widget
class FranchiseDashboardContent extends StatelessWidget {
  const FranchiseDashboardContent({Key? key}) : super(key: key);

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
                    'Welcome, Franchise Partner',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your franchise centers and business operations',
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorManager.textMedium,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Add new center
                },
                icon: const Icon(Icons.add_business),
                label: const Text('Add Center'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
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
                'View Centers',
                Icons.business_outlined,
                const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 16),
              _buildQuickActionButton(
                'Monthly Reports',
                Icons.analytics_outlined,
                ColorManager.info,
              ),
              const SizedBox(width: 16),
              _buildQuickActionButton(
                'Revenue Analytics',
                Icons.trending_up_outlined,
                ColorManager.warning,
              ),
              const SizedBox(width: 16),
              _buildQuickActionButton(
                'Support Tickets',
                Icons.support_agent_outlined,
                ColorManager.error,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Dashboard content - just placeholders
          Expanded(
            child: Center(
              child: Text(
                'Franchise Dashboard Content',
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

class FranchiseCentersContent extends StatelessWidget {
  const FranchiseCentersContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Franchise Centers',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage all your franchise centers and their operations',
            style: TextStyle(fontSize: 16, color: ColorManager.textMedium),
          ),
          const SizedBox(height: 32),
          // Centers list placeholder
          Expanded(
            child: Center(
              child: Text(
                'Franchise centers will be displayed here',
                style: TextStyle(fontSize: 18, color: ColorManager.textMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FranchiseTeachersContent extends StatelessWidget {
  const FranchiseTeachersContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teachers Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage teachers across all your franchise centers',
            style: TextStyle(fontSize: 16, color: ColorManager.textMedium),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Text(
                'Teachers management will be displayed here',
                style: TextStyle(fontSize: 18, color: ColorManager.textMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FranchiseStudentsContent extends StatefulWidget {
  const FranchiseStudentsContent({Key? key}) : super(key: key);

  @override
  State<FranchiseStudentsContent> createState() =>
      _FranchiseStudentsContentState();
}

class _FranchiseStudentsContentState extends State<FranchiseStudentsContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? franchiseName;
  List<Map<String, dynamic>> franchiseStudents = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFranchiseInfo();
  }

  Future<void> _loadFranchiseInfo() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot franchiseDoc = await _firestore
            .collection('Users')
            .doc('franchise')
            .collection('accounts')
            .doc(currentUser.email)
            .get();

        if (franchiseDoc.exists) {
          Map<String, dynamic> franchiseData =
              franchiseDoc.data() as Map<String, dynamic>;
          setState(() {
            franchiseName = franchiseData['Name'] ?? 'Unknown Franchise';
          });
          await _loadFranchiseStudents();
        }
      }
    } catch (e) {
      print('Error loading franchise info: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFranchiseStudents() async {
    try {
      setState(() {
        isLoading = true;
      });

      QuerySnapshot studentSnapshot = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .where('AddedBy', isEqualTo: 'franchise')
          .where('FranchiseName', isEqualTo: franchiseName)
          .get();

      List<Map<String, dynamic>> students = [];
      for (var doc in studentSnapshot.docs) {
        Map<String, dynamic> studentData = doc.data() as Map<String, dynamic>;
        studentData['docId'] = doc.id;
        students.add(studentData);
      }

      setState(() {
        franchiseStudents = students;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading franchise students: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addNewStudent() {
    if (franchiseName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FranchiseAddStudentPage(
            franchiseName: franchiseName!,
            onStudentAdded: () {
              _loadFranchiseStudents();
            },
          ),
        ),
      );
    }
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => _buildStudentDetailsDialog(student),
    );
  }

  Widget _buildStudentDetailsDialog(Map<String, dynamic> student) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32),
                    const Color(0xFF388E3C),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade100,
                      child: student['ProfilePicURL'] != null
                          ? ClipOval(
                              child: Image.network(
                                student['ProfilePicURL'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 30,
                              color: const Color(0xFF2E7D32),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['Name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student['Email'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Details
                    _buildDetailRow(
                        'Phone', student['Phone'] ?? 'Not provided'),
                    _buildDetailRow('Date Joined', student['DOJ'] ?? 'Unknown'),
                    _buildDetailRow(
                        'Added Date', student['AddedDate'] ?? 'Unknown'),
                    _buildDetailRow('Role', student['Role'] ?? 'student'),

                    const SizedBox(height: 20),

                    // Membership Status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.1),
                            Colors.green.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Active Membership',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Courses Section
                    Text(
                      'Enrolled Courses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (student['My Courses'] != null &&
                        (student['My Courses'] as List).isNotEmpty)
                      ...((student['My Courses'] as List)
                          .map(
                            (course) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.book,
                                      size: 20, color: Colors.blue[600]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      course.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList())
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No courses enrolled yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get filteredStudents {
    if (searchQuery.isEmpty) {
      return franchiseStudents;
    }
    return franchiseStudents.where((student) {
      final name = (student['Name'] ?? '').toLowerCase();
      final email = (student['Email'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  int _getThisMonthCount() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    return franchiseStudents.where((student) {
      final addedDate = student['AddedDate'] as String?;
      if (addedDate == null) return false;

      try {
        final parts = addedDate.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);

          return month == currentMonth && year == currentYear;
        }
      } catch (e) {
        print('Error parsing date: $addedDate');
      }
      return false;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(),

                const SizedBox(height: 32),

                // Stats Cards
                _buildStatsSection(),

                const SizedBox(height: 32),

                // Search Bar
                _buildSearchBar(),

                const SizedBox(height: 24),

                // Students Section
                _buildStudentsSection(),

                const SizedBox(height: 32), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF388E3C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Students Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  franchiseName != null
                      ? 'Manage students for $franchiseName'
                      : 'Loading franchise information...',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: franchiseName != null ? _addNewStudent : null,
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text(
                'Add Student',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2E7D32),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Students',
            franchiseStudents.length.toString(),
            Icons.people,
            const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Memberships',
            franchiseStudents.length.toString(),
            Icons.verified,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'This Month',
            _getThisMonthCount().toString(),
            Icons.calendar_today,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search students by name or email...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey[400], size: 24),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStudentsSection() {
    if (isLoading) {
      return Container(
        height: 400,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    if (filteredStudents.isEmpty) {
      return _buildEmptyState();
    }

    return _buildStudentsList();
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'Start by adding your first student',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            if (searchQuery.isEmpty) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _addNewStudent,
                icon: const Icon(Icons.person_add),
                label: const Text('Add First Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students (${filteredStudents.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (filteredStudents.length > 0)
                  Text(
                    'Showing ${filteredStudents.length} student${filteredStudents.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredStudents.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade100,
            ),
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              return _buildStudentTile(student);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student) {
    return InkWell(
      onTap: () => _showStudentDetails(student),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                child: student['ProfilePicURL'] != null
                    ? ClipOval(
                        child: Image.network(
                          student['ProfilePicURL'],
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: const Color(0xFF2E7D32),
                        size: 24,
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['Name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student['Email'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Member',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Joined: ${student['DOJ'] ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right side info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(student['My Courses'] as List?)?.length ?? 0} Course${(student['My Courses'] as List?)?.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FranchiseRevenueContent extends StatefulWidget {
  const FranchiseRevenueContent({Key? key}) : super(key: key);

  @override
  State<FranchiseRevenueContent> createState() =>
      _FranchiseRevenueContentState();
}

class _FranchiseRevenueContentState extends State<FranchiseRevenueContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TransactionService _transactionService = TransactionService();

  String? franchiseName;
  String? franchiseEmail;
  bool isLoading = true;

  // Revenue data from FranchiseCommissions
  List<Map<String, dynamic>> allCommissions = [];
  double totalRevenue = 0.0;
  int totalStudentsAdded = 0;
  Map<String, double> monthlyRevenue = {};
  List<Map<String, dynamic>> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    try {
      setState(() {
        isLoading = true;
      });

      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        franchiseEmail = currentUser.email;

        // Get franchise basic info
        DocumentSnapshot franchiseDoc = await _firestore
            .collection('Users')
            .doc('franchise')
            .collection('accounts')
            .doc(currentUser.email)
            .get();

        if (franchiseDoc.exists) {
          Map<String, dynamic> franchiseData =
              franchiseDoc.data() as Map<String, dynamic>;
          franchiseName = franchiseData['Name'] ?? 'Unknown Franchise';
        }

        // Fetch all commissions for this franchise
        await _fetchCommissionData();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading revenue data: $e');
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error loading revenue data: $e');
    }
  }

  Future<void> _fetchCommissionData() async {
    try {
      if (franchiseEmail == null) return;

      // Get all commissions for this franchise email
      List<Map<String, dynamic>> commissions = await _transactionService
          .getFranchiseCommissionsByEmail(franchiseEmail!);

      setState(() {
        allCommissions = commissions;
      });

      // Process the commission data
      _processCommissionData();
    } catch (e) {
      print('Error fetching commission data: $e');
      throw Exception('Failed to fetch commission data: $e');
    }
  }

  void _processCommissionData() {
    // Reset counters
    totalRevenue = 0.0;
    totalStudentsAdded = 0;
    monthlyRevenue.clear();
    recentTransactions.clear();

    // Process each commission
    for (var commission in allCommissions) {
      // Add to total revenue
      double amount =
          (commission['commissionAmount'] as num?)?.toDouble() ?? 0.0;
      totalRevenue += amount;

      // Count students (only for membership type)
      if (commission['type'] == 'membership') {
        totalStudentsAdded++;
      }

      // Process monthly revenue
      if (commission['timestamp'] != null) {
        DateTime date = (commission['timestamp'] as Timestamp).toDate();
        String monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';

        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0.0) + amount;
      }

      // Add to recent transactions (we'll limit this later)
      recentTransactions.add({
        'transactionId': commission['transactionId'],
        'amount': amount,
        'type': '${commission['type']}_commission',
        'studentEmail': commission['studentEmail'],
        'studentName': _getStudentNameFromEmail(commission['studentEmail']),
        'date': commission['timestamp'],
        'courseName': commission['courseName'], // For course commissions
      });
    }

    // Sort recent transactions by date (newest first) and limit to 10
    recentTransactions.sort((a, b) {
      if (a['date'] == null && b['date'] == null) return 0;
      if (a['date'] == null) return 1;
      if (b['date'] == null) return -1;
      return (b['date'] as Timestamp).compareTo(a['date'] as Timestamp);
    });

    if (recentTransactions.length > 10) {
      recentTransactions = recentTransactions.take(10).toList();
    }

    print('Processed commission data:');
    print('Total Revenue: ₹$totalRevenue');
    print('Total Students: $totalStudentsAdded');
    print('Recent Transactions: ${recentTransactions.length}');
  }

  String _getStudentNameFromEmail(String email) {
    // You could fetch this from Firestore if needed, but for now return email
    // Extract name part from email as fallback
    return email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Get current month revenue
  double get currentMonthRevenue {
    DateTime now = DateTime.now();
    String monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return monthlyRevenue[monthKey] ?? 0.0;
  }

  // Get previous month revenue
  double get previousMonthRevenue {
    DateTime lastMonth = DateTime.now().subtract(const Duration(days: 30));
    String monthKey =
        '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
    return monthlyRevenue[monthKey] ?? 0.0;
  }

  // Calculate average commission per student
  double get averageCommissionPerStudent {
    if (totalStudentsAdded == 0) return 0.0;
    return totalRevenue / totalStudentsAdded;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_IN');
    return '₹${formatter.format(amount)}';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  Widget _buildRevenueCard(
      String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: ColorManager.textMedium,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: ColorManager.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    // Get last 6 months data
    List<MapEntry<String, double>> chartData = [];
    DateTime now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      String monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      double revenue = monthlyRevenue[monthKey] ?? 0.0;
      chartData.add(MapEntry(DateFormat('MMM').format(month), revenue));
    }

    double maxRevenue = chartData.isEmpty
        ? 1000
        : chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxRevenue == 0) maxRevenue = 1000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Commission Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: chartData.map((entry) {
                double heightRatio = entry.value / maxRevenue;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 40,
                      height: 150 * heightRatio,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorManager.textMedium,
                      ),
                    ),
                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: ColorManager.textMedium,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Commission Earnings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 20),
          recentTransactions.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No recent transactions',
                        style: TextStyle(
                          color: ColorManager.textMedium,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final transaction = recentTransactions[index];
                    bool isMembership = transaction['type']
                            ?.toString()
                            .contains('membership') ??
                        false;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMembership
                              ? Colors.green.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isMembership ? Icons.card_membership : Icons.book,
                          color: isMembership
                              ? Colors.green[700]
                              : Colors.blue[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        transaction['studentName'] ??
                            transaction['studentEmail'] ??
                            'Unknown Student',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction['studentEmail'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorManager.textMedium,
                            ),
                          ),
                          if (transaction['courseName'] != null)
                            Text(
                              'Course: ${transaction['courseName']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            _formatDate(transaction['date']),
                            style: TextStyle(
                              fontSize: 10,
                              color: ColorManager.textMedium,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${_formatCurrency((transaction['amount'] as num).toDouble())}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            isMembership ? 'Membership' : 'Course',
                            style: TextStyle(
                              fontSize: 10,
                              color: ColorManager.textMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildRevenueInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average per Student',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorManager.textMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(averageCommissionPerStudent),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Growth Rate',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorManager.textMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          currentMonthRevenue > previousMonthRevenue
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: currentMonthRevenue > previousMonthRevenue
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          previousMonthRevenue > 0
                              ? '${(((currentMonthRevenue - previousMonthRevenue) / previousMonthRevenue) * 100).toStringAsFixed(1)}%'
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: currentMonthRevenue > previousMonthRevenue
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Commission breakdown
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membership Commissions',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorManager.textMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allCommissions
                          .where((c) => c['type'] == 'membership')
                          .length
                          .toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Commissions',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorManager.textMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allCommissions
                          .where((c) => c['type'] == 'course')
                          .length
                          .toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    franchiseName != null
                        ? 'Commission earnings for $franchiseName'
                        : 'Loading franchise information...',
                    style:
                        TextStyle(fontSize: 16, color: ColorManager.textMedium),
                  ),
                  if (franchiseEmail != null)
                    Text(
                      'Email: $franchiseEmail',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorManager.textMedium,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadRevenueData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Revenue Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildRevenueCard(
                            'Total Commission',
                            _formatCurrency(totalRevenue),
                            Icons.account_balance_wallet,
                            const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildRevenueCard(
                            'This Month',
                            _formatCurrency(currentMonthRevenue),
                            Icons.calendar_today,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildRevenueCard(
                            'Students Added',
                            totalStudentsAdded.toString(),
                            Icons.people,
                            Colors.orange,
                            subtitle: 'Membership students',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Revenue Insights
                    _buildRevenueInsights(),
                    const SizedBox(height: 24),

                    // Charts and Transactions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildMonthlyChart(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildRecentTransactions(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FranchiseMarketingContent extends StatelessWidget {
  const FranchiseMarketingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Franchise Marketing Content'));
  }
}

class FranchiseAnalyticsContent extends StatelessWidget {
  const FranchiseAnalyticsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Franchise Analytics Content'));
  }
}

class FranchiseSupportContent extends StatelessWidget {
  const FranchiseSupportContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Franchise Support Content'));
  }
}

class FranchiseProfileContent extends StatelessWidget {
  const FranchiseProfileContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Franchise Profile Content'));
  }
}

class FranchiseSettingsContent extends StatelessWidget {
  const FranchiseSettingsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Franchise Settings Content'));
  }
}
