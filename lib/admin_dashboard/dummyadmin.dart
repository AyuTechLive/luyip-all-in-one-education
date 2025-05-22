import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_dashboard_service.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/add_franchise.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/payment_content.dart';
import 'package:luyip_website_edu/admin_dashboard/payment_screen.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/add_student.dart';
import 'package:luyip_website_edu/Courses/addcourse.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/add_teachers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  bool _isLoading = true;
  String? _errorMessage;

  // Dashboard data
  Map<String, dynamic> _studentStats = {
    'total': 0,
    'graduate': 0,
    'undergraduate': 0
  };
  Map<String, dynamic> _teacherStats = {
    'total': 0,
    'fullTime': 0,
    'partTime': 0
  };
  Map<String, dynamic> _franchiseStats = {
    'total': 0,
    'active': 0,
    'inactive': 0,
    'pending': 0,
    'averageCommission': 0.0,
    'totalRevenue': 0.0
  };
  Map<String, dynamic> _courseStats = {'total': 0, 'online': 0, 'inPerson': 0};
  Map<String, dynamic> _assessmentStats = {
    'total': 0,
    'upcoming': 0,
    'completed': 0
  };
  Map<String, dynamic> _libraryStats = {
    'total': 0,
    'available': 0,
    'borrowed': 0
  };
  Map<String, dynamic> _revenueStats = {'total': 0, 'tuition': 0, 'other': 0};
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load all statistics in parallel for better performance
      final studentStatsResult = _dashboardService.getStudentsStats();
      final teacherStatsResult = _dashboardService.getTeachersStats();
      final courseStatsResult = _dashboardService.getCoursesStats();
      final assessmentStatsResult = _dashboardService.getAssessmentsStats();
      final libraryStatsResult = _dashboardService.getLibraryStats();
      final revenueStatsResult = _dashboardService.getRevenueStats();
      final franchiseStatsResult = _dashboardService.getFranchiseStats();
      final activitiesResult = _dashboardService.getRecentActivities();

      // Wait for all data to load
      final results = await Future.wait([
        studentStatsResult,
        teacherStatsResult,
        courseStatsResult,
        assessmentStatsResult,
        libraryStatsResult,
        revenueStatsResult,
        franchiseStatsResult,
        activitiesResult,
      ]);

      setState(() {
        _studentStats = results[0] as Map<String, dynamic>;
        _teacherStats = results[1] as Map<String, dynamic>;
        _courseStats = results[2] as Map<String, dynamic>;
        _assessmentStats = results[3] as Map<String, dynamic>;
        _libraryStats = results[4] as Map<String, dynamic>;
        _revenueStats = results[5] as Map<String, dynamic>;
        _franchiseStats = results[6] as Map<String, dynamic>;
        _recentActivities = results[7] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: ${error.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';

    double numValue =
        value is double ? value : double.tryParse(value.toString()) ?? 0;

    if (numValue >= 100000) {
      return '${(numValue / 100000).toStringAsFixed(2)}L';
    } else if (numValue >= 1000) {
      return '${(numValue / 1000).toStringAsFixed(1)}K';
    } else {
      return numValue.toStringAsFixed(0);
    }
  }

  String _getMonthlyEnrollments() {
    final int totalStudents = _studentStats['total'] ?? 0;
    if (totalStudents == 0) return '0';
    final int monthlyEstimate = (totalStudents * 0.1).round();
    return monthlyEstimate.toString();
  }

  String _getLastMonthEnrollments() {
    final int currentMonthEstimate =
        int.tryParse(_getMonthlyEnrollments()) ?? 0;
    final int lastMonthEstimate = (currentMonthEstimate * 0.85).round();
    return lastMonthEstimate.toString();
  }

  String _getEnrollmentGrowth() {
    final int currentMonth = int.tryParse(_getMonthlyEnrollments()) ?? 0;
    final int lastMonth = int.tryParse(_getLastMonthEnrollments()) ?? 0;

    if (lastMonth == 0) return '0%';

    final double growthRate = ((currentMonth - lastMonth) / lastMonth) * 100;
    return '${growthRate.toStringAsFixed(1)}%';
  }

  Color _getColorForActivity(String? colorName) {
    switch (colorName) {
      case 'primary':
        return ColorManager.primary;
      case 'secondary':
        return ColorManager.secondary;
      case 'info':
        return ColorManager.info;
      case 'warning':
        return ColorManager.warning;
      case 'success':
        return ColorManager.success;
      default:
        return ColorManager.primary;
    }
  }

  IconData _getIconForActivity(String? iconName) {
    switch (iconName) {
      case 'person_add_outlined':
        return Icons.person_add_outlined;
      case 'edit_note_outlined':
        return Icons.edit_note_outlined;
      case 'payment_outlined':
        return Icons.payment_outlined;
      case 'assignment_outlined':
        return Icons.assignment_outlined;
      case 'book_outlined':
        return Icons.book_outlined;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'card_membership':
        return Icons.card_membership;
      default:
        return Icons.event_note_outlined;
    }
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getColorForActivity(activity['iconColor'])
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForActivity(activity['icon']),
                        size: 24,
                        color: _getColorForActivity(activity['iconColor']),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] ?? 'Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          Text(
                            _dashboardService.getTimeAgo(activity['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorManager.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: ColorManager.textMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorManager.textMedium,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                if (activity['timestamp'] != null) ...[
                  Text(
                    'Timestamp',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(activity['timestamp']),
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorManager.textMedium,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(color: ColorManager.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Unknown';
      }
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: ColorManager.primary),
            const SizedBox(height: 16),
            Text(
              'Loading dashboard data...',
              style: TextStyle(
                color: ColorManager.textMedium,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Admin',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s what\'s happening with your institution today',
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
                        builder: (context) => AddCourse(
                          onCourseAdded: () {
                            _loadDashboardData();
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Course'),
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
            const SizedBox(height: 24),

            // Quick Action Buttons
            SizedBox(
              height: 80,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // _buildQuickActionButton(
                    //   'Add Student',
                    //   Icons.person_add_outlined,
                    //   ColorManager.info,
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => AddStudentPage(
                    //           onStudentAdded: () {
                    //             _loadDashboardData();
                    //           },
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                    const SizedBox(width: 16),
                    _buildQuickActionButton(
                      'Add Teacher',
                      Icons.school_outlined,
                      ColorManager.warning,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTeacherPage(
                              onTeacherAdded: () {
                                _loadDashboardData();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildQuickActionButton(
                      'View Payments',
                      Icons.payment_outlined,
                      ColorManager.success,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildQuickActionButton(
                      'Add Franchise',
                      Icons.store_outlined,
                      ColorManager.secondary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddFranchisePage(
                              onFranchiseAdded: () {
                                _loadDashboardData();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Main Content Area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Section (2/3 width)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Statistics Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          IconButton(
                            onPressed: _loadDashboardData,
                            icon: Icon(
                              Icons.refresh,
                              color: ColorManager.primary,
                            ),
                            tooltip: 'Refresh Data',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Statistics Grid with separate scrolling
                      SizedBox(
                        height: 600, // Fixed height for scrollable area
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.3,
                          ),
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            switch (index) {
                              case 0:
                                return _buildStatCard(
                                  'Total Students',
                                  _studentStats['total'].toString(),
                                  Icons.people_outlined,
                                  ColorManager.primary,
                                  [
                                    {
                                      'label': 'Graduate',
                                      'value':
                                          _studentStats['graduate'].toString()
                                    },
                                    {
                                      'label': 'Undergraduate',
                                      'value': _studentStats['undergraduate']
                                          .toString()
                                    },
                                  ],
                                );
                              case 1:
                                return _buildStatCard(
                                  'Active Courses',
                                  _courseStats['total'].toString(),
                                  Icons.school_outlined,
                                  ColorManager.secondary,
                                  [
                                    {
                                      'label': 'Online',
                                      'value': _courseStats['online'].toString()
                                    },
                                    {
                                      'label': 'In-person',
                                      'value':
                                          _courseStats['inPerson'].toString()
                                    },
                                  ],
                                );
                              case 2:
                                return _buildStatCard(
                                  'Teachers',
                                  _teacherStats['total'].toString(),
                                  Icons.person_outlined,
                                  ColorManager.info,
                                  [
                                    {
                                      'label': 'Full-time',
                                      'value':
                                          _teacherStats['fullTime'].toString()
                                    },
                                    {
                                      'label': 'Part-time',
                                      'value':
                                          _teacherStats['partTime'].toString()
                                    },
                                  ],
                                );
                              case 3:
                                return _buildStatCard(
                                  'Franchise Partners',
                                  _franchiseStats['total'].toString(),
                                  Icons.store_outlined,
                                  ColorManager.secondary,
                                  [
                                    {
                                      'label': 'Active',
                                      'value':
                                          _franchiseStats['active'].toString()
                                    },
                                    {
                                      'label': 'Pending',
                                      'value':
                                          _franchiseStats['pending'].toString()
                                    },
                                  ],
                                );
                              case 4:
                                return _buildStatCard(
                                  'Assessments',
                                  _assessmentStats['total'].toString(),
                                  Icons.assessment_outlined,
                                  ColorManager.warning,
                                  [
                                    {
                                      'label': 'Upcoming',
                                      'value': _assessmentStats['upcoming']
                                          .toString()
                                    },
                                    {
                                      'label': 'Completed',
                                      'value': _assessmentStats['completed']
                                          .toString()
                                    },
                                  ],
                                );
                              case 5:
                                return _buildStatCard(
                                  'Library Books',
                                  _libraryStats['total'].toString(),
                                  Icons.book_outlined,
                                  ColorManager.success,
                                  [
                                    {
                                      'label': 'Available',
                                      'value':
                                          _libraryStats['available'].toString()
                                    },
                                    {
                                      'label': 'Borrowed',
                                      'value':
                                          _libraryStats['borrowed'].toString()
                                    },
                                  ],
                                );
                              case 6:
                                return _buildStatCard(
                                  'Revenue (Monthly)',
                                  '₹${_formatCurrency(_revenueStats['total'])}',
                                  Icons.attach_money_outlined,
                                  ColorManager.secondaryDark,
                                  [
                                    {
                                      'label': 'Tuition',
                                      'value':
                                          '₹${_formatCurrency(_revenueStats['tuition'])}'
                                    },
                                    {
                                      'label': 'Membership',
                                      'value':
                                          '₹${_formatCurrency(_revenueStats['membership'] ?? 0)}'
                                    },
                                  ],
                                );
                              default:
                                return Container();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Recent Activities Section (1/3 width)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorManager.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ColorManager.dark.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Activities',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorManager.textDark,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // View all activities - could navigate to a dedicated page
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'View all activities feature coming soon!'),
                                      backgroundColor: ColorManager.info,
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
                        ),
                        SizedBox(
                          height: 600, // Fixed height matching stats section
                          child: _recentActivities.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inbox_outlined,
                                          size: 48,
                                          color: ColorManager.textLight,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No recent activities',
                                          style: TextStyle(
                                            color: ColorManager.textMedium,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Activities will appear here as they happen',
                                          style: TextStyle(
                                            color: ColorManager.textLight,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _recentActivities.length > 10
                                      ? 10
                                      : _recentActivities.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 20),
                                  itemBuilder: (context, index) {
                                    final activity = _recentActivities[index];
                                    return _buildActivityItem(
                                      activity['title'] ?? 'Activity',
                                      activity['description'] ??
                                          'No description',
                                      _dashboardService
                                          .getTimeAgo(activity['timestamp']),
                                      _getColorForActivity(
                                          activity['iconColor']),
                                      _getIconForActivity(activity['icon']),
                                      onTap: () =>
                                          _showActivityDetails(activity),
                                    );
                                  },
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
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color, {
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 200, // Fixed width for horizontal scrolling
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorManager.dark.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: ColorManager.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    List<Map<String, String>> details,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorManager.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorManager.dark.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ColorManager.textMedium,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 15),
          ...details.map((detail) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    detail['label'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorManager.textLight,
                    ),
                  ),
                  Text(
                    detail['value'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.textDark,
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

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String timeAgo,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ColorManager.light.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorManager.textMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: ColorManager.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: ColorManager.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder content widgets for other pages
class CoursesContent extends StatelessWidget {
  const CoursesContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage all your educational courses from this interface',
            style: TextStyle(fontSize: 16, color: ColorManager.textMedium),
          ),
          const SizedBox(height: 32),
          // Courses list would go here
          Expanded(
            child: Center(
              child: Text(
                'Courses content will be displayed here',
                style: TextStyle(fontSize: 18, color: ColorManager.textMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Similar content classes for other menu options

class LibraryContent extends StatelessWidget {
  const LibraryContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Library Content'));
  }
}

class AssessmentsContent extends StatelessWidget {
  const AssessmentsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Assessments Content'));
  }
}

class ScheduleContent extends StatelessWidget {
  const ScheduleContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Schedule Content'));
  }
}

class NotificationsContent extends StatelessWidget {
  const NotificationsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Notifications Content'));
  }
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Content'));
  }
}
