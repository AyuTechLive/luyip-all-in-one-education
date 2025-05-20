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
  const AddCourse({super.key, this.onCourseAdded});

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

  @override
  void initState() {
    super.initState();
    previewPdfHandler = FileUploadHandler();
    syllabusPdfHandler = FileUploadHandler();
    schedulePdfHandler = FileUploadHandler();
    documentUploadHandler = FileUploadHandler();
    imageHandler = ImageUploadHandler();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Course',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ColorManager.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textDark,
                ),
              ),
              SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Basic Details'),
                        SizedBox(height: 16),

                        // Course name field
                        _buildTextField(
                          controller: coursenamecontroller,
                          labelText: 'Course Name',
                          hintText: 'Enter course name',
                          prefixIcon: Icons.title,
                          maxLines: 1,
                        ),
                        SizedBox(height: 16),

                        // Course category dropdown
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
                        SizedBox(height: 16),

                        // Difficulty level field
                        _buildTextField(
                          controller: difficultyController,
                          labelText: 'Difficulty Level',
                          hintText: 'e.g., Beginner, Intermediate, Advanced',
                          prefixIcon: Icons.trending_up,
                          maxLines: 1,
                        ),
                        SizedBox(height: 16),

                        // Course description field
                        _buildTextField(
                          controller: coursediscriptioncontroller,
                          labelText: 'Course Description',
                          hintText: 'Provide a detailed description',
                          prefixIcon: Icons.description,
                          maxLines: 5,
                        ),
                        SizedBox(height: 24),

                        _buildSectionTitle('Pricing Information'),
                        SizedBox(height: 16),

                        // Course price field
                        _buildTextField(
                          controller: coursepricecontroller,
                          labelText: 'Price (₹)',
                          hintText: 'Enter course price',
                          prefixIcon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          maxLines: 1,
                        ),
                        SizedBox(height: 16),

                        // Discount percentage field
                        _buildTextField(
                          controller: discountPercentageController,
                          labelText: 'Membership Discount (%)',
                          hintText: 'Enter discount percentage for members',
                          prefixIcon: Icons.discount,
                          keyboardType: TextInputType.number,
                          maxLines: 1,
                        ),
                        SizedBox(height: 24),

                        _buildSectionTitle('Additional Information'),
                        SizedBox(height: 16),

                        // Duration field
                        _buildTextField(
                          controller: durationController,
                          labelText: 'Course Duration',
                          hintText: 'e.g., 8 weeks, 12 hours',
                          prefixIcon: Icons.timer,
                          maxLines: 1,
                        ),
                        SizedBox(height: 16),

                        // Prerequisites field
                        _buildTextField(
                          controller: prerequisitesController,
                          labelText: 'Prerequisites',
                          hintText: 'Any requirements or prerequisites',
                          prefixIcon: Icons.list_alt,
                          maxLines: 3,
                        ),
                        SizedBox(height: 16),

                        // Featured course checkbox
                        CheckboxListTile(
                          title: Text('Featured Course'),
                          value: isFeaturesCourse,
                          onChanged: (value) {
                            setState(() {
                              isFeaturesCourse = value!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 32),

                  // Right column
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Course Banner Image'),
                        SizedBox(height: 16),

                        // Image upload section using the new handler
                        imageHandler.getImagePreview(
                          height: 200,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        SizedBox(height: 16),

                        ElevatedButton.icon(
                          icon: Icon(Icons.upload),
                          label: Text('Select Banner Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 48),
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
                              } catch (e) {
                                Utils().toastMessage(
                                  'Failed to upload image: $e',
                                );
                              } finally {
                                setState(() {
                                  loading = false;
                                });
                              }
                            }
                          },
                        ),
                        SizedBox(height: 24),

                        // Replace single teacher selection with multiple teachers component
                        AddCourseTeachers(
                          selectedTeachers: selectedTeachers,
                          onTeachersChanged: (teachers) {
                            setState(() {
                              selectedTeachers = teachers;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Learning Objectives Section
              _buildSectionTitle('Learning Objectives'),
              SizedBox(height: 16),
              _buildObjectivesSection(),
              SizedBox(height: 24),

              // Feature Cards Section
              _buildSectionTitle('Feature Cards'),
              SizedBox(height: 16),
              _buildFeatureCardsSection(),
              SizedBox(height: 24),

              // Materials Section
              _buildSectionTitle('Course Materials'),
              SizedBox(height: 16),
              _buildMaterialsSection(),
              SizedBox(height: 24),

              // Key Documents Section
              _buildSectionTitle('Key Documents'),
              SizedBox(height: 16),
              _buildKeyDocumentsSection(),
              SizedBox(height: 32),

              // Submit button
              Center(
                child: SizedBox(
                  width: 300,
                  height: 50,
                  child: Roundbuttonnew(
                    loading: loading,
                    title: 'Create Course',
                    ontap: _createCourse,
                  ),
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectivesSection() {
    return Column(
      children: [
        Text(
            'Add learning objectives that students will achieve in this course'),
        SizedBox(height: 8),

        // List of existing objectives
        if (learningObjectives.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Objectives',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorManager.textDark,
                  ),
                ),
                SizedBox(height: 8),
                ...learningObjectives.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String objective = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: ColorManager.primary),
                        SizedBox(width: 8),
                        Expanded(child: Text(objective)),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red.shade300),
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
          SizedBox(height: 16),
        ],

        // Add new objective
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _objectiveController,
                decoration: InputDecoration(
                  labelText: 'Objective',
                  hintText: 'e.g., Master fundamental concepts',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 8),
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
                padding: EdgeInsets.all(12),
              ),
              child: Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCardsSection() {
    return Column(
      children: [
        Text('Add feature cards to highlight key aspects of your course'),
        SizedBox(height: 8),

        // List of existing feature cards
        if (featureCards.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feature Cards',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorManager.textDark,
                  ),
                ),
                SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                    final icon = _getIconFromString(feature['icon'] ?? 'info');

                    return Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
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
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      feature['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  feature['description'] ?? '',
                                  style: TextStyle(fontSize: 12),
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
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
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
          SizedBox(height: 16),
        ],

        // Add new feature card
        ExpansionTile(
          title: Text('Add New Feature Card'),
          tilePadding: EdgeInsets.symmetric(horizontal: 8),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _featureTitleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., Video Lectures',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _featureDescController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText:
                          'e.g., HD video content with interactive elements',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
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
                                  SizedBox(width: 8),
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
                      SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
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
                                  SizedBox(width: 8),
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
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_featureTitleController.text.trim().isNotEmpty &&
                          _featureDescController.text.trim().isNotEmpty) {
                        setState(() {
                          featureCards.add({
                            'title': _featureTitleController.text.trim(),
                            'description': _featureDescController.text.trim(),
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
                    icon: Icon(Icons.add),
                    label: Text('Add Feature Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialsSection() {
    return Column(
      children: [
        // Preview Video Link
        _buildTextField(
          controller: previewVideoController,
          labelText: 'Preview Video Link',
          hintText: 'Enter YouTube/Vimeo URL',
          prefixIcon: Icons.video_library,
        ),
        SizedBox(height: 16),

        // Preview PDF Upload
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
              icon: Icon(Icons.upload),
              onPressed: () async => _handleFileUpload(
                handler: previewPdfHandler,
                controller: previewPdfController,
                storagePath: 'course_previews',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Syllabus PDF Upload
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
              icon: Icon(Icons.upload),
              onPressed: () async => _handleFileUpload(
                handler: syllabusPdfHandler,
                controller: syllabusPdfController,
                storagePath: 'course_syllabi',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Schedule PDF Upload
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
              icon: Icon(Icons.upload),
              onPressed: () async => _handleFileUpload(
                handler: schedulePdfHandler,
                controller: schedulePdfController,
                storagePath: 'course_schedules',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyDocumentsSection() {
    return Column(
      children: [
        Text(
            'Add key documents for your course (worksheets, references, etc.)'),
        SizedBox(height: 8),

        // List of existing documents
        if (keyDocuments.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Documents',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorManager.textDark,
                  ),
                ),
                SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: keyDocuments.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final doc = keyDocuments[index];
                    final icon = _getDocIconFromType(doc['type'] ?? 'document');

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
          SizedBox(height: 16),
        ],

        // Add new document
        ExpansionTile(
          title: Text('Add New Document'),
          tilePadding: EdgeInsets.symmetric(horizontal: 8),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _documentTitleController,
                    decoration: InputDecoration(
                      labelText: 'Document Title',
                      hintText: 'e.g., Week 1 Worksheet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _documentDescController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText:
                          'e.g., Exercises to practice the first week\'s concepts',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
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
                            SizedBox(width: 8),
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
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _documentUrlController,
                          decoration: InputDecoration(
                            labelText: 'Document URL',
                            hintText: 'Upload document or enter URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.upload),
                        onPressed: () async => _handleFileUpload(
                          handler: documentUploadHandler,
                          controller: _documentUrlController,
                          storagePath: 'course_documents/${_selectedDocType}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_documentTitleController.text.trim().isNotEmpty &&
                          _documentDescController.text.trim().isNotEmpty &&
                          _documentUrlController.text.trim().isNotEmpty) {
                        setState(() {
                          keyDocuments.add({
                            'title': _documentTitleController.text.trim(),
                            'description': _documentDescController.text.trim(),
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
                    icon: Icon(Icons.add),
                    label: Text('Add Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorManager.primary,
          ),
        ),
        Divider(color: ColorManager.primary.withOpacity(0.5)),
      ],
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
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required IconData prefixIcon,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
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

    String id = coursenamecontroller.text.toString();
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

      await fireStore.doc(id).set({
        'Course Name': coursenamecontroller.text.toString(),
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
        'Created At': FieldValue.serverTimestamp(),

        // Add new dynamic content fields
        'LearningObjectives': learningObjectives,
        'FeatureCards': featureCards,
        'KeyDocuments': keyDocuments,

        // Add PDF documents
        if (previewVideoController.text.isNotEmpty)
          'PreviewVideo': previewVideoController.text,
        if (previewPdfController.text.isNotEmpty)
          'PreviewPDF': previewPdfController.text,
        if (syllabusPdfController.text.isNotEmpty)
          'SyllabusPDF': syllabusPdfController.text,
        if (schedulePdfController.text.isNotEmpty)
          'SchedulePDF': schedulePdfController.text,
      });

      // Also add the course to each teacher's My Courses list
      for (var teacher in selectedTeachers) {
        final teacherRef = FirebaseFirestore.instance
            .collection('Users')
            .doc('teacher')
            .collection('accounts')
            .where('Email', isEqualTo: teacher['Email'])
            .limit(1);

        final teacherDocs = await teacherRef.get();
        if (teacherDocs.docs.isNotEmpty) {
          final teacherDoc = teacherDocs.docs.first;
          List<dynamic> currentCourses = teacherDoc.data()['My Courses'] ?? [];
          if (!currentCourses.contains(coursenamecontroller.text.toString())) {
            currentCourses.add(coursenamecontroller.text.toString());
            await teacherDoc.reference.update({'My Courses': currentCourses});
          }
        }
      }

      Utils().toastMessage('Course Created Successfully');

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
}
