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
          const SizedBox(height: 24),
          Text(
            'Course Not Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find the course you were looking for.',
            style: TextStyle(fontSize: 16, color: ColorManager.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text(
              'Go Back',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
      {'icon': Icons.calendar_today, 'title': 'Schedule'},
      {'icon': Icons.book_outlined, 'title': 'Materials'},
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorManager.cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              child: Container(
                decoration: BoxDecoration(
                  color: activeTab == index
                      ? ColorManager.primary
                      : ColorManager.cardColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[index]['icon'] as IconData,
                        color: activeTab == index
                            ? Colors.white
                            : ColorManager.textMedium,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tabs[index]['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: activeTab == index
                              ? Colors.white
                              : ColorManager.textMedium,
                        ),
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
      expandedHeight: 300,
      pinned: true,
      backgroundColor: ColorManager.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'course-$courseName',
              child: ImageNetwork(
                image: data['Course Img Link'] ?? '',
                height: 300,
                width: size.width,
                fitAndroidIos: BoxFit.cover,
                onLoading: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                onError: Image.asset(
                  'assets/images/placeholder_course.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorManager.primary.withOpacity(0.1),
                    ColorManager.primary.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: ColorManager.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data['Duration'] ?? 'N/A',
                              style: TextStyle(
                                color: ColorManager.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: ColorManager.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data['Difficulty'] ?? 'All Levels',
                              style: TextStyle(
                                color: ColorManager.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCourseCompletionButton(context, userRole, courseName),
                  Text(
                    data['Course Name'] ?? courseName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        data['Rating']?.toString() ?? '4.5',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${data['Reviews'] ?? '124'} reviews)',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isLoadingMembership)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else if (isMember && discountPercentage > 0)
                            Row(
                              children: [
                                Text(
                                  data['Course Price'] ?? 'FREE',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${discountedPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              data['Course Price'] ?? 'FREE',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          if (isMember && discountPercentage > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Member Discount: ${discountPercentage.toStringAsFixed(0)}% Off',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 40,
              left: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 48),
      ),
    );
  }

  static Widget _buildCourseCompletionButton(
      BuildContext context, String userRole, String courseName) {
    // Only show to admins and teachers
    if (userRole != 'admin' && userRole != 'teacher') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark Course Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Manage Course Content'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.secondary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }

  static Widget buildCourseInfo(
    Map<String, dynamic> data,
    List<dynamic> learningObjectives,
    bool isMember,
    double discountPercentage,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              color: ColorManager.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data['Course Discription'] ??
                'This course is designed to help students master key concepts through interactive lessons and real-world applications.',
            style: TextStyle(
              fontSize: 16,
              color: ColorManager.textMedium,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Membership discount card
          if (discountPercentage > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMember
                    ? Colors.green.withOpacity(0.1)
                    : ColorManager.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMember
                      ? Colors.green.shade300
                      : ColorManager.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_membership,
                        color: isMember ? Colors.green : ColorManager.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Membership Benefit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isMember
                              ? Colors.green.shade800
                              : ColorManager.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMember
                        ? 'Your membership gives you ${discountPercentage.toStringAsFixed(0)}% off this course!'
                        : 'Members get ${discountPercentage.toStringAsFixed(0)}% off this course! Join our membership program to save.',
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isMember)
                    OutlinedButton(
                      onPressed: () {
                        // Navigate to membership screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MembershipScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorManager.primary,
                        side: BorderSide(color: ColorManager.primary),
                      ),
                      child: const Text('Learn more about membership'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What you will learn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildLearningObjectives(learningObjectives),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _buildLearningObjectives(List<dynamic> objectives) {
    // If no objectives are provided, display default ones
    if (objectives.isEmpty) {
      objectives = [
        'Master fundamental concepts',
        'Solve real-world problems',
        'Learn from industry experts',
        'Receive personalized feedback',
        'Join a community of learners',
        'Earn a recognized certificate',
      ];
    }

    return objectives.map((objective) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              color: ColorManager.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              objective.toString(),
              style: TextStyle(fontSize: 14, color: ColorManager.textMedium),
            ),
          ),
        ],
      );
    }).toList();
  }

  static Widget buildFeatureCards(List<dynamic> featureCards) {
    // If no feature cards are provided, display default ones
    if (featureCards.isEmpty) {
      featureCards = [
        {
          'icon': 'video_library',
          'title': 'Video Lectures',
          'description': 'HD video content with interactive elements',
          'color': 'blue',
        },
        {
          'icon': 'people',
          'title': 'Expert Support',
          'description': 'Get help from teachers and peers',
          'color': 'green',
        },
        {
          'icon': 'assignment',
          'title': 'Assignments',
          'description': 'Practice with real-world exercises',
          'color': 'orange',
        },
        {
          'icon': 'school',
          'title': 'Certification',
          'description': 'Earn a recognized certificate',
          'color': 'purple',
        },
      ];
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: featureCards.length,
      itemBuilder: (context, index) {
        final feature = featureCards[index];

        // Convert string icon name to IconData
        IconData iconData;
        switch (feature['icon'].toString()) {
          case 'video_library':
            iconData = Icons.video_library;
            break;
          case 'people':
            iconData = Icons.people;
            break;
          case 'assignment':
            iconData = Icons.assignment;
            break;
          case 'school':
            iconData = Icons.school;
            break;
          case 'star':
            iconData = Icons.star;
            break;
          case 'devices':
            iconData = Icons.devices;
            break;
          case 'support':
            iconData = Icons.support_agent;
            break;
          case 'chat':
            iconData = Icons.chat;
            break;
          default:
            iconData = Icons.info;
        }

        // Convert string color to Color
        Color color;
        switch (feature['color'].toString()) {
          case 'blue':
            color = Colors.blue;
            break;
          case 'green':
            color = Colors.green;
            break;
          case 'orange':
            color = Colors.orange;
            break;
          case 'purple':
            color = Colors.purple;
            break;
          case 'red':
            color = Colors.red;
            break;
          case 'teal':
            color = Colors.teal;
            break;
          default:
            color = ColorManager.primary;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    iconData,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  feature['title'].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature['description'].toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorManager.textMedium,
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

  static Widget buildTeachersSection(List teachers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet Our Expert Instructors',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            color: ColorManager.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 20),
        if (teachers.isEmpty)
          buildEmptyState(
            'No instructor details available yet',
            'We\'re currently finalizing our instructor roster.',
            Icons.people,
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ColorManager.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        height: 120,
                        child: ImageNetwork(
                          image: teacher['ProfilePicURL'] ?? '',
                          height: 120,
                          width: 100,
                          fitAndroidIos: BoxFit.cover,
                          onLoading: Center(
                            child: CircularProgressIndicator(
                              color: ColorManager.primary,
                              strokeWidth: 2,
                            ),
                          ),
                          onError: Icon(
                            Icons.person,
                            size: 60,
                            color: ColorManager.primary.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    teacher['Name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: ColorManager.textDark,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          ColorManager.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      teacher['Subject'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
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
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.work,
                                    size: 16,
                                    color: ColorManager.textMedium,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${teacher['Experience'] ?? 'N/A'} years experience',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ColorManager.textMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    teacher['Rating'] ?? '4.8',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ColorManager.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  static Widget buildCourseTimeline(
      List notices, String scheduleDocumentUrl, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Schedule',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            color: ColorManager.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 20),

        // Schedule PDF document card
        if (scheduleDocumentUrl.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: InkWell(
              onTap: () => _openPdf(context, scheduleDocumentUrl),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ColorManager.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month,
                        color: ColorManager.primary, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detailed Schedule',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View the complete course timetable, including class dates, times, and topics',
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorManager.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ColorManager.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.file_download,
                        color: Colors.white,
                        size: 20,
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
            Icons.calendar_today,
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: notices.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ColorManager.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ColorManager.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              notices[index].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorManager.textDark,
                              ),
                            ),
                          ),
                          if (index < notices.length - 1)
                            Container(
                              margin: const EdgeInsets.only(left: 20),
                              width: 2,
                              height: 20,
                              color: ColorManager.secondary.withOpacity(0.3),
                            ),
                        ],
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
      BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Materials',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            color: ColorManager.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 20),

        // Browse All Subjects Card
        isEnrolled
            ? InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CourseMaterials(courseName: courseName),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorManager.primary.withOpacity(0.8),
                        ColorManager.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.book, color: Colors.white, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Browse All Subjects',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View all course subjects and materials',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: ColorManager.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Enroll to access all subjects',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

        // Key Documents Section
        Text(
          'Key Documents',
          style: TextStyle(
            fontSize: 18,
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
            Icons.book,
          )
        else
          Column(
            children: [
              if (data['SyllabusPDF'] != null && data['SyllabusPDF'].isNotEmpty)
                buildMaterialCard(
                  'Syllabus',
                  'Complete course syllabus and learning objectives',
                  Icons.menu_book,
                  () => _openPdf(context, data['SyllabusPDF']),
                ),
              if (data['PreviewPDF'] != null && data['PreviewPDF'].isNotEmpty)
                buildMaterialCard(
                  'Preview Content',
                  'Sample lessons and exercises from the course',
                  Icons.visibility,
                  () => _openPdf(context, data['PreviewPDF']),
                ),
              if (data['WorksheetsPDF'] != null &&
                  data['WorksheetsPDF'].isNotEmpty)
                buildMaterialCard(
                  'Worksheets',
                  'Practice materials and homework assignments',
                  Icons.assignment,
                  () => _openPdf(context, data['WorksheetsPDF']),
                ),
              if (data['ReferencesPDF'] != null &&
                  data['ReferencesPDF'].isNotEmpty)
                buildMaterialCard(
                  'References',
                  'Additional reading materials and resources',
                  Icons.library_books,
                  () => _openPdf(context, data['ReferencesPDF']),
                ),

              // Display dynamic key documents from Firebase
              ...keyDocuments.map((document) {
                return buildMaterialCard(
                  document['title'] ?? 'Document',
                  document['description'] ?? 'Course document',
                  _getIconForDocType(document['type'] ?? 'document'),
                  () => _openPdf(context, document['url'] ?? ''),
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
        return Icons.menu_book;
      case 'worksheet':
        return Icons.assignment;
      case 'reference':
        return Icons.library_books;
      case 'lecture':
        return Icons.school;
      case 'preview':
        return Icons.visibility;
      default:
        return Icons.insert_drive_file;
    }
  }

  static Widget buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: ColorManager.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorManager.primary.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: ColorManager.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorManager.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ColorManager.textMedium),
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
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ColorManager.primary.withOpacity(0.1)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: ColorManager.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorManager.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorManager.primary,
                    borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorManager.primary.withOpacity(0.8), ColorManager.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎓 Ready to Start Learning?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join thousands of students already enrolled in this course. Start your learning journey today!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildEnrollmentStat('4.8', 'Rating'),
              _buildEnrollmentStat('2,500+', 'Students'),
              _buildEnrollmentStat('24/7', 'Support'),
            ],
          ),

          // Membership offer section
          if (discountPercentage > 0 && !isMember) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_membership,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
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
                          'Join for ₹1000/year and get exclusive discounts on all courses',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    // Use Builder to get context from the widget tree
                    builder: (context) => TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MembershipScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ColorManager.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('JOIN'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: size.width * 0.7,
            height: 56,
            child: ElevatedButton(
              onPressed: isEnrolled || isProcessingPayment
                  ? null
                  : () => onEnrollPressed(price),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ColorManager.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                          child: CircularProgressIndicator(),
                        ),
                        SizedBox(width: 12),
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
                        const SizedBox(width: 12),
                        Text(
                          price > 0
                              ? 'PAY ₹${finalPrice.toStringAsFixed(0)} & ENROLL'
                              : 'ENROLL NOW',
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Already Enrolled',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildEnrollmentStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
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
          content: const Text('PDF document not available'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
