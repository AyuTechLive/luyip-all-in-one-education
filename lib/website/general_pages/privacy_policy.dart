import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:luyip_website_edu/helpers/fevicon_helper.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
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
          title: 'Privacy Policy - $companyName',
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
                  // Header
                  _buildHeader(context, isMobile),

                  // Content
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 30 : 50,
                      horizontal: 20,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: isMobile ? 28 : 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5E4DCD),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildSection(
                            'Introduction',
                            'At ${_getWebsiteContent('companyName', 'Luiyp Education')}, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website and use our services.',
                          ),
                          _buildSection(
                            'Information We Collect',
                            '''We collect information you provide directly to us, such as:

• Personal Information: Name, email address, phone number, date of birth
• Educational Information: Academic records, course preferences, learning progress
• Payment Information: Billing details and transaction history
• Communication Data: Messages, feedback, and support interactions
• Usage Information: How you interact with our platform and services''',
                          ),
                          _buildSection(
                            'How We Use Your Information',
                            '''We use your information to:

• Provide and maintain our educational services
• Process transactions and manage your account
• Communicate with you about courses, updates, and support
• Personalize your learning experience
• Improve our platform and develop new features
• Ensure platform security and prevent fraud
• Comply with legal obligations''',
                          ),
                          _buildSection(
                            'Information Sharing',
                            '''We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:

• With your explicit consent
• With service providers who assist us in operating our platform
• To comply with legal requirements or court orders
• To protect our rights, property, or safety
• In connection with a business transfer or merger''',
                          ),
                          _buildSection(
                            'Data Security',
                            'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
                          ),
                          _buildSection(
                            'Your Rights',
                            '''You have the right to:

• Access and review your personal information
• Correct inaccurate or incomplete information
• Delete your account and personal data
• Restrict or object to certain processing activities
• Data portability for information you provided
• Withdraw consent at any time''',
                          ),
                          _buildSection(
                            'Cookies and Tracking',
                            'We use cookies and similar technologies to enhance your experience, analyze usage patterns, and provide personalized content. You can control cookie settings through your browser preferences.',
                          ),
                          _buildSection(
                            'Children\'s Privacy',
                            'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have collected such information, please contact us immediately.',
                          ),
                          _buildSection(
                            'Changes to This Policy',
                            'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
                          ),
                          _buildSection(
                            'Contact Us',
                            '''If you have any questions about this Privacy Policy, please contact us:

Email: ${_getWebsiteContent('footerEmail', 'support@luiypedu.com')}
Phone: ${_getWebsiteContent('footerPhone', '+91 1234567890')}
Address: ${_getWebsiteContent('companyName', 'Luiyp Education')} Support Team''',
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

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
