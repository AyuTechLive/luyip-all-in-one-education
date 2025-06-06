import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/auth/loginscreen.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:luyip_website_edu/home/main_page.dart';

class SignUpScreen extends StatefulWidget {
  final String? userRole; // Role parameter from previous screen (optional)

  const SignUpScreen({super.key, this.userRole});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool loading = false;
  final _formfield = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool _isPasswordVisible = false;
  late String selectedRole; // Will be set from parameter or default to student
  bool _acceptedTerms = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Set role from parameter or default to 'student'
    selectedRole = widget.userRole ?? 'student';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Get role display name
  String getRoleDisplayName() {
    switch (selectedRole) {
      case 'student':
        return 'Student';
      case 'teacher':
        return 'Teacher';
      case 'franchise':
        return 'Franchise';
      case 'admin':
        return 'Admin';
      default:
        return 'Student';
    }
  }

  // Get role icon
  IconData getRoleIcon() {
    switch (selectedRole) {
      case 'student':
        return Icons.school;
      case 'teacher':
        return Icons.person_outline;
      case 'franchise':
        return Icons.business;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.school;
    }
  }

  // Convert Firebase errors to user-friendly messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password with at least 6 characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Account creation is currently disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'requires-recent-login':
        return 'Please log in again to continue.';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';
      case 'invalid-credential':
        return 'Invalid credentials provided. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account with this email already exists with different credentials.';
      case 'permission-denied':
        return 'Permission denied. Please check your account permissions.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timeout. Please try again.';
      case 'already-exists':
        return 'User data already exists. Please try logging in instead.';
      case 'failed-precondition':
        return 'System requirements not met. Please try again.';
      case 'out-of-range':
        return 'Invalid data provided. Please check your information.';
      case 'unimplemented':
        return 'Feature not available. Please contact support.';
      case 'internal':
        return 'Internal error occurred. Please try again later.';
      case 'cancelled':
        return 'Operation was cancelled. Please try again.';
      case 'data-loss':
        return 'Data error occurred. Please try again.';
      case 'unauthenticated':
        return 'Authentication failed. Please try again.';
      case 'resource-exhausted':
        return 'Service quota exceeded. Please try again later.';
      case 'invalid-argument':
        return 'Invalid information provided. Please check your details.';
      case 'not-found':
        return 'Requested resource not found.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
    }
  }

  Future<void> signUp() async {
    if (_formfield.currentState!.validate()) {
      if (!_acceptedTerms) {
        Utils()
            .toastMessage('Please accept the terms and conditions to continue');
        return;
      }

      setState(() {
        loading = true;
      });

      try {
        // Create user with email and password
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Format current date
        DateTime currentDate = DateTime.now();
        String formattedDate =
            '${currentDate.day}-${currentDate.month}-${currentDate.year}';

        // Create user data map with "added by" information
        Map<String, dynamic> userData = {
          'Email': emailController.text.trim(),
          'UID': userCredential.user!.uid,
          'Name': nameController.text.trim(),
          'Phone': phoneController.text.trim(),
          'Role': selectedRole,
          'DOJ': formattedDate,
          'My Courses': [],
          'AddedBy': 'self', // Self registration
          'SelfRegistered': true,
          'AddedDate': formattedDate,
        };

        // Store in role-specific collection
        await _firestore
            .collection('Users')
            .doc(selectedRole)
            .collection('accounts')
            .doc(emailController.text.trim())
            .set(userData);

        // Login after successful signup
        Utils().toastMessage(
            'Welcome to LUIYP Education! Your account has been successfully created.');
        setState(() {
          loading = false;
        });

        // Navigate to main page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage(role: selectedRole)),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          loading = false;
        });
        String userFriendlyMessage = _getErrorMessage(e.code);
        Utils().toastMessage(userFriendlyMessage);
      } on FirebaseException catch (e) {
        setState(() {
          loading = false;
        });
        String userFriendlyMessage = _getErrorMessage(e.code);
        Utils().toastMessage(userFriendlyMessage);
      } catch (error) {
        setState(() {
          loading = false;
        });
        // Handle any other unexpected errors
        Utils().toastMessage(
            'Something went wrong. Please check your internet connection and try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 900;
    final bool isMediumScreen =
        screenSize.width > 600 && screenSize.width <= 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorManager.background,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: isLargeScreen
                  ? _buildLargeScreenLayout(screenSize)
                  : isMediumScreen
                      ? _buildMediumScreenLayout(screenSize)
                      : _buildSmallScreenLayout(screenSize),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout(Size screenSize) {
    return Row(
      children: [
        // Left side with image/branding
        Expanded(
          flex: 4,
          child: Container(
            height: screenSize.height * 0.85,
            margin: const EdgeInsets.only(left: 40, right: 20),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
              image: const DecorationImage(
                image: AssetImage('assets/images/signup_bg.jpg'),
                fit: BoxFit.cover,
                opacity: 0.4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getRoleIcon(),
                    color: ColorManager.primary,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 32),
                // Branding text
                Text(
                  'JOIN LUIYP EDUCATION',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Start your learning journey today',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 40),
                // Benefits
                _buildFeatureRow(
                    Icons.check_circle_outline, 'Access to premium courses'),
                const SizedBox(height: 16),
                _buildFeatureRow(
                    Icons.check_circle_outline, 'Learn from industry experts'),
                const SizedBox(height: 16),
                _buildFeatureRow(
                    Icons.check_circle_outline, 'Earn recognized certificates'),
                const SizedBox(height: 16),
                _buildFeatureRow(
                    Icons.check_circle_outline, 'Join a community of learners'),
              ],
            ),
          ),
        ),

        // Right side with signup form
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _buildSignupForm(screenSize),
          ),
        ),
      ],
    );
  }

  Widget _buildMediumScreenLayout(Size screenSize) {
    return Container(
      width: screenSize.width * 0.85,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Top branding
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorManager.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Logo or icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getRoleIcon(),
                    color: ColorManager.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                // Branding text
                Text(
                  'CREATE YOUR ACCOUNT',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join our growing community of learners',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Signup form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: _buildSignupForm(screenSize),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScreenLayout(Size screenSize) {
    return Container(
      width: screenSize.width * 0.9,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top branding
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorManager.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Logo or icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getRoleIcon(),
                    color: ColorManager.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                // Branding text
                Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Signup form
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSignupForm(screenSize),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(Size screenSize) {
    final bool isSmallScreen = screenSize.width <= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Signup header with role indicator
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 30,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to start learning',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: ColorManager.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            // Role indicator badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ColorManager.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    getRoleIcon(),
                    color: ColorManager.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    getRoleDisplayName(),
                    style: TextStyle(
                      color: ColorManager.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Registration type indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorManager.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ColorManager.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: ColorManager.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Self Registration',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColorManager.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Signup form
        Form(
          key: _formfield,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: nameController,
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: emailController,
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your email';
                  }
                  final bool emailValid = RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                  ).hasMatch(value);
                  if (!emailValid) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: phoneController,
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number (at least 10 digits)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 12),
              _buildTermsAndConditionsCheckbox(),
              const SizedBox(height: 24),
              _buildSignupButton(),
              const SizedBox(height: 20),
              _buildLoginPrompt(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: ColorManager.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorManager.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Create a strong password (minimum 6 characters)',
        prefixIcon: Icon(Icons.lock_outline, color: ColorManager.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: ColorManager.primary,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorManager.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        if (!RegExp(r'^(?=.*[a-zA-Z])').hasMatch(value)) {
          return 'Password must contain at least one letter';
        }
        return null;
      },
    );
  }

  Widget _buildTermsAndConditionsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) {
            setState(() {
              _acceptedTerms = value ?? false;
            });
          },
          activeColor: ColorManager.primary,
        ),
        Flexible(
          child: Text(
            'I agree to the Terms of Service and Privacy Policy',
            style: TextStyle(
              fontSize: 14,
              color: ColorManager.textMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorManager.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: ColorManager.primary.withOpacity(0.7),
        ),
        child: loading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Create ${getRoleDisplayName()} Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            color: ColorManager.textMedium,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LoginScreen(
                        userRole: selectedRole,
                      )),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: ColorManager.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'Log In',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
