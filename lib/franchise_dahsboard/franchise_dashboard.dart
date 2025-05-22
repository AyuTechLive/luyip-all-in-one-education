import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        return const FranchiseDashboardContent();
      case 'Franchise Centers':
        return const FranchiseCentersContent();
      case 'Teachers':
        return const FranchiseTeachersContent();
      case 'Students':
        return const FranchiseStudentsContent();
      case 'Courses':
        return const FranchiseCoursesContent();
      case 'Reports':
        return const FranchiseReportsContent();
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
        elevation: 0,
        title: Text(
          'Franchise Dashboard - $_currentPage',
          style: const TextStyle(fontWeight: FontWeight.w600),
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
        // Get franchise information
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

      // Query students added by this franchise
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
              _loadFranchiseStudents(); // Refresh the list
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
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
                        ),
                      ),
                      Text(
                        student['Email'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Student Details
            _buildDetailRow('Phone', student['Phone'] ?? 'Not provided'),
            _buildDetailRow('Date Joined', student['DOJ'] ?? 'Unknown'),
            _buildDetailRow('Added Date', student['AddedDate'] ?? 'Unknown'),
            _buildDetailRow('Role', student['Role'] ?? 'student'),

            // Membership Status
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Membership Active',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Courses
            const SizedBox(height: 16),
            Text(
              'Enrolled Courses:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              child: student['My Courses'] != null &&
                      (student['My Courses'] as List).isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: (student['My Courses'] as List).length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.book,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(student['My Courses'][index]),
                            ],
                          ),
                        );
                      },
                    )
                  : Text(
                      'No courses enrolled yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
            ),

            const SizedBox(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
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
                    'Students Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    franchiseName != null
                        ? 'Manage students for $franchiseName'
                        : 'Loading franchise information...',
                    style:
                        TextStyle(fontSize: 16, color: ColorManager.textMedium),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: franchiseName != null ? _addNewStudent : null,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Student'),
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

          // Stats Cards
          Row(
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
                  franchiseStudents.length
                      .toString(), // All franchise students have membership
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
          ),
          const SizedBox(height: 24),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students by name or email...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey[400]),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 24),

          // Students List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                    ),
                  )
                : filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: TextStyle(
              fontSize: 18,
              color: ColorManager.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try adjusting your search criteria'
                : 'Start by adding your first student',
            style: TextStyle(
              fontSize: 14,
              color: ColorManager.textMedium,
            ),
          ),
          if (searchQuery.isEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addNewStudent,
              icon: const Icon(Icons.person_add),
              label: const Text('Add First Student'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return Container(
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
      child: ListView.separated(
        itemCount: filteredStudents.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final student = filteredStudents[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
              child: student['ProfilePicURL'] != null
                  ? ClipOval(
                      child: Image.network(
                        student['ProfilePicURL'],
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: const Color(0xFF2E7D32),
                    ),
            ),
            title: Text(
              student['Name'] ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student['Email'] ?? ''),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Member',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Joined: ${student['DOJ'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(student['My Courses'] as List?)?.length ?? 0} Courses',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showStudentDetails(student),
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'View Details',
                ),
              ],
            ),
            onTap: () => _showStudentDetails(student),
          );
        },
      ),
    );
  }

  int _getThisMonthCount() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    return franchiseStudents.where((student) {
      final addedDate = student['AddedDate'] as String?;
      if (addedDate == null) return false;

      try {
        // Parse date format: "day-month-year"
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
}

class FranchiseCoursesContent extends StatelessWidget {
  const FranchiseCoursesContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Franchise Courses Content'));
  }
}

class FranchiseReportsContent extends StatelessWidget {
  const FranchiseReportsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Franchise Reports Content'));
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

  Map<String, dynamic> revenueData = {};
  bool isLoading = true;
  String? franchiseName;

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
          revenueData = franchiseData['revenue'] as Map<String, dynamic>? ?? {};
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading revenue data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  double get totalRevenue =>
      (revenueData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
  int get totalStudents => (revenueData['totalStudentsAdded'] as int?) ?? 0;
  List<dynamic> get recentTransactions =>
      revenueData['recentTransactions'] as List? ?? [];
  Map<String, dynamic> get monthlyRevenue =>
      revenueData['monthlyRevenue'] as Map<String, dynamic>? ?? {};

  double get currentMonthRevenue {
    DateTime now = DateTime.now();
    String monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return (monthlyRevenue[monthKey] as num?)?.toDouble() ?? 0.0;
  }

  double get previousMonthRevenue {
    DateTime lastMonth = DateTime.now().subtract(const Duration(days: 30));
    String monthKey =
        '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
    return (monthlyRevenue[monthKey] as num?)?.toDouble() ?? 0.0;
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
      double revenue = (monthlyRevenue[monthKey] as num?)?.toDouble() ?? 0.0;
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
            'Monthly Revenue Trend',
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
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        transaction['studentName'] ?? 'Unknown Student',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${transaction['studentEmail'] ?? ''}\n${_formatDate(transaction['date'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorManager.textMedium,
                        ),
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
                            'Commission',
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
                            'Total Revenue',
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
                            totalStudents.toString(),
                            Icons.people,
                            Colors.orange,
                            subtitle: 'Total lifetime',
                          ),
                        ),
                      ],
                    ),
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
