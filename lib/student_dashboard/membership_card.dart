import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool isLoading = true;
  Map<String, dynamic>? studentData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Fetch student data from Firestore
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('Users')
              .doc('student')
              .collection('accounts')
              .where('UID', isEqualTo: currentUser.uid)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("Student data not found");
      }

      // Get the first document
      DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;

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
      appBar: AppBar(
        backgroundColor: ColorManager.primary,
        title: const Text(
          'Student ID Card',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: ColorManager.primary),
              )
              : errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: ColorManager.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading ID card',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: ColorManager.textMedium),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: fetchStudentData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : buildIDCard(),
    );
  }

  Widget buildIDCard() {
    // Generate a student ID number based on DOJ and UID
    String doj = studentData!['DOJ'] ?? '';
    String uid = studentData!['UID'] ?? '';
    String studentId = 'LYP-${doj.replaceAll('-', '')}-${uid.substring(0, 4)}';

    // Format the date of joining
    String formattedDoj = '';
    try {
      List<String> dateParts = doj.split('-');
      if (dateParts.length == 3) {
        DateTime dateObj = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
        formattedDoj = DateFormat('dd MMM yyyy').format(dateObj);
      } else {
        formattedDoj = doj;
      }
    } catch (e) {
      formattedDoj = doj;
    }

    // Calculate expiry date (1 year from date of joining)
    String expiryDate = '';
    try {
      List<String> dateParts = doj.split('-');
      if (dateParts.length == 3) {
        DateTime dateObj = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
        DateTime expiryDateObj = dateObj.add(const Duration(days: 365));
        expiryDate = DateFormat('dd MMM yyyy').format(expiryDateObj);
      }
    } catch (e) {
      expiryDate = 'N/A';
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
                              "LUYIP EDUCATION",
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
                              detailRow('Expires', expiryDate),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: ColorManager.dividerColor,
                  ),

                  // QR Code
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          QrImageView(
                            data: 'LUYIP-STUDENT-${studentData!['UID']}',
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
                          'This ID card is the property of LUYIP Education.',
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
