import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/certificate/certificate_model.dart';
import 'package:luyip_website_edu/certificate/certificate_service.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  final _certificateService = CertificateService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<Certificate> _certificates = [];
  List<Map<String, dynamic>> _eligibleCourses = [];
  bool _isGenerating = false;

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
      final userId = _auth.currentUser?.uid;
      final userEmail = _auth.currentUser?.email;

      if (userId == null || userEmail == null) {
        throw Exception('You need to be logged in to view certificates');
      }

      // Load existing certificates
      final certificates =
          await _certificateService.getUserCertificates(userId);

      // Get list of courses user is enrolled in
      final userDoc = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(userEmail)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final myCourses = userDoc.data()?['My Courses'] as List<dynamic>? ?? [];

      // Get set of courses that already have certificates
      final certificatedCourses =
          certificates.map((cert) => cert.courseName).toSet();

      // Find eligible courses that don't have certificates yet
      List<Map<String, dynamic>> eligibleCourses = [];

      for (final courseName in myCourses) {
        // Skip courses that already have certificates
        if (certificatedCourses.contains(courseName)) continue;

        // Check if course is completed and user is eligible
        final eligibilityData = await _certificateService
            .checkCertificateEligibility(userId, courseName.toString());

        if (eligibilityData['isEligible'] == true) {
          eligibleCourses.add({
            'courseName': courseName.toString(),
            'testPassPercentage': eligibilityData['testPassPercentage'] ?? 0.0,
          });
        }
      }

      setState(() {
        _certificates = certificates;
        _eligibleCourses = eligibleCourses;
        _isLoading = false;
      });
    } catch (e) {
      Utils().toastMessage('Error loading certificates: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateCertificate(String courseName) async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      final userEmail = _auth.currentUser?.email;

      if (userId == null || userEmail == null) {
        throw Exception('You need to be logged in to generate a certificate');
      }

      final certificate = await _certificateService.generateCertificate(
        userId: userId,
        userEmail: userEmail,
        courseName: courseName,
      );

      if (certificate != null) {
        Utils().toastMessage('Certificate generated successfully!');

        // Reload data to update the UI
        await _loadData();
      } else {
        Utils().toastMessage('Failed to generate certificate');
      }
    } catch (e) {
      Utils().toastMessage('Error generating certificate: ${e.toString()}');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _viewCertificate(Certificate certificate) async {
    try {
      if (certificate.certificateUrl.isNotEmpty) {
        final url = Uri.parse(certificate.certificateUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          throw Exception('Could not launch certificate URL');
        }
      } else {
        throw Exception('Certificate URL is not available');
      }
    } catch (e) {
      Utils().toastMessage('Error viewing certificate: ${e.toString()}');
    }
  }

  Future<void> _downloadCertificate(Certificate certificate) async {
    try {
      if (certificate.certificateUrl.isNotEmpty) {
        final url = Uri.parse(certificate.certificateUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          throw Exception('Could not download certificate');
        }
      } else {
        throw Exception('Certificate URL is not available');
      }
    } catch (e) {
      Utils().toastMessage('Error downloading certificate: ${e.toString()}');
    }
  }

  void _shareCertificate(Certificate certificate) {
    // This would use a share plugin
    Utils().toastMessage('Share functionality not implemented');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: Colors.white,
        foregroundColor: ColorManager.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _certificates.isEmpty && _eligibleCourses.isEmpty
                      ? _buildNoCertificatesView()
                      : _buildCertificatesAndEligibleCoursesList(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Certificates',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View, download and generate your course completion certificates',
            style: TextStyle(
              color: ColorManager.textMedium,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorManager.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: ColorManager.info,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Certificates are available for completed courses where you\'ve passed at least 70% of the tests.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorManager.textDark,
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

  Widget _buildNoCertificatesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No Certificates Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Complete your courses successfully to earn certificates. You need to pass at least 70% of tests in a course to qualify.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to courses page
              Navigator.pop(context);
            },
            icon: const Icon(Icons.school),
            label: const Text('View Courses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesAndEligibleCoursesList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Eligible courses section
        if (_eligibleCourses.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Eligible for Certificate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorManager.textDark,
              ),
            ),
          ),
          ..._eligibleCourses.map((course) => _buildEligibleCourseCard(course)),
          SizedBox(height: 24),
        ],

        // Issued certificates section
        if (_certificates.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Issued Certificates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorManager.textDark,
              ),
            ),
          ),
          ..._certificates
              .map((certificate) => _buildCertificateCard(certificate)),
        ],
      ],
    );
  }

  Widget _buildEligibleCourseCard(Map<String, dynamic> course) {
    final String courseName = course['courseName'];
    final double testPassPercentage = course['testPassPercentage'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        children: [
          // Course header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.secondary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Course icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school,
                    color: ColorManager.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Course title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Eligible for Certificate',
                        style: TextStyle(
                          color: ColorManager.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Generate certificate button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Performance info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You passed ${testPassPercentage.toStringAsFixed(1)}% of the tests',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Generate button
                ElevatedButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () => _generateCertificate(courseName),
                  icon: _isGenerating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.workspace_premium),
                  label: Text(
                      _isGenerating ? 'Generating...' : 'Generate Certificate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildCertificateCard(Certificate certificate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        children: [
          // Certificate header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Certificate icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: ColorManager.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Certificate title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.courseName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Course Completion Certificate',
                        style: TextStyle(
                          color: ColorManager.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Certificate details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Certificate info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Issued On',
                        DateFormat('dd MMM, yyyy')
                            .format(certificate.issueDate),
                        Icons.calendar_today,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Certificate ID',
                        certificate.certificateNumber.substring(0, 14) + '...',
                        Icons.badge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Issued To',
                        certificate.userName,
                        Icons.person,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Score',
                        '${certificate.percentageScore.toStringAsFixed(1)}%',
                        Icons.analytics,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewCertificate(certificate),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorManager.primary,
                          side: BorderSide(color: ColorManager.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadCertificate(certificate),
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _shareCertificate(certificate),
                      icon: const Icon(Icons.share),
                      tooltip: 'Share',
                      color: ColorManager.textMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorManager.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: ColorManager.textMedium,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: ColorManager.textMedium,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ColorManager.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
