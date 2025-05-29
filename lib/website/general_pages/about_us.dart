// File: lib/pages/about_us_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/helpers/fevicon_helper.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  Map<String, dynamic> websiteContent = {};

  @override
  void initState() {
    super.initState();
    _fetchWebsiteContent();
  }

  Future<void> _fetchWebsiteContent() async {
    try {
      final websiteDoc =
          await _firestore.collection('website_general').doc('dashboard').get();

      if (websiteDoc.exists) {
        final data = websiteDoc.data() as Map<String, dynamic>;
        setState(() {
          websiteContent =
              Map<String, dynamic>.from(data['websiteContent'] ?? {});
        });

        // Update favicon and page title
        final logoUrl = websiteContent['logoUrl']?.toString() ?? '';
        final companyName =
            websiteContent['companyName']?.toString() ?? 'Luiyp Education';

        FaviconHelper.updateBranding(
          logoUrl: logoUrl.isNotEmpty ? logoUrl : null,
          title: 'About Us - $companyName',
        );
      }
    } catch (e) {
      print('Error fetching website content: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getWebsiteContent(String key, String defaultValue) {
    return websiteContent[key]?.toString() ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 800;

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header with navigation
                  _buildHeader(context, isMobile),

                  // Hero Section
                  _buildHeroSection(isMobile),

                  // Mission & Vision Section
                  _buildMissionVisionSection(isMobile),

                  // Our Story Section
                  _buildOurStorySection(isMobile),

                  // Why Choose Us Section
                  _buildWhyChooseUsSection(isMobile),

                  // Team Section
                  _buildTeamSection(isMobile),

                  // Footer
                  _buildFooter(isMobile),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 20, vertical: isMobile ? 12 : 16),
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
        children: [
          // Logo and Company Name
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
            child: Row(
              children: [
                if (_getWebsiteContent('logoUrl', '').isNotEmpty)
                  Image.network(
                    _getWebsiteContent('logoUrl', ''),
                    width: 30,
                    height: 30,
                  ),
                const SizedBox(width: 8),
                Text(
                  _getWebsiteContent('companyName', 'Luiyp Education'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Back to Home Button
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E4DCD),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
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
            'About ${_getWebsiteContent('companyName', 'Luiyp Education')}',
            style: TextStyle(
              fontSize: isMobile ? 28 : 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              'Empowering students across India with quality education and innovative learning solutions.',
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionVisionSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mission
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.track_changes,
                        size: 50,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Our Mission',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'To democratize quality education in India by making it accessible, affordable, and effective for every student, regardless of their geographical or economic background.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              if (!isMobile) const SizedBox(width: 20),

              // Vision
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 50,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Our Vision',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'To become India\'s most trusted and comprehensive educational platform, transforming millions of students into confident, knowledgeable, and successful individuals.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOurStorySection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: 20,
      ),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Text(
            'Our Story',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Text(
              '''${_getWebsiteContent('companyName', 'Luiyp Education')} was founded with a simple yet powerful vision: to bridge the educational gap in India and make quality learning accessible to every student.

Our journey began when we recognized that talented students across the country were unable to access quality education due to geographical limitations, financial constraints, or lack of proper guidance. We set out to change this narrative by leveraging technology and innovative teaching methodologies.

Today, we are proud to serve millions of students across India, helping them achieve their academic goals and build successful careers. Our platform combines traditional teaching wisdom with modern technology to create an unparalleled learning experience.

From humble beginnings to becoming one of India's leading educational platforms, our story is one of dedication, innovation, and unwavering commitment to student success.''',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseUsSection(bool isMobile) {
    final features = [
      {
        'icon': Icons.school,
        'title': 'Expert Faculty',
        'description': 'Learn from experienced educators and industry experts',
      },
      {
        'icon': Icons.devices,
        'title': 'Multi-Platform Access',
        'description': 'Study anytime, anywhere on any device',
      },
      {
        'icon': Icons.assessment,
        'title': 'Comprehensive Testing',
        'description':
            'Regular assessments and mock tests for better preparation',
      },
      {
        'icon': Icons.support,
        'title': '24/7 Support',
        'description': 'Round-the-clock support for all your queries',
      },
      {
        'icon': Icons.money_off,
        'title': 'Affordable Pricing',
        'description': 'Quality education at pocket-friendly prices',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Proven Results',
        'description': 'Thousands of successful students and counting',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Text(
            'Why Choose Us?',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: isMobile ? 3 : 1.2,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      size: 40,
                      color: const Color(0xFF5E4DCD),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feature['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: 20,
      ),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Text(
            'Our Team',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Meet the passionate educators and innovators behind ${_getWebsiteContent('companyName', 'Luiyp Education')}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.group,
                  size: 80,
                  color: const Color(0xFF5E4DCD),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dedicated Professionals',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Our team consists of experienced educators, subject matter experts, technology professionals, and student support specialists who work tirelessly to ensure the best learning experience for our students.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
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

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 30 : 40,
        horizontal: 20,
      ),
      color: Colors.grey.shade900,
      child: Column(
        children: [
          Text(
            'Ready to Start Your Learning Journey?',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/student'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E4DCD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Get Started Today'),
          ),
          const SizedBox(height: 30),
          Text(
            '© ${DateTime.now().year} ${_getWebsiteContent('companyName', 'Luiyp Education')}. All rights reserved.',
            style: TextStyle(
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
