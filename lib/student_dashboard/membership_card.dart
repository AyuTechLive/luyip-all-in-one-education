import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/Membership/membership_screen.dart';
import 'package:luyip_website_edu/Membership/membership_service.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class StudentIDCardScreen extends StatefulWidget {
  const StudentIDCardScreen({Key? key}) : super(key: key);

  @override
  State<StudentIDCardScreen> createState() => _StudentIDCardScreenState();
}

class _StudentIDCardScreenState extends State<StudentIDCardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MembershipService _membershipService = MembershipService();
  bool isLoading = true;
  Map<String, dynamic>? studentData;
  String? errorMessage;
  bool isMember = false;
  DateTime? membershipExpiryDate;
  String? membershipId;

  @override
  void initState() {
    super.initState();
    _checkMembershipAndFetchData();
  }

  Future<void> _checkMembershipAndFetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // First check membership status
      final membershipStatus = await _membershipService.getMembershipStatus();

      isMember = membershipStatus['isMember'] ?? false;
      membershipExpiryDate = membershipStatus['expiryDate'];
      membershipId = membershipStatus['membershipId'];

      if (!isMember) {
        setState(() {
          isLoading = false;
          errorMessage = "Membership required to access ID card";
        });
        return;
      }

      // If member, proceed to fetch student data
      await fetchStudentData();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> fetchStudentData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Fetch student data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(currentUser.email)
          .get();

      if (!userDoc.exists) {
        throw Exception("Student data not found");
      }

      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      setState(() {
        studentData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      // appBar: AppBar(
      //   backgroundColor: ColorManager.primary,
      //   // title: const Text(
      //   //   'Student ID Card',
      //   //   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      //   // ),
      //   elevation: 0,
      // ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            )
          : errorMessage != null
              ? _buildMembershipRequiredState()
              : buildIDCard(),
    );
  }

  Widget _buildMembershipRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership,
            size: 80,
            color: ColorManager.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            'Membership Required',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage ??
                  'You need an active membership to access your student ID card',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: ColorManager.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MembershipScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // icon: const Icon(Icons.arrow_back),
            label: const Text(
              'Buy Membership',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildIDCard() {
    // Generate a student ID number based on membership ID or DOJ and UID
    String studentId = membershipId ?? '';
    if (studentId.isEmpty) {
      String doj = studentData!['DOJ'] ?? '';
      String uid = studentData!['UID'] ?? '';
      studentId = 'LYP-${doj.replaceAll('-', '')}-${uid.substring(0, 4)}';
    }

    // Format the date of joining
    String formattedDoj = '';
    try {
      List<String> dateParts = studentData!['DOJ'].split('-');
      if (dateParts.length == 3) {
        DateTime dateObj = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
        formattedDoj = DateFormat('dd MMM yyyy').format(dateObj);
      } else {
        formattedDoj = studentData!['DOJ'];
      }
    } catch (e) {
      formattedDoj = studentData!['DOJ'] ?? 'N/A';
    }

    // Get formatted membership expiry date
    String expiryDate = 'N/A';
    if (membershipExpiryDate != null) {
      expiryDate = DateFormat('dd MMM yyyy').format(membershipExpiryDate!);
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ID Card
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorManager.primary,
                          ColorManager.primaryDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Text(
                            "L",
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "LUIYP EDUCATION",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "Student Identification Card",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Student Photo and Basic Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Photo
                        Container(
                          width: 100,
                          height: 120,
                          decoration: BoxDecoration(
                            color: ColorManager.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ColorManager.primaryDark,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: ColorManager.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Student Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentData!['Name'] ?? 'N/A',
                                style: TextStyle(
                                  color: ColorManager.textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              detailRow('Student ID', studentId),
                              detailRow(
                                'Email',
                                studentData!['Email'] ?? 'N/A',
                              ),
                              detailRow('Joined', formattedDoj),
                              detailRow('Valid Until', expiryDate),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Membership Badge
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Premium Member',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: ColorManager.dividerColor,
                    ),
                  ),

                  // QR Code
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          QrImageView(
                            data: 'LUIYP-MEMBER-${studentData!['UID']}',
                            version: QrVersions.auto,
                            size: 120,
                            backgroundColor: Colors.white,
                            gapless: true,
                            errorStateBuilder: (context, error) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.white,
                                child: Center(
                                  child: Text(
                                    'Error generating QR',
                                    style: TextStyle(color: ColorManager.error),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            studentId,
                            style: TextStyle(
                              color: ColorManager.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorManager.light,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'This ID card is the property of LUIYP Education.',
                          style: TextStyle(
                            color: ColorManager.textMedium,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'If found, please return to the nearest LUYIP office.',
                          style: TextStyle(
                            color: ColorManager.textMedium,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Download button
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Add download functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID Card downloaded successfully!'),
                    backgroundColor: ColorManager.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Download ID Card'),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label + ':',
              style: TextStyle(
                color: ColorManager.textMedium,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: ColorManager.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
