import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class AddFranchisePage extends StatefulWidget {
  final VoidCallback? onFranchiseAdded;

  const AddFranchisePage({Key? key, this.onFranchiseAdded}) : super(key: key);

  @override
  State<AddFranchisePage> createState() => _AddFranchisePageState();
}

class _AddFranchisePageState extends State<AddFranchisePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _franchiseNameController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _selectedStatus = 'Active';
  String _selectedCategory = 'Standard';

  // Store current admin credentials
  String? adminEmail;
  String? adminPassword;

  final List<String> _statusOptions = ['Active', 'Inactive', 'Pending'];
  final List<String> _categoryOptions = [
    'Standard',
    'Premium',
    'Gold',
    'Platinum'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAdminData();
  }

  void _initializeAdminData() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      adminEmail = currentUser.email!;
      print('Admin email stored: $adminEmail');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _franchiseNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _commissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<String> _promptForAdminPassword() async {
    String? password;
    bool keepTrying = true;
    int attemptCount = 0;
    const maxAttempts = 3;

    while (keepTrying && attemptCount < maxAttempts) {
      attemptCount++;
      String errorMessage = '';

      // Show error message if this is a retry
      if (attemptCount > 1) {
        if (attemptCount == maxAttempts) {
          errorMessage =
              'Last attempt! Incorrect password. Please try again carefully.';
        } else {
          errorMessage =
              'Incorrect password. Please try again. (${maxAttempts - attemptCount + 1} attempts remaining)';
        }
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          TextEditingController passwordController = TextEditingController();
          bool isPasswordVisible = false;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.security,
                        color: ColorManager.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      attemptCount > 1 ? 'Try Again' : 'Re-authenticate',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show error message if this is a retry
                    if (errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Please enter your password to continue creating the franchise account:',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorManager.textMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      child: TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        autofocus: true, // Auto focus for better UX
                        decoration: InputDecoration(
                          labelText: 'Admin Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: ColorManager.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: ColorManager.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: ColorManager.primary, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        onSubmitted: (value) {
                          // Allow pressing Enter to submit
                          password = value;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (attemptCount >=
                      maxAttempts) // Show cancel only on last attempt
                    TextButton(
                      onPressed: () {
                        password = null; // Set to null to indicate cancellation
                        keepTrying = false;
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel Registration',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      password = ''; // Empty password to continue loop
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Skip for Now',
                      style: TextStyle(color: ColorManager.textMedium),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      password = passwordController.text;
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(attemptCount > 1 ? 'Try Again' : 'Continue'),
                  ),
                ],
              );
            },
          );
        },
      );

      // Check what user chose
      if (password == null) {
        // User cancelled completely
        keepTrying = false;
        return '';
      } else if (password!.isEmpty) {
        // User chose to skip - treat as cancellation
        keepTrying = false;
        return '';
      } else {
        // User entered a password, try to authenticate
        try {
          // Test the password by attempting to sign in
          User? adminUser = _auth.currentUser;
          if (adminUser?.email != null) {
            // Create a temporary auth instance to test password
            await _auth.signInWithEmailAndPassword(
              email: adminUser!.email!,
              password: password!,
            );
            // If we reach here, password is correct
            keepTrying = false;
            return password!;
          } else {
            throw Exception('Admin user not found');
          }
        } catch (e) {
          // Password is wrong, continue the loop
          if (attemptCount >= maxAttempts) {
            // Max attempts reached
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Maximum password attempts reached. Registration cancelled.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            keepTrying = false;
            return '';
          }
          // Continue loop for retry
        }
      }
    }

    return '';
  }

  Future<void> _addFranchise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Store current admin user
      User? adminUser = _auth.currentUser;
      if (adminUser == null) {
        throw Exception('Admin user not logged in');
      }

      // Create Firebase Auth account for the franchise
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Sign out the newly created franchise user
      await _auth.signOut();

      // Prompt for admin password and re-authenticate with retry logic
      String adminPassword = await _promptForAdminPassword();
      if (adminPassword.isEmpty) {
        throw Exception('Admin authentication cancelled');
      }

      // Re-authenticate admin user
      await _auth.signInWithEmailAndPassword(
        email: adminUser.email!,
        password: adminPassword,
      );

      // Format current date
      DateTime currentDate = DateTime.now();
      String formattedDate =
          '${currentDate.day}-${currentDate.month}-${currentDate.year}';

      // Create franchise data
      Map<String, dynamic> franchiseData = {
        'UID': userCredential.user!.uid, // Add Firebase Auth UID
        'Name': _nameController.text.trim(),
        'Email': _emailController.text.trim(),
        'Phone': _phoneController.text.trim(),
        'FranchiseName': _franchiseNameController.text.trim(),
        'Address': _addressController.text.trim(),
        'City': _cityController.text.trim(),
        'State': _stateController.text.trim(),
        'PinCode': _pinCodeController.text.trim(),
        'CommissionPercent': double.parse(_commissionController.text.trim()),
        'Status': _selectedStatus,
        'Category': _selectedCategory,
        'Notes': _notesController.text.trim(),
        'DOJ': formattedDate,
        'Role': 'franchise',
        'TotalRevenue': 0.0,
        'MonthlyRevenue': 0.0,
        'TotalStudents': 0,
        'ActiveCourses': [],
        'My Courses': [], // Add this for consistency with other user types
        'CreatedAt': FieldValue.serverTimestamp(),
        'AddedBy': 'admin',
        'AddedDate': formattedDate,
      };

      // Add to Firestore in franchise collection (same structure as signup)
      await _firestore
          .collection('Users')
          .doc('franchise')
          .collection('accounts')
          .doc(_emailController.text.trim())
          .set(franchiseData);

      // Also add to a separate Franchises collection for easier management
      await _firestore
          .collection('Franchises')
          .doc(_emailController.text.trim())
          .set(franchiseData);

      Utils().toastMessage('Franchise account created successfully!');

      // Show success dialog with details
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ Franchise Account Created'),
                Text('📧 Email: ${_emailController.text.trim()}'),
                Text('🏢 Franchise: ${_franchiseNameController.text.trim()}'),
                Text('💰 Commission: ${_commissionController.text.trim()}%'),
                Text(
                    '📍 Location: ${_cityController.text.trim()}, ${_stateController.text.trim()}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Call callback if provided
      if (widget.onFranchiseAdded != null) {
        widget.onFranchiseAdded!();
      }

      // Clear form
      _clearForm();

      setState(() {
        _isLoading = false;
      });

      // Navigate back
      Navigator.pop(context);
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      String errorMessage = 'Error creating franchise account: ';

      // Handle specific Firebase Auth errors
      if (error.toString().contains('email-already-in-use')) {
        errorMessage += 'This email is already registered.';
      } else if (error.toString().contains('weak-password')) {
        errorMessage += 'Password is too weak.';
      } else if (error.toString().contains('invalid-email')) {
        errorMessage += 'Invalid email address.';
      } else if (error.toString().contains('wrong-password')) {
        errorMessage += 'Incorrect admin password provided.';
      } else if (error.toString().contains('user-not-found')) {
        errorMessage += 'Admin account not found.';
      } else if (error.toString().contains('too-many-requests')) {
        errorMessage += 'Too many failed attempts. Please try again later.';
      } else if (error.toString().contains('authentication cancelled')) {
        errorMessage = 'Authentication cancelled by user.';
      } else {
        errorMessage += error.toString();
      }

      Utils().toastMessage(errorMessage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _phoneController.clear();
    _franchiseNameController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pinCodeController.clear();
    _commissionController.clear();
    _notesController.clear();
    setState(() {
      _selectedStatus = 'Active';
      _selectedCategory = 'Standard';
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Franchise'),
        backgroundColor: ColorManager.primary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _clearForm,
            icon: const Icon(Icons.clear_all, color: Colors.white),
            label:
                const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Container(
        color: ColorManager.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.store_outlined,
                        color: ColorManager.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Franchise Partner',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the details to register a new franchise partner with login credentials',
                            style: TextStyle(
                              fontSize: 16,
                              color: ColorManager.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Info card about login and authentication
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorManager.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ColorManager.info.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: ColorManager.info),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This will create a franchise account with login credentials. You will be asked to re-authenticate to maintain admin session security.',
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorManager.info,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.security,
                            color: ColorManager.info, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your admin session will remain active after creating the franchise account.',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorManager.info,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      _buildSectionHeader(
                          'Personal Information', Icons.person_outline),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'Enter full name',
                              icon: Icons.person_outline,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter full name'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'Enter email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Please enter email';
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value!)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter phone number'
                            : null,
                      ),

                      const SizedBox(height: 32),

                      // Login Credentials Section
                      _buildSectionHeader(
                          'Login Credentials', Icons.security_outlined),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildPasswordField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Create a password for franchise login',
                              isVisible: _isPasswordVisible,
                              onToggleVisibility: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hint: 'Confirm the password',
                              isVisible: _isConfirmPasswordVisible,
                              onToggleVisibility: () => setState(() =>
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible),
                              isConfirmPassword: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Franchise Information Section
                      _buildSectionHeader(
                          'Franchise Information', Icons.store_outlined),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _franchiseNameController,
                        label: 'Franchise Name',
                        hint: 'Enter franchise business name',
                        icon: Icons.business_outlined,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter franchise name'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        hint: 'Enter complete address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter address'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'City',
                              hint: 'Enter city',
                              icon: Icons.location_city_outlined,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter city'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _stateController,
                              label: 'State',
                              hint: 'Enter state',
                              icon: Icons.map_outlined,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter state'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _pinCodeController,
                              label: 'PIN Code',
                              hint: 'Enter PIN code',
                              icon: Icons.pin_drop_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Please enter PIN code';
                                if (value!.length != 6)
                                  return 'PIN code must be 6 digits';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Business Terms Section
                      _buildSectionHeader(
                          'Business Terms', Icons.business_center_outlined),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _commissionController,
                              label: 'Commission Percentage',
                              hint: 'Enter commission %',
                              icon: Icons.percent_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Please enter commission percentage';
                                final commission = double.tryParse(value!);
                                if (commission == null)
                                  return 'Please enter a valid number';
                                if (commission < 0 || commission > 100)
                                  return 'Commission must be between 0-100%';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Status',
                              value: _selectedStatus,
                              items: _statusOptions,
                              onChanged: (value) =>
                                  setState(() => _selectedStatus = value!),
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Category',
                              value: _selectedCategory,
                              items: _categoryOptions,
                              onChanged: (value) =>
                                  setState(() => _selectedCategory = value!),
                              icon: Icons.star_outline,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _notesController,
                        label: 'Additional Notes',
                        hint: 'Enter any additional notes or comments',
                        icon: Icons.note_outlined,
                        maxLines: 3,
                        required: false,
                      ),

                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _addFranchise,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Creating Franchise...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_business,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Add Franchise',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ColorManager.textDark,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side:
                                    BorderSide(color: ColorManager.textMedium),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ColorManager.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: ColorManager.primary),
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: required
          ? (validator ??
              (value) =>
                  value?.isEmpty ?? true ? 'This field is required' : null)
          : null,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    bool isConfirmPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.lock_outline, color: ColorManager.primary),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: ColorManager.primary,
          ),
          onPressed: onToggleVisibility,
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return isConfirmPassword
              ? 'Please confirm password'
              : 'Please enter password';
        }
        if (value!.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (isConfirmPassword && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade50,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: ColorManager.primary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
