import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:luyip_website_edu/Courses/transaction_service.dart';
import 'package:razorpay_web/razorpay_web.dart';

class FranchiseAddStudentPage extends StatefulWidget {
  final Function onStudentAdded;
  final String franchiseName;

  const FranchiseAddStudentPage({
    Key? key,
    required this.onStudentAdded,
    required this.franchiseName,
  }) : super(key: key);

  @override
  State<FranchiseAddStudentPage> createState() =>
      _FranchiseAddStudentPageState();
}

class _FranchiseAddStudentPageState extends State<FranchiseAddStudentPage> {
  bool loading = false;
  bool isProcessingPayment = false;
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool _isPasswordVisible = false;
  File? _profileImage;

  late Razorpay _razorpay;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TransactionService _transactionService = TransactionService();

  // Payment configuration
  final double membershipFee = 1000.0;
  double franchiseCommissionPercentage = 20.0;

  // Temporary storage for student data during payment
  Map<String, dynamic>? pendingStudentData;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _fetchFranchiseCommission();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchFranchiseCommission() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No current user found');
        return;
      }

      DocumentSnapshot franchiseDoc = await _firestore
          .collection('Users')
          .doc('franchise')
          .collection('accounts')
          .doc(currentUser.email)
          .get();

      if (franchiseDoc.exists) {
        Map<String, dynamic> franchiseData =
            franchiseDoc.data() as Map<String, dynamic>;

        // Get commission percentage from Firestore
        double commissionFromFirestore =
            (franchiseData['CommissionPercent'] as num?)?.toDouble() ?? 20.0;

        setState(() {
          franchiseCommissionPercentage = commissionFromFirestore;
        });

        print('Fetched commission percentage: $franchiseCommissionPercentage%');
      } else {
        print(
            'Franchise document not found, using default commission: $franchiseCommissionPercentage%');
      }
    } catch (e) {
      print('Error fetching franchise commission: $e');
      // Keep the default value if there's an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note: Using default commission rate. Error: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateFranchiseRevenue(
      String transactionId, double commissionAmount) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No current user found');
        return;
      }

      print('Updating franchise revenue for: ${currentUser.email}');
      print('Commission amount: ₹$commissionAmount');

      // Get current franchise data
      DocumentReference franchiseRef = _firestore
          .collection('Users')
          .doc('franchise')
          .collection('accounts')
          .doc(currentUser.email);

      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot franchiseDoc = await transaction.get(franchiseRef);

        Map<String, dynamic> franchiseData = {};
        if (franchiseDoc.exists) {
          franchiseData = franchiseDoc.data() as Map<String, dynamic>;
        }

        // Get current revenue data or initialize with defaults
        Map<String, dynamic> revenueData =
            franchiseData['revenue'] as Map<String, dynamic>? ??
                {
                  'totalRevenue': 0.0,
                  'totalStudentsAdded': 0,
                  'recentTransactions': [],
                  'monthlyRevenue': {},
                  'currency': 'INR',
                };

        // Calculate new totals
        double currentTotalRevenue =
            (revenueData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        int currentTotalStudents =
            (revenueData['totalStudentsAdded'] as int?) ?? 0;
        List<dynamic> currentTransactions =
            List.from(revenueData['recentTransactions'] as List? ?? []);
        Map<String, dynamic> monthlyRevenue = Map<String, dynamic>.from(
            revenueData['monthlyRevenue'] as Map<String, dynamic>? ?? {});

        // Update totals
        double newTotalRevenue = currentTotalRevenue + commissionAmount;
        int newTotalStudents = currentTotalStudents + 1;

        // Add new transaction to recent transactions (keep last 10)
        Map<String, dynamic> newTransaction = {
          'transactionId': transactionId,
          'amount': commissionAmount,
          'type': 'membership_commission',
          'studentEmail': pendingStudentData!['email'],
          'studentName': pendingStudentData!['name'],
          'date': FieldValue.serverTimestamp(),
          'franchise': widget.franchiseName,
        };

        currentTransactions.insert(0, newTransaction);
        if (currentTransactions.length > 10) {
          currentTransactions = currentTransactions.sublist(0, 10);
        }

        // Get current month/year for monthly tracking
        DateTime now = DateTime.now();
        String monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

        double currentMonthRevenue =
            (monthlyRevenue[monthKey] as num?)?.toDouble() ?? 0.0;
        monthlyRevenue[monthKey] = currentMonthRevenue + commissionAmount;

        // Create updated revenue data
        Map<String, dynamic> updatedRevenueData = {
          'totalRevenue': newTotalRevenue,
          'totalStudentsAdded': newTotalStudents,
          'recentTransactions': currentTransactions,
          'monthlyRevenue': monthlyRevenue,
          'lastUpdated': FieldValue.serverTimestamp(),
          'currency': 'INR',
          'averageCommissionPerStudent':
              newTotalStudents > 0 ? newTotalRevenue / newTotalStudents : 0.0,
        };

        // Update franchise document with new revenue data
        Map<String, dynamic> updateData =
            Map<String, dynamic>.from(franchiseData);
        updateData['revenue'] = updatedRevenueData;

        transaction.set(franchiseRef, updateData, SetOptions(merge: true));

        print(
            'Revenue updated successfully: Total: ₹$newTotalRevenue, Students: $newTotalStudents');
      });
    } catch (e) {
      print('Error updating franchise revenue: $e');
      // Show error to user but don't break the flow
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note: Revenue tracking may not be updated. Error: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  double _calculateNetAmount() {
    double commission = membershipFee * franchiseCommissionPercentage / 100;
    return membershipFee - commission;
  }

  double _getCommissionAmount() {
    return membershipFee * franchiseCommissionPercentage / 100;
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    // Store student data temporarily
    pendingStudentData = {
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(),
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'profileImage': _profileImage,
    };

    try {
      double netAmount = _calculateNetAmount();

      var options = {
        'key': 'rzp_test_OIvgwDrw6v8gWS', // Replace with your actual key
        'amount': (netAmount * 100).toInt(), // Amount in paise
        'name': 'LuYip Education',
        'description': 'Student Membership - ${nameController.text.trim()}',
        'prefill': {
          'email': _auth.currentUser?.email ?? '',
        },
        'notes': {
          'franchise_name': widget.franchiseName,
          'student_name': nameController.text.trim(),
          'student_email': emailController.text.trim(),
          'type': 'franchise_student_membership',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        isProcessingPayment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initiating payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() {
        loading = true;
        isProcessingPayment = false;
      });

      // Generate consistent transaction ID format
      String transactionId =
          'TXN_FRANCHISE_${DateTime.now().millisecondsSinceEpoch}';

      await _createStudentAccount(transactionId, response.paymentId!);
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating student: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? 'Unknown error'}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;

    try {
      final storageRef =
          _storage.ref().child('profile_images/students/$userId');
      final uploadTask = storageRef.putFile(_profileImage!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _createStudentAccount(
      String transactionId, String razorpayPaymentId) async {
    if (pendingStudentData == null) {
      throw Exception('No student data found');
    }

    try {
      // Store current franchise user
      User? franchiseUser = _auth.currentUser;
      if (franchiseUser == null) {
        throw Exception('Franchise user not logged in');
      }

      // Create Firebase user for student (this will temporarily sign in as student)
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: pendingStudentData!['email'],
        password: pendingStudentData!['password'],
      );

      String userId = userCredential.user!.uid;

      // Sign out the student immediately
      await _auth.signOut();

      // Sign back in as the franchise user
      await _auth.signInWithEmailAndPassword(
        email: franchiseUser.email!,
        password: await _promptForFranchisePassword(),
      );

      // Upload profile image if exists (now as franchise user again)
      String? profilePicURL;
      if (pendingStudentData!['profileImage'] != null) {
        profilePicURL = await _uploadProfileImage(userId);
      }

      // Create membership details
      DateTime startDate = DateTime.now();
      DateTime expiryDate = startDate.add(const Duration(days: 365));
      String membershipId =
          'MEM-${startDate.day}${startDate.month}${startDate.year}-${userId.substring(0, 4)}';
      String formattedDate =
          '${startDate.day}-${startDate.month}-${startDate.year}';

      // Create student document
      Map<String, dynamic> userData = {
        'Email': pendingStudentData!['email'],
        'UID': userId,
        'Name': pendingStudentData!['name'],
        'Phone': pendingStudentData!['phone'],
        'Role': 'student',
        'DOJ': formattedDate,
        'My Courses': [],
        'ProfilePicURL': profilePicURL,
        'AddedBy': 'franchise',
        'FranchiseName': widget.franchiseName,
        'AddedDate': formattedDate,
        'membership': {
          'isActive': true,
          'startDate': startDate,
          'expiryDate': expiryDate,
          'membershipId': membershipId,
          'transactionId': transactionId, // Use consistent transaction ID
          'razorpayPaymentId':
              razorpayPaymentId, // Store Razorpay payment ID separately
          'addedByFranchise': true,
          'franchiseName': widget.franchiseName,
        },
      };

      // Save to Firestore
      await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(pendingStudentData!['email'])
          .set(userData);

      // Record membership transaction with consistent transaction ID
      await _transactionService.recordMembershipTransaction(
        transactionId: transactionId,
        amount: _calculateNetAmount(),
        currency: 'INR',
        membershipId: membershipId,
        startDate: startDate,
        expiryDate: expiryDate,
        franchiseName: widget.franchiseName,
        franchiseCommission: _getCommissionAmount(),
      );

      // Record franchise commission with consistent transaction ID
      await _transactionService.recordFranchiseCommission(
        transactionId: transactionId,
        franchiseName: widget.franchiseName,
        commissionAmount: _getCommissionAmount(),
        originalAmount: membershipFee,
        commissionPercentage: franchiseCommissionPercentage,
        studentEmail: pendingStudentData!['email'],
        type: 'membership',
      );

      // Update franchise revenue data with consistent transaction ID
      await _updateFranchiseRevenue(transactionId, _getCommissionAmount());

      // Clear pending data
      pendingStudentData = null;

      setState(() {
        loading = false;
      });

      Utils().toastMessage('Student added successfully with membership!');

      // Show detailed success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅ Student Account Created'),
              const Text('✅ Membership Activated'),
              const Text('✅ Commission Recorded'),
              Text(
                  '💰 Commission Earned: ₹${_getCommissionAmount().toStringAsFixed(0)}'),
              Text('🔗 Transaction ID: $transactionId'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      widget.onStudentAdded();
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        loading = false;
      });
      throw e;
    }
  }

  // Method to prompt franchise user for password (for re-authentication)
  Future<String> _promptForFranchisePassword() async {
    String? password;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        TextEditingController passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Re-authenticate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your password to continue:'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                password = passwordController.text;
                Navigator.of(context).pop();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return password ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add New Student'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Franchise info header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: const Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Text(
                        'Franchise: ${widget.franchiseName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Membership Fee:'),
                            Text('₹${membershipFee.toStringAsFixed(0)}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                'Commission (${franchiseCommissionPercentage.toStringAsFixed(1)}%):'), // Now shows dynamic percentage
                            Text(
                                '₹${_getCommissionAmount().toStringAsFixed(0)}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount to Pay:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '₹${_calculateNetAmount().toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Profile Image
            Center(
              child: Stack(
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: _profileImage != null
                        ? ClipOval(
                            child: Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                              height: 120,
                              width: 120,
                            ),
                          )
                        : const Icon(Icons.person,
                            size: 60, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField('Full Name', 'Enter student name',
                          nameController, Icons.person),
                      const SizedBox(height: 15),
                      _buildTextField('Email', 'Enter student email',
                          emailController, Icons.email),
                      const SizedBox(height: 15),
                      _buildTextField('Phone', 'Enter phone number',
                          phoneController, Icons.phone),
                      const SizedBox(height: 15),
                      _buildPasswordField(),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed:
                    (loading || isProcessingPayment) ? null : _initiatePayment,
                child: (loading || isProcessingPayment)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isProcessingPayment
                                ? 'Processing Payment...'
                                : 'Creating Account...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Pay ₹${_calculateNetAmount().toStringAsFixed(0)} & Add Student',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
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

  Widget _buildTextField(String label, String hint,
      TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFF2E7D32).withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (label == 'Email' &&
                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Enter a valid email';
            }
            if (label == 'Phone' && value.length < 10) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Create password',
            filled: true,
            fillColor: const Color(0xFF2E7D32).withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.lock, color: Color(0xFF2E7D32)),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }
}
