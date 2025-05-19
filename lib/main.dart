import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/admin_dashboard/sidebar.dart';
import 'package:luyip_website_edu/auth/loginscreen.dart';
import 'package:luyip_website_edu/firebase_options.dart';
import 'package:luyip_website_edu/home/admin_dashboard.dart';
import 'package:luyip_website_edu/home/franchise_dashboard.dart';
import 'package:luyip_website_edu/home/student_dashboard.dart';
import 'package:luyip_website_edu/home/teacher_dashboard.dart';
import 'package:luyip_website_edu/student_dashboard/student_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EducationApp());
}

class EducationApp extends StatelessWidget {
  const EducationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Educational Platform',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
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
          DocumentSnapshot userDoc =
              await _firestore
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navigation Bar
            const NavBar(),

            // Hero Banner
            const HeroBanner(),

            // Platform Stats Section
            const PlatformStatsSection(),

            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E4DCD),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF5E4DCD),
        child: const Icon(Icons.call),
      ),
    );
  }
}

class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          const CircleAvatar(
            backgroundColor: Colors.black,
            radius: 25,
            child: Text(
              'PW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // Menu Items - Responsive
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDropdownMenu('All Courses'),
                      _buildMenuItem('Vidyapeeth'),
                      _buildMenuItem('Upskilling'),
                      _buildMenuItem('PW Store (Books)'),
                      _buildMenuItem('REAL Test'),
                      _buildMenuItem('CuriousJr'),
                      _buildMenuItem('Power Batch'),
                    ],
                  );
                } else {
                  return Container(); // On mobile, we'll use a drawer
                }
              },
            ),
          ),

          // Login/Register Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E4DCD),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }

  Widget _buildMenuItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: () {},
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownMenu(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 40),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: 'Course 1', child: Text('Course 1')),
              const PopupMenuItem(value: 'Course 2', child: Text('Course 2')),
            ],
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            'A Platform Trusted by Students',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          const Text(
            'Physics Wallah aims to transform not just through words, but provide results with numbers!',
            style: TextStyle(fontSize: 18, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Image Carousel Slider
          const ImageCarouselSlider(),

          // "Bharat's Trusted" section only for larger screens
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Bharat's ",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Trusted & ",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Affordable",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const Text(
                        "Educational Platform",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }
}

class ImageCarouselSlider extends StatefulWidget {
  const ImageCarouselSlider({Key? key}) : super(key: key);

  @override
  State<ImageCarouselSlider> createState() => _ImageCarouselSliderState();
}

class _ImageCarouselSliderState extends State<ImageCarouselSlider> {
  int _currentIndex = 0;

  // Sample colors for carousel items
  final List<Color> _carouselColors = [
    Colors.purple.shade600,
    Colors.blue.shade600,
    Colors.green.shade600,
    Colors.orange.shade600,
  ];

  // Sample promotional text for carousel items
  final List<Map<String, String>> _carouselItems = [
    {
      'title': 'Master Physics',
      'subtitle': 'Learn from top educators',
      'cta': 'Join Now',
    },
    {
      'title': 'JEE Preparation',
      'subtitle': 'Comprehensive course materials',
      'cta': 'Enroll Today',
    },
    {
      'title': 'NEET Success',
      'subtitle': 'Achieve your medical dreams',
      'cta': 'Get Started',
    },
    {
      'title': 'Board Exams',
      'subtitle': 'Score high with our expert guidance',
      'cta': 'Learn More',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: List.generate(
            _carouselItems.length,
            (index) => _buildCarouselItem(index),
          ),
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
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
          children: List.generate(_carouselItems.length, (index) {
            return Container(
              width: 12.0,
              height: 12.0,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _currentIndex == index
                        ? const Color(0xFF5E4DCD)
                        : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _carouselColors[index],
            _carouselColors[index].withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
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
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              children: [
                // Text content
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _carouselItems[index]['title']!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _carouselItems[index]['subtitle']!,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _carouselItems[index]['cta']!,
                          style: TextStyle(
                            color: _carouselColors[index],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Image space (using placeholders)
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.school, size: 80, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlatformStatsSection extends StatelessWidget {
  const PlatformStatsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'count': '15Million+',
        'label': 'Happy Students',
        'color': Colors.orange.shade50,
      },
      {'count': '24000+', 'label': 'Mock Tests', 'color': Colors.pink.shade50},
      {
        'count': '14000+',
        'label': 'Video Lectures',
        'color': Colors.blue.shade50,
      },
      {
        'count': '80000+',
        'label': 'Practice Papers',
        'color': Colors.purple.shade50,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Desktop layout - row
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  stats
                      .map((stat) => _buildStatCard(stat, constraints.maxWidth))
                      .toList(),
            );
          } else {
            // Mobile layout - column
            return Column(
              children:
                  stats
                      .map((stat) => _buildStatCard(stat, constraints.maxWidth))
                      .toList(),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, double maxWidth) {
    final isDesktop = maxWidth > 800;
    final width = isDesktop ? maxWidth * 0.2 : maxWidth - 40;

    return Container(
      width: width,
      height: width * 0.8,
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 10 : 0,
        vertical: isDesktop ? 0 : 10,
      ),
      decoration: BoxDecoration(
        color: stat['color'],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat['count'],
            style: TextStyle(
              fontSize: isDesktop ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stat['label'],
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
          // Content