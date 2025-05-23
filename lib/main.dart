import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/Courses/allcourses.dart';
import 'package:luyip_website_edu/Courses/course_deatils.dart';
import 'package:luyip_website_edu/Courses/course_details/course_details.dart';
import 'package:luyip_website_edu/admin_dashboard/sidebar.dart';
import 'package:luyip_website_edu/auth/loginscreen.dart';
import 'package:luyip_website_edu/firebase_options.dart';
import 'package:luyip_website_edu/franchise_dahsboard/franchise_dashboard.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/coming_soon.dart';
import 'package:luyip_website_edu/helpers/video_helper.dart';
import 'package:luyip_website_edu/home/admin_dashboard.dart';

import 'package:luyip_website_edu/home/student_dashboard.dart';

import 'package:luyip_website_edu/student_dashboard/student_dashboard.dart';
import 'package:luyip_website_edu/teacher/teacherdashboard.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EducationApp());
  if (kIsWeb) {
    initializeSecurePlayer();
  }
}

class EducationApp extends StatelessWidget {
  const EducationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Educational Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16.0),
          bodyMedium: TextStyle(fontSize: 14.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    checkUserAuth();
  }

  Future<void> checkUserAuth() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      // User is signed in, now determine their role
      try {
        // Check each role collection to find the user
        for (String role in ['student', 'teacher', 'franchise', 'admin']) {
          DocumentSnapshot userDoc = await _firestore
              .collection('Users')
              .doc(role)
              .collection('accounts')
              .doc(currentUser.email)
              .get();

          if (userDoc.exists) {
            setState(() {
              userRole = role;
              isLoading = false;
            });
            return;
          }
        }

        // If no role found, sign out
        await _auth.signOut();
        setState(() {
          isLoading = false;
        });
      } catch (e) {
        print("Error finding user role: $e");
        await _auth.signOut();
        setState(() {
          isLoading = false;
        });
      }
    } else {
      // No user is signed in
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', width: 120, height: 120),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading your educational journey...'),
            ],
          ),
        ),
      );
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      return const HomePage(); // Show homepage with login/register option
    }

    // User is logged in, redirect based on role
    switch (userRole) {
      case 'student':
        return const StudentDashboardContainer();
      case 'teacher':
        return const TeacherDashboard();
      case 'franchise':
        return const FranchiseDashboard();
      case 'admin':
        return const AdminDashboardContainer();
      default:
        return const HomePage();
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  bool isScrolled = false;
  final ScrollController _scrollController = ScrollController();

  // Data holders
  List<Map<String, dynamic>> banners = [];
  List<Map<String, dynamic>> stats = [];
  List<Map<String, dynamic>> announcements = [];
  List<Map<String, dynamic>> testimonials = [];
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> upcomingEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchHomePageData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 10 && !isScrolled) {
      setState(() {
        isScrolled = true;
      });
    } else if (_scrollController.offset <= 10 && isScrolled) {
      setState(() {
        isScrolled = false;
      });
    }
  }

  Future<void> _fetchHomePageData() async {
    try {
      // Fetch website general data (banners, announcements)
      final websiteDoc =
          await _firestore.collection('website_general').doc('dashboard').get();

      if (websiteDoc.exists) {
        final data = websiteDoc.data() as Map<String, dynamic>;

        // Get banners
        if (data.containsKey('banners')) {
          setState(() {
            banners = List<Map<String, dynamic>>.from(data['banners'] ?? []);
          });
        } else {
          // Use default banners if none are configured
          _setDefaultBanners();
        }

        // Get announcements
        if (data.containsKey('announcements')) {
          setState(() {
            announcements =
                List<Map<String, dynamic>>.from(data['announcements'] ?? []);
          });
        }

        // Get testimonials
        if (data.containsKey('testimonials')) {
          setState(() {
            testimonials =
                List<Map<String, dynamic>>.from(data['testimonials'] ?? []);
          });
        }

        // Get upcoming events
        if (data.containsKey('upcomingEvents')) {
          setState(() {
            upcomingEvents =
                List<Map<String, dynamic>>.from(data['upcomingEvents'] ?? []);
          });
        }
      } else {
        _setDefaultBanners();
      }

      // Fetch platform stats
      final statsDoc =
          await _firestore.collection('website_general').doc('stats').get();

      if (statsDoc.exists) {
        final data = statsDoc.data() as Map<String, dynamic>;
        setState(() {
          stats = List<Map<String, dynamic>>.from(data['stats'] ?? []);
        });
      } else {
        _setDefaultStats();
      }

      // Fetch featured courses
    } catch (e) {
      print('Error fetching homepage data: $e');
      _setDefaultBanners();
      _setDefaultStats();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Default data setting methods remain the same
  void _setDefaultBanners() {
    setState(() {
      banners = [
        {
          'title': 'Master Physics',
          'subtitle': 'Learn from top educators',
          'cta': 'Join Now',
          'color': 'purple',
        },
        {
          'title': 'JEE Preparation',
          'subtitle': 'Comprehensive course materials',
          'cta': 'Enroll Today',
          'color': 'blue',
        },
        {
          'title': 'NEET Success',
          'subtitle': 'Achieve your medical dreams',
          'cta': 'Get Started',
          'color': 'green',
        },
        {
          'title': 'Board Exams',
          'subtitle': 'Score high with our expert guidance',
          'cta': 'Learn More',
          'color': 'orange',
        },
      ];
    });
  }

  void _setDefaultStats() {
    setState(() {
      stats = [
        {
          'count': '15Million+',
          'label': 'Happy Students',
          'color': 'orange',
        },
        {
          'count': '24000+',
          'label': 'Mock Tests',
          'color': 'pink',
        },
        {
          'count': '14000+',
          'label': 'Video Lectures',
          'color': 'blue',
        },
        {
          'count': '80000+',
          'label': 'Practice Papers',
          'color': 'purple',
        },
      ];
    });
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'purple':
        return const Color(0xFF5E4DCD); // Primary brand color
      case 'blue':
        return Colors.blue.shade600;
      case 'green':
        return Colors.green.shade600;
      case 'orange':
        return Colors.orange.shade600;
      case 'pink':
        return Colors.pink.shade600;
      default:
        return const Color(0xFF5E4DCD); // Default to primary
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Main content with scroll
                SafeArea(
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Ensure scrolling always works
                    slivers: [
                      // Top Navigation Bar padding for fixed navbar
                      SliverToBoxAdapter(
                        child: SizedBox(
                            height: isMobile
                                ? 80
                                : (isScrolled
                                    ? 70
                                    : 0)), // Increased mobile height
                      ),

                      // Hero Banner with dynamic content
                      SliverToBoxAdapter(
                        child: HeroBanner(
                          banners: banners,
                          getColorFromString: _getColorFromString,
                        ),
                      ),

                      // Platform Stats Section with dynamic content
                      SliverToBoxAdapter(
                        child: PlatformStatsSection(
                          stats: stats,
                          getColorFromString: _getColorFromString,
                        ),
                      ),

                      // Featured Courses Section
                      SliverToBoxAdapter(
                        child: FeaturedCoursesSection(
                          getColorFromString: _getColorFromString,
                        ),
                      ),

                      // Announcements Section (if there are any)
                      if (announcements.isNotEmpty)
                        SliverToBoxAdapter(
                          child:
                              AnnouncementsBanner(announcements: announcements),
                        ),

                      // Testimonials Section (if there are any)
                      if (testimonials.isNotEmpty)
                        SliverToBoxAdapter(
                          child:
                              TestimonialsSection(testimonials: testimonials),
                        ),

                      // Upcoming Events Section (if there are any)
                      if (upcomingEvents.isNotEmpty)
                        SliverToBoxAdapter(
                          child: UpcomingEventsSection(events: upcomingEvents),
                        ),

                      // Get Started Section
                      SliverToBoxAdapter(
                        child: GetStartedSection(),
                      ),

                      // Footer
                      SliverToBoxAdapter(
                        child: Footer(),
                      ),
                    ],
                  ),
                ),

                // Fixed position navbar that changes with scroll
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: isScrolled
                        ? Colors.white.withOpacity(0.95)
                        : Colors.transparent,
                    padding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: isScrolled ? 8 : 10),
                    child: NavBar(isScrolled: isScrolled),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Uri phoneUri = Uri(scheme: 'tel', path: '+911234567890');
          if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
          } else {
            // Contact functionality fallback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Contact support feature coming soon!')),
            );
          }
        },
        backgroundColor: const Color(0xFF5E4DCD),
        child: const Icon(Icons.call),
      ),
    );
  }
}

class NavBar extends StatefulWidget {
  final bool isScrolled;

  const NavBar({
    Key? key,
    this.isScrolled = false,
  }) : super(key: key);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  bool _showMenu = false;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 20, vertical: widget.isScrolled ? 8 : 10),
      decoration: BoxDecoration(
        color: widget.isScrolled ? Colors.white : Colors.white.withOpacity(0.9),
        boxShadow: widget.isScrolled
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        borderRadius: widget.isScrolled ? null : BorderRadius.circular(0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E4DCD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Luiyp Education',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              // Menu Items - Responsive
              if (!isMobile)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavigationItem('Home', () {
                        // Stay on homepage
                      }),
                      _buildNavigationItem('Courses', () {
                        // Navigate to courses screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  AllCoursesScreen(userType: 'student')),
                        );
                      }),
                      _buildNavigationItem('Franchise', () {
                        // Navigate to franchise info screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(
                              userRole: 'franchise',
                            ),
                          ),
                        );
                      }),
                      _buildNavigationItem('Teacher', () {
                        // Navigate to teacher info screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(
                              userRole: 'teacher',
                            ),
                          ),
                        );
                      }),
                      _buildNavigationItem('Verify Certificate', () {
                        // Navigate to certificate verification screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ComingSoonScreen(
                                  pageName: 'Page not found')),
                        );
                      }),
                      _buildNavigationItem('About Us', () {
                        // Navigate to about screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('About Us section coming soon!')),
                        );
                      }),
                      _buildNavigationItem('Contact', () {
                        // Navigate to contact screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Contact information coming soon!')),
                        );
                      }),
                    ],
                  ),
                )
              else
                // On mobile, show a menu button
                IconButton(
                  icon: Icon(
                    _showMenu ? Icons.close : Icons.menu,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _showMenu = !_showMenu;
                    });
                  },
                ),

              // Login/Register Button
              if (!isMobile)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen(
                                userRole: 'student',
                              )),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E4DCD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Login/Register',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),

          // Mobile menu dropdown
          if (isMobile && _showMenu)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileMenuItem('Home', Icons.home, () {
                    setState(() {
                      _showMenu = false;
                    });
                  }),
                  _buildMobileMenuItem('Courses', Icons.school, () {
                    setState(() {
                      _showMenu = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Placeholder(
                          child: Center(child: Text('All Courses Screen')),
                        ),
                      ),
                    );
                  }),
                  _buildMobileMenuItem('Franchise', Icons.business, () {
                    setState(() {
                      _showMenu = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(
                          userRole: 'franchise',
                        ),
                      ),
                    );
                  }),
                  _buildMobileMenuItem('Teacher', Icons.person_outline, () {
                    setState(() {
                      _showMenu = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(
                          userRole: 'teacher',
                        ),
                      ),
                    );
                  }),
                  _buildMobileMenuItem('Verify Certificate', Icons.verified,
                      () {
                    setState(() {
                      _showMenu = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(
                          userRole: '',
                        ),
                      ),
                    );
                  }),
                  _buildMobileMenuItem('About Us', Icons.info, () {
                    setState(() {
                      _showMenu = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('About Us section coming soon!')),
                    );
                  }),
                  _buildMobileMenuItem('Contact', Icons.contact_phone, () {
                    setState(() {
                      _showMenu = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Contact information coming soon!')),
                    );
                  }),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen(
                                    userRole: 'student',
                                  )),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E4DCD),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Login/Register'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF5E4DCD)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  final List<Map<String, dynamic>> banners;
  final Color Function(String) getColorFromString;

  const HeroBanner({
    Key? key,
    required this.banners,
    required this.getColorFromString,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 30 : 40, // Increased mobile padding
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        image: const DecorationImage(
          image: AssetImage('assets/images/pattern_background.png'),
          fit: BoxFit.cover,
          opacity: 0.05,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isMobile ? 10 : 40), // Reduced top spacing on mobile

          // Main Title - Updated for better mobile visibility
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile
                  ? screenSize.width - 40
                  : 800, // Full width minus padding on mobile
            ),
            child: Text(
              'Building Futures Through Quality Education',
              style: TextStyle(
                fontSize: isMobile
                    ? 24
                    : 42, // Slightly smaller on mobile but still visible
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: isMobile ? 1.3 : 1.2, // Better line height for mobile
              ),
              textAlign: TextAlign.center,
              maxLines: isMobile ? 3 : 2, // Allow more lines on mobile
            ),
          ),

          SizedBox(height: isMobile ? 12 : 16),

          // Subtitle - Updated for mobile
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? screenSize.width - 40 : 700,
            ),
            child: Text(
              'Luiyp Education aims to transform education in India by providing affordable and quality learning opportunities for all.',
              style: TextStyle(
                fontSize: isMobile ? 14 : 18,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: isMobile ? 4 : 3, // Allow more lines on mobile
            ),
          ),

          SizedBox(height: isMobile ? 30 : 40), // Reduced spacing on mobile

          // Image Carousel Slider with dynamic content
          ImageCarouselSlider(
            banners: banners,
            getColorFromString: getColorFromString,
          ),

          // "Bharat's Trusted" section - Modified for mobile
          Container(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 40 : 60, // Reduced padding on mobile
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // First line
                Text(
                  "Bharat's ",
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 42, // Much smaller on mobile
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Second line
                Text(
                  "Trusted & Affordable",
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 42,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.primary, // Using consistent color
                  ),
                  textAlign: TextAlign.center,
                ),
                // Third line
                Text(
                  "Educational Platform",
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImageCarouselSlider extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final Color Function(String) getColorFromString;

  const ImageCarouselSlider({
    Key? key,
    required this.banners,
    required this.getColorFromString,
  }) : super(key: key);

  @override
  State<ImageCarouselSlider> createState() => _ImageCarouselSliderState();
}

class _ImageCarouselSliderState extends State<ImageCarouselSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Column(
      children: [
        CarouselSlider(
          items: List.generate(
            widget.banners.length,
            (index) => _buildCarouselItem(index, isMobile),
          ),
          options: CarouselOptions(
            height: isMobile ? 350 : 400,
            viewportFraction: 1.0,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            return Container(
              width: 12.0,
              height: 12.0,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index
                    ? const Color(0xFF5E4DCD)
                    : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(int index, bool isMobile) {
    final banner = widget.banners[index];
    final colorStr = banner['color'] ?? 'purple';
    final color = widget.getColorFromString(colorStr);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Content container
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: isMobile
                ? _buildMobileCarouselContent(banner, color)
                : _buildDesktopCarouselContent(banner, color),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCarouselContent(
      Map<String, dynamic> banner, Color color) {
    return Row(
      children: [
        // Text content
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                banner['title'] ?? 'Educational Excellence',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                banner['subtitle'] ?? 'Join our platform for success',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(
                        userRole: 'student',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  banner['cta'] ?? 'Get Started',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Image space (using placeholders or actual images)
        Expanded(
          flex: 2,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: banner['imageUrl'] != null &&
                    banner['imageUrl'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      banner['imageUrl'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child:
                              Icon(Icons.school, size: 80, color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child:
                              Icon(Icons.school, size: 80, color: Colors.white),
                        );
                      },
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school, size: 80, color: Colors.white),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Premium Course',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCarouselContent(Map<String, dynamic> banner, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Banner image
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: banner['imageUrl'] != null &&
                  banner['imageUrl'].toString().isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.network(
                    banner['imageUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child:
                            Icon(Icons.school, size: 50, color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child:
                            Icon(Icons.school, size: 50, color: Colors.white),
                      );
                    },
                  ),
                )
              : const Icon(Icons.school, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 20),

        // Text content
        Text(
          banner['title'] ?? 'Educational Excellence',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          banner['subtitle'] ?? 'Join our platform for success',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(
                  userRole: 'student',
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            banner['cta'] ?? 'Get Started',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class AnnouncementsBanner extends StatelessWidget {
  final List<Map<String, dynamic>> announcements;

  const AnnouncementsBanner({
    Key? key,
    required this.announcements,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(vertical: 40, horizontal: isMobile ? 20 : 40),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.announcement_rounded,
                color: const Color(0xFF5E4DCD),
                size: isMobile ? 24 : 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Latest Announcements',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Fixed height container for announcements to prevent layout jumps
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isMobile ? 500 : 400,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  // Desktop layout - grid
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: announcements.length.clamp(0, 6),
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return _buildAnnouncementCard(announcement);
                    },
                  );
                } else if (constraints.maxWidth > 600) {
                  // Tablet layout - 2 columns
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: announcements.length.clamp(0, 4),
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return _buildAnnouncementCard(announcement);
                    },
                  );
                } else {
                  // Mobile layout - single column with fixed height
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: announcements.length.clamp(0, 3),
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAnnouncementCard(announcement),
                      );
                    },
                  );
                }
              },
            ),
          ),

          if (announcements.length > 3)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to announcements page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('View all announcements coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View All Announcements'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5E4DCD),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ensure minimum required size
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    announcement['title'] ?? 'Announcement',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF5E4DCD),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    announcement['date'] ?? '',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement['content'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              maxLines: 3, // Limit number of lines for content
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Read more functionality
                },
                child: const Text(
                  'Read More',
                  style: TextStyle(
                    color: Color(0xFF5E4DCD),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlatformStatsSection extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  final Color Function(String) getColorFromString;

  const PlatformStatsSection({
    Key? key,
    required this.stats,
    required this.getColorFromString,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        image: const DecorationImage(
          image: AssetImage('assets/images/dots_pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.05,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Our Impact in Numbers',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Join millions of students who have already transformed their educational journey with Luiyp Education',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                // Desktop layout - row
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: stats
                      .map((stat) =>
                          _buildStatCard(stat, constraints.maxWidth, true))
                      .toList(),
                );
              } else if (constraints.maxWidth > 600) {
                // Tablet layout - 2x2 grid
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: stats
                      .map((stat) => _buildStatCard(
                          stat, constraints.maxWidth / 2 - 30, false))
                      .toList(),
                );
              } else {
                // Mobile layout - 2x2 grid with smaller cards
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: stats
                      .map((stat) => _buildStatCard(
                          stat, constraints.maxWidth / 2 - 24, false))
                      .toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      Map<String, dynamic> stat, double width, bool isDesktop) {
    final colorStr = stat['color'] ?? 'purple';
    final color = getColorFromString(colorStr);
    final bgColor = color.withOpacity(0.1);

    final cardWidth = isDesktop ? width * 0.2 : width;
    final cardHeight = isDesktop ? 180.0 : 150.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.all(isDesktop ? 10 : 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat['count'] ?? '0+',
            style: TextStyle(
              fontSize: isDesktop ? 42 : 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              stat['label'] ?? 'Stat',
              style: TextStyle(
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class FeaturedCoursesSection extends StatefulWidget {
  final Color Function(String) getColorFromString;

  const FeaturedCoursesSection({
    Key? key,
    required this.getColorFromString,
  }) : super(key: key);

  @override
  State<FeaturedCoursesSection> createState() => _FeaturedCoursesSectionState();
}

class _FeaturedCoursesSectionState extends State<FeaturedCoursesSection> {
  bool isLoading = true;
  List<Map<String, dynamic>> courses = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchFeaturedCourses();
  }

  Future<void> _fetchFeaturedCourses() async {
    try {
      // Query the 'All Courses' collection, limit to 4 courses
      final QuerySnapshot coursesSnapshot = await _firestore
          .collection('All Courses')
          .limit(4) // Limiting to 4 featured courses
          .get();

      if (coursesSnapshot.docs.isNotEmpty) {
        setState(() {
          courses = coursesSnapshot.docs.map((doc) {
            // Convert Firestore data to our course format
            return {
              'title': doc['Course Name'] ?? 'Course Title',
              'instructor': doc['Instructor'] ?? 'Instructor',
              'price': doc['Course Price'] ?? '₹0',
              'discountPrice':
                  doc['Discount Price'] ?? doc['Course Price'] ?? '₹0',
              'rating': doc['Rating'] ?? 4.5,
              'students': doc['Students'] ?? 0,
              'image': doc['Course Img Link'] ?? '',
              'category': doc['Category'] ?? 'General',
              'color': doc['Color'] ?? 'purple',
            };
          }).toList();
          isLoading = false;
        });
      } else {
        // No courses found
        setState(() {
          courses = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching featured courses: $e');
      setState(() {
        courses = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    // If no courses and not loading, don't show the section
    if (courses.isEmpty && !isLoading) {
      return const SizedBox.shrink(); // Return empty widget
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: 20,
      ),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Featured Courses',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Explore our top-rated courses designed to help you achieve academic excellence',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),

          // Loading indicator or courses grid/list
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF5E4DCD),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 1100) {
                      // Desktop layout - 4 columns
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return _buildCourseCard(course);
                        },
                      );
                    } else if (constraints.maxWidth > 800) {
                      // Tablet layout - 3 columns
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return _buildCourseCard(course);
                        },
                      );
                    } else if (constraints.maxWidth > 600) {
                      // Small tablet - 2 columns
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return _buildCourseCard(course);
                        },
                      );
                    } else {
                      // Mobile layout - single column with horizontal scroll
                      return SizedBox(
                        height: 420,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            return Container(
                              width: 280,
                              margin: const EdgeInsets.only(right: 16),
                              child: _buildCourseCard(course),
                            );
                          },
                        ),
                      );
                    }
                  },
                ),

          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to all courses page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AllCoursesScreen(userType: 'student'),
                ),
              );
            },
            icon: const Icon(Icons.school),
            label: const Text('View All Courses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E4DCD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final colorStr = course['color'] ?? 'purple';
    final color = widget.getColorFromString(colorStr);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: course['image'] != null &&
                        course['image'].toString().isNotEmpty
                    ? Image.network(
                        course['image'],
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 160,
                            width: double.infinity,
                            color: color.withOpacity(0.2),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: color,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 160,
                            width: double.infinity,
                            color: color.withOpacity(0.2),
                            child: Icon(
                              Icons.school,
                              size: 60,
                              color: color,
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 160,
                        width: double.infinity,
                        color: color.withOpacity(0.2),
                        child: Icon(
                          Icons.school,
                          size: 60,
                          color: color,
                        ),
                      ),
              ),
              // Category badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    course['category'] ?? 'Course',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course title
                  Text(
                    course['title'] ?? 'Course Title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Instructor
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          course['instructor'] ?? 'Instructor',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Students count
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course['students'] ?? 0} students',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < (course['rating'] ?? 0).floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course['rating'] ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['price'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            course['discountPrice'] ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),

                      // Enroll button
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to course details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseDetails(
                                userRole: 'student',
                                coursename: course['title'] ?? 'Course Title',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Enroll'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TestimonialsSection extends StatelessWidget {
  final List<Map<String, dynamic>> testimonials;

  const TestimonialsSection({
    Key? key,
    required this.testimonials,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: 20,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'What Our Students Say',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Hear from our students about their learning experience with Physics Wallah',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),

          // Fixed height testimonials carousel
          SizedBox(
            height: isMobile ? 320 : 280,
            child: CarouselSlider(
              options: CarouselOptions(
                height: isMobile ? 320 : 280,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: isMobile ? 0.9 : 0.5,
                initialPage: 0,
                autoPlayInterval: const Duration(seconds: 5),
              ),
              items: testimonials.map((testimonial) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: _buildTestimonialCard(testimonial),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(Map<String, dynamic> testimonial) {
    final String name = testimonial['name'] ?? 'Student';
    final String courseName = testimonial['courseName'] ?? '';
    final String content = testimonial['content'] ?? '';
    final double rating = testimonial['rating'] is int
        ? (testimonial['rating'] as int).toDouble()
        : (testimonial['rating'] as double? ?? 5.0);
    final String photoUrl = testimonial['photoUrl'] ?? '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Use minimum size needed
          children: [
            // Quote icon
            const Icon(
              Icons.format_quote,
              color: Color(0xFF5E4DCD),
              size: 32,
            ),
            const SizedBox(height: 16),

            // Testimonial content with limited lines
            Expanded(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 4, // Limit number of lines
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Student info
            Row(
              children: [
                // Student photo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E4DCD).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: photoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.person,
                              color: Color(0xFF5E4DCD),
                              size: 25,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Color(0xFF5E4DCD),
                          size: 25,
                        ),
                ),
                const SizedBox(width: 16),

                // Student details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Rating
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating.floor() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
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
}

Widget _buildTestimonialCard(Map<String, dynamic> testimonial) {
  final String name = testimonial['name'] ?? 'Student';
  final String courseName = testimonial['courseName'] ?? '';
  final String content = testimonial['content'] ?? '';
  final double rating = testimonial['rating'] is int
      ? (testimonial['rating'] as int).toDouble()
      : (testimonial['rating'] as double? ?? 5.0);
  final String photoUrl = testimonial['photoUrl'] ?? '';

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quote icon
          const Icon(
            Icons.format_quote,
            color: Color(0xFF5E4DCD),
            size: 32,
          ),
          const SizedBox(height: 16),

          // Testimonial content
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // Student info
          Row(
            children: [
              // Student photo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF5E4DCD).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: photoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.person,
                            color: Color(0xFF5E4DCD),
                            size: 25,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Color(0xFF5E4DCD),
                        size: 25,
                      ),
              ),
              const SizedBox(width: 16),

              // Student details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courseName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Rating
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating.floor() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
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

class UpcomingEventsSection extends StatelessWidget {
  final List<Map<String, dynamic>> events;

  const UpcomingEventsSection({
    Key? key,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: 20,
      ),
      color: const Color(0xFF5E4DCD).withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text(
                    'Join our workshops, webinars, and special events to enhance your learning experience',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Fixed height container for events grid/list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isMobile ? 250 : 500,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  // Desktop layout - 3 columns
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: events.length.clamp(0, 6),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventCard(event);
                    },
                  );
                } else if (constraints.maxWidth > 600) {
                  // Tablet layout - 2 columns
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: events.length.clamp(0, 4),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventCard(event);
                    },
                  );
                } else {
                  // Mobile layout - horizontal scroll with fixed height
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: events.length.clamp(0, 6),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Container(
                        width: 300,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildEventCard(event),
                      );
                    },
                  );
                }
              },
            ),
          ),

          // View all events button
          if (events.length > 6)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to events page
                  },
                  icon: const Icon(Icons.event),
                  label: const Text('View All Events'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E4DCD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    // Extract event color
    Color categoryColor = _getCategoryColor(event['category'] ?? '');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: categoryColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Use minimum size needed
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event['category'] ?? 'Event',
                  style: TextStyle(
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Event title
              Text(
                event['title'] ?? 'Event Title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              const Spacer(),

              // Event time
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event['time'] ?? 'Upcoming',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Register button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle event registration
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: categoryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Register Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'web development':
        return Colors.blue.shade700;
      case 'data structures':
        return Colors.red.shade600;
      case 'ui/ux design':
        return Colors.orange.shade600;
      case 'jee':
        return Colors.purple.shade600;
      case 'neet':
        return Colors.green.shade600;
      case 'foundation':
        return Colors.teal.shade600;
      default:
        return const Color(0xFF5E4DCD);
    }
  }
}

Widget _buildEventCard(Map<String, dynamic> event) {
  // Extract event color
  Color categoryColor = _getCategoryColor(event['category'] ?? '');

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: categoryColor,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                event['category'] ?? 'Event',
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Event title
            Text(
              event['title'] ?? 'Event Title',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            const Spacer(),

            // Event time
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  event['time'] ?? 'Upcoming',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Register button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle event registration
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
                child: const Text('Register Now'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Color _getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'web development':
      return Colors.blue.shade700;
    case 'data structures':
      return Colors.red.shade600;
    case 'ui/ux design':
      return Colors.orange.shade600;
    case 'jee':
      return Colors.purple.shade600;
    case 'neet':
      return Colors.green.shade600;
    case 'foundation':
      return Colors.teal.shade600;
    default:
      return const Color(0xFF5E4DCD);
  }
}

class GetStartedSection extends StatelessWidget {
  const GetStartedSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 60 : 80,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF5E4DCD),
            Colors.purple.shade700,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Ready to Transform Your Learning Journey?',
            style: TextStyle(
              fontSize: isMobile ? 24 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              'Join Luiyp Education today and experience the best in educational content, expert guidance, and comprehensive exam preparation.',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(
                        userRole: 'student',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Get Started'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5E4DCD),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 32,
                    vertical: isMobile ? 16 : 20,
                  ),
                  textStyle: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to contact page
                },
                icon: const Icon(Icons.phone),
                label: const Text('Contact Us'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 32,
                    vertical: isMobile ? 16 : 20,
                  ),
                  textStyle: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({Key? key}) : super(key: key);

  // Navigation helper method
  void _navigateToPage(BuildContext context, String pageName) {
    Widget targetPage;

    switch (pageName) {
      case 'About Us':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Courses':
        targetPage = const AllCoursesScreen(userType: 'Page not found');
        break;
      case 'Study Materials':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Test Series':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Success Stories':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Blog':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Admin':
        targetPage = const LoginScreen(userRole: 'admin');
        break;
      case 'NCERT Solutions':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Sample Papers':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Previous Year Papers':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Scholarships':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Career Guidance':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'FAQ':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Terms & Conditions':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Privacy Policy':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Refund Policy':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Cookie Policy':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Disclaimer':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      case 'Contact Us':
        targetPage = const ComingSoonScreen(pageName: 'Page not found');
        break;
      default:
        // For unhandled cases, show a coming soon screen
        targetPage = ComingSoonScreen(pageName: pageName);
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 40,
      ),
      color: Colors.grey.shade900,
      child: Column(
        children: [
          // Footer content
          isMobile
              ? _buildMobileFooterContent(context)
              : _buildDesktopFooterContent(context),

          const SizedBox(height: 40),
          const Divider(color: Colors.grey),
          const SizedBox(height: 20),

          // Copyright and social media
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '© ${DateTime.now().year} Luiyp Education. All rights reserved.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              if (!isMobile) _buildSocialMediaIcons(),
            ],
          ),

          if (isMobile) const SizedBox(height: 20),
          if (isMobile) _buildSocialMediaIcons(),
        ],
      ),
    );
  }

  Widget _buildDesktopFooterContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company info
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E4DCD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Luiyp Education',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Luiyp Education is India\'s leading educational platform dedicated to providing affordable and quality education to students across the country.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.email,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'support@luiypedu.com',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+91 1234567890',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 40),

        // Quick links
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Links',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildFooterLink(context, 'About Us'),
              _buildFooterLink(context, 'Courses'),
              _buildFooterLink(context, 'Study Materials'),
              _buildFooterLink(context, 'Test Series'),
              _buildFooterLink(context, 'Success Stories'),
              _buildFooterLink(context, 'Blog'),
              _buildFooterLink(context, 'Admin'),
            ],
          ),
        ),

        const SizedBox(width: 40),

        // Resources
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resources',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildFooterLink(context, 'NCERT Solutions'),
              _buildFooterLink(context, 'Sample Papers'),
              _buildFooterLink(context, 'Previous Year Papers'),
              _buildFooterLink(context, 'Scholarships'),
              _buildFooterLink(context, 'Career Guidance'),
              _buildFooterLink(context, 'FAQ'),
            ],
          ),
        ),

        const SizedBox(width: 40),

        // Legal
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildFooterLink(context, 'Terms & Conditions'),
              _buildFooterLink(context, 'Privacy Policy'),
              _buildFooterLink(context, 'Refund Policy'),
              _buildFooterLink(context, 'Cookie Policy'),
              _buildFooterLink(context, 'Disclaimer'),
              _buildFooterLink(context, 'Contact Us'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooterContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5E4DCD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Luiyp Education',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Luiyp Education is India\'s leading educational platform dedicated to providing affordable and quality education to students across the country.',
          style: TextStyle(
            color: Colors.grey.shade400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(
              Icons.email,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'support@luiypedu.com',
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.phone,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '+91 1234567890',
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // Expandable sections
        _buildMobileExpandableSection(context, 'Quick Links', [
          'About Us',
          'Courses',
          'Study Materials',
          'Test Series',
          'Success Stories',
          'Blog',
          'Admin',
        ]),

        _buildMobileExpandableSection(context, 'Resources', [
          'NCERT Solutions',
          'Sample Papers',
          'Previous Year Papers',
          'Scholarships',
          'Career Guidance',
          'FAQ',
        ]),

        _buildMobileExpandableSection(context, 'Legal', [
          'Terms & Conditions',
          'Privacy Policy',
          'Refund Policy',
          'Cookie Policy',
          'Disclaimer',
          'Contact Us',
        ]),
      ],
    );
  }

  Widget _buildMobileExpandableSection(
      BuildContext context, String title, List<String> links) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.grey.shade400,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: links.map((link) => _buildFooterLink(context, link)).toList(),
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToPage(context, text),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(Icons.facebook, Colors.blue),
        _buildSocialIcon(Icons.youtube_searched_for, Colors.red),
        _buildSocialIcon(Icons.telegram, Colors.blue.shade300),
        _buildSocialIcon(Icons.camera_alt, Colors.pink),
        _buildSocialIcon(Icons.link, Colors.grey),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// Generic Coming Soon Screen for unimplemented pages
