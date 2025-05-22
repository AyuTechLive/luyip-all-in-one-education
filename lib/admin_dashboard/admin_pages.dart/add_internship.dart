import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_network/image_network.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class AdminInternshipPage extends StatefulWidget {
  const AdminInternshipPage({Key? key}) : super(key: key);

  @override
  State<AdminInternshipPage> createState() => _AdminInternshipPageState();
}

class _AdminInternshipPageState extends State<AdminInternshipPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _internships = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadInternships();
  }

  Future<void> _loadInternships() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Internships')
          .orderBy('postedDate', descending: true)
          .get();

      List<Map<String, dynamic>> internships = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        internships.add(data);
      }

      setState(() {
        _internships = internships;
      });
    } catch (e) {
      print('Error loading internships: $e');
      Utils().toastMessage('Error loading internships');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredInternships {
    if (_selectedFilter == 'All') {
      return _internships;
    }
    return _internships.where((internship) {
      if (_selectedFilter == 'Members Only') {
        return internship['visibility'] == 'members';
      } else if (_selectedFilter == 'Public') {
        return internship['visibility'] == 'all';
      }
      String type = internship['type'] ?? '';
      return type.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  Future<void> _deleteInternship(String internshipId) async {
    try {
      await _firestore.collection('Internships').doc(internshipId).delete();
      Utils().toastMessage('Internship deleted successfully');
      _loadInternships();
    } catch (e) {
      Utils().toastMessage('Error deleting internship');
    }
  }

  void _confirmDelete(String internshipId, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteInternship(internshipId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _openAddEditDialog({Map<String, dynamic>? internship}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddEditInternshipDialog(
          internship: internship,
          onSaved: () {
            Navigator.of(context).pop();
            _loadInternships();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = _isSmallScreen(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            )
          : Column(
              children: [
                // Header with filters and stats
                _buildHeader(isSmallScreen),

                // Internships list
                Expanded(
                  child: _filteredInternships.isEmpty
                      ? _buildEmptyState()
                      : _buildInternshipsList(isSmallScreen),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditDialog(),
        backgroundColor: ColorManager.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isSmallScreen ? 'Add' : 'Add Internship',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total', _internships.length.toString(),
                    Icons.work, ColorManager.primary, isSmallScreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Public',
                    _internships
                        .where((i) => i['visibility'] == 'all')
                        .length
                        .toString(),
                    Icons.public,
                    ColorManager.info,
                    isSmallScreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Members',
                    _internships
                        .where((i) => i['visibility'] == 'members')
                        .length
                        .toString(),
                    Icons.star,
                    ColorManager.warning,
                    isSmallScreen),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter chips
          if (isSmallScreen) _buildMobileFilters() else _buildDesktopFilters(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: ColorManager.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    final filters = [
      'All',
      'Remote',
      'On-site',
      'Hybrid',
      'Public',
      'Members Only'
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : ColorManager.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: ColorManager.primary,
              backgroundColor: Colors.white,
              side: BorderSide(color: ColorManager.primary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopFilters() {
    final filters = [
      'All',
      'Remote',
      'On-site',
      'Hybrid',
      'Public',
      'Members Only'
    ];

    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return FilterChip(
          label: Text(
            filter,
            style: TextStyle(
              color: isSelected ? Colors.white : ColorManager.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = filter;
            });
          },
          selectedColor: ColorManager.primary,
          backgroundColor: Colors.white,
          side: BorderSide(color: ColorManager.primary),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: ColorManager.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              'No Internships Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorManager.textMedium,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by adding your first internship posting',
              style: TextStyle(
                color: ColorManager.textLight,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInternshipsList(bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: _loadInternships,
      color: ColorManager.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        itemCount: _filteredInternships.length,
        itemBuilder: (context, index) {
          final internship = _filteredInternships[index];
          return _buildInternshipCard(internship, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildInternshipCard(
      Map<String, dynamic> internship, bool isSmallScreen) {
    final String id = internship['id'] ?? '';
    final String title = internship['title'] ?? 'Untitled';
    final String company = internship['company'] ?? 'Unknown Company';
    final String location = internship['location'] ?? 'Location not specified';
    final String type = internship['type'] ?? 'Not specified';
    final String duration = internship['duration'] ?? 'Not specified';
    final String stipend = internship['stipend'] ?? 'Not mentioned';
    final String imageUrl = internship['imageUrl'] ?? '';
    final String visibility = internship['visibility'] ?? 'all';
    final Timestamp? postedDate = internship['postedDate'];

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          if (imageUrl.isNotEmpty) _buildImageSection(imageUrl, isSmallScreen),

          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: ColorManager.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _openAddEditDialog(internship: internship),
                          icon: Icon(Icons.edit, color: ColorManager.info),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () => _confirmDelete(id, title),
                          icon: Icon(Icons.delete, color: ColorManager.error),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Details and status
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(Icons.location_on_outlined, location,
                              isSmallScreen),
                          _buildInfoChip(
                              Icons.work_outline, type, isSmallScreen),
                          _buildInfoChip(
                              Icons.schedule_outlined, duration, isSmallScreen),
                          _buildInfoChip(
                              Icons.currency_rupee, stipend, isSmallScreen),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Visibility and date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: visibility == 'members'
                            ? Colors.amber.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: visibility == 'members'
                              ? Colors.amber.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            visibility == 'members' ? Icons.star : Icons.public,
                            color: visibility == 'members'
                                ? Colors.amber.shade700
                                : Colors.green,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            visibility == 'members' ? 'Members Only' : 'Public',
                            style: TextStyle(
                              color: visibility == 'members'
                                  ? Colors.amber.shade700
                                  : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (postedDate != null)
                      Text(
                        'Posted ${_formatDate(postedDate.toDate())}',
                        style: TextStyle(
                          fontSize: 11,
                          color: ColorManager.textLight,
                        ),
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

  Widget _buildImageSection(String imageUrl, bool isSmallScreen) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 200 : 250,
            child: ImageNetwork(
              image: imageUrl,
              height: isSmallScreen ? 200 : 250,
              width: constraints.maxWidth,
              fitAndroidIos: BoxFit.cover,
              onLoading: Container(
                color: ColorManager.background,
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
              onError: Container(
                color: ColorManager.background,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: ColorManager.textLight,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: ColorManager.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorManager.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorManager.light),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 12 : 14,
            color: ColorManager.textMedium,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: ColorManager.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }
}

// Add/Edit Internship Dialog
class _AddEditInternshipDialog extends StatefulWidget {
  final Map<String, dynamic>? internship;
  final VoidCallback onSaved;

  const _AddEditInternshipDialog({
    this.internship,
    required this.onSaved,
  });

  @override
  State<_AddEditInternshipDialog> createState() =>
      _AddEditInternshipDialogState();
}

class _AddEditInternshipDialogState extends State<_AddEditInternshipDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _durationController;
  late TextEditingController _stipendController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _applyUrlController;
  late TextEditingController _eligibilityController;
  late TextEditingController _skillsController;

  String _selectedType = 'Remote';
  String _selectedVisibility = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController =
        TextEditingController(text: widget.internship?['title'] ?? '');
    _companyController =
        TextEditingController(text: widget.internship?['company'] ?? '');
    _locationController =
        TextEditingController(text: widget.internship?['location'] ?? '');
    _durationController =
        TextEditingController(text: widget.internship?['duration'] ?? '');
    _stipendController =
        TextEditingController(text: widget.internship?['stipend'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.internship?['description'] ?? '');
    _imageUrlController =
        TextEditingController(text: widget.internship?['imageUrl'] ?? '');
    _applyUrlController =
        TextEditingController(text: widget.internship?['applyUrl'] ?? '');

    // Convert lists to strings for editing
    _eligibilityController = TextEditingController(
        text: widget.internship?['eligibility']?.join('\n') ?? '');
    _skillsController = TextEditingController(
        text: widget.internship?['skills']?.join(', ') ?? '');

    _selectedType = widget.internship?['type'] ?? 'Remote';
    _selectedVisibility = widget.internship?['visibility'] ?? 'all';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _stipendController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _applyUrlController.dispose();
    _eligibilityController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _saveInternship() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare data
      final data = {
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'type': _selectedType,
        'duration': _durationController.text.trim(),
        'stipend': _stipendController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'applyUrl': _applyUrlController.text.trim(),
        'eligibility': _eligibilityController.text
            .trim()
            .split('\n')
            .where((item) => item.trim().isNotEmpty)
            .map((item) => item.trim())
            .toList(),
        'skills': _skillsController.text
            .trim()
            .split(',')
            .where((item) => item.trim().isNotEmpty)
            .map((item) => item.trim())
            .toList(),
        'visibility': _selectedVisibility,
        'postedDate': widget.internship == null
            ? FieldValue.serverTimestamp()
            : widget.internship!['postedDate'],
        'lastModified': FieldValue.serverTimestamp(),
      };

      if (widget.internship == null) {
        // Add new internship
        await _firestore.collection('Internships').add(data);
        Utils().toastMessage('Internship posted successfully');
      } else {
        // Update existing internship
        await _firestore
            .collection('Internships')
            .doc(widget.internship!['id'])
            .update(data);
        Utils().toastMessage('Internship updated successfully');
      }

      widget.onSaved();
    } catch (e) {
      Utils().toastMessage('Error saving internship: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    return Dialog(
      child: Container(
        width: isSmallScreen ? double.infinity : 600,
        height: isSmallScreen ? MediaQuery.of(context).size.height * 0.9 : 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.internship == null
                      ? 'Add Internship'
                      : 'Edit Internship',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: ColorManager.textMedium),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Basic Information
                      _buildTextField(_titleController, 'Job Title',
                          'e.g., Frontend Developer Intern'),
                      const SizedBox(height: 16),
                      _buildTextField(_companyController, 'Company Name',
                          'e.g., Tech Solutions Inc.'),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(_locationController,
                                'Location', 'e.g., Mumbai, India'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown('Type', _selectedType,
                                ['Remote', 'On-site', 'Hybrid'], (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(_durationController,
                                'Duration', 'e.g., 3 months'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(_stipendController,
                                'Stipend', 'e.g., ₹15,000/month'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _buildTextField(_descriptionController, 'Description',
                          'Describe the internship role and responsibilities',
                          maxLines: 4),
                      const SizedBox(height: 16),

                      // URLs
                      _buildTextField(
                          _imageUrlController,
                          'Image URL (Optional)',
                          'https://example.com/image.jpg'),
                      const SizedBox(height: 16),
                      _buildTextField(_applyUrlController, 'Application URL',
                          'https://company.com/apply'),
                      const SizedBox(height: 16),

                      // Eligibility (one per line)
                      _buildTextField(
                          _eligibilityController,
                          'Eligibility Criteria',
                          'Enter each criterion on a new line',
                          maxLines: 4),
                      const SizedBox(height: 16),

                      // Skills (comma separated)
                      _buildTextField(_skillsController, 'Required Skills',
                          'Separate skills with commas',
                          maxLines: 2),
                      const SizedBox(height: 16),

                      // Visibility
                      _buildDropdown(
                          'Visibility', _selectedVisibility, ['all', 'members'],
                          (value) {
                        setState(() {
                          _selectedVisibility = value!;
                        });
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: TextStyle(color: ColorManager.textMedium)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveInternship,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(widget.internship == null
                          ? 'Post Internship'
                          : 'Update Internship'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorManager.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorManager.primary, width: 2),
        ),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option == 'all'
              ? 'Public'
              : option == 'members'
                  ? 'Members Only'
                  : option),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
