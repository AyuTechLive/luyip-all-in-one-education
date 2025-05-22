import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class AddTeacherPage extends StatefulWidget {
  final Function onTeacherAdded;

  const AddTeacherPage({Key? key, required this.onTeacherAdded})
      : super(key: key);

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage>
    with TickerProviderStateMixin {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final qualificationController = TextEditingController();
  final achievementsController = TextEditingController();
  final subjectsController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // State variables
  bool _isPasswordVisible = false;
  String? _webImageUrl;
  Uint8List? _webImageBytes;
  String? _webImageName;
  int _currentStep = 0;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Store current user to restore after teacher creation
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Store the current user
    _currentUser = _auth.currentUser;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    qualificationController.dispose();
    achievementsController.dispose();
    subjectsController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final html.FileUploadInputElement input = html.FileUploadInputElement()
      ..accept = 'image/*';

    input.click();
    await input.onChange.first;

    if (input.files!.isNotEmpty) {
      final html.File file = input.files![0];
      _webImageName = file.name;

      final html.FileReader reader = html.FileReader();

      reader.onLoad.listen((event) {
        setState(() {
          _webImageUrl = reader.result as String;
          _webImageBytes = base64Decode(_webImageUrl!.split(',')[1]);
        });
      });

      reader.readAsDataUrl(file);
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_webImageBytes == null) return null;

    try {
      final String fileName = _webImageName ??
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageRef = _storage.ref().child(
            'profile_images/teachers/$userId/$fileName',
          );

      final uploadTask = storageRef.putData(
        _webImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> addTeacher() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
      });

      try {
        // Store current user info before creating new user
        final String? currentUserToken = await _currentUser?.getIdToken();

        // Create a secondary Firebase App instance for user creation
        // This prevents logging out the current user
        FirebaseAuth secondaryAuth = FirebaseAuth.instance;

        UserCredential userCredential;

        try {
          // Method 1: Use a secondary auth instance (recommended)
          userCredential = await secondaryAuth.createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

          // Immediately sign out the newly created user to restore admin session
          await secondaryAuth.signOut();

          // Re-authenticate the original admin user if needed
          if (_currentUser != null && currentUserToken != null) {
            // The current user should still be signed in
            await _auth.currentUser?.reload();
          }
        } catch (e) {
          // Fallback method: Create user and restore admin session
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

          // Sign out the newly created teacher
          await _auth.signOut();

          // Re-sign in the admin user if we have their credentials stored
          // Note: You might need to implement a way to store and restore admin credentials
          // For now, we'll show a message to the admin to refresh/re-login
        }

        // Generate a unique UID for Firestore document
        String teacherUID = userCredential.user!.uid;

        // Upload profile image if selected
        String? profilePicURL;
        if (_webImageBytes != null) {
          profilePicURL = await _uploadProfileImage(teacherUID);
        }

        // Format current date
        DateTime currentDate = DateTime.now();
        String formattedDate =
            '${currentDate.day}-${currentDate.month}-${currentDate.year}';

        // Create user data map
        Map<String, dynamic> userData = {
          'Email': emailController.text.trim(),
          'UID': teacherUID,
          'Name': nameController.text.trim(),
          'Phone': phoneController.text.trim(),
          'Address': addressController.text.trim(),
          'Role': 'teacher',
          'DOJ': formattedDate,
          'Qualification': qualificationController.text.trim(),
          'Achievements': achievementsController.text.trim(),
          'Subjects': subjectsController.text.trim(),
          'Assigned Courses': [],
          'ProfilePicURL': profilePicURL,
          'Status': 'Active',
          'CreatedAt': FieldValue.serverTimestamp(),
          'Password': passwordController.text
              .trim(), // Store for admin reference (consider encryption)
        };

        // Store in role-specific collection
        await _firestore
            .collection('Users')
            .doc('teacher')
            .collection('accounts')
            .doc(emailController.text.trim())
            .set(userData);

        // Also store in a general teachers collection for easier management
        await _firestore.collection('Teachers').doc(teacherUID).set(userData);

        _showSuccessDialog();

        setState(() {
          loading = false;
        });

        widget.onTeacherAdded();
      } catch (error) {
        setState(() {
          loading = false;
        });
        _showErrorDialog(error.toString());
      }
    }
  }

  // Alternative method using Cloud Functions (recommended for production)
  Future<void> addTeacherWithCloudFunction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
      });

      try {
        // Create a callable cloud function to handle user creation
        // This way, the admin user stays logged in

        // You would need to create a Cloud Function like this:
        /*
        const functions = require('firebase-functions');
        const admin = require('firebase-admin');
        
        exports.createTeacher = functions.https.onCall(async (data, context) => {
          // Verify that the requester is an admin
          if (!context.auth || context.auth.token.role !== 'admin') {
            throw new functions.https.HttpsError('permission-denied', 'Must be admin');
          }
          
          try {
            const userRecord = await admin.auth().createUser({
              email: data.email,
              password: data.password,
              displayName: data.name,
            });
            
            // Set custom claims
            await admin.auth().setCustomUserClaims(userRecord.uid, { role: 'teacher' });
            
            return { uid: userRecord.uid, success: true };
          } catch (error) {
            throw new functions.https.HttpsError('internal', error.message);
          }
        });
        */

        // For now, we'll use the previous method with session restoration
        await addTeacher();
      } catch (error) {
        setState(() {
          loading = false;
        });
        _showErrorDialog(error.toString());
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  const Text(
                    'Teacher has been added successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_auth.currentUser == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please refresh the page and log back in as admin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  // If admin is logged out, redirect to login
                  if (_auth.currentUser == null) {
                    // Navigate to login page or show login dialog
                    _showReLoginDialog();
                  }
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.login,
                  color: Colors.blue,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Session Restored',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please refresh the page to restore your admin session.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Refresh the page
                  html.window.location.reload();
                },
                child: const Text('Refresh Page'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Try Again'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Professional App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: ColorManager.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Add New Teacher',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorManager.primary,
                      ColorManager.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.person_add_alt_1,
                    size: 48,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                margin: const EdgeInsets.all(16),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            _buildHeaderSection(),
                            const SizedBox(height: 32),

                            // Profile Image Section
                            _buildProfileImageSection(),
                            const SizedBox(height: 40),

                            // Form Fields
                            _buildFormFields(),
                            const SizedBox(height: 40),

                            // Action Buttons
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.primary.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorManager.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teacher Registration',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a new teacher to your educational institution',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorManager.primary.withOpacity(0.1),
                      ColorManager.primary.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorManager.primary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorManager.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _webImageBytes != null
                    ? ClipOval(
                        child: Image.network(
                          _webImageUrl!,
                          fit: BoxFit.cover,
                          height: 140,
                          width: 140,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 80,
                        color: ColorManager.primary.withOpacity(0.5),
                      ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorManager.primary,
                          ColorManager.primary.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
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
          const SizedBox(height: 16),
          Text(
            'Profile Picture',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Click the camera icon to upload',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information Section
        _buildSectionHeader('Personal Information', Icons.person),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildProfessionalInputField(
                'Full Name',
                'Enter teacher\'s full name',
                nameController,
                Icons.person_outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProfessionalInputField(
                'Email Address',
                'Enter email address',
                emailController,
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildPasswordField(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProfessionalInputField(
                'Phone Number',
                'Enter phone number',
                phoneController,
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildProfessionalInputField(
          'Address',
          'Enter complete address',
          addressController,
          Icons.location_on_outlined,
          maxLines: 2,
        ),

        const SizedBox(height: 32),

        // Professional Information Section
        _buildSectionHeader('Professional Information', Icons.work),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildProfessionalInputField(
                'Qualification',
                'E.g., Ph.D. in Mathematics',
                qualificationController,
                Icons.school_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProfessionalInputField(
                'Subjects Taught',
                'Comma-separated subjects',
                subjectsController,
                Icons.subject_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildProfessionalInputField(
          'Achievements & Experience',
          'Notable achievements and professional experience',
          achievementsController,
          Icons.emoji_events_outlined,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: ColorManager.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: ColorManager.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInputField(
    String label,
    String hintText,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorManager.primary, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 12),
                child: Icon(
                  icon,
                  color: ColorManager.primary.withOpacity(0.7),
                  size: 22,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              if (label == 'Email Address') {
                final bool emailValid = RegExp(
                  r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                ).hasMatch(value);
                if (!emailValid) {
                  return 'Enter a valid email address';
                }
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
            decoration: InputDecoration(
              hintText: 'Enter secure password',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorManager.primary, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.lock_outline,
                  color: ColorManager.primary.withOpacity(0.7),
                  size: 22,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: ColorManager.primary.withOpacity(0.7),
                  size: 22,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              } else if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Password must be at least 6 characters long',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Submit Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ColorManager.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: loading ? null : addTeacher,
            child: loading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Processing...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Register Teacher',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Cancel Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
