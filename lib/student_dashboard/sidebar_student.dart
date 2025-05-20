import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/auth/auth_service.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class StudentSidebar extends StatefulWidget {
  final String selectedPage;
  final Function(String) onPageChanged;

  const StudentSidebar({
    Key? key,
    required this.selectedPage,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  State<StudentSidebar> createState() => _StudentSidebarState();
}

class _StudentSidebarState extends State<StudentSidebar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _studentName = "Loading...";
  String _studentEmail = "";
  bool _isLoading = true;
  String _studentInitial = "?";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get the email
        setState(() {
          _studentEmail = currentUser.email ?? "";
        });

        // If display name exists in auth user, use it
        if (currentUser.displayName != null &&
            currentUser.displayName!.isNotEmpty) {
          setState(() {
            _studentName = currentUser.displayName!;
            _studentInitial = _studentName[0].toUpperCase();
            _isLoading = false;
          });
        } else {
          // Otherwise fetch from Firestore
          final userDoc = await _firestore
              .collection('Users')
              .doc('student')
              .collection('accounts')
              .doc(currentUser.email)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null && userData.containsKey('Name')) {
              setState(() {
                _studentName = userData['Name'];
                _studentInitial = _studentName.isNotEmpty
                    ? _studentName[0].toUpperCase()
                    : "S";
              });
            }
          }

          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _studentName = "Student";
        _studentInitial = "S";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: 250,
      child: Container(
        // Use a light color for the sidebar background
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Student profile area with gradient background
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
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "LUYIP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Student profile section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _isLoading
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(),
                        )
                      : CircleAvatar(
                          radius: 24,
                          backgroundColor: ColorManager.primaryLight,
                          child: Text(
                            _studentInitial,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.primaryDark,
                            ),
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoading ? "Loading..." : _studentName,
                          style: TextStyle(
                            color: ColorManager.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLoading ? "" : _studentEmail,
                          style: TextStyle(
                            color: ColorManager.textMedium,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: ColorManager.textLight.withOpacity(0.2),
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
                    color: ColorManager.textMedium,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Menu items
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
                      Icons.class_outlined,
                      'My Batches',
                      isActive: widget.selectedPage == 'My Batches',
                      badge: '3',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.menu_book_outlined,
                      'All Courses',
                      isActive: widget.selectedPage == 'All Courses',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.card_membership_outlined,
                      'Certificates',
                      isActive: widget.selectedPage == 'Certificates',
                      badge: '2',
                    ),

                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: ColorManager.textLight.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),

                    // Learning section title
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "LEARNING",
                          style: TextStyle(
                            color: ColorManager.textMedium,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    _buildSidebarItem(
                      context,
                      Icons.calendar_today_outlined,
                      'Schedule',
                      isActive: widget.selectedPage == 'Schedule',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.assignment_outlined,
                      'Assignments',
                      isActive: widget.selectedPage == 'Assignments',
                      badge: '4',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.library_books_outlined,
                      'Library',
                      isActive: widget.selectedPage == 'Library',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.workspace_premium_outlined,
                      'Take Membership',
                      isActive: widget.selectedPage == 'Take Membership',
                      hasProTag: true,
                    ),

                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: ColorManager.textLight.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),

                    // Account section title
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "ACCOUNT",
                          style: TextStyle(
                            color: ColorManager.textMedium,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    _buildSidebarItem(
                      context,
                      Icons.message_outlined,
                      'Messages',
                      isActive: widget.selectedPage == 'Messages',
                      badge: '5',
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

            // Footer with logout button - Updated with AuthService
            Container(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  // Show confirmation dialog before logout
                  _showLogoutConfirmationDialog(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: ColorManager.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: ColorManager.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog before logout
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

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String label, {
    bool isActive = false,
    String? badge,
    bool hasProTag = false,
  }) {
    return GestureDetector(
      onTap: () {
        // Use the callback to change the page
        widget.onPageChanged(label);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isActive
              ? ColorManager.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? ColorManager.primary : ColorManager.textMedium,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isActive ? ColorManager.primary : ColorManager.textDark,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (hasProTag)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorManager.warning,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "PRO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? ColorManager.primary
                      : ColorManager.secondary.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
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
}
