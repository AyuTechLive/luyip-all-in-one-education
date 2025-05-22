import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/auth/auth_service.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class FranchiseDashboardSidebar extends StatefulWidget {
  final String selectedPage;
  final Function(String) onPageChanged;

  const FranchiseDashboardSidebar({
    Key? key,
    required this.selectedPage,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  State<FranchiseDashboardSidebar> createState() =>
      _FranchiseDashboardSidebarState();
}

class _FranchiseDashboardSidebarState extends State<FranchiseDashboardSidebar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _franchiseName = "Franchise Partner";
  String _franchiseEmail = "";
  String _franchiseInitial = "F";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFranchiseInfo();
  }

  Future<void> _loadFranchiseInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user
      User? user = _auth.currentUser;
      if (user != null) {
        // Set email from Firebase Auth
        setState(() {
          _franchiseEmail = user.email ?? "";

          // Set initial based on email if available
          if (_franchiseEmail.isNotEmpty) {
            _franchiseInitial = _franchiseEmail[0].toUpperCase();
          }
        });

        // Query Firestore for franchise partner's name
        final QuerySnapshot snapshot = await _firestore
            .collection('Users')
            .doc('franchise')
            .collection('accounts')
            .where('Email', isEqualTo: _franchiseEmail)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final franchiseData =
              snapshot.docs.first.data() as Map<String, dynamic>;

          setState(() {
            // Get franchise name from Firestore
            _franchiseName = franchiseData['Name'] ?? "Franchise Partner";

            // If we have a name, use the first letter as initial
            if (_franchiseName.isNotEmpty) {
              _franchiseInitial = _franchiseName[0].toUpperCase();
            }
          });
        }
      }
    } catch (e) {
      print('Error loading franchise info: $e');
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
        color: const Color(0xFF1B5E20), // Dark green theme for franchise
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo area with gradient background
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2E7D32), const Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "FRANCHISE PORTAL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Franchise profile section
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
                              const Color(0xFF2E7D32).withOpacity(0.3),
                          child: Text(
                            _franchiseInitial,
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
                                _franchiseName,
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
                                _franchiseEmail,
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
              color: Color(0xFF2E7D32), // Slightly lighter than dark green
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
                      Icons.business_outlined,
                      'Franchise Centers',
                      isActive: widget.selectedPage == 'Franchise Centers',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.school_outlined,
                      'Teachers',
                      isActive: widget.selectedPage == 'Teachers',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.people_outlined,
                      'Students',
                      isActive: widget.selectedPage == 'Students',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.book_outlined,
                      'Courses',
                      isActive: widget.selectedPage == 'Courses',
                    ),

                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 16),

                    // Business section title
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "BUSINESS",
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
                      Icons.assessment_outlined,
                      'Reports',
                      isActive: widget.selectedPage == 'Reports',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.trending_up_outlined,
                      'Revenue',
                      isActive: widget.selectedPage == 'Revenue',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.campaign_outlined,
                      'Marketing',
                      isActive: widget.selectedPage == 'Marketing',
                    ),
                    _buildSidebarItem(
                      context,
                      Icons.analytics_outlined,
                      'Analytics',
                      isActive: widget.selectedPage == 'Analytics',
                    ),

                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 16),

                    // Support & Profile section title
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "SUPPORT",
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
                      Icons.support_agent_outlined,
                      'Support',
                      isActive: widget.selectedPage == 'Support',
                      badge: '2',
                    ),
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
          color: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
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
                      : const Color(0xFF2E7D32).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF2E7D32) : Colors.white,
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
