import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/auth/signp.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:luyip_website_edu/home/main_page.dart';

class LoginScreen extends StatefulWidget {
  final String? userRole; // Role parameter from previous screen

  const LoginScreen({super.key, required this.userRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formfield = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool loading = false;
  late String selectedRole; // Will be set from parameter or default to student

  final _auth = FirebaseAuth.instance;
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
    super.dispose();
  }

  void login() {
    if (_formfield.currentState!.validate()) {
      setState(() {
        loading = true;
      });

      _auth
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      )
          .then((userCredential) async {
        // Verify user's role matches selected role
        String uid = userCredential.user!.uid;

        try {
          // Check if user exists in the selected role collection
          DocumentSnapshot userDoc = await _firestore
              .collection('Users')
              .doc(selectedRole)
              .collection('accounts')
              .doc(emailController.text.trim())
              .get();

          if (userDoc.exists) {
            setState(() {
              loading = false;
            });
            Utils().toastMessage('Login successful');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(role: selectedRole),
              ),
            );
          } else {
            // User not found in the selected role collection
            await _auth.signOut();
            setState(() {
              loading = false;
            });
            Utils().toastMessage(
              'User not registered as $selectedRole. Please check your credentials.',
            );
          }
        } catch (e) {
          setState(() {
            loading = false;
          });
          Utils().toastMessage(e.toString());
        }
      }).catchError((error) {
        setState(() {
          loading = false;
        });
        Utils().toastMessage(error.toString());
      });
    }
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

  // Check if current role allows self-registration
  bool canSelfRegister() {
    return selectedRole == 'student';
  }

  // Get appropriate message for non-registrable roles
  String getRegistrationMessage() {
    switch (selectedRole) {
      case 'teacher':
        return 'Teacher accounts are created by administrators. Please contact your admin for access.';
      case 'franchise':
        return 'Franchise accounts are created by administrators. Please contact support for access.';
      case 'admin':
        return 'Admin accounts are created by system administrators. Please contact support for access.';
      default:
        return '';
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
          flex: 5,
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
                image: AssetImage('assets/images/login_bg.jpg'),
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
                  'LUIYP EDUCATION',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Learning Today, Leading Tomorrow',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 40),
                // Features or benefits
                _buildFeatureRow(
                    Icons.verified_user_outlined, 'Expert Instructors'),
                const SizedBox(height: 16),
                _buildFeatureRow(
                    Icons.play_circle_outline, 'Interactive Learning'),
                const SizedBox(height: 16),
                _buildFeatureRow(Icons.thumb_up_outlined, 'Quality Education'),
                const SizedBox(height: 16),
                _buildFeatureRow(Icons.support_agent_outlined, '24/7 Support'),
              ],
            ),
          ),
        ),

        // Right side with login form
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _buildLoginForm(screenSize),
          ),
        ),
      ],
    );
  }

  Widget _buildMediumScreenLayout(Size screenSize) {
    return Container(
      width: screenSize.width * 0.8,
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
                  'LUIYP EDUCATION',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Learning Today, Leading Tomorrow',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Login form
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
            child: _buildLoginForm(screenSize),
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
                  'LUIYP EDUCATION',
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

          // Login form
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildLoginForm(screenSize),
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

  Widget _buildLoginForm(Size screenSize) {
    final bool isSmallScreen = screenSize.width <= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSmallScreen) const SizedBox(height: 8),

        // Login header with role indicator
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 30,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please sign in to access your account',
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
        const SizedBox(height: 32),

        // Login form
        Form(
          key: _formfield,
          child: Column(
            children: [
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 12),
              _buildForgotPassword(),
              const SizedBox(height: 32),
              _buildLoginButton(),
              const SizedBox(height: 20),
              // Conditional sign up prompt or info message
              canSelfRegister() ? _buildSignUpPrompt() : _buildInfoMessage(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        prefixIcon: Icon(Icons.email_outlined, color: ColorManager.primary),
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
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Please enter your email';
        if (!RegExp(
          r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
        ).hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
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
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Please enter your password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          /* Add forgot password logic */
        },
        style: TextButton.styleFrom(
          foregroundColor: ColorManager.textDark,
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        ),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : login,
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
                'Sign In as ${getRoleDisplayName()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: ColorManager.textMedium,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignUpScreen(userRole: selectedRole),
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: ColorManager.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'Sign Up',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorManager.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: ColorManager.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              getRegistrationMessage(),
              style: TextStyle(
                fontSize: 13,
                color: ColorManager.textMedium,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
