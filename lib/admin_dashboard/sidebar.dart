import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/Courses/addvideo.dart';
import 'package:luyip_website_edu/Courses/allcourses.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/add_internship.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/franchise_content.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/manage_test.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/payment_content.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/students.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/teachers.dart';
import 'package:luyip_website_edu/admin_dashboard/dummyadmin.dart';
import 'package:luyip_website_edu/admin_dashboard/payment_screen.dart';
import 'package:luyip_website_edu/auth/auth_service.dart';
import 'package:luyip_website_edu/auth/loginscreen.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/website/student_home_content.dart';

// Create a main dashboard container that will hold both sidebar and content
class AdminDashboardContainer extends StatefulWidget {
  const AdminDashboardContainer({Key? key, this.initialPage = 'Dashboard'})
      : super(key: key);

  final String initialPage;

  @override
  State<AdminDashboardContainer> createState() =>
      _AdminDashboardContainerState();
}

class _AdminDashboardContainerState extends State<AdminDashboardContainer> {
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
        return const DashboardContent();
      case 'Courses':
        return const AllCoursesScreen(userType: "admin");
      case 'Students':
        return const StudentsContent();
      case 'Teachers':
        return const TeachersContent();
      case 'Franchises': // Add this new case
        return const FranchisesContent();
      case 'Internship':
        return const AdminInternshipPage();
      case 'Assessments':
        return const AssessmentsContent();
      case 'Schedule':
        return const ScheduleContent();
      case 'Payments':
        return const PaymentsScreen();
      case 'Notifications':
        return const NotificationsContent();
      case 'Settings':
        return const WebsiteGeneralAdminPage();
      default:
        return const DashboardContent();
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
          'Luyip Admin Dashboard - $_currentPage',
          style:
              const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: ColorManager.primary,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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
            DashboardSidebar(
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

// Modified sidebar that takes a callback for page changes
class DashboardSidebar extends StatelessWidget {
  final String selectedPage;
  final Function(String) onPageChanged;

  const DashboardSidebar({
    Key? key,
    required this.selectedPage,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity, // Ensures it fills the entire height
      width: 250, // Keeps the fixed width for the sidebar
      child: Container(
        color: ColorManager.dark, // Using dark slate instead of pure black
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo area with dynamic logo from Firebase
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorManager.primary, ColorManager.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('website_general')
                    .doc('dashboard')
                    .get(),
                builder: (context, snapshot) {
                  String logoUrl = '';
                  String companyName = 'LUYIP';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final websiteContent =
                        data?['websiteContent'] as Map<String, dynamic>? ?? {};
                    logoUrl = websiteContent['logoUrl']?.toString() ?? '';
                    companyName = websiteContent['companyName']?.toString() ??
                        websiteContent['companyShortName']?.toString() ??
                        'LUYIP';
                  }

                  return Center(
                    child: logoUrl.isNotEmpty
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                logoUrl,
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    companyName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      letterSpacing: 1.5,
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  companyName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            companyName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              letterSpacing: 1.5,
                            ),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Admin profile section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ColorManager.primaryLight,
                    child: Text(
                      "A",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Admin User",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "System Administrator",
                        style: TextStyle(
                          color: ColorManager.light.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Color(0xFF3A4750), // Slightly lighter than dark
            ),
            const SizedBox(height: 16),

            // Menu section title
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "MAIN MENU",
                  style: TextStyle(
                    color: ColorManager.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Menu items with enhanced styling
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildSidebarItem(
                      context,
                      Icons.dashboard_outlined,
                      'Dashboard',
                      isActive: selectedPage == 'Dashboard',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.school_outlined,
                      'Courses',
                      isActive: selectedPage == 'Courses',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.people_outlined,
                      'Students',
                      isActive: selectedPage == 'Students',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.person_outlined,
                      'Teachers',
                      isActive: selectedPage == 'Teachers',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.store_outlined,
                      'Franchises',
                      isActive: selectedPage == 'Franchises',
                    ),

                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFF3A4750),
                    ),
                    const SizedBox(height: 16),

                    // Management section title
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "MANAGEMENT",
                          style: TextStyle(
                            color: ColorManager.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    _buildSidebarItem(
                      context,
                      Icons.library_books_outlined,
                      'Internship',
                      isActive: selectedPage == 'Internship',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.payment_outlined,
                      'Payments',
                      isActive: selectedPage == 'Payments',
                      badge: '5',
                    ),

                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFF3A4750),
                    ),
                    const SizedBox(height: 16),

                    // System section title
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "SYSTEM",
                          style: TextStyle(
                            color: ColorManager.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    _buildSidebarItem(
                      context,
                      Icons.notifications_outlined,
                      'Notifications',
                      isActive: selectedPage == 'Notifications',
                      badge: '12',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.settings_outlined,
                      'Settings',
                      isActive: selectedPage == 'Settings',
                    ),
                  ],
                ),
              ),
            ),

            // Footer with logout button
            Container(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  // Handle logout
                  _showLogoutConfirmationDialog(context);
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorManager.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout,
                        color: ColorManager.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String label, {
    bool isActive = false,
    String? badge,
  }) {
    return GestureDetector(
      onTap: () {
        // Use the callback to change the page instead of navigating
        onPageChanged(label);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? ColorManager.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isActive ? Colors.white : ColorManager.light.withOpacity(0.8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : ColorManager.light.withOpacity(0.8),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : ColorManager.secondary.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isActive ? ColorManager.primary : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ColorManager.textDark),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Call the logout method from AuthService
              AuthService().logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.error,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
