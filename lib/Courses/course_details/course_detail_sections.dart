import 'package:flutter/material.dart';
import 'package:image_network/image_network.dart';
import 'package:luyip_website_edu/Courses/pdfviewer/pdfviewer.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/membership/membership_screen.dart';
import 'package:luyip_website_edu/Courses/course_materials.dart';
import 'package:luyip_website_edu/Courses/mark_course_complete.dart';
import 'package:luyip_website_edu/Courses/course_management_screen.dart';

class CourseDetailSections {
  static Widget buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Course Not Found',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We couldn\'t find the course you were looking for.\nPlease check the course link or try again.',
            style: TextStyle(
              fontSize: 16,
              color: ColorManager.textMedium,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            label: const Text(
              'Go Back',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTabBar(int activeTab, Function(int) onTabChanged) {
    final tabs = [
      {'icon': Icons.info_outline, 'title': 'Overview'},
      {'icon': Icons.people_outline, 'title': 'Instructors'},
      {'icon': Icons.calendar_today_outlined, 'title': 'Schedule'},
      {'icon': Icons.library_books_outlined, 'title': 'Materials'},
    ];

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: activeTab == index
                      ? ColorManager.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: activeTab == index
                      ? [
                          BoxShadow(
                            color: ColorManager.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          tabs[index]['icon'] as IconData,
                          color: activeTab == index
                              ? Colors.white
                              : ColorManager.textMedium,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: activeTab == index
                              ? Colors.white
                              : ColorManager.textMedium,
                        ),
                        child: Text(tabs[index]['title'] as String),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildSliverAppBar(
    Map<String, dynamic> data,
    Size size,
    String courseName,
    bool isScrolled,
    bool isEnrolled,
    bool isMember,
    double discountPercentage,
    double originalPrice,
    double discountedPrice,
    bool isLoadingMembership,
    String userRole,
    BuildContext context,
  ) {
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Main image with proper fitting
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Hero(
                tag: 'course-$courseName',
                child: ImageNetwork(
                  image: data['Course Img Link'] ?? '',
                  height: 360,
                  width: size.width,
                  fitAndroidIos: BoxFit.cover,
                  onLoading: Container(
                    color: ColorManager.primary.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ColorManager.primary,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  onError: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorManager.primary.withOpacity(0.8),
                          ColorManager.primary,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school,
                        size: 80,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Content overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Course badges
                    Row(
                      children: [
                        _buildInfoBadge(
                          icon: Icons.access_time,
                          label: data['Duration'] ?? 'N/A',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoBadge(
                          icon: Icons.signal_cellular_4_bar,
                          label: data['Difficulty'] ?? 'All Levels',
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Course title
                    Text(
                      data['Course Name'] ?? courseName,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rating and price row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data['Rating']?.toString() ?? '4.5',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${data['Reviews'] ?? '124'})',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _buildPriceSection(
                          data,
                          isMember,
                          discountPercentage,
                          discountedPrice,
                          isLoadingMembership,
                        ),
                      ],
                    ),

                    // Admin/Teacher buttons
                  ],
                ),
              ),
            ),

            // Custom back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      //  backdropFilter: null,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        title: AnimatedOpacity(
          opacity: isScrolled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            data['Course Name'] ?? courseName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
      ),
    );
  }

  static Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPriceSection(
    Map<String, dynamic> data,
    bool isMember,
    double discountPercentage,
    double discountedPrice,
    bool isLoadingMembership,
  ) {
    if (isLoadingMembership) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isMember && discountPercentage > 0) ...[
          Text(
            data['Course Price'] ?? 'FREE',
            style: const TextStyle(
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Text(
              '${discountPercentage.toStringAsFixed(0)}% OFF',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${discountedPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ] else ...[
          Text(
            data['Course Price'] ?? 'FREE',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  static Widget _buildAdminButtons(BuildContext context, String courseName) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              'Mark Complete',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green.withOpacity(0.5)),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarkCourseCompletePage(
                    courseName: courseName,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(
              'Manage',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue.withOpacity(0.5)),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseContentManagement(
                    courseName: courseName,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget buildCourseInfo(
      Map<String, dynamic> data,
      List<dynamic> learningObjectives,
      bool isMember,
      double discountPercentage,
      BuildContext context,
      String userRole,
      String courseName) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userRole == 'admin' || userRole == 'teacher') ...[
            const SizedBox(height: 16),
            _buildAdminButtons(context, courseName),
          ],
          const SizedBox(height: 30),
          _buildSectionHeader('Course Overview', Icons.info_outline),
          const SizedBox(height: 20),

          // Course description with better styling
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              data['Course Discription'] ??
                  'This comprehensive course is designed to help students master key concepts through interactive lessons, real-world applications, and expert guidance. Join our community of learners and start your journey today.',
              style: TextStyle(
                fontSize: 16,
                color: ColorManager.textMedium,
                height: 1.7,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Membership benefit card
          if (discountPercentage > 0) ...[
            _buildMembershipCard(isMember, discountPercentage, context),
            const SizedBox(height: 24),
          ],

          // Learning objectives
          _buildLearningObjectivesCard(learningObjectives),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: ColorManager.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textDark,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: ColorManager.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildMembershipCard(
    bool isMember,
    double discountPercentage,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMember
              ? [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]
              : [
                  ColorManager.primary.withOpacity(0.15),
                  ColorManager.primary.withOpacity(0.05)
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMember
              ? Colors.green.withOpacity(0.3)
              : ColorManager.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMember
                      ? Colors.green.withOpacity(0.2)
                      : ColorManager.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: isMember ? Colors.green : ColorManager.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membership Benefit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMember
                            ? Colors.green.shade800
                            : ColorManager.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMember
                          ? 'You\'re saving ${discountPercentage.toStringAsFixed(0)}% on this course!'
                          : 'Save ${discountPercentage.toStringAsFixed(0)}% with membership',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorManager.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isMember) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MembershipScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Join Membership'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildLearningObjectivesCard(List<dynamic> objectives) {
    if (objectives.isEmpty) {
      objectives = [
        'Master fundamental concepts and theories',
        'Apply knowledge to real-world scenarios',
        'Develop critical thinking skills',
        'Learn industry best practices',
        'Build practical project experience',
        'Earn a recognized certification',
      ];
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_objects_outlined,
                color: ColorManager.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'What you\'ll learn',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...objectives.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check,
                      color: ColorManager.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        color: ColorManager.textMedium,
                        height: 1.5,
                      ),
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

  static Widget buildFeatureCards(List<dynamic> featureCards) {
    if (featureCards.isEmpty) {
      featureCards = [
        {
          'icon': 'video_library',
          'title': 'HD Video Lectures',
          'description': 'High-quality video content with interactive elements',
          'color': 'blue',
        },
        {
          'icon': 'people',
          'title': 'Expert Support',
          'description': 'Get help from experienced instructors',
          'color': 'green',
        },
        {
          'icon': 'assignment',
          'title': 'Practice Assignments',
          'description': 'Real-world exercises and projects',
          'color': 'orange',
        },
        {
          'icon': 'school',
          'title': 'Certification',
          'description': 'Earn industry-recognized credentials',
          'color': 'purple',
        },
      ];
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: featureCards.length,
      itemBuilder: (context, index) {
        final feature = featureCards[index];
        final iconData = _getIconData(feature['icon'].toString());
        final color = _getColor(feature['color'].toString());

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(iconData, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  feature['title'].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feature['description'].toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorManager.textMedium,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'video_library':
        return Icons.video_library_outlined;
      case 'people':
        return Icons.people_outline;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'star':
        return Icons.star_outline;
      case 'devices':
        return Icons.devices_outlined;
      case 'support':
        return Icons.support_agent_outlined;
      case 'chat':
        return Icons.chat_outlined;
      default:
        return Icons.info_outline;
    }
  }

  static Color _getColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return const Color(0xFF4A90E2);
      case 'green':
        return const Color(0xFF50C878);
      case 'orange':
        return const Color(0xFFFF8C42);
      case 'purple':
        return const Color(0xFF9B59B6);
      case 'red':
        return const Color(0xFFE74C3C);
      case 'teal':
        return const Color(0xFF1ABC9C);
      default:
        return const Color(0xFF4A90E2);
    }
  }

  static Widget buildTeachersSection(List teachers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Meet Our Expert Instructors', Icons.people_outline),
        const SizedBox(height: 24),
        if (teachers.isEmpty)
          buildEmptyState(
            'No instructor details available yet',
            'We\'re currently finalizing our instructor roster.',
            Icons.people_outline,
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Profile image with better styling
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: ColorManager.primary.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: ImageNetwork(
                            image: teacher['ProfilePicURL'] ?? '',
                            height: 80,
                            width: 80,
                            fitAndroidIos: BoxFit.cover,
                            onLoading: Container(
                              color: ColorManager.primary.withOpacity(0.1),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: ColorManager.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            onError: Container(
                              decoration: BoxDecoration(
                                color: ColorManager.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: ColorManager.primary.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Teacher info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    teacher['Name'] ?? 'Instructor',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: ColorManager.textDark,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        ColorManager.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    teacher['Subject'] ?? 'Subject',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ColorManager.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Text(
                              teacher['Qualification'] ??
                                  'Experienced educator with a passion for teaching and helping students succeed.',
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorManager.textMedium,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),

                            // Stats row
                            Row(
                              children: [
                                _buildTeacherStat(
                                  Icons.work_outline,
                                  '${teacher['Experience'] ?? 'N/A'} years',
                                ),
                                const SizedBox(width: 20),
                                _buildTeacherStat(
                                  Icons.star_outline,
                                  teacher['Rating'] ?? '4.8',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  static Widget _buildTeacherStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ColorManager.primary,
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ColorManager.textMedium,
          ),
        ),
      ],
    );
  }

  static Widget buildCourseTimeline(
      List notices, String scheduleDocumentUrl, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Course Schedule', Icons.calendar_today_outlined),
        const SizedBox(height: 24),

        // Schedule PDF document card with enhanced design
        if (scheduleDocumentUrl.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: InkWell(
              onTap: () =>
                  _openPdf(context, scheduleDocumentUrl, 'Course Schedule'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorManager.primary.withOpacity(0.1),
                      ColorManager.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ColorManager.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        color: ColorManager.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detailed Schedule',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'View the complete course timetable with class dates, times, and topics',
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorManager.textMedium,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ColorManager.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (notices.isEmpty)
          buildEmptyState(
            'No schedule available yet',
            'Class schedule will be posted soon. Check back later!',
            Icons.calendar_today_outlined,
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: notices.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ColorManager.primary,
                                ColorManager.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: ColorManager.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (index < notices.length - 1)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            width: 3,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ColorManager.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 20),

                    // Notice content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          notices[index].toString(),
                          style: TextStyle(
                            fontSize: 15,
                            color: ColorManager.textDark,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  static Widget buildMaterialsSection(
      Map<String, dynamic> data,
      List<dynamic> keyDocuments,
      bool isEnrolled,
      String courseName,
      String userRole, // Add userRole parameter
      BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Course Materials', Icons.library_books_outlined),
        const SizedBox(height: 24),

        // Browse All Subjects Card with enhanced design
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: InkWell(
            onTap: (isEnrolled ||
                    userRole == 'franchise') // Allow franchise access
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CourseMaterials(courseName: courseName),
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: (isEnrolled || userRole == 'franchise')
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorManager.primary.withOpacity(0.9),
                          ColorManager.primary,
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade300,
                          Colors.grey.shade400,
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isEnrolled || userRole == 'franchise')
                        ? ColorManager.primary.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      (isEnrolled || userRole == 'franchise')
                          ? Icons.library_books
                          : Icons.lock,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (isEnrolled || userRole == 'franchise')
                              ? 'Browse All Subjects'
                              : 'Enroll to Access Materials',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (isEnrolled || userRole == 'franchise')
                              ? 'Access all course subjects and study materials'
                              : 'Complete enrollment to unlock all course content',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEnrolled || userRole == 'franchise')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: ColorManager.primary,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Key Documents Section
        Text(
          'Key Documents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 16),

        if (keyDocuments.isEmpty &&
            (data['SyllabusPDF'] == null || data['SyllabusPDF'].isEmpty) &&
            (data['PreviewPDF'] == null || data['PreviewPDF'].isEmpty))
          buildEmptyState(
            'No materials available yet',
            'Course materials will be added soon. Check back later!',
            Icons.library_books_outlined,
          )
        else
          Column(
            children: [
              if (data['SyllabusPDF'] != null && data['SyllabusPDF'].isNotEmpty)
                buildMaterialCard(
                  'Syllabus',
                  'Complete course syllabus and learning objectives',
                  Icons.menu_book_outlined,
                  () => _openPdf(context, data['SyllabusPDF'], 'Syllabus'),
                ),
              if (data['PreviewPDF'] != null && data['PreviewPDF'].isNotEmpty)
                buildMaterialCard(
                  'Preview Content',
                  'Sample lessons and exercises from the course',
                  Icons.visibility_outlined,
                  () => _openPdf(context, data['PreviewPDF'], 'Preview'),
                ),
              if (data['WorksheetsPDF'] != null &&
                  data['WorksheetsPDF'].isNotEmpty)
                buildMaterialCard(
                  'Worksheets',
                  'Practice materials and homework assignments',
                  Icons.assignment_outlined,
                  () => _openPdf(context, data['WorksheetsPDF'], 'Worksheets'),
                ),
              if (data['ReferencesPDF'] != null &&
                  data['ReferencesPDF'].isNotEmpty)
                buildMaterialCard(
                  'References',
                  'Additional reading materials and resources',
                  Icons.library_books_outlined,
                  () => _openPdf(context, data['ReferencesPDF'], 'References'),
                ),

              // Display dynamic key documents from Firebase
              ...keyDocuments.map((document) {
                return buildMaterialCard(
                  document['title'] ?? 'Document',
                  document['description'] ?? 'Course document',
                  _getIconForDocType(document['type'] ?? 'document'),
                  () => _openPdf(
                    context,
                    document['url'] ?? '',
                    document['title'] ?? 'Document',
                  ),
                );
              }).toList(),
            ],
          ),
      ],
    );
  }

  static IconData _getIconForDocType(String type) {
    switch (type.toLowerCase()) {
      case 'syllabus':
        return Icons.menu_book_outlined;
      case 'worksheet':
        return Icons.assignment_outlined;
      case 'reference':
        return Icons.library_books_outlined;
      case 'lecture':
        return Icons.school_outlined;
      case 'preview':
        return Icons.visibility_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  static Widget buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorManager.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 48,
                color: ColorManager.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorManager.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: ColorManager.textMedium,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildMaterialCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ColorManager.primary.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: ColorManager.primary, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorManager.textMedium,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorManager.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildEnrollSection(
    Size size,
    double price,
    bool isEnrolled,
    bool isProcessingPayment,
    bool isMember,
    double discountPercentage,
    double discountedPrice,
    Function(double) onEnrollPressed,
  ) {
    double finalPrice =
        isMember && discountPercentage > 0 ? discountedPrice : price;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorManager.primary.withOpacity(0.9),
            ColorManager.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎓 Ready to Start Learning?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join thousands of students already enrolled in this course. Transform your skills and advance your career with expert-led instruction.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          // Stats row with better design
          Row(
            children: [
              _buildEnrollmentStat('4.8', 'Rating', Icons.star),
              _buildEnrollmentStat('2,500+', 'Students', Icons.people),
              _buildEnrollmentStat('24/7', 'Support', Icons.support_agent),
            ],
          ),

          // Membership offer section
          if (discountPercentage > 0 && !isMember) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save ${discountPercentage.toStringAsFixed(0)}% with Membership!',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join for ₹1000/year and get exclusive discounts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MembershipScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ColorManager.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'JOIN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Main CTA button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: isEnrolled || isProcessingPayment
                  ? null
                  : () => onEnrollPressed(price),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ColorManager.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: isProcessingPayment
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'PROCESSING...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          price > 0 ? Icons.payment : Icons.school,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          price > 0
                              ? 'PAY ₹${finalPrice.toStringAsFixed(0)} & ENROLL'
                              : 'ENROLL NOW - FREE',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (isEnrolled)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade300, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Successfully Enrolled',
                    style: TextStyle(
                      color: Colors.green.shade100,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildEnrollmentStat(
      String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static void _openPdf(BuildContext context, String url,
      [String title = 'Document']) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Text('PDF document not available'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Navigate to the PdfViewerScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfUrl: url,
          title: title,
        ),
      ),
    );
  }
}
