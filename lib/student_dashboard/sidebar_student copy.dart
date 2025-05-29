import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/auth/auth_service.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class StudentSidebar extends StatefulWidget {
  final String selectedPage;
  final Function(String) onPageChanged;
  final bool isMobile;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const StudentSidebar({
    Key? key,
    required this.selectedPage,
    required this.onPageChanged,
    this.isMobile = false,
    this.isExpanded = true,
    this.onToggle,
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
    // Determine sidebar width based on expanded state and screen size
    double sidebarWidth = widget.isExpanded ? 250 : 70;
    if (!widget.isExpanded && !widget.isMobile) {
      sidebarWidth = 70; // Collapsed width for desktop
    } else if (widget.isMobile && widget.isExpanded) {
      sidebarWidth = 250; // Full width when expanded on mobile
    } else if (widget.isMobile && !widget.isExpanded) {
      sidebarWidth = 0; // Hidden when collapsed on mobile
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      height: double.infinity,
      child: widget.isMobile && !widget.isExpanded
          ? Container() // Return empty container when sidebar is collapsed on mobile
          : Container(
              // Use a light color for the sidebar background
              color: const Color(0xFFF5F7FA),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo header with dynamic logo from Firebase
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorManager.primary,
                          ColorManager.primaryDark
                        ],
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
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('website_general')
                          .doc('dashboard')
                          .get(),
                      builder: (context, snapshot) {
                        String logoUrl = '';
                        String companyName = 'LUIYP';

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final websiteContent = data?['websiteContent']
                                  as Map<String, dynamic>? ??
                              {};
                          logoUrl = websiteContent['logoUrl']?.toString() ?? '';
                          companyName = websiteContent['companyName']
                                  ?.toString() ??
                              websiteContent['companyShortName']?.toString() ??
                              'LUIYP';
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.isExpanded && logoUrl.isNotEmpty)
                              Image.network(
                                logoUrl,
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
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
                            if (widget.isExpanded && logoUrl.isNotEmpty)
                              const SizedBox(width: 12),
                            if (widget.isExpanded)
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
                              )
                            else
                              logoUrl.isNotEmpty
                                  ? Image.network(
                                      logoUrl,
                                      width: 30,
                                      height: 30,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Text(
                                          "L",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return const SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                    )
                                  : const Text(
                                      "L",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                            // Only show toggle button on desktop collapsed view
                            if (!widget.isMobile && !widget.isExpanded)
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                ),
                                onPressed: widget.onToggle,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Student profile section - show only when expanded
                  if (widget.isExpanded)
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
                    )
                  else if (!widget
                      .isMobile) // Show only avatar in collapsed desktop mode
                    _isLoading
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(),
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: ColorManager.primaryLight,
                            child: Text(
                              _studentInitial,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ColorManager.primaryDark,
                              ),
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

                  // Menu section title - only when expanded
                  if (widget.isExpanded)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, bottom: 8),
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
                          _buildSidebarItem(
                            context,
                            Icons.message_outlined,
                            'Internship',
                            isActive: widget.selectedPage == 'Internship',
                          ),
                          if (widget.isExpanded) const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: ColorManager.textLight.withOpacity(0.2),
                          ),
                          if (widget.isExpanded) const SizedBox(height: 16),

                          // Learning section title - only when expanded
                          if (widget.isExpanded)
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
                            Icons.workspace_premium_outlined,
                            'Take Membership',
                            isActive: widget.selectedPage == 'Take Membership',
                            hasProTag: true,
                          ),

                          if (widget.isExpanded) const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: ColorManager.textLight.withOpacity(0.2),
                          ),
                          if (widget.isExpanded) const SizedBox(height: 16),

                          // Account section title - only when expanded
                          if (widget.isExpanded)
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
                            Icons.settings_outlined,
                            'Settings',
                            isActive: widget.selectedPage == 'Settings',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer with logout button - show only in expanded view
                  if (widget.isExpanded)
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
                              Icon(Icons.logout,
                                  color: ColorManager.error, size: 18),
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
                    )
                  else if (!widget
                      .isMobile) // Show icon-only logout in collapsed desktop mode
                    IconButton(
                      icon: Icon(
                        Icons.logout,
                        color: ColorManager.error,
                      ),
                      onPressed: () {
                        _showLogoutConfirmationDialog(context);
                      },
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
        // First change the page
        widget.onPageChanged(label);

        // Then handle mobile drawer closing
        if (widget.isMobile) {
          // Check if we're in a drawer and close it
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.of(context).pop(); // Only pop the drawer
          }
        }
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
          mainAxisAlignment: widget.isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? ColorManager.primary : ColorManager.textMedium,
              size: 20,
            ),
            if (widget.isExpanded) const SizedBox(width: 12),
            if (widget.isExpanded)
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
            if (widget.isExpanded && hasProTag)
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
            if (widget.isExpanded && badge != null)
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
