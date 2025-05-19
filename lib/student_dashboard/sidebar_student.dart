// Student sidebar implementation with light color theme
import 'package:flutter/material.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class StudentSidebar extends StatelessWidget {
  final String selectedPage;
  final Function(String) onPageChanged;

  const StudentSidebar({
    Key? key,
    required this.selectedPage,
    required this.onPageChanged,
  }) : super(key: key);

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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ColorManager.primaryLight,
                    child: Text(
                      "S",
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
                        "Student Name",
                        style: TextStyle(
                          color: ColorManager.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Computer Science",
                        style: TextStyle(
                          color: ColorManager.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                      isActive: selectedPage == 'Dashboard',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.class_outlined,
                      'My Batches',
                      isActive: selectedPage == 'My Batches',
                      badge: '3',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.menu_book_outlined,
                      'All Courses',
                      isActive: selectedPage == 'All Courses',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.card_membership_outlined,
                      'Certificates',
                      isActive: selectedPage == 'Certificates',
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
                      isActive: selectedPage == 'Schedule',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.assignment_outlined,
                      'Assignments',
                      isActive: selectedPage == 'Assignments',
                      badge: '4',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.library_books_outlined,
                      'Library',
                      isActive: selectedPage == 'Library',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.workspace_premium_outlined,
                      'Take Membership',
                      isActive: selectedPage == 'Take Membership',
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
                      isActive: selectedPage == 'Messages',
                      badge: '5',
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
                  // Handle logout logic here
                  Navigator.pushReplacementNamed(context, '/login');
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
        onPageChanged(label);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color:
              isActive
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
                  color:
                      isActive
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

// Student Dashboard Content
