import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:luyip_website_edu/Courses/helper/add_course_teacher.dart';
import 'package:luyip_website_edu/Courses/helper/file_upload_handler.dart';
import 'package:luyip_website_edu/Courses/helper/image_upload_handler.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class AddCourse extends StatefulWidget {
  final Function? onCourseAdded;
  final DocumentSnapshot? courseDoc; // For editing existing courses
  final bool isEditing; // Flag to determine if we're editing

  const AddCourse({
    super.key,
    this.onCourseAdded,
    this.courseDoc,
    this.isEditing = false,
  });

  @override
  State<AddCourse> createState() => _AddCourseState();
}

class _AddCourseState extends State<AddCourse> {
  bool loading = false;
  final coursediscriptioncontroller = TextEditingController();
  final coursenamecontroller = TextEditingController();
  final coursepricecontroller = TextEditingController();
  final courseimglinkcontroller = TextEditingController();
  final discountPercentageController = TextEditingController();
  final durationController = TextEditingController();
  final prerequisitesController = TextEditingController();
  final difficultyController = TextEditingController();
  final previewPdfController = TextEditingController();
  final previewVideoController = TextEditingController();
  final syllabusPdfController = TextEditingController();
  final schedulePdfController = TextEditingController();
  late FileUploadHandler previewPdfHandler;
  late FileUploadHandler syllabusPdfHandler;
  late FileUploadHandler schedulePdfHandler;

  // Learning objectives
  List<String> learningObjectives = [];
  final TextEditingController _objectiveController = TextEditingController();

  // Feature cards
  List<Map<String, dynamic>> featureCards = [];
  final TextEditingController _featureTitleController = TextEditingController();
  final TextEditingController _featureDescController = TextEditingController();
  String _selectedIcon = 'video_library';
  String _selectedColor = 'blue';

  // Key documents
  List<Map<String, dynamic>> keyDocuments = [];
  final TextEditingController _documentTitleController =
      TextEditingController();
  final TextEditingController _documentDescController = TextEditingController();
  final TextEditingController _documentUrlController = TextEditingController();
  String _selectedDocType = 'document';
  late FileUploadHandler documentUploadHandler;

  bool isFeaturesCourse = false;
  String selectedCategory = 'Programming';
  List<String> categories = [
    'Programming',
    'Design',
    'Business',
    'Marketing',
    'Finance',
    'Personal Development',
    'Other',
  ];

  // Icon options for feature cards
  final Map<String, IconData> iconOptions = {
    'video_library': Icons.video_library,
    'people': Icons.people,
    'assignment': Icons.assignment,
    'school': Icons.school,
    'star': Icons.star,
    'devices': Icons.devices,
    'support': Icons.support_agent,
    'chat': Icons.chat,
    'forum': Icons.forum,
  };

  // Color options for feature cards
  final Map<String, Color> colorOptions = {
    'blue': Colors.blue,
    'green': Colors.green,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'red': Colors.red,
    'teal': Colors.teal,
  };

  // Document type options
  final Map<String, IconData> docTypeOptions = {
    'document': Icons.insert_drive_file,
    'syllabus': Icons.menu_book,
    'worksheet': Icons.assignment,
    'reference': Icons.library_books,
    'lecture': Icons.school,
    'preview': Icons.visibility,
  };

  // Replace single teacher with list of teachers
  List<Map<String, dynamic>> selectedTeachers = [];

  final fireStore = FirebaseFirestore.instance.collection('All Courses');

  // Use the ImageUploadHandler instead of direct File handling
  late ImageUploadHandler imageHandler;

  // Store original course name for editing
  String? originalCourseName;

  Future<void> _handleFileUpload({
    required FileUploadHandler handler,
    required TextEditingController controller,
    required String storagePath,
  }) async {
    final success = await handler.pickFile();
    if (!success) return;

    setState(() => loading = true);
    try {
      final url = await handler.uploadFile(storagePath);
      controller.text = url;
      Utils().toastMessage('File uploaded successfully!');
    } catch (e) {
      Utils().toastMessage('Upload failed: ${e.toString()}');
    } finally {
      setState(() => loading = false);
    }
  }

  void _loadCourseDataForEditing() {
    if (widget.courseDoc == null) return;

    final data = widget.courseDoc!.data() as Map<String, dynamic>;

    // Store original course name
    originalCourseName = data['Course Name'];

    // Basic info
    coursenamecontroller.text = data['Course Name'] ?? '';
    coursediscriptioncontroller.text = data['Course Discription'] ?? '';
    coursepricecontroller.text = data['Course Price'] ?? '';
    courseimglinkcontroller.text = data['Course Img Link'] ?? '';

    // Additional fields
    selectedCategory = data['Category'] ?? 'Programming';
    difficultyController.text = data['Difficulty'] ?? '';
    discountPercentageController.text = data['Membership Discount'] ?? '';
    durationController.text = data['Duration'] ?? '';
    prerequisitesController.text = data['Prerequisites'] ?? '';
    isFeaturesCourse = data['Is Featured'] ?? false;

    // Load preview/materials
    previewVideoController.text = data['PreviewVideo'] ?? '';
    previewPdfController.text = data['PreviewPDF'] ?? '';
    syllabusPdfController.text = data['SyllabusPDF'] ?? '';
    schedulePdfController.text = data['SchedulePDF'] ?? '';

    // Load dynamic content
    learningObjectives = List<String>.from(data['LearningObjectives'] ?? []);
    featureCards = List<Map<String, dynamic>>.from(data['FeatureCards'] ?? []);
    keyDocuments = List<Map<String, dynamic>>.from(data['KeyDocuments'] ?? []);

    // Load teachers
    List<dynamic> teachersData = data['Teachers'] ?? [];
    selectedTeachers = teachersData
        .map((teacher) => {
              'Name': teacher['Name'] ?? '',
              'Email': teacher['Email'] ?? '',
              'ProfilePicURL': teacher['ProfilePicURL'] ?? '',
              'Subject': teacher['Subject'] ?? '',
              'Qualification': teacher['Qualification'] ?? '',
              'Experience': teacher['Experience'] ?? '',
              'Rating': teacher['Rating'] ?? '4.5',
            })
        .toList();
  }

  @override
  void initState() {
    super.initState();
    previewPdfHandler = FileUploadHandler();
    syllabusPdfHandler = FileUploadHandler();
    schedulePdfHandler = FileUploadHandler();
    documentUploadHandler = FileUploadHandler();
    imageHandler = ImageUploadHandler();

    // Load existing course data if editing
    if (widget.isEditing && widget.courseDoc != null) {
      _loadCourseDataForEditing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Course' : 'Create New Course',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 80,
        actions: widget.isEditing
            ? [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Editing Mode',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isLargeScreen ? 32 : 16),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 1400 : double.infinity),
            child: isLargeScreen ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Main Form (70%)
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildPricingSection(),
              const SizedBox(height: 24),
              _buildAdditionalInfoSection(),
              const SizedBox(height: 24),
              _buildLearningObjectivesSection(),
              const SizedBox(height: 24),
              _buildFeatureCardsSection(),
              const SizedBox(height: 24),
              _buildMaterialsSection(),
              const SizedBox(height: 24),
              _buildKeyDocumentsSection(),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right Column - Image & Teachers (30%)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildImageUploadSection(),
              const SizedBox(height: 24),
              _buildTeachersSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildBasicInfoSection(),
        const SizedBox(height: 24),
        _buildImageUploadSection(),
        const SizedBox(height: 24),
        _buildPricingSection(),
        const SizedBox(height: 24),
        _buildAdditionalInfoSection(),
        const SizedBox(height: 24),
        _buildTeachersSection(),
        const SizedBox(height: 24),
        _buildLearningObjectivesSection(),
        const SizedBox(height: 24),
        _buildFeatureCardsSection(),
        const SizedBox(height: 24),
        _buildMaterialsSection(),
        const SizedBox(height: 24),
        _buildKeyDocumentsSection(),
        const SizedBox(height: 32),
        _buildSubmitButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCard(
      String title, String subtitle, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: ColorManager.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildCard(
      'Basic Information',
      'Enter the fundamental details about your course',
      Icons.info_outline,
      Column(
        children: [
          _buildTextField(
            controller: coursenamecontroller,
            labelText: 'Course Name',
            hintText: 'Enter course name',
            prefixIcon: Icons.title,
            maxLines: 1,
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            labelText: 'Category',
            value: selectedCategory,
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value!;
              });
            },
            prefixIcon: Icons.category,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: difficultyController,
            labelText: 'Difficulty Level',
            hintText: 'e.g., Beginner, Intermediate, Advanced',
            prefixIcon: Icons.trending_up,
            maxLines: 1,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: coursediscriptioncontroller,
            labelText: 'Course Description',
            hintText: 'Provide a detailed description',
            prefixIcon: Icons.description,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return _buildCard(
      'Pricing Information',
      'Set your course pricing and discounts',
      Icons.monetization_on,
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: coursepricecontroller,
                  labelText: 'Price (₹)',
                  hintText: 'Enter course price',
                  prefixIcon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: discountPercentageController,
                  labelText: 'Membership Discount (%)',
                  hintText: 'Enter discount percentage',
                  prefixIcon: Icons.discount,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: CheckboxListTile(
              title: const Text(
                'Featured Course',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Highlight this course on the homepage'),
              value: isFeaturesCourse,
              onChanged: (value) {
                setState(() {
                  isFeaturesCourse = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: ColorManager.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return _buildCard(
      'Additional Information',
      'Course duration and prerequisites',
      Icons.info,
      Column(
        children: [
          _buildTextField(
            controller: durationController,
            labelText: 'Course Duration',
            hintText: 'e.g., 8 weeks, 12 hours',
            prefixIcon: Icons.timer,
            maxLines: 1,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: prerequisitesController,
            labelText: 'Prerequisites',
            hintText: 'Any requirements or prerequisites',
            prefixIcon: Icons.list_alt,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return _buildCard(
      'Course Banner',
      'Upload an attractive banner image',
      Icons.image,
      Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: courseimglinkcontroller.text.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      courseimglinkcontroller.text,
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return imageHandler.getImagePreview(
                          height: 200,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(12),
                        );
                      },
                    ),
                  )
                : imageHandler.getImagePreview(
                    height: 200,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(12),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Select Banner Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final success = await imageHandler.pickImage();
                if (success) {
                  setState(() {
                    loading = true;
                  });
                  try {
                    final imageUrl = await imageHandler
                        .uploadImageToFirebase('/course_banners');
                    courseimglinkcontroller.text = imageUrl;
                    Utils().toastMessage('Image uploaded successfully!');
                    setState(() {}); // Update UI to show new image
                  } catch (e) {
                    Utils().toastMessage('Failed to upload image: $e');
                  } finally {
                    setState(() {
                      loading = false;
                    });
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersSection() {
    return _buildCard(
      'Course Instructors',
      'Select teachers for this course',
      Icons.people,
      AddCourseTeachers(
        selectedTeachers: selectedTeachers,
        onTeachersChanged: (teachers) {
          setState(() {
            selectedTeachers = teachers;
          });
        },
      ),
    );
  }

  Widget _buildLearningObjectivesSection() {
    return _buildCard(
      'Learning Objectives',
      'What will students achieve in this course?',
      Icons.track_changes,
      Column(
        children: [
          if (learningObjectives.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learning Objectives',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...learningObjectives.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String objective = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.circle,
                              size: 8, color: ColorManager.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(objective)),
                          IconButton(
                            icon:
                                Icon(Icons.delete, color: Colors.red.shade300),
                            onPressed: () {
                              setState(() {
                                learningObjectives.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _objectiveController,
                  decoration: const InputDecoration(
                    labelText: 'Objective',
                    hintText: 'e.g., Master fundamental concepts',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_objectiveController.text.trim().isNotEmpty) {
                    setState(() {
                      learningObjectives.add(_objectiveController.text.trim());
                      _objectiveController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCardsSection() {
    return _buildCard(
      'Feature Cards',
      'Highlight key aspects of your course',
      Icons.featured_play_list,
      Column(
        children: [
          if (featureCards.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feature Cards',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: featureCards.length,
                    itemBuilder: (context, index) {
                      final feature = featureCards[index];
                      final color =
                          _getColorFromString(feature['color'] ?? 'blue');
                      final icon =
                          _getIconFromString(feature['icon'] ?? 'info');

                      return Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(icon, color: color, size: 20),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        feature['title'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    feature['description'] ?? '',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  featureCards.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ExpansionTile(
            title: const Text('Add New Feature Card'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _featureTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Video Lectures',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _featureDescController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'e.g., HD video content with interactive elements',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Icon',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedIcon,
                            items: iconOptions.keys.map((key) {
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Row(
                                  children: [
                                    Icon(iconOptions[key]),
                                    const SizedBox(width: 8),
                                    Text(key),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedIcon = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Color',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedColor,
                            items: colorOptions.keys.map((key) {
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: colorOptions[key],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(key),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedColor = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_featureTitleController.text.trim().isNotEmpty &&
                              _featureDescController.text.trim().isNotEmpty) {
                            setState(() {
                              featureCards.add({
                                'title': _featureTitleController.text.trim(),
                                'description':
                                    _featureDescController.text.trim(),
                                'icon': _selectedIcon,
                                'color': _selectedColor,
                              });
                              _featureTitleController.clear();
                              _featureDescController.clear();
                            });
                          } else {
                            Utils().toastMessage('Please fill in all fields');
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Feature Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return _buildCard(
      'Course Materials',
      'Upload course files and resources',
      Icons.folder_open,
      Column(
        children: [
          _buildTextField(
            controller: previewVideoController,
            labelText: 'Preview Video Link',
            hintText: 'Enter YouTube/Vimeo URL',
            prefixIcon: Icons.video_library,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: previewPdfController,
                  labelText: 'Preview PDF',
                  hintText: 'Upload course preview PDF',
                  prefixIcon: Icons.picture_as_pdf,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.upload),
                onPressed: () async => _handleFileUpload(
                  handler: previewPdfHandler,
                  controller: previewPdfController,
                  storagePath: 'course_previews',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: syllabusPdfController,
                  labelText: 'Syllabus PDF',
                  hintText: 'Upload course syllabus',
                  prefixIcon: Icons.assignment,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.upload),
                onPressed: () async => _handleFileUpload(
                  handler: syllabusPdfHandler,
                  controller: syllabusPdfController,
                  storagePath: 'course_syllabi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: schedulePdfController,
                  labelText: 'Schedule PDF',
                  hintText: 'Upload course schedule/timetable',
                  prefixIcon: Icons.calendar_month,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.upload),
                onPressed: () async => _handleFileUpload(
                  handler: schedulePdfHandler,
                  controller: schedulePdfController,
                  storagePath: 'course_schedules',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyDocumentsSection() {
    return _buildCard(
      'Key Documents',
      'Add worksheets, references, and other materials',
      Icons.library_books,
      Column(
        children: [
          if (keyDocuments.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Documents',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: keyDocuments.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final doc = keyDocuments[index];
                      final icon =
                          _getDocIconFromType(doc['type'] ?? 'document');

                      return ListTile(
                        leading: Icon(icon, color: ColorManager.primary),
                        title: Text(doc['title'] ?? ''),
                        subtitle: Text(doc['description'] ?? ''),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red.shade300),
                          onPressed: () {
                            setState(() {
                              keyDocuments.removeAt(index);
                            });
                          },
                        ),
                        dense: true,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ExpansionTile(
            title: const Text('Add New Document'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _documentTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title',
                        hintText: 'e.g., Week 1 Worksheet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _documentDescController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'e.g., Exercises to practice the first week\'s concepts',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Document Type',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDocType,
                      items: docTypeOptions.keys.map((key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Row(
                            children: [
                              Icon(docTypeOptions[key]),
                              const SizedBox(width: 8),
                              Text(key),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDocType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _documentUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Document URL',
                              hintText: 'Upload document or enter URL',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.upload),
                          onPressed: () async => _handleFileUpload(
                            handler: documentUploadHandler,
                            controller: _documentUrlController,
                            storagePath: 'course_documents/$_selectedDocType',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_documentTitleController.text.trim().isNotEmpty &&
                              _documentDescController.text.trim().isNotEmpty &&
                              _documentUrlController.text.trim().isNotEmpty) {
                            setState(() {
                              keyDocuments.add({
                                'title': _documentTitleController.text.trim(),
                                'description':
                                    _documentDescController.text.trim(),
                                'type': _selectedDocType,
                                'url': _documentUrlController.text.trim(),
                              });
                              _documentTitleController.clear();
                              _documentDescController.clear();
                              _documentUrlController.clear();
                            });
                          } else {
                            Utils().toastMessage('Please fill in all fields');
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Document'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Ready to Create?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isEditing
                      ? 'Review your changes and update the course'
                      : 'Review your course details and create',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Roundbuttonnew(
                    loading: loading,
                    title: widget.isEditing ? 'Update Course' : 'Create Course',
                    ontap: widget.isEditing ? _updateCourse : _createCourse,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon:
                Icon(prefixIcon, color: const Color(0xFF6B7280), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorManager.primary, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(prefixIcon, color: const Color(0xFF6B7280), size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: items,
            onChanged: onChanged,
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorFromString(String colorName) {
    return colorOptions[colorName] ?? Colors.blue;
  }

  IconData _getIconFromString(String iconName) {
    return iconOptions[iconName] ?? Icons.info;
  }

  IconData _getDocIconFromType(String docType) {
    return docTypeOptions[docType] ?? Icons.insert_drive_file;
  }

  void _createCourse() async {
    await _saveCourse(isUpdate: false);
  }

  void _updateCourse() async {
    await _saveCourse(isUpdate: true);
  }

  Future<void> _saveCourse({required bool isUpdate}) async {
    // Validate required fields
    if (coursenamecontroller.text.isEmpty ||
        coursediscriptioncontroller.text.isEmpty ||
        coursepricecontroller.text.isEmpty ||
        courseimglinkcontroller.text.isEmpty) {
      Utils().toastMessage('Please fill in all required fields');
      return;
    }

    if (selectedTeachers.isEmpty) {
      Utils().toastMessage(
        'Please select at least one teacher for this course',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    String courseId =
        isUpdate ? widget.courseDoc!.id : coursenamecontroller.text.toString();
    String newCourseName = coursenamecontroller.text.toString();

    try {
      // Prepare teachers data structure
      List<Map<String, dynamic>> teachersData = selectedTeachers
          .map(
            (teacher) => {
              'Name': teacher['Name'],
              'Email': teacher['Email'],
              'ProfilePicURL': teacher['ProfilePicURL'],
              'Subject': teacher['Subject'],
              'Qualification': teacher['Qualification'] ?? '',
              'Experience': teacher['Experience'] ?? '',
              'Rating': teacher['Rating'] ?? '4.5',
            },
          )
          .toList();

      Map<String, dynamic> courseData = {
        'Course Name': newCourseName,
        'Course Discription': coursediscriptioncontroller.text.toString(),
        'Course Price': coursepricecontroller.text,
        'Course Img Link': courseimglinkcontroller.text.toString(),
        'Category': selectedCategory,
        'Difficulty': difficultyController.text.isEmpty
            ? 'All Levels'
            : difficultyController.text,
        'Membership Discount': discountPercentageController.text.isEmpty
            ? "0"
            : discountPercentageController.text,
        'Duration': durationController.text,
        'Prerequisites': prerequisitesController.text,
        'Is Featured': isFeaturesCourse,
        'Teachers': teachersData,
        'LearningObjectives': learningObjectives,
        'FeatureCards': featureCards,
        'KeyDocuments': keyDocuments,
      };

      // Add optional fields
      if (previewVideoController.text.isNotEmpty)
        courseData['PreviewVideo'] = previewVideoController.text;
      if (previewPdfController.text.isNotEmpty)
        courseData['PreviewPDF'] = previewPdfController.text;
      if (syllabusPdfController.text.isNotEmpty)
        courseData['SyllabusPDF'] = syllabusPdfController.text;
      if (schedulePdfController.text.isNotEmpty)
        courseData['SchedulePDF'] = schedulePdfController.text;

      if (isUpdate) {
        // Update existing course
        courseData['Updated At'] = FieldValue.serverTimestamp();
        await fireStore.doc(courseId).update(courseData);

        // Handle course name change
        if (originalCourseName != null && originalCourseName != newCourseName) {
          await _handleCourseNameChange(
              originalCourseName!, newCourseName, teachersData);
        } else {
          // Update teachers' course lists if teachers changed
          await _updateTeachersCourses(newCourseName, teachersData);
        }

        Utils().toastMessage('Course Updated Successfully');
      } else {
        // Create new course
        courseData['Created At'] = FieldValue.serverTimestamp();
        await fireStore.doc(courseId).set(courseData);

        // Add course to teachers' lists
        await _updateTeachersCourses(newCourseName, teachersData);

        Utils().toastMessage('Course Created Successfully');
      }

      if (widget.onCourseAdded != null) {
        widget.onCourseAdded!();
      }

      Navigator.pop(context);
    } catch (error) {
      Utils().toastMessage(error.toString());
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _handleCourseNameChange(String oldName, String newName,
      List<Map<String, dynamic>> newTeachers) async {
    // Update all user enrollments
    final userTypes = ['student', 'teacher', 'parent'];
    for (String userType in userTypes) {
      final usersQuery = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userType)
          .collection('accounts')
          .get();

      for (var userDoc in usersQuery.docs) {
        Map<String, dynamic> userData = userDoc.data();
        if (userData.containsKey(oldName)) {
          // Copy old course data to new name
          final courseData = userData[oldName];
          await userDoc.reference.update({
            newName: courseData,
            oldName: FieldValue.delete(),
          });
        }
      }
    }

    // Update teachers' course lists
    await _updateTeachersCourses(newName, newTeachers);

    // Remove old course name from previous teachers who are no longer assigned
    final oldCourseDoc = await fireStore.doc(widget.courseDoc!.id).get();
    if (oldCourseDoc.exists) {
      final oldData = oldCourseDoc.data() as Map<String, dynamic>;
      List<dynamic> oldTeachers = oldData['Teachers'] ?? [];

      for (var oldTeacher in oldTeachers) {
        bool stillAssigned = newTeachers
            .any((newTeacher) => newTeacher['Email'] == oldTeacher['Email']);

        if (!stillAssigned) {
          final teacherQuery = await FirebaseFirestore.instance
              .collection('Users')
              .doc('teacher')
              .collection('accounts')
              .where('Email', isEqualTo: oldTeacher['Email'])
              .limit(1)
              .get();

          if (teacherQuery.docs.isNotEmpty) {
            final teacherDoc = teacherQuery.docs.first;
            List<dynamic> currentCourses =
                teacherDoc.data()['My Courses'] ?? [];
            currentCourses.remove(oldName);
            await teacherDoc.reference.update({'My Courses': currentCourses});
          }
        }
      }
    }
  }

  Future<void> _updateTeachersCourses(
      String courseName, List<Map<String, dynamic>> teachers) async {
    for (var teacher in teachers) {
      final teacherQuery = await FirebaseFirestore.instance
          .collection('Users')
          .doc('teacher')
          .collection('accounts')
          .where('Email', isEqualTo: teacher['Email'])
          .limit(1)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        final teacherDoc = teacherQuery.docs.first;
        List<dynamic> currentCourses = teacherDoc.data()['My Courses'] ?? [];
        if (!currentCourses.contains(courseName)) {
          currentCourses.add(courseName);
          await teacherDoc.reference.update({'My Courses': currentCourses});
        }
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    coursediscriptioncontroller.dispose();
    coursenamecontroller.dispose();
    coursepricecontroller.dispose();
    courseimglinkcontroller.dispose();
    discountPercentageController.dispose();
    durationController.dispose();
    prerequisitesController.dispose();
    difficultyController.dispose();
    previewPdfController.dispose();
    previewVideoController.dispose();
    syllabusPdfController.dispose();
    schedulePdfController.dispose();
    _objectiveController.dispose();
    _featureTitleController.dispose();
    _featureDescController.dispose();
    _documentTitleController.dispose();
    _documentDescController.dispose();
    _documentUrlController.dispose();
    super.dispose();
  }
}
