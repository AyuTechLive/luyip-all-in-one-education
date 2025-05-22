import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/auth/auth_service.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class TeacherDashboardSidebar extends StatefulWidget {
  final String selectedPage;
  final Function(String) onPageChanged;

  const TeacherDashboardSidebar({
    Key? key,
    required this.selectedPage,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  State<TeacherDashboardSidebar> createState() =>
      _TeacherDashboardSidebarState();
}

class _TeacherDashboardSidebarState extends State<TeacherDashboardSidebar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _teacherName = "Teacher";
  String _teacherEmail = "";
  String _teacherInitial = "T";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user
      User? user = _auth.currentUser;
      if (user != null) {
        // Set email from Firebase Auth
        setState(() {
          _teacherEmail = user.email ?? "";

          // Set initial based on email if available
          if (_teacherEmail.isNotEmpty) {
            _teacherInitial = _teacherEmail[0].toUpperCase();
          }
        });

        // Query Firestore for teacher's name
        final QuerySnapshot snapshot = await _firestore
            .collection('Users')
            .doc('teacher')
            .collection('accounts')
            .where('Email', isEqualTo: _teacherEmail)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final teacherData =
              snapshot.docs.first.data() as Map<String, dynamic>;

          setState(() {
            // Get teacher name from Firestore
            _teacherName = teacherData['Name'] ?? "Teacher";

            // If we have a name, use the first letter as initial
            if (_teacherName.isNotEmpty) {
              _teacherInitial = _teacherName[0].toUpperCase();
            }
          });
        }
      }
    } catch (e) {
      print('Error loading teacher info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity, // Ensures it fills the entire height
      width: 250, // Fixed width for the sidebar
      child: Container(
        color: ColorManager.dark, // Using dark slate for the sidebar
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo area with gradient background
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF5E4DCD), const Color(0xFF483AAB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "TEACHER PORTAL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Teacher profile section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              const Color(0xFF5E4DCD).withOpacity(0.3),
                          child: Text(
                            _teacherInitial,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _teacherName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _teacherEmail,
                                style: TextStyle(
                                  color: ColorManager.light.withOpacity(0.7),
                                  fontSize: 12,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
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
                      isActive: widget.selectedPage == 'Dashboard',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.school_outlined,
                      'My Courses',
                      isActive: widget.selectedPage == 'My Courses',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.people_outlined,
                      'Students',
                      isActive: widget.selectedPage == 'Students',
                    ),
                    // _buildSidebarItem(
                    //   context,
                    //   Icons.assignment_outlined,
                    //   'Assignments',
                    //   isActive: widget.selectedPage == 'Assignments',
                    //   badge: '3',
                    // ),

                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFF3A4750),
                    ),
                    const SizedBox(height: 16),

                    // Teaching section title
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "TEACHING",
                          style: TextStyle(
                            color: ColorManager.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // _buildSidebarItem(
                    //   context,
                    //   Icons.fact_check_outlined,
                    //   'Attendance',
                    //   isActive: widget.selectedPage == 'Attendance',
                    // ),
                    // _buildSidebarItem(
                    //   context,
                    //   Icons.grading_outlined,
                    //   'Grades',
                    //   isActive: widget.selectedPage == 'Grades',
                    // ),
                    // _buildSidebarItem(
                    //   context,
                    //   Icons.event_outlined,
                    //   'Calendar',
                    //   isActive: widget.selectedPage == 'Calendar',
                    // ),
                    // _buildSidebarItem(
                    //   context,
                    //   Icons.folder_outlined,
                    //   'Resources',
                    //   isActive: widget.selectedPage == 'Resources',
                    // ),

                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFF3A4750),
                    ),
                    const SizedBox(height: 16),

                    // Profile & Settings section title
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "PERSONAL",
                          style: TextStyle(
                            color: ColorManager.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // _buildSidebarItem(
                    //   context,
                    //   Icons.message_outlined,
                    //   'Messages',
                    //   isActive: widget.selectedPage == 'Messages',
                    //   badge: '5',
                    // ),
                    _buildSidebarItem(
                      context,
                      Icons.person_outlined,
                      'Profile',
                      isActive: widget.selectedPage == 'Profile',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.settings_outlined,
                      'Settings',
                      isActive: widget.selectedPage == 'Settings',
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
        // Use the callback to change the page
        widget.onPageChanged(label);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5E4DCD) : Colors.transparent,
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
                      : const Color(0xFF5E4DCD).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF5E4DCD) : Colors.white,
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
