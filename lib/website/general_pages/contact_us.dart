import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:luyip_website_edu/helpers/fevicon_helper.dart';

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
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
          title: 'Terms & Conditions - $companyName',
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
                            'Terms & Conditions',
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
                            'Agreement to Terms',
                            'By accessing and using ${_getWebsiteContent('companyName', 'Luiyp Education')} services, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
                          ),
                          _buildSection(
                            'Use License',
                            '''Permission is granted to temporarily download one copy of the materials on ${_getWebsiteContent('companyName', 'Luiyp Education')} for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:

• Modify or copy the materials
• Use the materials for any commercial purpose or for any public display
• Attempt to reverse engineer any software contained on the website
• Remove any copyright or other proprietary notations from the materials

This license shall automatically terminate if you violate any of these restrictions and may be terminated by us at any time.''',
                          ),
                          _buildSection(
                            'User Accounts',
                            '''When you create an account with us, you must provide information that is accurate, complete, and current at all times. You are responsible for:

• Safeguarding the password and all activities under your account
• Notifying us immediately of any unauthorized use of your account
• Ensuring your account information remains accurate and up-to-date

We reserve the right to refuse service, terminate accounts, or cancel orders at our sole discretion.''',
                          ),
                          _buildSection(
                            'Educational Services',
                            '''Our educational services include but are not limited to:

• Online courses and video lectures
• Study materials and practice tests
• Live classes and doubt sessions
• Certification programs

All course content is protected by intellectual property rights. Students may not reproduce, distribute, or commercially exploit any course materials without explicit written permission.''',
                          ),
                          _buildSection(
                            'Payment Terms',
                            '''• All fees are quoted in Indian Rupees (INR) unless otherwise stated
• Payment must be made in full before accessing premium content
• We accept various payment methods as displayed during checkout
• All sales are final unless otherwise specified in our refund policy
• Prices are subject to change without notice''',
                          ),
                          _buildSection(
                            'Prohibited Uses',
                            '''You may not use our service:

• For any unlawful purpose or to solicit others to perform unlawful acts
• To violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances
• To infringe upon or violate our intellectual property rights or the intellectual property rights of others
• To harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate
• To submit false or misleading information
• To upload or transmit viruses or any other type of malicious code''',
                          ),
                          _buildSection(
                            'Content Ownership',
                            '''All content on our platform, including but not limited to text, graphics, logos, images, audio clips, video clips, data compilations, and software, is the property of ${_getWebsiteContent('companyName', 'Luiyp Education')} or its content suppliers and is protected by copyright laws.

Users retain ownership of content they submit but grant us a license to use, modify, and display such content for providing our services.''',
                          ),
                          _buildSection(
                            'Limitation of Liability',
                            '''In no event shall ${_getWebsiteContent('companyName', 'Luiyp Education')}, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, use, goodwill, or other intangible losses, resulting from your use of the service.''',
                          ),
                          _buildSection(
                            'Governing Law',
                            'These terms shall be interpreted and governed in accordance with the laws of India, without regard to its conflict of law provisions. Any disputes arising from these terms will be subject to the exclusive jurisdiction of the courts of India.',
                          ),
                          _buildSection(
                            'Changes to Terms',
                            'We reserve the right to modify or replace these terms at any time. If a revision is material, we will try to provide at least 30 days notice prior to any new terms taking effect.',
                          ),
                          _buildSection(
                            'Contact Information',
                            '''If you have any questions about these Terms and Conditions, please contact us:

Email: ${_getWebsiteContent('footerEmail', 'support@luiypedu.com')}
Phone: ${_getWebsiteContent('footerPhone', '+91 1234567890')}''',
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
