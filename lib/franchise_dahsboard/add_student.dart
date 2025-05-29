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
  String? franchiseEmail;
  String? franchisePassword;

  late Razorpay _razorpay;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TransactionService _transactionService = TransactionService();

  // Payment configuration
  double membershipFee = 1000.0;
  double franchiseCommissionPercentage = 20.0;

  // Temporary storage for student data during payment
  Map<String, dynamic>? pendingStudentData;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _fetchFranchiseCommission();
    _initializeFranchiseData();
    _loadMembershipFee();
  }

  Future<void> _loadMembershipFee() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('website_general')
          .doc('dashboard')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final websiteContent = data['websiteContent'] as Map<String, dynamic>?;

        if (websiteContent != null &&
            websiteContent.containsKey('membershipFee')) {
          setState(() {
            membershipFee =
                (websiteContent['membershipFee'] as num?)?.toDouble() ?? 1000.0;
          });
        }
      }
    } catch (e) {
      print('Error loading membership fee: $e');
      // Keep default value
    }
  }

  void _initializeFranchiseData() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      franchiseEmail = currentUser.email!;
      print('Franchise email stored globally: $franchiseEmail');
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note: Using default commission rate. Error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
        'key': 'rzp_test_OIvgwDrw6v8gWS',
        'amount': (netAmount * 100).toInt(),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() {
        loading = true;
        isProcessingPayment = false;
      });

      String transactionId =
          'TXN_FRANCHISE_${DateTime.now().millisecondsSinceEpoch}';

      await _createStudentAccount(transactionId, response.paymentId!);
    } catch (e) {
      setState(() {
        loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      isProcessingPayment = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Payment failed: ${response.message ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      isProcessingPayment = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet: ${response.walletName}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
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
      User? franchiseUser = _auth.currentUser;
      if (franchiseUser == null) {
        throw Exception('Franchise user not logged in');
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: pendingStudentData!['email'],
        password: pendingStudentData!['password'],
      );

      String userId = userCredential.user!.uid;
      await _auth.signOut();

      await _auth.signInWithEmailAndPassword(
        email: franchiseUser.email!,
        password: await _promptForFranchisePassword(),
      );

      String? profilePicURL;
      if (pendingStudentData!['profileImage'] != null) {
        profilePicURL = await _uploadProfileImage(userId);
      }

      DateTime startDate = DateTime.now();
      DateTime expiryDate = startDate.add(const Duration(days: 365));
      String membershipId =
          'MEM-${startDate.day}${startDate.month}${startDate.year}-${userId.substring(0, 4)}';
      String formattedDate =
          '${startDate.day}-${startDate.month}-${startDate.year}';

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
          'transactionId': transactionId,
          'razorpayPaymentId': razorpayPaymentId,
          'addedByFranchise': true,
          'franchiseName': widget.franchiseName,
        },
      };

      await _firestore
          .collection('Users')
          .doc('student')
          .collection('accounts')
          .doc(pendingStudentData!['email'])
          .set(userData);

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

      await _transactionService.recordFranchiseCommission(
        franchiseEmail: franchiseEmail!,
        transactionId: transactionId,
        franchiseName: widget.franchiseName,
        commissionAmount: _getCommissionAmount(),
        originalAmount: membershipFee,
        commissionPercentage: franchiseCommissionPercentage,
        studentEmail: pendingStudentData!['email'],
        type: 'membership',
      );

      pendingStudentData = null;

      setState(() {
        loading = false;
      });

      Utils().toastMessage('Student added successfully with membership!');

      if (mounted) {
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
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating student: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      throw e;
    }
  }

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Add New Student',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Franchise Info Card
                  _buildFranchiseInfoCard(),

                  const SizedBox(height: 32),

                  // Profile Section
                  _buildProfileSection(),

                  const SizedBox(height: 32),

                  // Form Fields
                  _buildFormFields(),

                  const SizedBox(height: 40),

                  // Submit Button
                  _buildSubmitButton(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFranchiseInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF388E3C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.franchiseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _buildPriceRow(
                  'Membership Fee',
                  '₹${membershipFee.toStringAsFixed(0)}',
                  isSubtle: true,
                ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Your Commission (${franchiseCommissionPercentage.toStringAsFixed(1)}%)',
                  '₹${_getCommissionAmount().toStringAsFixed(0)}',
                  isHighlighted: true,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                _buildPriceRow(
                  'Amount to Pay',
                  '₹${_calculateNetAmount().toStringAsFixed(0)}',
                  isFinal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String amount, {
    bool isSubtle = false,
    bool isHighlighted = false,
    bool isFinal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSubtle ? 14 : (isFinal ? 16 : 15),
            fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
            // opacity: isSubtle ? 0.8 : 1.0,
          ),
        ),
        Container(
          padding: isHighlighted
              ? const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                )
              : EdgeInsets.zero,
          decoration: isHighlighted
              ? BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSubtle ? 14 : (isFinal ? 18 : 15),
              fontWeight: isFinal
                  ? FontWeight.bold
                  : (isHighlighted ? FontWeight.w600 : FontWeight.normal),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Student Profile Picture',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withOpacity(0.2),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                    : const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF2E7D32),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2E7D32),
                          const Color(0xFF388E3C),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Student Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Full Name',
          'Enter student\'s full name',
          nameController,
          Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Email Address',
          'Enter student\'s email',
          emailController,
          Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Phone Number',
          'Enter phone number',
          phoneController,
          Icons.phone_outlined,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D32),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF2E7D32),
                size: 22,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              if (label == 'Email Address' &&
                  !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                return 'Enter a valid email address';
              }
              if (label == 'Phone Number' && value.length < 10) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Create a secure password',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D32),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF2E7D32),
                size: 22,
              ),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF388E3C),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: (loading || isProcessingPayment) ? null : _initiatePayment,
        child: (loading || isProcessingPayment)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    isProcessingPayment
                        ? 'Processing Payment...'
                        : 'Creating Account...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pay ₹${_calculateNetAmount().toStringAsFixed(0)} & Add Student',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
