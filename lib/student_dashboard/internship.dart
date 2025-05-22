import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_network/image_network.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/Membership/membership_service.dart';

class StudentInternshipPage extends StatefulWidget {
  const StudentInternshipPage({Key? key}) : super(key: key);

  @override
  State<StudentInternshipPage> createState() => _StudentInternshipPageState();
}

class _StudentInternshipPageState extends State<StudentInternshipPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MembershipService _membershipService = MembershipService();

  bool _isLoading = true;
  bool _isMember = false;
  List<Map<String, dynamic>> _internships = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check membership status
      final membershipStatus = await _membershipService.getMembershipStatus();
      _isMember = membershipStatus['isMember'] ?? false;

      // Load internships
      await _loadInternships();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInternships() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Internships')
          .orderBy('postedDate', descending: true)
          .get();

      List<Map<String, dynamic>> internships = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Check visibility
        String visibility = data['visibility'] ?? 'all';

        // Show all internships to members, only 'all' visibility to non-members
        if (_isMember || visibility == 'all') {
          internships.add(data);
        }
      }

      setState(() {
        _internships = internships;
      });
    } catch (e) {
      print('Error loading internships: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredInternships {
    if (_selectedFilter == 'All') {
      return _internships;
    }
    return _internships.where((internship) {
      String type = internship['type'] ?? '';
      return type.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = _isSmallScreen(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            )
          : Column(
              children: [
                // Header with filters
                _buildHeader(isSmallScreen),

                // Internships list
                Expanded(
                  child: _filteredInternships.isEmpty
                      ? _buildEmptyState()
                      : _buildInternshipsList(isSmallScreen),
                ),
              ],
            ),
      floatingActionButton: isSmallScreen
          ? FloatingActionButton(
              onPressed: _loadData,
              backgroundColor: ColorManager.primary,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Internships',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find the perfect internship to kickstart your career',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: ColorManager.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isMember)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Member',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter chips
          if (isSmallScreen) _buildMobileFilters() else _buildDesktopFilters(),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    final filters = ['All', 'Remote', 'On-site', 'Hybrid'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : ColorManager.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: ColorManager.primary,
              backgroundColor: Colors.white,
              side: BorderSide(color: ColorManager.primary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopFilters() {
    final filters = ['All', 'Remote', 'On-site', 'Hybrid'];

    return Row(
      children: [
        Text(
          'Filter by type: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(width: 16),
        ...filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : ColorManager.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: ColorManager.primary,
              backgroundColor: Colors.white,
              side: BorderSide(color: ColorManager.primary),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: ColorManager.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              'No Internships Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorManager.textMedium,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isMember
                  ? 'Check back later for new opportunities'
                  : 'Become a member to access exclusive internships',
              style: TextStyle(
                color: ColorManager.textLight,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInternshipsList(bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: ColorManager.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        itemCount: _filteredInternships.length,
        itemBuilder: (context, index) {
          final internship = _filteredInternships[index];
          return _buildInternshipCard(internship, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildInternshipCard(
      Map<String, dynamic> internship, bool isSmallScreen) {
    final String title = internship['title'] ?? 'Untitled';
    final String company = internship['company'] ?? 'Unknown Company';
    final String location = internship['location'] ?? 'Location not specified';
    final String type = internship['type'] ?? 'Not specified';
    final String duration = internship['duration'] ?? 'Not specified';
    final String stipend = internship['stipend'] ?? 'Not mentioned';
    final String description = internship['description'] ?? '';
    final String imageUrl = internship['imageUrl'] ?? '';
    final List<dynamic> eligibility = internship['eligibility'] ?? [];
    final List<dynamic> skills = internship['skills'] ?? [];
    final String applyUrl = internship['applyUrl'] ?? '';
    final String visibility = internship['visibility'] ?? 'all';
    final Timestamp? postedDate = internship['postedDate'];

    return Container(
      margin:
          EdgeInsets.only(bottom: isSmallScreen ? 12 : 16), // Reduced margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Slightly smaller radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section - only show if image exists
          if (imageUrl.isNotEmpty) _buildImageSection(imageUrl, isSmallScreen),

          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildCardHeader(title, company, location, type, duration,
                    stipend, visibility, postedDate, isSmallScreen),

                const SizedBox(height: 12), // Reduced spacing

                // Description - truncated for compact view
                if (description.isNotEmpty) ...[
                  Text(
                    description.length > 150
                        ? '${description.substring(0, 150)}...'
                        : description,
                    style: TextStyle(
                      color: ColorManager.textMedium,
                      fontSize: isSmallScreen ? 12 : 13, // Smaller font
                      height: 1.4,
                    ),
                    maxLines: 3, // Limit to 3 lines
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Skills - show only first few
                if (skills.isNotEmpty) ...[
                  _buildCompactSkillChips(skills, isSmallScreen),
                  const SizedBox(height: 12),
                ],

                // Apply button - more compact
                _buildCompactApplyButton(applyUrl, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSkillChips(List<dynamic> skills, bool isSmallScreen) {
    // Show only first 4 skills to keep it compact
    final displaySkills = skills.take(4).toList();
    final hasMore = skills.length > 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills Required',
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...displaySkills.map((skill) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: ColorManager.primary.withOpacity(0.3)),
                ),
                child: Text(
                  skill.toString(),
                  style: TextStyle(
                    color: ColorManager.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            if (hasMore)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: ColorManager.textLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${skills.length - 4} more',
                  style: TextStyle(
                    color: ColorManager.textMedium,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactApplyButton(String applyUrl, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 36 : 40, // Smaller height
      child: ElevatedButton.icon(
        onPressed: applyUrl.isNotEmpty ? () => _launchURL(applyUrl) : null,
        icon: Icon(
          Icons.open_in_new,
          size: 16, // Smaller icon
        ),
        label: Text(
          'Apply Now',
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14, // Smaller font
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorManager.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ColorManager.textLight,
          elevation: 1, // Reduced elevation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Smaller radius
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(String imageUrl, bool isSmallScreen) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 200 : 250,
            child: ImageNetwork(
              image: imageUrl,
              height: isSmallScreen ? 200 : 250,
              width: constraints.maxWidth,
              fitAndroidIos: BoxFit.contain,
              onLoading: Container(
                color: ColorManager.background,
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
              onError: Container(
                color: ColorManager.background,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: ColorManager.textLight,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: ColorManager.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardHeader(
      String title,
      String company,
      String location,
      String type,
      String duration,
      String stipend,
      String visibility,
      Timestamp? postedDate,
      bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    company,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (visibility == 'members')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Members Only',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Details chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip(Icons.location_on_outlined, location, isSmallScreen),
            _buildInfoChip(Icons.work_outline, type, isSmallScreen),
            _buildInfoChip(Icons.schedule_outlined, duration, isSmallScreen),
            _buildInfoChip(Icons.currency_rupee, stipend, isSmallScreen),
          ],
        ),

        if (postedDate != null) ...[
          const SizedBox(height: 8),
          Text(
            'Posted ${_formatDate(postedDate.toDate())}',
            style: TextStyle(
              fontSize: 11,
              color: ColorManager.textLight,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorManager.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorManager.light),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 12 : 14,
            color: ColorManager.textMedium,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: ColorManager.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isSmallScreen ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: ColorManager.textDark,
      ),
    );
  }

  Widget _buildMobileSkillsEligibility(
      List<dynamic> eligibility, List<dynamic> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eligibility.isNotEmpty) ...[
          _buildSectionTitle('Eligibility Criteria', true),
          const SizedBox(height: 8),
          _buildBulletList(eligibility, true),
          const SizedBox(height: 16),
        ],
        if (skills.isNotEmpty) ...[
          _buildSectionTitle('Skills Required', true),
          const SizedBox(height: 8),
          _buildSkillChips(skills, true),
        ],
      ],
    );
  }

  Widget _buildDesktopSkillsEligibility(
      List<dynamic> eligibility, List<dynamic> skills) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eligibility.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Eligibility Criteria', false),
                const SizedBox(height: 8),
                _buildBulletList(eligibility, false),
              ],
            ),
          ),
        if (eligibility.isNotEmpty && skills.isNotEmpty)
          const SizedBox(width: 24),
        if (skills.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Skills Required', false),
                const SizedBox(height: 8),
                _buildSkillChips(skills, false),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBulletList(List<dynamic> items, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 8, right: 8),
                decoration: BoxDecoration(
                  color: ColorManager.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  item.toString(),
                  style: TextStyle(
                    color: ColorManager.textMedium,
                    fontSize: isSmallScreen ? 13 : 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkillChips(List<dynamic> skills, bool isSmallScreen) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
          ),
          child: Text(
            skill.toString(),
            style: TextStyle(
              color: ColorManager.primary,
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplyButton(String applyUrl, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 45 : 50,
      child: ElevatedButton.icon(
        onPressed: applyUrl.isNotEmpty ? () => _launchURL(applyUrl) : null,
        icon: Icon(
          Icons.open_in_new,
          size: isSmallScreen ? 18 : 20,
        ),
        label: Text(
          'Apply Now',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorManager.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ColorManager.textLight,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }
}
